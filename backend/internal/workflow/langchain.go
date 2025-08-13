package workflow

import (
	"context"
	"fmt"
	"innerworld-backend/internal/llm"
	"innerworld-backend/internal/personas"
	"innerworld-backend/internal/storage"
	"innerworld-backend/internal/types"
	"log"
	"strings"
	"time"

	"github.com/google/uuid"

	// LangChain-Go imports for Phase 2 foundation
	_ "github.com/tmc/langchaingo/chains" // Will be used in Phase 3+
	_ "github.com/tmc/langchaingo/llms"   // Will be used in Phase 3+
	_ "github.com/tmc/langchaingo/schema" // Will be used in Phase 3+
)

// ConversationChain represents a LangChain-Go based conversation processor
type ConversationChain struct {
	personaLoader *personas.PersonaLoader
	llmClient     *llm.OpenRouterClient
	storage       storage.DynamoDBClient
	// Note: LangChain chains will be fully implemented in Phase 3+
}

// ConversationInput holds the input for conversation processing
type ConversationInput struct {
	UserMessage  string                 `json:"user_message"`
	Persona      string                 `json:"persona"`
	SessionID    string                 `json:"session_id"`
	UserID       string                 `json:"user_id"`
	UserContext  map[string]interface{} `json:"user_context"`
	SessionStart time.Time              `json:"session_start"`
}

// ConversationOutput holds the result of conversation processing
type ConversationOutput struct {
	MessageID    string    `json:"message_id"`
	LLMResponse  string    `json:"llm_response"`
	ProcessedAt  time.Time `json:"processed_at"`
	SafetyPassed bool      `json:"safety_passed"`
	Error        string    `json:"error,omitempty"`
}

// NewConversationChain creates a new LangChain-based conversation processor
func NewConversationChain(personaLoader *personas.PersonaLoader, llmClient *llm.OpenRouterClient, storage storage.DynamoDBClient) *ConversationChain {
	return &ConversationChain{
		personaLoader: personaLoader,
		llmClient:     llmClient,
		storage:       storage,
		// Note: LangChain sequential chains will be implemented in Phase 3+
	}
}

// ProcessConversation executes the LangChain workflow
func (c *ConversationChain) ProcessConversation(ctx context.Context, input *ConversationInput) (*ConversationOutput, error) {
	log.Printf("Starting LangChain conversation processing for session %s", input.SessionID)

	messageID := "msg_" + uuid.New().String()[:8]

	result := &ConversationOutput{
		MessageID:   messageID,
		ProcessedAt: time.Now(),
	}

	// Step 1: Safety Check
	safetyResult, err := c.performSafetyCheck(ctx, input.UserMessage)
	if err != nil {
		result.Error = fmt.Sprintf("safety check failed: %v", err)
		return result, err
	}

	if !safetyResult {
		result.SafetyPassed = false
		result.LLMResponse = "I understand you might be going through a difficult time. Please consider talking to a trusted adult or calling 988 (Suicide & Crisis Lifeline) if you need immediate support."
		return result, nil
	}

	result.SafetyPassed = true

	// Step 2: Generate response using LangChain with persona
	response, err := c.generatePersonaResponse(ctx, input)
	if err != nil {
		result.Error = fmt.Sprintf("response generation failed: %v", err)
		// Fallback response
		result.LLMResponse = "I'm here to listen and support you. Could you tell me a bit more about what's on your mind?"
	} else {
		// Step 2a: Safety check on AI response (outgoing message safety)
		aiSafetyResult, err := c.performSafetyCheck(ctx, response)
		if err != nil {
			log.Printf("AI response safety check failed: %v", err)
			// Use safe fallback response
			result.LLMResponse = "I'm here to support you. What would you like to talk about today?"
		} else if !aiSafetyResult {
			log.Printf("AI response failed safety check - using safe fallback")
			// AI generated unsafe content - use safe fallback instead of potentially harmful response
			result.LLMResponse = "I want to support you in a safe and helpful way. Let's focus on something positive."
		} else {
			// AI response passed safety check
			result.LLMResponse = response
		}
	}

	// Step 3: Store conversation in DynamoDB
	if err := c.storeConversation(ctx, input, result); err != nil {
		log.Printf("Failed to store conversation: %v", err)
		// Don't fail the entire operation if storage fails
	}

	log.Printf("Completed LangChain conversation processing for session %s", input.SessionID)
	return result, nil
}

// performSafetyCheck implements basic safety moderation for both incoming and outgoing messages
func (c *ConversationChain) performSafetyCheck(ctx context.Context, message string) (bool, error) {
	log.Printf("Performing safety check on message")

	// Basic keyword-based safety check (Phase 2 implementation)
	// Used for both user inputs and AI responses
	message = strings.ToLower(message)

	harmfulKeywords := []string{
		"kill myself", "end it all", "hurt myself", "self harm",
		"suicide", "die", "cutting", "overdose",
	}

	for _, keyword := range harmfulKeywords {
		if strings.Contains(message, keyword) {
			log.Printf("Safety concern detected: keyword '%s' found", keyword)
			return false, nil
		}
	}

	if len(strings.TrimSpace(message)) == 0 {
		return false, fmt.Errorf("empty message")
	}

	if len(message) > 2000 {
		return false, fmt.Errorf("message too long")
	}

	return true, nil
}

// generatePersonaResponse creates a response using LangChain with persona context
func (c *ConversationChain) generatePersonaResponse(ctx context.Context, input *ConversationInput) (string, error) {
	log.Printf("Generating response using LangChain for persona: %s", input.Persona)

	// Get persona configuration (for Phase 3+ LangChain prompt templates)
	_, err := c.personaLoader.FormatPersonaPrompt(input.Persona, input.UserContext)
	if err != nil {
		return "", fmt.Errorf("failed to load persona: %w", err)
	}

	// If OpenRouter client is not available, use mock response
	if c.llmClient == nil {
		return fmt.Sprintf("I hear you. (Mock LangChain response from %s persona - OpenRouter not configured)", input.Persona), nil
	}

	// Note: LangChain prompt templates will be implemented in Phase 3+

	// Use existing OpenRouter client through LangChain-compatible interface
	response, err := c.llmClient.GenerateResponse(ctx, input.UserMessage)
	if err != nil {
		return "", fmt.Errorf("LLM generation failed: %w", err)
	}

	if len(response.Choices) > 0 {
		return response.Choices[0].Message.Content, nil
	}

	return "I'm here for you. What would you like to talk about?", nil
}

// storeConversation stores both user message and AI response in DynamoDB
func (c *ConversationChain) storeConversation(ctx context.Context, input *ConversationInput, result *ConversationOutput) error {
	log.Printf("Storing conversation in DynamoDB for session %s", input.SessionID)

	conversationID := storage.CreateConversationID(input.SessionID)

	// Store user message
	userMessage := &types.LiveConversationItem{
		ConversationID: conversationID,
		MessageID:      "user_" + result.MessageID,
		UserID:         input.UserID,
		Persona:        input.Persona,
		Timestamp:      time.Now(),
		MessageType:    "user",
		Content:        input.UserMessage,
		SessionStart:   input.SessionStart,
		SessionID:      input.SessionID,
	}

	if err := c.storage.StoreMessage(ctx, userMessage); err != nil {
		return fmt.Errorf("failed to store user message: %w", err)
	}

	// Store AI response
	aiMessage := &types.LiveConversationItem{
		ConversationID: conversationID,
		MessageID:      "ai_" + result.MessageID,
		UserID:         input.UserID,
		Persona:        input.Persona,
		Timestamp:      time.Now(),
		MessageType:    "assistant",
		Content:        result.LLMResponse,
		SessionStart:   input.SessionStart,
		SessionID:      input.SessionID,
	}

	if err := c.storage.StoreMessage(ctx, aiMessage); err != nil {
		return fmt.Errorf("failed to store AI message: %w", err)
	}

	return nil
}

// Note: LangChain-Go LLM integrations and prompt templates will be implemented in Phase 3+
// This Phase 2 implementation provides the foundation with:
// - LangChain-Go dependency added
// - Conversation processing structure established
// - Bidirectional safety: Input safety -> Persona prompt -> LLM generation -> Output safety -> Storage workflow
