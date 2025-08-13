package main

import (
	"context"
	"encoding/json"
	"fmt"
	"innerworld-backend/internal/config"
	"innerworld-backend/internal/graph"
	"log"
	"time"
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

func main() {
	startTime := time.Now()

	// Load configuration
	cfg, err := config.LoadConfig()
	if err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}

	// Initialize Neptune client (mock for development)
	var neptuneClient graph.NeptuneClient
	if cfg.IsDevelopment() {
		neptuneClient = graph.NewMockNeptuneClient()
		log.Println("Initialized Mock Neptune client for development")
	} else {
		neptuneClient = graph.NewMockNeptuneClient()
		log.Println("Using Mock Neptune client (production Neptune not yet configured)")
	}

	ctx := context.Background()

	// Check all services (same logic as the real health check)
	log.Println("Running health checks...")
	services := make(map[string]ServiceHealth)

	// Check Neptune connectivity
	neptuneHealth := checkNeptuneHealth(ctx, neptuneClient)
	services["neptune"] = neptuneHealth

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
		Version:   "1.0.0",
		Services:  services,
	}

	// Add debug info in development
	if cfg.Debug {
		response.Debug = map[string]interface{}{
			"environment":    cfg.Environment,
			"responseTimeMs": time.Since(startTime).Milliseconds(),
			"configLoaded":   true,
		}
	}

	// Output JSON response
	responseJSON, err := json.MarshalIndent(response, "", "  ")
	if err != nil {
		log.Fatalf("Failed to marshal response: %v", err)
	}

	fmt.Println(string(responseJSON))
}

// checkNeptuneHealth verifies Neptune database connectivity
func checkNeptuneHealth(ctx context.Context, neptuneClient graph.NeptuneClient) ServiceHealth {
	start := time.Now()

	// Create context with timeout
	neptuneCtx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()

	err := neptuneClient.HealthCheck(neptuneCtx)
	responseTime := time.Since(start)

	if err != nil {
		log.Printf("Neptune health check failed: %v", err)
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
