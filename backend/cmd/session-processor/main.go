package main

import (
	"context"
	"encoding/json"
	"fmt"
	"innerworld-backend/internal/config"
	"innerworld-backend/internal/graph"
	"innerworld-backend/internal/llm"
	"innerworld-backend/internal/storage"
	"innerworld-backend/internal/types"
	"log"
	"strings"
	"time"

	"github.com/aws/aws-lambda-go/lambda"
)

// Global variables for connection reuse across invocations
var (
	cfg              *config.Config
	dynamoDB         storage.DynamoDBClient
	neptuneClient    graph.NeptuneClient
	openRouterClient *llm.OpenRouterClient
)

// init runs once when Lambda container starts
func init() {
	var err error

	// Load configuration
	cfg, err = config.LoadConfig()
	if err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}

	// Initialize DynamoDB client (mock for Phase 2)
	dynamoDB = storage.NewMockDynamoDBClient()
	log.Println("Initialized mock DynamoDB client")

	// Initialize Neptune client (mock for Phase 2)
	neptuneClient = graph.NewMockNeptuneClient()
	log.Println("Initialized mock Neptune client - GraphRAG disabled in Phase 2")

	// Initialize OpenRouter client for element extraction
	if cfg.OpenRouter.APIKey != "" && cfg.OpenRouter.APIKey != "your-openrouter-api-key-here" {
		openRouterClient = llm.NewOpenRouterClient(cfg.OpenRouter.APIKey)
		log.Println("Initialized OpenRouter client for conversation analysis")
	} else {
		log.Println("OpenRouter API key not provided - will use mock element extraction")
	}
}

// handleSessionEndProcessing processes session end requests
func handleSessionEndProcessing(ctx context.Context, request types.SessionEndRequest) (*types.SessionProcessingResult, error) {
	log.Printf("Processing session end for session %s (reason: %s)", request.SessionID, request.Reason)

	startTime := time.Now()

	result := &types.SessionProcessingResult{
		SessionID:   request.SessionID,
		ProcessedAt: startTime,
		Success:     false,
	}

	// Step 1: Retrieve all messages for the session from DynamoDB
	messages, err := dynamoDB.GetSessionMessages(ctx, request.SessionID)
	if err != nil {
		result.Error = fmt.Sprintf("failed to retrieve session messages: %v", err)
		return result, err
	}

	if len(messages) == 0 {
		log.Printf("No messages found for session %s", request.SessionID)
		result.Success = true // Not an error, just empty session
		return result, nil
	}

	log.Printf("Retrieved %d messages for session %s", len(messages), request.SessionID)

	// Step 2: Extract conversation elements (Events, Feelings, Values, etc.)
	elements, err := extractConversationElements(ctx, messages)
	if err != nil {
		result.Error = fmt.Sprintf("failed to extract conversation elements: %v", err)
		return result, err
	}

	result.ElementsExtracted = elements
	log.Printf("Extracted %d elements from conversation", len(elements))

	// Step 3: Update Neptune graph with extracted elements
	nodesCreated, edgesCreated, err := updateNeptuneGraph(ctx, request.UserID, elements)
	if err != nil {
		result.Error = fmt.Sprintf("failed to update Neptune graph: %v", err)
		return result, err
	}

	result.GraphNodesCreated = nodesCreated
	result.GraphEdgesCreated = edgesCreated
	log.Printf("Created %d nodes and %d edges in Neptune", nodesCreated, edgesCreated)

	// Step 4: Refresh cached context with new graph data
	if err := refreshUserContext(ctx, request.UserID); err != nil {
		// Log error but don't fail the entire process
		log.Printf("Failed to refresh user context cache: %v", err)
	} else {
		log.Printf("Refreshed context cache for user %s", request.UserID)
	}

	// Step 5: Clean up DynamoDB conversation data
	if err := dynamoDB.DeleteSessionMessages(ctx, request.SessionID); err != nil {
		// Log error but don't fail the entire process
		log.Printf("Failed to cleanup session messages: %v", err)
	} else {
		log.Printf("Cleaned up session messages for %s", request.SessionID)
	}

	result.Success = true
	log.Printf("Successfully processed session %s in %v", request.SessionID, time.Since(startTime))

	return result, nil
}

// extractConversationElements analyzes the conversation to extract meaningful elements
func extractConversationElements(ctx context.Context, messages []types.LiveConversationItem) ([]types.ConversationElement, error) {
	log.Printf("Extracting elements from %d messages", len(messages))

	// Build conversation text for analysis
	var conversationText strings.Builder
	for _, msg := range messages {
		conversationText.WriteString(fmt.Sprintf("%s: %s\n", msg.MessageType, msg.Content))
	}

	conversation := conversationText.String()
	if len(conversation) > 4000 { // Limit for API call
		conversation = conversation[:4000] + "..."
	}

	if openRouterClient == nil {
		// Mock element extraction for Phase 2
		return generateMockElements(messages), nil
	}

	// Use LLM to analyze conversation and extract elements
	analysisPrompt := buildExtractionPrompt(conversation)

	response, err := openRouterClient.GenerateResponse(ctx, analysisPrompt)
	if err != nil {
		log.Printf("LLM element extraction failed, using mock: %v", err)
		return generateMockElements(messages), nil
	}

	if len(response.Choices) == 0 {
		return generateMockElements(messages), nil
	}

	// Parse LLM response into structured elements
	elements := parseExtractedElements(response.Choices[0].Message.Content, messages)

	log.Printf("LLM extracted %d elements", len(elements))
	return elements, nil
}

// buildExtractionPrompt creates the prompt for element extraction
func buildExtractionPrompt(conversation string) string {
	return fmt.Sprintf(`Analyze this conversation between a teen and an AI companion. Extract meaningful elements in JSON format:

Types to extract:
- Event: Specific things that happened or are happening
- Feeling: Emotions experienced by the user
- Value: What matters to the user or guides their decisions
- Goal: Things the user wants to achieve or work toward
- Habit: Patterns of behavior, positive or negative

For each element, provide:
- type: one of the above types
- content: brief description 
- confidence: 0.0-1.0 confidence score

Example output:
[
  {"type": "Event", "content": "presentation at school tomorrow", "confidence": 0.9},
  {"type": "Feeling", "content": "nervous about public speaking", "confidence": 0.8},
  {"type": "Value", "content": "wants to do well academically", "confidence": 0.7}
]

Conversation:
%s

Extract 3-8 most meaningful elements as JSON array:`, conversation)
}

// parseExtractedElements converts LLM response to structured elements
func parseExtractedElements(llmResponse string, messages []types.LiveConversationItem) []types.ConversationElement {
	// Try to parse JSON from LLM response
	var elements []types.ConversationElement

	// Look for JSON array in the response
	start := strings.Index(llmResponse, "[")
	end := strings.LastIndex(llmResponse, "]")

	if start != -1 && end != -1 && end > start {
		jsonStr := llmResponse[start : end+1]

		var rawElements []map[string]interface{}
		if err := json.Unmarshal([]byte(jsonStr), &rawElements); err == nil {
			for _, raw := range rawElements {
				element := types.ConversationElement{
					Timestamp: time.Now(),
					Metadata:  make(map[string]interface{}),
				}

				if typ, ok := raw["type"].(string); ok {
					element.Type = typ
				}
				if content, ok := raw["content"].(string); ok {
					element.Content = content
				}
				if conf, ok := raw["confidence"].(float64); ok {
					element.Confidence = conf
				}

				elements = append(elements, element)
			}
		}
	}

	// Fallback to mock if parsing failed
	if len(elements) == 0 {
		elements = generateMockElements(messages)
	}

	return elements
}

// generateMockElements creates mock elements for Phase 2 testing
func generateMockElements(messages []types.LiveConversationItem) []types.ConversationElement {
	elements := []types.ConversationElement{
		{
			Type:       "Event",
			Content:    "user engaged in conversation",
			Confidence: 0.9,
			Timestamp:  time.Now(),
			Metadata:   map[string]interface{}{"message_count": len(messages)},
		},
		{
			Type:       "Feeling",
			Content:    "seeking connection and support",
			Confidence: 0.7,
			Timestamp:  time.Now(),
			Metadata:   map[string]interface{}{"session_type": "conversational"},
		},
	}

	// Add persona-specific elements
	if len(messages) > 0 {
		persona := messages[0].Persona
		switch persona {
		case "courage":
			elements = append(elements, types.ConversationElement{
				Type:       "Goal",
				Content:    "building confidence and courage",
				Confidence: 0.8,
				Timestamp:  time.Now(),
				Metadata:   map[string]interface{}{"persona": persona},
			})
		case "comfort":
			elements = append(elements, types.ConversationElement{
				Type:       "Feeling",
				Content:    "needing emotional support",
				Confidence: 0.8,
				Timestamp:  time.Now(),
				Metadata:   map[string]interface{}{"persona": persona},
			})
		}
	}

	return elements
}

// updateNeptuneGraph creates nodes and edges in the Neptune graph database
func updateNeptuneGraph(ctx context.Context, userID string, elements []types.ConversationElement) (int, int, error) {
	log.Printf("Updating Neptune graph for user %s with %d elements", userID, len(elements))

	// Phase 2: Mock Neptune operations
	// Phase 3+: Real Gremlin queries to create nodes and relationships

	nodesCreated := 0
	edgesCreated := 0

	for _, element := range elements {
		// Mock node creation
		nodeID := fmt.Sprintf("%s_%s_%d", element.Type, userID, time.Now().Unix())

		// Create node in Neptune (mock)
		if err := neptuneClient.CreateNode(userID, element.Type, element.Content); err != nil {
			log.Printf("Failed to create node %s: %v", nodeID, err)
			continue
		}
		nodesCreated++

		// Create temporal edge (mock)
		if err := neptuneClient.CreateEdge(userID, nodeID, "temporal", element.Timestamp.Format(time.RFC3339)); err != nil {
			log.Printf("Failed to create temporal edge for %s: %v", nodeID, err)
		} else {
			edgesCreated++
		}
	}

	log.Printf("Neptune graph update completed: %d nodes, %d edges", nodesCreated, edgesCreated)
	return nodesCreated, edgesCreated, nil
}

// refreshUserContext updates the cached user context with new Neptune data
func refreshUserContext(ctx context.Context, userID string) error {
	log.Printf("Refreshing context cache for user %s", userID)

	// Retrieve updated context from Neptune
	graphContext, err := neptuneClient.GetUserContext(ctx, userID)
	if err != nil {
		return fmt.Errorf("failed to retrieve updated context: %w", err)
	}

	// Convert GraphContext to map format for caching
	contextData := map[string]interface{}{
		"user_id":      userID,
		"summary":      graphContext.Summary,
		"last_updated": graphContext.LastUpdated.Format(time.RFC3339),
		"refreshed_at": time.Now().Format(time.RFC3339),
	}

	// Add additional mock context data
	mockData := storage.GenerateMockUserContext(userID)
	for key, value := range mockData {
		contextData[key] = value
	}

	// Add refresh timestamp
	contextData["last_refreshed"] = time.Now().Format(time.RFC3339)
	contextData["refresh_source"] = "session_processing"

	// Update cache
	if err := dynamoDB.RefreshUserContext(ctx, userID, contextData); err != nil {
		return fmt.Errorf("failed to update context cache: %w", err)
	}

	log.Printf("Successfully refreshed context cache for user %s", userID)
	return nil
}

func main() {
	lambda.Start(func(ctx context.Context, event json.RawMessage) (interface{}, error) {
		var request types.SessionEndRequest
		if err := json.Unmarshal(event, &request); err != nil {
			return nil, fmt.Errorf("failed to parse session end request: %w", err)
		}

		if request.SessionID == "" || request.UserID == "" {
			return nil, fmt.Errorf("missing required fields: sessionId and userId")
		}

		return handleSessionEndProcessing(ctx, request)
	})
}
