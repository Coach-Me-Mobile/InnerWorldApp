package config

import (
	"fmt"
	"os"
	"strconv"
	"strings"
)

// Config holds basic application configuration for Phase 1
type Config struct {
	// Environment
	Environment string `json:"environment"`
	Debug       bool   `json:"debug"`

	// External APIs
	OpenRouter OpenRouterConfig `json:"openrouter"`
	OpenAI     OpenAIConfig     `json:"openai"`

	// Storage
	S3 S3Config `json:"s3"`
}

// OpenRouterConfig holds OpenRouter API configuration
type OpenRouterConfig struct {
	APIKey  string `json:"api_key"`
	BaseURL string `json:"base_url"`
	Model   string `json:"model"`
}

// OpenAIConfig holds OpenAI API configuration
type OpenAIConfig struct {
	APIKey string `json:"api_key"`
	Model  string `json:"model"`
}

// S3Config holds basic S3 configuration
type S3Config struct {
	Bucket string `json:"bucket"`
	Region string `json:"region"`
}

// LoadConfig loads configuration from environment variables
func LoadConfig() (*Config, error) {
	config := &Config{
		Environment: getEnvOrDefault("ENVIRONMENT", "development"),
		Debug:       getEnvAsBool("DEBUG", false),

		OpenRouter: OpenRouterConfig{
			APIKey:  getEnvOrDefault("OPENROUTER_API_KEY", ""),
			BaseURL: getEnvOrDefault("OPENROUTER_BASE_URL", "https://openrouter.ai/api/v1"),
			Model:   getEnvOrDefault("OPENROUTER_MODEL", "openai/gpt-4o-mini"),
		},

		OpenAI: OpenAIConfig{
			APIKey: getEnvOrDefault("OPENAI_API_KEY", ""),
			Model:  getEnvOrDefault("OPENAI_MODEL", "text-embedding-3-small"),
		},

		S3: S3Config{
			Bucket: getEnvOrDefault("S3_BUCKET", "innerworld-dev-bucket"),
			Region: getEnvOrDefault("S3_REGION", "us-west-2"),
		},
	}

	// Basic validation
	if err := validateConfig(config); err != nil {
		return nil, fmt.Errorf("configuration validation failed: %w", err)
	}

	return config, nil
}

// validateConfig ensures basic configuration is valid
func validateConfig(config *Config) error {
	var errors []string

	// In production, API keys should be present (but not required for development)
	if config.Environment == "production" {
		if config.OpenRouter.APIKey == "" {
			errors = append(errors, "OPENROUTER_API_KEY is required in production")
		}
		if config.OpenAI.APIKey == "" {
			errors = append(errors, "OPENAI_API_KEY is required in production")
		}
	}

	// Validate S3 configuration
	if config.S3.Bucket == "" {
		errors = append(errors, "S3_BUCKET is required")
	}
	if config.S3.Region == "" {
		errors = append(errors, "S3_REGION is required")
	}

	if len(errors) > 0 {
		return fmt.Errorf("configuration errors:\n%s", strings.Join(errors, "\n"))
	}

	return nil
}

// IsProduction returns true if running in production environment
func (c *Config) IsProduction() bool {
	return c.Environment == "production"
}

// IsDevelopment returns true if running in development environment
func (c *Config) IsDevelopment() bool {
	return c.Environment == "development"
}

// Utility functions for environment variable parsing

func getEnvOrDefault(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getEnvAsInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if intValue, err := strconv.Atoi(value); err == nil {
			return intValue
		}
	}
	return defaultValue
}

func getEnvAsBool(key string, defaultValue bool) bool {
	if value := os.Getenv(key); value != "" {
		if boolValue, err := strconv.ParseBool(value); err == nil {
			return boolValue
		}
	}
	return defaultValue
}
