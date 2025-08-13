package embeddings

import (
	"context"
	"fmt"
	"log"

	"github.com/sashabaranov/go-openai"
)

// OpenAIEmbeddingsClient handles text embeddings via OpenAI API
type OpenAIEmbeddingsClient struct {
	client *openai.Client
	model  string
}

// NewOpenAIEmbeddingsClient creates a new OpenAI embeddings client
func NewOpenAIEmbeddingsClient(apiKey string) *OpenAIEmbeddingsClient {
	client := openai.NewClient(apiKey)

	return &OpenAIEmbeddingsClient{
		client: client,
		model:  "text-embedding-3-small", // Cost-effective for GraphRAG
	}
}

// EmbeddingResult represents an embedding with metadata
type EmbeddingResult struct {
	Text      string    `json:"text"`
	Embedding []float32 `json:"embedding"`
	Model     string    `json:"model"`
	Tokens    int       `json:"tokens"`
}

// GenerateEmbedding creates an embedding for a single text
func (e *OpenAIEmbeddingsClient) GenerateEmbedding(ctx context.Context, text string) (*EmbeddingResult, error) {
	log.Printf("[EMBEDDINGS] Generating embedding for text: %s...", text[:min(50, len(text))])

	req := openai.EmbeddingRequest{
		Input: []string{text},
		Model: openai.EmbeddingModel(0), // Will use string in future API versions
	}

	resp, err := e.client.CreateEmbeddings(ctx, req)
	if err != nil {
		return nil, fmt.Errorf("failed to create embedding: %w", err)
	}

	if len(resp.Data) == 0 {
		return nil, fmt.Errorf("no embeddings returned from OpenAI")
	}

	result := &EmbeddingResult{
		Text:      text,
		Embedding: resp.Data[0].Embedding,
		Model:     e.model, // Use our internal model string
		Tokens:    resp.Usage.TotalTokens,
	}

	log.Printf("[EMBEDDINGS] Generated %d-dimensional embedding using %d tokens",
		len(result.Embedding), result.Tokens)

	return result, nil
}

// GenerateBatchEmbeddings creates embeddings for multiple texts
func (e *OpenAIEmbeddingsClient) GenerateBatchEmbeddings(ctx context.Context, texts []string) ([]*EmbeddingResult, error) {
	if len(texts) == 0 {
		return []*EmbeddingResult{}, nil
	}

	log.Printf("[EMBEDDINGS] Generating batch embeddings for %d texts", len(texts))

	req := openai.EmbeddingRequest{
		Input: texts,
		Model: openai.EmbeddingModel(0), // Will use string in future API versions
	}

	resp, err := e.client.CreateEmbeddings(ctx, req)
	if err != nil {
		return nil, fmt.Errorf("failed to create batch embeddings: %w", err)
	}

	if len(resp.Data) != len(texts) {
		return nil, fmt.Errorf("expected %d embeddings, got %d", len(texts), len(resp.Data))
	}

	results := make([]*EmbeddingResult, len(texts))
	for i, data := range resp.Data {
		results[i] = &EmbeddingResult{
			Text:      texts[i],
			Embedding: data.Embedding,
			Model:     e.model,                // Use our internal model string
			Tokens:    resp.Usage.TotalTokens, // Note: this is total for batch
		}
	}

	log.Printf("[EMBEDDINGS] Generated %d embeddings using %d total tokens",
		len(results), resp.Usage.TotalTokens)

	return results, nil
}

// EmbedConversationElement creates embedding for graph elements
func (e *OpenAIEmbeddingsClient) EmbedConversationElement(ctx context.Context, elementType, title, description string) (*EmbeddingResult, error) {
	// Create comprehensive text for embedding that captures context
	embeddingText := fmt.Sprintf("%s: %s. %s", elementType, title, description)

	return e.GenerateEmbedding(ctx, embeddingText)
}

// EmbedUserQuery creates embedding for user search queries
func (e *OpenAIEmbeddingsClient) EmbedUserQuery(ctx context.Context, query string, userID string) (*EmbeddingResult, error) {
	// Could add user context to query embedding for personalized search
	embeddingText := fmt.Sprintf("User query: %s", query)

	return e.GenerateEmbedding(ctx, embeddingText)
}

// CalculateCosineSimilarity calculates similarity between two embeddings
func (e *OpenAIEmbeddingsClient) CalculateCosineSimilarity(embedding1, embedding2 []float32) float32 {
	if len(embedding1) != len(embedding2) {
		return 0.0
	}

	var dotProduct, norm1, norm2 float32

	for i := range embedding1 {
		dotProduct += embedding1[i] * embedding2[i]
		norm1 += embedding1[i] * embedding1[i]
		norm2 += embedding2[i] * embedding2[i]
	}

	if norm1 == 0.0 || norm2 == 0.0 {
		return 0.0
	}

	return dotProduct / (sqrt32(norm1) * sqrt32(norm2))
}

// FindMostSimilar finds the most similar embedding from a set
func (e *OpenAIEmbeddingsClient) FindMostSimilar(queryEmbedding []float32, candidates []*EmbeddingResult) (*EmbeddingResult, float32) {
	if len(candidates) == 0 {
		return nil, 0.0
	}

	var bestMatch *EmbeddingResult
	var bestScore float32 = -1.0

	for _, candidate := range candidates {
		similarity := e.CalculateCosineSimilarity(queryEmbedding, candidate.Embedding)
		if similarity > bestScore {
			bestScore = similarity
			bestMatch = candidate
		}
	}

	return bestMatch, bestScore
}

// GetEmbeddingDimension returns the dimension of embeddings for this model
func (e *OpenAIEmbeddingsClient) GetEmbeddingDimension() int {
	// text-embedding-3-small has 1536 dimensions
	return 1536
}

// GetModel returns the current model being used
func (e *OpenAIEmbeddingsClient) GetModel() string {
	return e.model
}

// SetModel allows changing the embedding model
func (e *OpenAIEmbeddingsClient) SetModel(model string) {
	e.model = model
	log.Printf("[EMBEDDINGS] Changed model to: %s", model)
}

// Helper function for square root of float32
func sqrt32(x float32) float32 {
	// Simple Newton-Raphson method for square root
	if x == 0 {
		return 0
	}

	guess := x / 2
	for i := 0; i < 10; i++ { // 10 iterations should be enough for float32
		guess = (guess + x/guess) / 2
	}
	return guess
}
