package main

import (
	"context"
	"encoding/json"
	"fmt"
	"innerworld-backend/internal/config"
	"innerworld-backend/internal/llm"
	"innerworld-backend/internal/personas"
	"innerworld-backend/internal/storage"
	"innerworld-backend/internal/types"
	"innerworld-backend/internal/workflow"
	"log"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/google/uuid"
)

// Global variables for connection reuse across invocations
var (
	cfg               *config.Config
	dynamoDB          storage.DynamoDBClient
	openRouterClient  *llm.OpenRouterClient
	personaLoader     *personas.PersonaLoader
	conversationChain *workflow.ConversationChain
	connectionStore   map[string]string // connectionID -> userID mapping (mock)
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

	// Initialize OpenRouter client if API key is available
	if cfg.OpenRouter.APIKey != "" && cfg.OpenRouter.APIKey != "your-openrouter-api-key-here" {
		openRouterClient = llm.NewOpenRouterClient(cfg.OpenRouter.APIKey)
		log.Println("Initialized OpenRouter client")
	} else {
		log.Println("OpenRouter API key not provided - will use mock responses")
	}

	// Initialize persona loader
	personaLoader = personas.NewPersonaLoader()
	log.Printf("Initialized persona loader with %d personas", len(personaLoader.GetAvailablePersonas()))

	// Initialize LangChain conversation chain
	conversationChain = workflow.NewConversationChain(personaLoader, openRouterClient, dynamoDB)
	log.Println("Initialized LangChain conversation chain")

	// Initialize connection store (mock for Phase 2)
	connectionStore = make(map[string]string)
}

// handleWebSocketEvent processes WebSocket API Gateway events
func handleWebSocketEvent(ctx context.Context, request events.APIGatewayWebsocketProxyRequest) (events.APIGatewayProxyResponse, error) {
	log.Printf("Processing WebSocket event: %s for connection %s", request.RequestContext.RouteKey, request.RequestContext.ConnectionID)

	switch request.RequestContext.RouteKey {
	case "$connect":
		return handleConnect(ctx, request)
	case "$disconnect":
		return handleDisconnect(ctx, request)
	case "sendmessage":
		return handleSendMessage(ctx, request)
	case "$default":
		return handleDefault(ctx, request)
	default:
		log.Printf("Unknown route: %s", request.RequestContext.RouteKey)
		return events.APIGatewayProxyResponse{StatusCode: 400}, nil
	}
}

// handleConnect manages new WebSocket connections
func handleConnect(ctx context.Context, request events.APIGatewayWebsocketProxyRequest) (events.APIGatewayProxyResponse, error) {
	connectionID := request.RequestContext.ConnectionID

	// Extract user ID from query parameters (set by frontend during connection)
	userID := request.QueryStringParameters["userId"]
	if userID == "" {
		log.Printf("Connection rejected - no userId provided")
		return events.APIGatewayProxyResponse{StatusCode: 400}, nil
	}

	// Store connection mapping (Phase 2: in-memory, Phase 3+: DynamoDB table)
	connectionStore[connectionID] = userID

	log.Printf("WebSocket connected: %s -> %s", connectionID, userID)

	// Send welcome message
	welcomeMsg := types.WebSocketResponse{
		MessageID:   "welcome_" + uuid.New().String()[:8],
		Content:     "Connected to InnerWorld. Choose your persona and start chatting!",
		Timestamp:   time.Now(),
		MessageType: "system",
	}

	// Phase 2: Mock sending message (Phase 3+: actual WebSocket API Gateway call)
	log.Printf("Would send welcome message to connection %s: %s", connectionID, welcomeMsg.Content)

	return events.APIGatewayProxyResponse{StatusCode: 200}, nil
}

// handleDisconnect manages WebSocket disconnections and triggers session end processing
func handleDisconnect(ctx context.Context, request events.APIGatewayWebsocketProxyRequest) (events.APIGatewayProxyResponse, error) {
	connectionID := request.RequestContext.ConnectionID

	// Get user ID from connection mapping
	userID, exists := connectionStore[connectionID]
	if !exists {
		log.Printf("Disconnect for unknown connection: %s", connectionID)
		return events.APIGatewayProxyResponse{StatusCode: 200}, nil
	}

	log.Printf("WebSocket disconnected: %s (user: %s)", connectionID, userID)

	// Clean up connection mapping
	delete(connectionStore, connectionID)

	// Trigger session end processing for any active sessions
	// Phase 2: Mock session end processing
	// Phase 3+: Invoke Session End Processor Lambda
	log.Printf("Would trigger session end processing for user %s", userID)

	return events.APIGatewayProxyResponse{StatusCode: 200}, nil
}

// handleSendMessage processes conversation messages
func handleSendMessage(ctx context.Context, request events.APIGatewayWebsocketProxyRequest) (events.APIGatewayProxyResponse, error) {
	connectionID := request.RequestContext.ConnectionID

	// Get user ID from connection mapping
	userID, exists := connectionStore[connectionID]
	if !exists {
		log.Printf("Message from unknown connection: %s", connectionID)
		return events.APIGatewayProxyResponse{StatusCode: 400}, nil
	}

	// Parse incoming message
	var wsMessage types.WebSocketMessage
	if err := json.Unmarshal([]byte(request.Body), &wsMessage); err != nil {
		log.Printf("Failed to parse WebSocket message: %v", err)
		return events.APIGatewayProxyResponse{StatusCode: 400}, nil
	}

	// Validate message
	wsMessage.UserID = userID // Ensure user ID matches connection
	if wsMessage.SessionID == "" {
		wsMessage.SessionID = "session_" + uuid.New().String()[:8]
	}
	if wsMessage.Persona == "" {
		wsMessage.Persona = "default"
	}

	log.Printf("Processing message from user %s (session %s, persona %s): %s",
		userID, wsMessage.SessionID, wsMessage.Persona, wsMessage.Message[:min(50, len(wsMessage.Message))])

	// Retrieve cached user context
	userContext, err := dynamoDB.GetUserContext(ctx, userID)
	if err != nil {
		log.Printf("Failed to retrieve user context (using empty): %v", err)
		// Continue with empty context rather than failing
	}

	var contextData map[string]interface{}
	if userContext != nil {
		contextData = userContext.ContextData
	}

	// Execute LangChain conversation processing
	conversationInput := &workflow.ConversationInput{
		UserMessage:  wsMessage.Message,
		Persona:      wsMessage.Persona,
		SessionID:    wsMessage.SessionID,
		UserID:       userID,
		UserContext:  contextData,
		SessionStart: time.Now(), // Phase 3+: Track actual session start time
	}

	conversationResult, err := conversationChain.ProcessConversation(ctx, conversationInput)
	if err != nil {
		log.Printf("LangChain conversation processing failed: %v", err)

		// Send error response
		errorResponse := types.WebSocketResponse{
			MessageID:   "error_" + uuid.New().String()[:8],
			Content:     "I'm sorry, I'm having trouble processing your message right now. Please try again.",
			Persona:     wsMessage.Persona,
			Timestamp:   time.Now(),
			SessionID:   wsMessage.SessionID,
			MessageType: "assistant",
		}

		return sendWebSocketResponse(ctx, connectionID, errorResponse)
	}

	// Send AI response back to client
	response := types.WebSocketResponse{
		MessageID:   conversationResult.MessageID,
		Content:     conversationResult.LLMResponse,
		Persona:     wsMessage.Persona,
		Timestamp:   conversationResult.ProcessedAt,
		SessionID:   wsMessage.SessionID,
		MessageType: "assistant",
	}

	return sendWebSocketResponse(ctx, connectionID, response)
}

// handleDefault handles unknown WebSocket routes
func handleDefault(ctx context.Context, request events.APIGatewayWebsocketProxyRequest) (events.APIGatewayProxyResponse, error) {
	log.Printf("Default handler for route: %s", request.RequestContext.RouteKey)
	return events.APIGatewayProxyResponse{StatusCode: 200}, nil
}

// sendWebSocketResponse sends a response message back through the WebSocket
func sendWebSocketResponse(ctx context.Context, connectionID string, response types.WebSocketResponse) (events.APIGatewayProxyResponse, error) {
	// Phase 2: Mock WebSocket response (log the message)
	// Phase 3+: Use API Gateway WebSocket API to send actual message

	responseJSON, _ := json.Marshal(response)
	log.Printf("Sending WebSocket response to connection %s: %s", connectionID, string(responseJSON))

	// Mock successful response
	return events.APIGatewayProxyResponse{
		StatusCode: 200,
		Body:       string(responseJSON),
	}, nil
}

// handleDirectInvocation handles direct Lambda invocations for testing
func handleDirectInvocation(ctx context.Context, wsMessage types.WebSocketMessage) (*types.WebSocketResponse, error) {
	log.Printf("Processing direct WebSocket message for testing")

	// Set defaults for testing
	if wsMessage.SessionID == "" {
		wsMessage.SessionID = "test_session_" + uuid.New().String()[:8]
	}
	if wsMessage.Persona == "" {
		wsMessage.Persona = "default"
	}
	if wsMessage.UserID == "" {
		wsMessage.UserID = "test_user"
	}

	// Mock user context retrieval
	contextData := storage.GenerateMockUserContext(wsMessage.UserID)

	// Execute LangChain conversation processing
	conversationInput := &workflow.ConversationInput{
		UserMessage:  wsMessage.Message,
		Persona:      wsMessage.Persona,
		SessionID:    wsMessage.SessionID,
		UserID:       wsMessage.UserID,
		UserContext:  contextData,
		SessionStart: time.Now(),
	}

	conversationResult, err := conversationChain.ProcessConversation(ctx, conversationInput)
	if err != nil {
		return nil, fmt.Errorf("LangChain conversation processing failed: %w", err)
	}

	response := &types.WebSocketResponse{
		MessageID:   conversationResult.MessageID,
		Content:     conversationResult.LLMResponse,
		Persona:     wsMessage.Persona,
		Timestamp:   conversationResult.ProcessedAt,
		SessionID:   wsMessage.SessionID,
		MessageType: "assistant",
	}

	return response, nil
}

// Helper function for min
func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

func main() {
	lambda.Start(func(ctx context.Context, event json.RawMessage) (interface{}, error) {
		// Try to parse as WebSocket API Gateway event first
		var wsEvent events.APIGatewayWebsocketProxyRequest
		if err := json.Unmarshal(event, &wsEvent); err == nil && wsEvent.RequestContext.ConnectionID != "" {
			// WebSocket API Gateway invocation
			return handleWebSocketEvent(ctx, wsEvent)
		}

		// Try direct invocation for testing
		var directMessage types.WebSocketMessage
		if err := json.Unmarshal(event, &directMessage); err == nil && directMessage.Message != "" {
			return handleDirectInvocation(ctx, directMessage)
		}

		return nil, fmt.Errorf("unrecognized event format")
	})
}
