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
