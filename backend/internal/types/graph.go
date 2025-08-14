package types

import "time"

// GraphContext represents basic user context from S3
type GraphContext struct {
	UserID      string    `json:"userId"`
	LastUpdated time.Time `json:"lastUpdated"`
	Summary     string    `json:"summary"` // Simple text summary of user context
}
