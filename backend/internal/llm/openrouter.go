package llm

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
)

// OpenRouterClient handles basic interactions with OpenRouter API
type OpenRouterClient struct {
	apiKey     string
	baseURL    string
	httpClient *http.Client
}

// NewOpenRouterClient creates a new OpenRouter API client
func NewOpenRouterClient(apiKey string) *OpenRouterClient {
	return &OpenRouterClient{
		apiKey:  apiKey,
		baseURL: "https://openrouter.ai/api/v1",
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

// ChatRequest represents OpenRouter chat completion request
type ChatRequest struct {
	Model       string        `json:"model"`
	Messages    []ChatMessage `json:"messages"`
	Temperature float64       `json:"temperature,omitempty"`
	MaxTokens   int           `json:"max_tokens,omitempty"`
}

// ChatMessage represents a chat message
type ChatMessage struct {
	Role    string `json:"role"` // "system" | "user" | "assistant"
	Content string `json:"content"`
}

// ChatResponse represents OpenRouter API response
type ChatResponse struct {
	ID      string       `json:"id"`
	Object  string       `json:"object"`
	Created int64        `json:"created"`
	Model   string       `json:"model"`
	Choices []ChatChoice `json:"choices"`
	Usage   Usage        `json:"usage"`
}

// ChatChoice represents a choice in the response
type ChatChoice struct {
	Index        int         `json:"index"`
	Message      ChatMessage `json:"message"`
	FinishReason string      `json:"finish_reason"`
}

// Usage represents token usage statistics
type Usage struct {
	PromptTokens     int `json:"prompt_tokens"`
	CompletionTokens int `json:"completion_tokens"`
	TotalTokens      int `json:"total_tokens"`
}

// GenerateResponse creates a basic LLM response
func (c *OpenRouterClient) GenerateResponse(ctx context.Context, userMessage string) (*ChatResponse, error) {
	// Simple system message for basic conversation
	systemMessage := "You are a helpful AI assistant for a teen wellness app called InnerWorld. Be supportive and encouraging."

	request := ChatRequest{
		Model:       "anthropic/claude-3.5-sonnet",
		Temperature: 0.7,
		MaxTokens:   150,
		Messages: []ChatMessage{
			{Role: "system", Content: systemMessage},
			{Role: "user", Content: userMessage},
		},
	}

	response, err := c.makeRequest(ctx, "/chat/completions", request)
	if err != nil {
		return nil, fmt.Errorf("OpenRouter API request failed: %w", err)
	}

	return response, nil
}

// makeRequest handles HTTP requests to OpenRouter API
func (c *OpenRouterClient) makeRequest(ctx context.Context, endpoint string, payload interface{}) (*ChatResponse, error) {
	jsonPayload, err := json.Marshal(payload)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, "POST", c.baseURL+endpoint, bytes.NewBuffer(jsonPayload))
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+c.apiKey)
	req.Header.Set("HTTP-Referer", "https://innerworld.app")
	req.Header.Set("X-Title", "InnerWorld")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("HTTP request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("API request failed with status %d: %s", resp.StatusCode, string(body))
	}

	var response ChatResponse
	if err := json.NewDecoder(resp.Body).Decode(&response); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	return &response, nil
}
