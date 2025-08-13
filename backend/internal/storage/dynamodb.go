package storage

import (
	"context"
	"fmt"
	"innerworld-backend/internal/types"
	"log"
	"sync"
	"time"

	"github.com/google/uuid"
)

// DynamoDBClient interface for production and mock implementations
type DynamoDBClient interface {
	// LiveConversations operations
	StoreMessage(ctx context.Context, item *types.LiveConversationItem) error
	GetSessionMessages(ctx context.Context, sessionID string) ([]types.LiveConversationItem, error)
	DeleteSessionMessages(ctx context.Context, sessionID string) error

	// UserContextCache operations
	CacheUserContext(ctx context.Context, item *types.UserContextCacheItem) error
	GetUserContext(ctx context.Context, userID string) (*types.UserContextCacheItem, error)
	RefreshUserContext(ctx context.Context, userID string, newContext map[string]interface{}) error
}

// MockDynamoDBClient implements DynamoDBClient for testing
type MockDynamoDBClient struct {
	// In-memory storage for mock testing
	conversations map[string][]types.LiveConversationItem // sessionID -> messages
	contextCache  map[string]types.UserContextCacheItem   // userID -> context
	mutex         sync.RWMutex
}

// NewMockDynamoDBClient creates a new mock DynamoDB client
func NewMockDynamoDBClient() *MockDynamoDBClient {
	return &MockDynamoDBClient{
		conversations: make(map[string][]types.LiveConversationItem),
		contextCache:  make(map[string]types.UserContextCacheItem),
		mutex:         sync.RWMutex{},
	}
}

// StoreMessage stores a conversation message
func (m *MockDynamoDBClient) StoreMessage(ctx context.Context, item *types.LiveConversationItem) error {
	m.mutex.Lock()
	defer m.mutex.Unlock()

	// Generate message ID if not provided
	if item.MessageID == "" {
		item.MessageID = "msg_" + uuid.New().String()[:8]
	}

	// Set TTL to 24 hours from now (for testing)
	if item.TTL == 0 {
		item.TTL = time.Now().Add(24 * time.Hour).Unix()
	}

	// Add to in-memory storage
	sessionMessages := m.conversations[item.SessionID]

	// Set message sequence
	item.MessageSequence = len(sessionMessages) + 1

	m.conversations[item.SessionID] = append(sessionMessages, *item)

	log.Printf("MockDynamoDB: Stored message %s for session %s", item.MessageID, item.SessionID)
	return nil
}

// GetSessionMessages retrieves all messages for a session
func (m *MockDynamoDBClient) GetSessionMessages(ctx context.Context, sessionID string) ([]types.LiveConversationItem, error) {
	m.mutex.RLock()
	defer m.mutex.RUnlock()

	messages, exists := m.conversations[sessionID]
	if !exists {
		return []types.LiveConversationItem{}, nil
	}

	log.Printf("MockDynamoDB: Retrieved %d messages for session %s", len(messages), sessionID)
	return messages, nil
}

// DeleteSessionMessages removes all messages for a session (cleanup after processing)
func (m *MockDynamoDBClient) DeleteSessionMessages(ctx context.Context, sessionID string) error {
	m.mutex.Lock()
	defer m.mutex.Unlock()

	delete(m.conversations, sessionID)
	log.Printf("MockDynamoDB: Deleted messages for session %s", sessionID)
	return nil
}

// CacheUserContext stores user's Neptune context for fast access
func (m *MockDynamoDBClient) CacheUserContext(ctx context.Context, item *types.UserContextCacheItem) error {
	m.mutex.Lock()
	defer m.mutex.Unlock()

	// Set TTL to 1 hour from now
	if item.TTL == 0 {
		item.TTL = time.Now().Add(1 * time.Hour).Unix()
	}

	item.LastUpdated = time.Now()
	m.contextCache[item.UserID] = *item

	log.Printf("MockDynamoDB: Cached context for user %s", item.UserID)
	return nil
}

// GetUserContext retrieves cached user context
func (m *MockDynamoDBClient) GetUserContext(ctx context.Context, userID string) (*types.UserContextCacheItem, error) {
	m.mutex.RLock()
	defer m.mutex.RUnlock()

	item, exists := m.contextCache[userID]
	if !exists {
		return nil, fmt.Errorf("user context not found: %s", userID)
	}

	// Check TTL expiration
	if time.Now().Unix() > item.TTL {
		return nil, fmt.Errorf("user context expired: %s", userID)
	}

	log.Printf("MockDynamoDB: Retrieved cached context for user %s", userID)
	return &item, nil
}

// RefreshUserContext updates cached context with new Neptune data
func (m *MockDynamoDBClient) RefreshUserContext(ctx context.Context, userID string, newContext map[string]interface{}) error {
	m.mutex.Lock()
	defer m.mutex.Unlock()

	item, exists := m.contextCache[userID]
	if !exists {
		// Create new cache entry if doesn't exist
		item = types.UserContextCacheItem{
			UserID: userID,
			TTL:    time.Now().Add(1 * time.Hour).Unix(),
		}
	}

	// Update context data
	item.ContextData = newContext
	item.LastUpdated = time.Now()
	item.TTL = time.Now().Add(1 * time.Hour).Unix() // Reset TTL

	m.contextCache[userID] = item

	log.Printf("MockDynamoDB: Refreshed context for user %s", userID)
	return nil
}

// Helper function to create conversation ID based on session and date
func CreateConversationID(sessionID string) string {
	return fmt.Sprintf("%s_%s", sessionID, time.Now().Format("2006-01-02"))
}

// Helper function to generate mock user context (for testing when Neptune is not available)
func GenerateMockUserContext(userID string) map[string]interface{} {
	return map[string]interface{}{
		"user_id":       userID,
		"recent_themes": []string{"anxiety", "school", "friendship"},
		"core_values":   []string{"authenticity", "connection", "growth"},
		"conversation_history": map[string]interface{}{
			"total_sessions":  5,
			"last_persona":    "comfort",
			"frequent_topics": []string{"presentations", "social situations"},
		},
		"mock_note": "This is mock context data until Neptune GraphRAG is implemented",
	}
}
