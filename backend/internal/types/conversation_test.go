package types

import (
	"encoding/json"
	"testing"
	"time"
)

func TestConversationRequest(t *testing.T) {
	req := ConversationRequest{
		Message: "Hello, how are you?",
		UserID:  "user-123",
	}
	
	if req.Message != "Hello, how are you?" {
		t.Errorf("Expected message 'Hello, how are you?', got '%s'", req.Message)
	}
	
	if req.UserID != "user-123" {
		t.Errorf("Expected UserID 'user-123', got '%s'", req.UserID)
	}
}

func TestConversationResponse(t *testing.T) {
	now := time.Now()
	resp := ConversationResponse{
		MessageID: "msg-456",
		Content:   "I'm doing well, thank you!",
		Timestamp: now,
	}
	
	if resp.MessageID != "msg-456" {
		t.Errorf("Expected MessageID 'msg-456', got '%s'", resp.MessageID)
	}
	
	if resp.Content != "I'm doing well, thank you!" {
		t.Errorf("Expected content 'I'm doing well, thank you!', got '%s'", resp.Content)
	}
	
	if !resp.Timestamp.Equal(now) {
		t.Errorf("Expected timestamp %v, got %v", now, resp.Timestamp)
	}
}

func TestConversationRequestJSON(t *testing.T) {
	req := ConversationRequest{
		Message: "Test message",
		UserID:  "test-user",
	}
	
	// Test JSON marshalling
	jsonData, err := json.Marshal(req)
	if err != nil {
		t.Fatalf("Failed to marshal ConversationRequest: %v", err)
	}
	
	expectedJSON := `{"message":"Test message","userId":"test-user"}`
	if string(jsonData) != expectedJSON {
		t.Errorf("Expected JSON %s, got %s", expectedJSON, string(jsonData))
	}
	
	// Test JSON unmarshalling
	var unmarshaled ConversationRequest
	err = json.Unmarshal(jsonData, &unmarshaled)
	if err != nil {
		t.Fatalf("Failed to unmarshal ConversationRequest: %v", err)
	}
	
	if unmarshaled.Message != req.Message {
		t.Errorf("Unmarshaled message mismatch: expected '%s', got '%s'", req.Message, unmarshaled.Message)
	}
	
	if unmarshaled.UserID != req.UserID {
		t.Errorf("Unmarshaled UserID mismatch: expected '%s', got '%s'", req.UserID, unmarshaled.UserID)
	}
}

func TestConversationResponseJSON(t *testing.T) {
	now := time.Now().UTC().Truncate(time.Second) // Truncate for JSON precision
	resp := ConversationResponse{
		MessageID: "test-msg",
		Content:   "Test response",
		Timestamp: now,
	}
	
	// Test JSON marshalling
	jsonData, err := json.Marshal(resp)
	if err != nil {
		t.Fatalf("Failed to marshal ConversationResponse: %v", err)
	}
	
	// Test JSON unmarshalling
	var unmarshaled ConversationResponse
	err = json.Unmarshal(jsonData, &unmarshaled)
	if err != nil {
		t.Fatalf("Failed to unmarshal ConversationResponse: %v", err)
	}
	
	if unmarshaled.MessageID != resp.MessageID {
		t.Errorf("Unmarshaled MessageID mismatch: expected '%s', got '%s'", resp.MessageID, unmarshaled.MessageID)
	}
	
	if unmarshaled.Content != resp.Content {
		t.Errorf("Unmarshaled Content mismatch: expected '%s', got '%s'", resp.Content, unmarshaled.Content)
	}
	
	// Time comparison with some tolerance due to JSON serialization
	timeDiff := unmarshaled.Timestamp.Sub(resp.Timestamp)
	if timeDiff > time.Second || timeDiff < -time.Second {
		t.Errorf("Unmarshaled Timestamp mismatch: expected %v, got %v", resp.Timestamp, unmarshaled.Timestamp)
	}
}

func TestConversationRequestValidation(t *testing.T) {
	testCases := []struct {
		name    string
		request ConversationRequest
		valid   bool
	}{
		{
			name: "Valid request",
			request: ConversationRequest{
				Message: "Hello",
				UserID:  "user-123",
			},
			valid: true,
		},
		{
			name: "Empty message",
			request: ConversationRequest{
				Message: "",
				UserID:  "user-123",
			},
			valid: false,
		},
		{
			name: "Empty UserID",
			request: ConversationRequest{
				Message: "Hello",
				UserID:  "",
			},
			valid: false,
		},
		{
			name: "Both empty",
			request: ConversationRequest{
				Message: "",
				UserID:  "",
			},
			valid: false,
		},
	}
	
	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			isValid := tc.request.Message != "" && tc.request.UserID != ""
			if isValid != tc.valid {
				t.Errorf("Expected validation result %v, got %v for %s", tc.valid, isValid, tc.name)
			}
		})
	}
}

func TestConversationResponseValidation(t *testing.T) {
	testCases := []struct {
		name     string
		response ConversationResponse
		valid    bool
	}{
		{
			name: "Valid response",
			response: ConversationResponse{
				MessageID: "msg-123",
				Content:   "Hello there!",
				Timestamp: time.Now(),
			},
			valid: true,
		},
		{
			name: "Empty MessageID",
			response: ConversationResponse{
				MessageID: "",
				Content:   "Hello there!",
				Timestamp: time.Now(),
			},
			valid: false,
		},
		{
			name: "Empty Content",
			response: ConversationResponse{
				MessageID: "msg-123",
				Content:   "",
				Timestamp: time.Now(),
			},
			valid: false,
		},
		{
			name: "Zero timestamp",
			response: ConversationResponse{
				MessageID: "msg-123",
				Content:   "Hello there!",
				Timestamp: time.Time{},
			},
			valid: false,
		},
	}
	
	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			isValid := tc.response.MessageID != "" && tc.response.Content != "" && !tc.response.Timestamp.IsZero()
			if isValid != tc.valid {
				t.Errorf("Expected validation result %v, got %v for %s", tc.valid, isValid, tc.name)
			}
		})
	}
}
