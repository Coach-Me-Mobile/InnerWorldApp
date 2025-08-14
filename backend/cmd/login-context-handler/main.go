package main

import (
	"context"
	"encoding/json"
	"fmt"
	"innerworld-backend/internal/config"
	"innerworld-backend/internal/graph"
	"innerworld-backend/internal/storage"
	"innerworld-backend/internal/types"
	"log"
	"time"

	"github.com/aws/aws-lambda-go/lambda"
)

// Global variables for connection reuse across invocations
var (
	cfg      *config.Config
	dynamoDB storage.DynamoDBClient
	s3Client graph.S3Client
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

	// Initialize S3 client (mock for Phase 2)
	s3Client = graph.NewMockS3Client()
	log.Println("Initialized mock S3 client - GraphRAG disabled in Phase 2")
}

// CognitoTriggerEvent represents the Cognito Post-Authentication trigger event
type CognitoTriggerEvent struct {
	Version       string `json:"version"`
	TriggerSource string `json:"triggerSource"`
	Region        string `json:"region"`
	UserPoolID    string `json:"userPoolId"`
	Request       struct {
		UserAttributes map[string]string `json:"userAttributes"`
	} `json:"request"`
	Response struct {
		ClaimsOverride map[string]interface{} `json:"claimsOverride,omitempty"`
	} `json:"response"`
}

// handleCognitoTrigger processes Cognito Post-Authentication events
func handleCognitoTrigger(ctx context.Context, event CognitoTriggerEvent) (CognitoTriggerEvent, error) {
	log.Printf("Processing Cognito trigger: %s", event.TriggerSource)

	// Extract user ID from Cognito event
	userID := event.Request.UserAttributes["sub"]
	if userID == "" {
		return event, fmt.Errorf("user ID not found in Cognito event")
	}

	log.Printf("Caching context for user: %s", userID)

	// Retrieve user's full GraphRAG context from S3
	userContext, err := retrieveUserContext(ctx, userID)
	if err != nil {
		log.Printf("Failed to retrieve S3 context for user %s: %v", userID, err)
		// Use mock context for Phase 2 testing
		userContext = storage.GenerateMockUserContext(userID)
	}

	// Cache context in DynamoDB for fast access during conversations
	cacheItem := &types.UserContextCacheItem{
		UserID:      userID,
		ContextData: userContext,
		TTL:         time.Now().Add(1 * time.Hour).Unix(), // 1-hour cache
	}

	if err := dynamoDB.CacheUserContext(ctx, cacheItem); err != nil {
		log.Printf("Failed to cache user context: %v", err)
		// Don't fail the login process, just log the error
	} else {
		log.Printf("Successfully cached context for user %s", userID)
	}

	// Return the event unchanged (required for Cognito triggers)
	return event, nil
}

// handleDirectInvocation handles direct Lambda invocations for testing
func handleDirectInvocation(ctx context.Context, req types.LoginContextRequest) (*types.UserContextCacheItem, error) {
	log.Printf("Processing direct login context request for user: %s", req.UserID)

	// Retrieve user's full GraphRAG context from S3
	userContext, err := retrieveUserContext(ctx, req.UserID)
	if err != nil {
		log.Printf("Failed to retrieve S3 context for user %s: %v", req.UserID, err)
		// Use mock context for Phase 2 testing
		userContext = storage.GenerateMockUserContext(req.UserID)
	}

	// Cache context in DynamoDB
	cacheItem := &types.UserContextCacheItem{
		UserID:         req.UserID,
		LoginSessionID: req.LoginSessionID,
		ContextData:    userContext,
		TTL:            time.Now().Add(1 * time.Hour).Unix(),
	}

	if err := dynamoDB.CacheUserContext(ctx, cacheItem); err != nil {
		return nil, fmt.Errorf("failed to cache user context: %w", err)
	}

	log.Printf("Successfully cached context for user %s", req.UserID)
	return cacheItem, nil
}

// retrieveUserContext gets the user's full GraphRAG context from S3
func retrieveUserContext(ctx context.Context, userID string) (map[string]interface{}, error) {
	log.Printf("Retrieving S3 context for user: %s", userID)

	// Phase 2: Use mock S3 client
	// Phase 3+: Replace with real S3 operations

	// Mock query: Get user's conversation history and themes
	// In production, this would be S3 object queries for user data

	graphContext, err := s3Client.GetUserContext(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("S3 query failed: %w", err)
	}

	// Convert S3 GraphContext to context map for caching
	userContext := map[string]interface{}{
		"user_id":        userID,
		"retrieved_at":   time.Now().Format(time.RFC3339),
		"context_source": "s3_mock",
		"summary":        graphContext.Summary,
		"last_updated":   graphContext.LastUpdated.Format(time.RFC3339),
	}

	// Add mock context data for Phase 2 testing
	userContext["recent_themes"] = []string{"school", "friendship", "anxiety"}
	userContext["core_values"] = []string{"authenticity", "growth", "connection"}
	userContext["total_conversations"] = 3
	userContext["favorite_persona"] = "comfort"

	log.Printf("Retrieved context with %d fields for user %s", len(userContext), userID)
	return userContext, nil
}

func main() {
	lambda.Start(func(ctx context.Context, event json.RawMessage) (interface{}, error) {
		// Try to parse as Cognito trigger event first
		var cognitoEvent CognitoTriggerEvent
		if err := json.Unmarshal(event, &cognitoEvent); err == nil && cognitoEvent.TriggerSource != "" {
			// Cognito Post-Authentication trigger
			return handleCognitoTrigger(ctx, cognitoEvent)
		}

		// Try direct invocation for testing
		var directRequest types.LoginContextRequest
		if err := json.Unmarshal(event, &directRequest); err == nil && directRequest.UserID != "" {
			return handleDirectInvocation(ctx, directRequest)
		}

		return nil, fmt.Errorf("unrecognized event format")
	})
}
