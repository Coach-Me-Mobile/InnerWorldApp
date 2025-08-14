package main

import (
	"context"
	"encoding/json"
	"fmt"
	"innerworld-backend/internal/config"
	"innerworld-backend/internal/graph"
	"log"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

// HealthCheckResponse represents the health check response
type HealthCheckResponse struct {
	Status    string                   `json:"status"`
	Timestamp string                   `json:"timestamp"`
	Version   string                   `json:"version"`
	Services  map[string]ServiceHealth `json:"services"`
	Debug     map[string]interface{}   `json:"debug,omitempty"`
}

// ServiceHealth represents the health status of a service
type ServiceHealth struct {
	Status       string `json:"status"` // "healthy" | "unhealthy" | "degraded"
	ResponseTime string `json:"responseTime,omitempty"`
	Error        string `json:"error,omitempty"`
}

// Global variables for reuse across invocations
var (
	cfg      *config.Config
	s3Client graph.S3Client
)

// init runs once when the Lambda function is initialized
func init() {
	var err error

	// Load configuration
	cfg, err = config.LoadConfig()
	if err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}

	// Initialize S3 client (mock for local development)
	if cfg.IsDevelopment() {
		s3Client = graph.NewMockS3Client()
		log.Println("Initialized Mock S3 client for development")
	} else {
		// TODO: Initialize real S3 client when infrastructure is ready
		s3Client = graph.NewMockS3Client()
		log.Println("Using Mock S3 client (production S3 not yet configured)")
	}
}

// handleHealthCheck processes health check requests
func handleHealthCheck(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	startTime := time.Now()

	log.Printf("Health check requested from: %s", request.Headers["User-Agent"])

	// Check all services
	services := make(map[string]ServiceHealth)

	// Check S3 connectivity
	s3Health := checkS3Health(ctx)
	services["s3"] = s3Health

	// Check OpenRouter (skip in health check to avoid API costs)
	services["openrouter"] = ServiceHealth{
		Status: "skipped",
	}

	// Check OpenAI (skip in health check to avoid API costs)
	services["openai"] = ServiceHealth{
		Status: "skipped",
	}

	// Determine overall status
	overallStatus := "healthy"
	for _, service := range services {
		if service.Status == "unhealthy" {
			overallStatus = "unhealthy"
			break
		} else if service.Status == "degraded" && overallStatus == "healthy" {
			overallStatus = "degraded"
		}
	}

	// Build response
	response := HealthCheckResponse{
		Status:    overallStatus,
		Timestamp: time.Now().UTC().Format(time.RFC3339),
		Version:   "1.0.0", // TODO: Get from build info
		Services:  services,
	}

	// Add debug info in development
	if cfg.Debug {
		response.Debug = map[string]interface{}{
			"environment":    cfg.Environment,
			"responseTimeMs": time.Since(startTime).Milliseconds(),
			"requestId":      request.RequestContext.RequestID,
			"sourceIP":       request.Headers["X-Forwarded-For"],
		}
	}

	// Determine HTTP status code
	var statusCode int
	switch overallStatus {
	case "unhealthy":
		statusCode = 503 // Service Unavailable
	case "degraded":
		statusCode = 200 // Still operational
	default:
		statusCode = 200
	}

	// Marshal response
	responseBody, err := json.Marshal(response)
	if err != nil {
		log.Printf("Failed to marshal health check response: %v", err)
		return events.APIGatewayProxyResponse{
			StatusCode: 500,
			Headers: map[string]string{
				"Content-Type": "application/json",
			},
			Body: `{"status": "error", "message": "Failed to generate response"}`,
		}, nil
	}

	log.Printf("Health check completed: %s (took %dms)",
		overallStatus, time.Since(startTime).Milliseconds())

	return events.APIGatewayProxyResponse{
		StatusCode: statusCode,
		Headers: map[string]string{
			"Content-Type":  "application/json",
			"Cache-Control": "no-cache",
		},
		Body: string(responseBody),
	}, nil
}

// checkS3Health verifies S3 storage connectivity
func checkS3Health(ctx context.Context) ServiceHealth {
	start := time.Now()

	// Create context with timeout
	s3Ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()

	err := s3Client.HealthCheck(s3Ctx)
	responseTime := time.Since(start)

	if err != nil {
		log.Printf("S3 health check failed: %v", err)
		return ServiceHealth{
			Status:       "unhealthy",
			ResponseTime: responseTime.String(),
			Error:        err.Error(),
		}
	}

	// Check response time for degraded status
	status := "healthy"
	if responseTime > 5*time.Second {
		status = "degraded"
	}

	return ServiceHealth{
		Status:       status,
		ResponseTime: responseTime.String(),
	}
}

// handleDirectInvocation handles direct Lambda invocations (useful for monitoring)
func handleDirectInvocation(ctx context.Context) (HealthCheckResponse, error) {
	// Convert to API Gateway format for consistency
	request := events.APIGatewayProxyRequest{
		RequestContext: events.APIGatewayProxyRequestContext{
			RequestID: "direct-invocation",
		},
		Headers: map[string]string{
			"User-Agent": "Lambda-Direct",
		},
	}

	response, err := handleHealthCheck(ctx, request)
	if err != nil {
		return HealthCheckResponse{}, err
	}

	var healthResponse HealthCheckResponse
	if err := json.Unmarshal([]byte(response.Body), &healthResponse); err != nil {
		return HealthCheckResponse{}, fmt.Errorf("failed to parse health response: %w", err)
	}

	return healthResponse, nil
}

func main() {
	// Handle both API Gateway and direct invocations
	lambda.Start(func(ctx context.Context, event json.RawMessage) (interface{}, error) {
		// Try to parse as API Gateway event first
		var apiGatewayEvent events.APIGatewayProxyRequest
		if err := json.Unmarshal(event, &apiGatewayEvent); err == nil && apiGatewayEvent.RequestContext.RequestID != "" {
			// API Gateway invocation
			return handleHealthCheck(ctx, apiGatewayEvent)
		}

		// Direct invocation
		return handleDirectInvocation(ctx)
	})
}
