package graph

import (
	"context"
	"fmt"
	"innerworld-backend/internal/types"
	"log"
	"time"
)

// MockNeptuneClient implements basic NeptuneClient interface for development
type MockNeptuneClient struct {
	users map[string]*types.GraphContext
}

// NewMockNeptuneClient creates a new mock Neptune client
func NewMockNeptuneClient() *MockNeptuneClient {
	return &MockNeptuneClient{
		users: make(map[string]*types.GraphContext),
	}
}

// GetUserContext returns mock user context data
func (m *MockNeptuneClient) GetUserContext(ctx context.Context, userID string) (*types.GraphContext, error) {
	log.Printf("[MOCK NEPTUNE] Getting context for user: %s", userID)

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
func (m *MockNeptuneClient) UpdateUserGraph(ctx context.Context, userID string, data interface{}) error {
	log.Printf("[MOCK NEPTUNE] UpdateUserGraph called for user: %s (not implemented in Phase 1)", userID)
	return nil
}

// RefreshUserContext returns current context
func (m *MockNeptuneClient) RefreshUserContext(ctx context.Context, userID string) (*types.GraphContext, error) {
	log.Printf("[MOCK NEPTUNE] Refreshing context for user: %s", userID)
	return m.GetUserContext(ctx, userID)
}

// HealthCheck simulates Neptune connectivity check
func (m *MockNeptuneClient) HealthCheck(ctx context.Context) error {
	log.Println("[MOCK NEPTUNE] Health check - OK")
	return nil
}

// CreateUser initializes mock user
func (m *MockNeptuneClient) CreateUser(ctx context.Context, userID string) error {
	log.Printf("[MOCK NEPTUNE] Creating new user: %s", userID)

	if _, exists := m.users[userID]; exists {
		return fmt.Errorf("user %s already exists", userID)
	}

	_, err := m.GetUserContext(ctx, userID)
	return err
}

// DeleteUserData removes mock user data
func (m *MockNeptuneClient) DeleteUserData(ctx context.Context, userID string) error {
	log.Printf("[MOCK NEPTUNE] Deleting data for user: %s", userID)
	delete(m.users, userID)
	return nil
}
