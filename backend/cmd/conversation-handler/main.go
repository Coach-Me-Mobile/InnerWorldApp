package main

import (
	"context"
	"encoding/json"
	"fmt"
	"innerworld-backend/internal/config"
	// TODO: Uncomment when GraphRAG is implemented in Phase 2
	// "innerworld-backend/internal/embeddings"
	// "innerworld-backend/internal/graph"
	"innerworld-backend/internal/llm"
	"log"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/google/uuid"
)

// ConversationRequest represents a basic conversation request
type ConversationRequest struct {
	Message string `json:"message"`
	UserID  string `json:"userId"`
}

// ConversationResponse represents a basic conversation response
type ConversationResponse struct {
	MessageID string    `json:"messageId"`
	Content   string    `json:"content"`
	Timestamp time.Time `json:"timestamp"`
}

// Global variables for connection reuse across invocations
var (
	cfg              *config.Config
	openRouterClient *llm.OpenRouterClient
	// TODO: Implement openAIClient for embeddings when GraphRAG is added
	// openAIClient     *embeddings.OpenAIEmbeddingsClient
	// TODO: Implement neptuneClient for graph operations when GraphRAG is added
	// neptuneClient    graph.NeptuneClient
)

// init runs once when Lambda container starts
func init() {
	var err error

	// Load configuration
	cfg, err = config.LoadConfig()
	if err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}

	// Initialize OpenRouter client if API key is available
	if cfg.OpenRouter.APIKey != "" && cfg.OpenRouter.APIKey != "your-openrouter-api-key-here" {
		openRouterClient = llm.NewOpenRouterClient(cfg.OpenRouter.APIKey)
		log.Println("Initialized OpenRouter client")
	} else {
		log.Println("OpenRouter API key not provided - will use mock responses")
	}

	// TODO: Initialize OpenAI client when GraphRAG is implemented
	// if cfg.OpenAI.APIKey != "" && cfg.OpenAI.APIKey != "your-openai-api-key-here" {
	//	openAIClient = embeddings.NewOpenAIEmbeddingsClient(cfg.OpenAI.APIKey)
	//	log.Println("Initialized OpenAI embeddings client")
	// } else {
	//	log.Println("OpenAI API key not provided - embeddings disabled")
	// }

	// TODO: Initialize Neptune client when GraphRAG is implemented
	// neptuneClient = graph.NewMockNeptuneClient()
	log.Println("GraphRAG components (OpenAI/Neptune) disabled in Phase 1")
}

// handleConversationRequest processes basic conversation requests
func handleConversationRequest(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	// Parse request
	var conversationReq ConversationRequest
	if err := json.Unmarshal([]byte(request.Body), &conversationReq); err != nil {
		log.Printf("Failed to parse request: %v", err)
		return events.APIGatewayProxyResponse{StatusCode: 400}, nil
	}

	log.Printf("Processing message from user %s: %s", conversationReq.UserID, conversationReq.Message)

	// Generate response
	var responseContent string
	if openRouterClient != nil {
		// Use OpenRouter to generate response
		llmResponse, err := openRouterClient.GenerateResponse(ctx, conversationReq.Message)
		if err != nil {
			log.Printf("OpenRouter request failed: %v", err)
			responseContent = "I'm sorry, I'm having trouble generating a response right now."
		} else if len(llmResponse.Choices) > 0 {
			responseContent = llmResponse.Choices[0].Message.Content
		} else {
			responseContent = "I didn't get a proper response. Could you try again?"
		}
	} else {
		// Mock response when OpenRouter is not configured
		responseContent = "Hello! I'm here to support you. (This is a mock response - OpenRouter not configured)"
	}

	// Create response
	response := ConversationResponse{
		MessageID: uuid.New().String(),
		Content:   responseContent,
		Timestamp: time.Now(),
	}

	// Return response
	responseBody, _ := json.Marshal(response)

	return events.APIGatewayProxyResponse{
		StatusCode: 200,
		Headers: map[string]string{
			"Content-Type": "application/json",
		},
		Body: string(responseBody),
	}, nil
}

// handleDirectInvocation handles direct Lambda invocations for testing
func handleDirectInvocation(ctx context.Context, payload json.RawMessage) (interface{}, error) {
	var req ConversationRequest
	if err := json.Unmarshal(payload, &req); err != nil {
		return nil, fmt.Errorf("invalid conversation request: %w", err)
	}

	// Convert to API Gateway format for consistency
	apiRequest := events.APIGatewayProxyRequest{
		Body: string(payload),
	}

	response, err := handleConversationRequest(ctx, apiRequest)
	if err != nil {
		return nil, err
	}

	var result ConversationResponse
	if err := json.Unmarshal([]byte(response.Body), &result); err != nil {
		return nil, fmt.Errorf("failed to parse response: %w", err)
	}

	return result, nil
}

func main() {
	lambda.Start(func(ctx context.Context, event json.RawMessage) (interface{}, error) {
		// Try to parse as API Gateway event first
		var apiEvent events.APIGatewayProxyRequest
		if err := json.Unmarshal(event, &apiEvent); err == nil && apiEvent.RequestContext.RequestID != "" {
			// API Gateway invocation
			return handleConversationRequest(ctx, apiEvent)
		}

		// Direct invocation
		return handleDirectInvocation(ctx, event)
	})
}
