package embeddings

import (
	"testing"
)

func TestNewOpenAIEmbeddingsClient(t *testing.T) {
	client := NewOpenAIEmbeddingsClient("test-api-key")
	
	if client == nil {
		t.Fatal("Expected client to be created, got nil")
	}
	
	if client.client == nil {
		t.Error("Expected OpenAI client to be initialized, got nil")
	}
	
	if client.model != "text-embedding-3-small" {
		t.Errorf("Expected model to be 'text-embedding-3-small', got '%s'", client.model)
	}
}

func TestEmbeddingResult(t *testing.T) {
	result := &EmbeddingResult{
		Text:      "Hello world",
		Embedding: []float32{0.1, 0.2, 0.3},
		Model:     "text-embedding-3-small",
		Tokens:    5,
	}
	
	if result.Text != "Hello world" {
		t.Errorf("Expected text 'Hello world', got '%s'", result.Text)
	}
	
	if len(result.Embedding) != 3 {
		t.Errorf("Expected embedding length 3, got %d", len(result.Embedding))
	}
	
	if result.Model != "text-embedding-3-small" {
		t.Errorf("Expected model 'text-embedding-3-small', got '%s'", result.Model)
	}
	
	if result.Tokens != 5 {
		t.Errorf("Expected tokens 5, got %d", result.Tokens)
	}
}

func TestCalculateCosineSimilarity(t *testing.T) {
	client := NewOpenAIEmbeddingsClient("test-key")
	
	// Test identical embeddings (should be 1.0)
	embedding1 := []float32{1.0, 0.0, 0.0}
	embedding2 := []float32{1.0, 0.0, 0.0}
	
	similarity := client.CalculateCosineSimilarity(embedding1, embedding2)
	if similarity < 0.99 || similarity > 1.01 {
		t.Errorf("Expected similarity ~1.0 for identical embeddings, got %f", similarity)
	}
	
	// Test orthogonal embeddings (should be 0.0)
	embedding3 := []float32{1.0, 0.0, 0.0}
	embedding4 := []float32{0.0, 1.0, 0.0}
	
	similarity = client.CalculateCosineSimilarity(embedding3, embedding4)
	if similarity < -0.01 || similarity > 0.01 {
		t.Errorf("Expected similarity ~0.0 for orthogonal embeddings, got %f", similarity)
	}
	
	// Test different length embeddings (should be 0.0)
	embedding5 := []float32{1.0, 0.0}
	embedding6 := []float32{1.0, 0.0, 0.0}
	
	similarity = client.CalculateCosineSimilarity(embedding5, embedding6)
	if similarity != 0.0 {
		t.Errorf("Expected similarity 0.0 for different length embeddings, got %f", similarity)
	}
}

func TestFindMostSimilar(t *testing.T) {
	client := NewOpenAIEmbeddingsClient("test-key")
	
	queryEmbedding := []float32{1.0, 0.0, 0.0}
	
	candidates := []*EmbeddingResult{
		{
			Text:      "Similar text",
			Embedding: []float32{1.0, 0.0, 0.0}, // Identical
		},
		{
			Text:      "Different text",
			Embedding: []float32{0.0, 1.0, 0.0}, // Orthogonal
		},
		{
			Text:      "Somewhat similar",
			Embedding: []float32{0.5, 0.5, 0.0}, // Partially similar
		},
	}
	
	bestMatch, score := client.FindMostSimilar(queryEmbedding, candidates)
	
	if bestMatch == nil {
		t.Fatal("Expected to find a best match, got nil")
	}
	
	if bestMatch.Text != "Similar text" {
		t.Errorf("Expected best match to be 'Similar text', got '%s'", bestMatch.Text)
	}
	
	if score < 0.99 {
		t.Errorf("Expected high similarity score, got %f", score)
	}
	
	// Test empty candidates
	emptyMatch, emptyScore := client.FindMostSimilar(queryEmbedding, []*EmbeddingResult{})
	if emptyMatch != nil {
		t.Error("Expected nil match for empty candidates")
	}
	if emptyScore != 0.0 {
		t.Errorf("Expected 0.0 score for empty candidates, got %f", emptyScore)
	}
}

func TestGetEmbeddingDimension(t *testing.T) {
	client := NewOpenAIEmbeddingsClient("test-key")
	
	dimension := client.GetEmbeddingDimension()
	if dimension != 1536 {
		t.Errorf("Expected dimension 1536 for text-embedding-3-small, got %d", dimension)
	}
}

func TestModelMethods(t *testing.T) {
	client := NewOpenAIEmbeddingsClient("test-key")
	
	// Test GetModel
	model := client.GetModel()
	if model != "text-embedding-3-small" {
		t.Errorf("Expected model 'text-embedding-3-small', got '%s'", model)
	}
	
	// Test SetModel
	client.SetModel("text-embedding-3-large")
	newModel := client.GetModel()
	if newModel != "text-embedding-3-large" {
		t.Errorf("Expected model to be changed to 'text-embedding-3-large', got '%s'", newModel)
	}
}

func TestSqrt32(t *testing.T) {
	// Test basic square root functionality
	testCases := []struct {
		input    float32
		expected float32
		tolerance float32
	}{
		{0.0, 0.0, 0.01},
		{1.0, 1.0, 0.01},
		{4.0, 2.0, 0.01},
		{9.0, 3.0, 0.01},
		{16.0, 4.0, 0.01},
	}
	
	for _, tc := range testCases {
		result := sqrt32(tc.input)
		if result < tc.expected-tc.tolerance || result > tc.expected+tc.tolerance {
			t.Errorf("sqrt32(%f): expected ~%f, got %f", tc.input, tc.expected, result)
		}
	}
}

// Note: The actual embedding generation tests would require either:
// 1. A real OpenAI API key (not suitable for CI)
// 2. Mocking the OpenAI client (complex due to external dependency)
// 3. Integration tests (separate from unit tests)
//
// For CI purposes, these structural tests verify the basic functionality
// without making external API calls.
