package types

import (
	"time"
)

// ConversationRequest represents basic conversation requests
type ConversationRequest struct {
	Message string `json:"message"`
	UserID  string `json:"userId"`
}

// ConversationResponse represents basic conversation responses
type ConversationResponse struct {
	MessageID string    `json:"messageId"`
	Content   string    `json:"content"`
	Timestamp time.Time `json:"timestamp"`
}

// Phase 2 Types for WebSocket and Session Management

// WebSocketMessage represents incoming WebSocket messages
type WebSocketMessage struct {
	Action    string `json:"action"`    // "sendmessage"
	Message   string `json:"message"`   // User's message content
	Persona   string `json:"persona"`   // Selected persona: courage, comfort, creative, compass
	SessionID string `json:"sessionId"` // Unique session identifier
	UserID    string `json:"userId"`    // User identifier from Cognito
}

// WebSocketResponse represents outgoing WebSocket responses
type WebSocketResponse struct {
	MessageID   string    `json:"messageId"`
	Content     string    `json:"content"`
	Persona     string    `json:"persona"`
	Timestamp   time.Time `json:"timestamp"`
	SessionID   string    `json:"sessionId"`
	MessageType string    `json:"messageType"` // "assistant"
}

// LiveConversationItem represents a DynamoDB item in LiveConversations table
type LiveConversationItem struct {
	ConversationID  string    `json:"conversation_id" dynamodbav:"conversation_id"` // PK: session_123_2024-01-15
	MessageID       string    `json:"message_id" dynamodbav:"message_id"`           // SK: msg_001
	UserID          string    `json:"user_id" dynamodbav:"user_id"`
	Persona         string    `json:"persona" dynamodbav:"persona"`
	Timestamp       time.Time `json:"timestamp" dynamodbav:"timestamp"`
	MessageType     string    `json:"message_type" dynamodbav:"message_type"` // "user" | "assistant"
	Content         string    `json:"content" dynamodbav:"content"`
	SessionStart    time.Time `json:"session_start" dynamodbav:"session_start"`
	TTL             int64     `json:"ttl" dynamodbav:"ttl"`               // 24-hour auto-cleanup timestamp
	SessionID       string    `json:"session_id" dynamodbav:"session_id"` // GSI for session queries
	MessageSequence int       `json:"message_sequence" dynamodbav:"message_sequence"`
}

// UserContextCacheItem represents cached S3 context in DynamoDB
type UserContextCacheItem struct {
	UserID         string                 `json:"user_id" dynamodbav:"user_id"`           // PK
	ContextData    map[string]interface{} `json:"context_data" dynamodbav:"context_data"` // S3 GraphRAG context
	LastUpdated    time.Time              `json:"last_updated" dynamodbav:"last_updated"`
	LoginSessionID string                 `json:"login_session_id" dynamodbav:"login_session_id"`
	TTL            int64                  `json:"ttl" dynamodbav:"ttl"` // 1-hour TTL, refreshed on use
}

// SessionEndRequest represents session processing request
type SessionEndRequest struct {
	SessionID string `json:"sessionId"`
	UserID    string `json:"userId"`
	Reason    string `json:"reason"` // "timeout", "manual", "disconnect"
}

// LoginContextRequest represents context caching on login
type LoginContextRequest struct {
	UserID         string `json:"userId"`
	LoginSessionID string `json:"loginSessionId"`
}

// ConversationElement represents extracted elements from conversation
type ConversationElement struct {
	Type       string                 `json:"type"`       // "Event", "Feeling", "Value", "Goal", "Habit"
	Content    string                 `json:"content"`    // Description of the element
	Metadata   map[string]interface{} `json:"metadata"`   // Additional context
	Timestamp  time.Time              `json:"timestamp"`  // When it occurred in conversation
	Confidence float64                `json:"confidence"` // Extraction confidence (0-1)
}

// SessionProcessingResult represents the outcome of session processing
type SessionProcessingResult struct {
	SessionID         string                `json:"sessionId"`
	ProcessedAt       time.Time             `json:"processedAt"`
	ElementsExtracted []ConversationElement `json:"elementsExtracted"`
	GraphNodesCreated int                   `json:"graphNodesCreated"`
	GraphEdgesCreated int                   `json:"graphEdgesCreated"`
	Success           bool                  `json:"success"`
	Error             string                `json:"error,omitempty"`
}
