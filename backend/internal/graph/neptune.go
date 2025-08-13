package graph

import (
	"context"
	"innerworld-backend/internal/types"
)

// NeptuneClient interface defines Neptune operations for Phase 1 & 2
type NeptuneClient interface {
	// GetUserContext retrieves basic user context
	GetUserContext(ctx context.Context, userID string) (*types.GraphContext, error)

	// UpdateUserGraph placeholder for future graph updates
	UpdateUserGraph(ctx context.Context, userID string, data interface{}) error

	// RefreshUserContext updates cached context
	RefreshUserContext(ctx context.Context, userID string) (*types.GraphContext, error)

	// HealthCheck verifies connectivity
	HealthCheck(ctx context.Context) error

	// CreateUser initializes new user
	CreateUser(ctx context.Context, userID string) error

	// DeleteUserData removes user data
	DeleteUserData(ctx context.Context, userID string) error

	// Phase 2 additions for session processing
	CreateNode(userID string, nodeType string, content string) error
	CreateEdge(userID string, nodeID string, edgeType string, target string) error
}

// Config holds basic Neptune connection configuration
type Config struct {
	Endpoint string `json:"endpoint"`
	Port     int    `json:"port"`
	Region   string `json:"region"`
}
