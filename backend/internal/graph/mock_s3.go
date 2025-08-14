package graph

import (
	"context"
	"fmt"
	"innerworld-backend/internal/types"
	"log"
	"time"
)

// MockS3Client implements basic S3Client interface for development
type MockS3Client struct {
	users map[string]*types.GraphContext
}

// NewMockS3Client creates a new mock S3 client
func NewMockS3Client() *MockS3Client {
	return &MockS3Client{
		users: make(map[string]*types.GraphContext),
	}
}

// GetUserContext returns mock user context data
func (m *MockS3Client) GetUserContext(ctx context.Context, userID string) (*types.GraphContext, error) {
	log.Printf("[MOCK S3] Getting context for user: %s", userID)

	// Return existing context or create default
	if context, exists := m.users[userID]; exists {
		return context, nil
	}

	// Create basic default context for new user
	defaultContext := &types.GraphContext{
		UserID:      userID,
		LastUpdated: time.Now(),
		Summary:     "New user - no conversation history yet",
	}

	m.users[userID] = defaultContext
	return defaultContext, nil
}

// UpdateUserGraph is a placeholder for updating user graph (not implemented in Phase 1)
func (m *MockS3Client) UpdateUserGraph(ctx context.Context, userID string, data interface{}) error {
	log.Printf("[MOCK S3] UpdateUserGraph called for user: %s (not implemented in Phase 1)", userID)
	return nil
}

// RefreshUserContext returns current context
func (m *MockS3Client) RefreshUserContext(ctx context.Context, userID string) (*types.GraphContext, error) {
	log.Printf("[MOCK S3] Refreshing context for user: %s", userID)
	return m.GetUserContext(ctx, userID)
}

// HealthCheck simulates S3 connectivity check
func (m *MockS3Client) HealthCheck(ctx context.Context) error {
	log.Println("[MOCK S3] Health check - OK")
	return nil
}

// CreateUser initializes mock user
func (m *MockS3Client) CreateUser(ctx context.Context, userID string) error {
	log.Printf("[MOCK S3] Creating new user: %s", userID)

	if _, exists := m.users[userID]; exists {
		return fmt.Errorf("user %s already exists", userID)
	}

	_, err := m.GetUserContext(ctx, userID)
	return err
}

// DeleteUserData removes mock user data
func (m *MockS3Client) DeleteUserData(ctx context.Context, userID string) error {
	log.Printf("[MOCK S3] Deleting data for user: %s", userID)
	delete(m.users, userID)
	return nil
}

// CreateNode creates a mock node in S3
func (m *MockS3Client) CreateNode(userID string, nodeType string, content string) error {
	log.Printf("[MOCK S3] Creating %s node for user %s: %s", nodeType, userID, content)
	// Mock implementation - just log the operation
	return nil
}

// CreateEdge creates a mock edge in S3
func (m *MockS3Client) CreateEdge(userID string, nodeID string, edgeType string, target string) error {
	log.Printf("[MOCK S3] Creating %s edge for user %s: %s -> %s", edgeType, userID, nodeID, target)
	// Mock implementation - just log the operation
	return nil
}
