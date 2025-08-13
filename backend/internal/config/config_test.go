package config

import (
	"os"
	"testing"
)

func TestLoadConfig(t *testing.T) {
	// Test with default values
	config, err := LoadConfig()
	if err != nil {
		t.Fatalf("LoadConfig() failed: %v", err)
	}

	if config.Environment != "development" {
		t.Errorf("Expected Environment to be 'development', got '%s'", config.Environment)
	}

	if config.Debug != false {
		t.Errorf("Expected Debug to be false, got %v", config.Debug)
	}

	if config.OpenRouter.BaseURL != "https://openrouter.ai/api/v1" {
		t.Errorf("Expected OpenRouter BaseURL to be 'https://openrouter.ai/api/v1', got '%s'", config.OpenRouter.BaseURL)
	}

	if config.Neptune.Port != 8182 {
		t.Errorf("Expected Neptune Port to be 8182, got %d", config.Neptune.Port)
	}
}

func TestLoadConfigWithEnvironmentVariables(t *testing.T) {
	// Set environment variables
	_ = os.Setenv("ENVIRONMENT", "test")
	_ = os.Setenv("DEBUG", "true")
	_ = os.Setenv("OPENROUTER_API_KEY", "test-key")
	_ = os.Setenv("NEPTUNE_PORT", "9999")

	defer func() {
		_ = os.Unsetenv("ENVIRONMENT")
		_ = os.Unsetenv("DEBUG")
		_ = os.Unsetenv("OPENROUTER_API_KEY")
		_ = os.Unsetenv("NEPTUNE_PORT")
	}()

	config, err := LoadConfig()
	if err != nil {
		t.Fatalf("LoadConfig() failed: %v", err)
	}

	if config.Environment != "test" {
		t.Errorf("Expected Environment to be 'test', got '%s'", config.Environment)
	}

	if config.Debug != true {
		t.Errorf("Expected Debug to be true, got %v", config.Debug)
	}

	if config.OpenRouter.APIKey != "test-key" {
		t.Errorf("Expected OpenRouter APIKey to be 'test-key', got '%s'", config.OpenRouter.APIKey)
	}

	if config.Neptune.Port != 9999 {
		t.Errorf("Expected Neptune Port to be 9999, got %d", config.Neptune.Port)
	}
}

func TestValidateConfigProduction(t *testing.T) {
	// Test production validation without API keys (should fail)
	config := &Config{
		Environment: "production",
		OpenRouter: OpenRouterConfig{
			APIKey: "",
		},
		OpenAI: OpenAIConfig{
			APIKey: "",
		},
		Neptune: NeptuneConfig{
			Port: 8182,
		},
	}

	err := validateConfig(config)
	if err == nil {
		t.Error("Expected validation to fail for production without API keys")
	}
}

func TestValidateConfigDevelopment(t *testing.T) {
	// Test development validation without API keys (should pass)
	config := &Config{
		Environment: "development",
		OpenRouter: OpenRouterConfig{
			APIKey: "",
		},
		OpenAI: OpenAIConfig{
			APIKey: "",
		},
		Neptune: NeptuneConfig{
			Port: 8182,
		},
	}

	err := validateConfig(config)
	if err != nil {
		t.Errorf("Expected development validation to pass without API keys, got error: %v", err)
	}
}

func TestValidateConfigInvalidPort(t *testing.T) {
	config := &Config{
		Environment: "development",
		Neptune: NeptuneConfig{
			Port: -1, // Invalid port
		},
	}

	err := validateConfig(config)
	if err == nil {
		t.Error("Expected validation to fail for invalid port")
	}
}

func TestConfigMethods(t *testing.T) {
	prodConfig := &Config{Environment: "production"}
	devConfig := &Config{Environment: "development"}

	if !prodConfig.IsProduction() {
		t.Error("Expected IsProduction() to return true for production config")
	}

	if prodConfig.IsDevelopment() {
		t.Error("Expected IsDevelopment() to return false for production config")
	}

	if devConfig.IsProduction() {
		t.Error("Expected IsProduction() to return false for development config")
	}

	if !devConfig.IsDevelopment() {
		t.Error("Expected IsDevelopment() to return true for development config")
	}
}

func TestUtilityFunctions(t *testing.T) {
	// Test getEnvOrDefault
	_ = os.Setenv("TEST_VAR", "test_value")
	defer func() { _ = os.Unsetenv("TEST_VAR") }()

	result := getEnvOrDefault("TEST_VAR", "default")
	if result != "test_value" {
		t.Errorf("Expected 'test_value', got '%s'", result)
	}

	result = getEnvOrDefault("NON_EXISTENT_VAR", "default")
	if result != "default" {
		t.Errorf("Expected 'default', got '%s'", result)
	}

	// Test getEnvAsInt
	_ = os.Setenv("TEST_INT", "42")
	defer func() { _ = os.Unsetenv("TEST_INT") }()

	intResult := getEnvAsInt("TEST_INT", 0)
	if intResult != 42 {
		t.Errorf("Expected 42, got %d", intResult)
	}

	intResult = getEnvAsInt("NON_EXISTENT_INT", 100)
	if intResult != 100 {
		t.Errorf("Expected 100, got %d", intResult)
	}

	// Test getEnvAsBool
	_ = os.Setenv("TEST_BOOL", "true")
	defer func() { _ = os.Unsetenv("TEST_BOOL") }()

	boolResult := getEnvAsBool("TEST_BOOL", false)
	if boolResult != true {
		t.Errorf("Expected true, got %v", boolResult)
	}

	boolResult = getEnvAsBool("NON_EXISTENT_BOOL", false)
	if boolResult != false {
		t.Errorf("Expected false, got %v", boolResult)
	}
}
