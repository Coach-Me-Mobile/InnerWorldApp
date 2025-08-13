package main

import (
	"context"
	"encoding/json"
	"fmt"
	"innerworld-backend/internal/config"
	"innerworld-backend/internal/graph"
	"innerworld-backend/internal/llm"
	"log"
	"os"
	"time"

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

func main() {
	// Load configuration
	cfg, err := config.LoadConfig()
	if err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}

	// Initialize OpenRouter client (the main thing we want to test)
	var openRouterClient *llm.OpenRouterClient

	// Initialize OpenRouter client if API key is available
	if cfg.OpenRouter.APIKey != "" && cfg.OpenRouter.APIKey != "your-openrouter-api-key-here" {
		openRouterClient = llm.NewOpenRouterClient(cfg.OpenRouter.APIKey)
		log.Println("Initialized OpenRouter client")
	} else {
		log.Println("OpenRouter API key not provided - will use mock responses")
	}

	// Note: We don't need OpenAI or Neptune for this basic conversation test
	if cfg.OpenAI.APIKey != "" && cfg.OpenAI.APIKey != "your-openai-api-key-here" {
		log.Println("OpenAI API key found (embeddings available)")
	} else {
		log.Println("OpenAI API key not provided - embeddings disabled")
	}

	// Mock Neptune client is available but not used in this test
	_ = graph.NewMockNeptuneClient()
	log.Println("Mock Neptune client available")

	// Read JSON from stdin
	var req ConversationRequest
	if err := json.NewDecoder(os.Stdin).Decode(&req); err != nil {
		log.Fatalf("Failed to parse input JSON: %v", err)
	}

	ctx := context.Background()

	// Process the conversation (same logic as the real handler)
	log.Printf("Processing message from user %s: %s", req.UserID, req.Message)

	// Generate response
	var responseContent string
	if openRouterClient != nil {
		// Use OpenRouter to generate response
		llmResponse, err := openRouterClient.GenerateResponse(ctx, req.Message)
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

	// Output JSON response
	responseJSON, err := json.Marshal(response)
	if err != nil {
		log.Fatalf("Failed to marshal response: %v", err)
	}

	fmt.Println(string(responseJSON))
}
