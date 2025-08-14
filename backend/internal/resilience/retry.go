package resilience

import (
	"context"
	"fmt"
	"log"
	"math"
	"time"
)

// RetryConfig defines retry behavior
type RetryConfig struct {
	MaxAttempts       int           // Maximum number of retry attempts
	InitialDelay      time.Duration // Initial delay before first retry
	MaxDelay          time.Duration // Maximum delay between retries
	BackoffMultiplier float64       // Multiplier for exponential backoff
}

// DefaultRetryConfig provides sensible defaults for Lambda functions
func DefaultRetryConfig() RetryConfig {
	return RetryConfig{
		MaxAttempts:       3,
		InitialDelay:      1 * time.Second,
		MaxDelay:          30 * time.Second,
		BackoffMultiplier: 2.0,
	}
}

// RetryableFunc defines a function that can be retried
type RetryableFunc[T any] func(ctx context.Context, attempt int) (T, error)

// IsRetryableError determines if an error should trigger a retry
type IsRetryableError func(error) bool

// RetryWithBackoff executes a function with exponential backoff retry logic
func RetryWithBackoff[T any](ctx context.Context, config RetryConfig, isRetryable IsRetryableError, fn RetryableFunc[T]) (T, error) {
	var lastErr error
	var result T

	for attempt := 1; attempt <= config.MaxAttempts; attempt++ {
		// Execute the function
		result, err := fn(ctx, attempt)
		if err == nil {
			// Success!
			if attempt > 1 {
				log.Printf("Operation succeeded on attempt %d", attempt)
			}
			return result, nil
		}

		lastErr = err

		// Check if we should retry this error
		if !isRetryable(err) {
			log.Printf("Non-retryable error on attempt %d: %v", attempt, err)
			return result, fmt.Errorf("non-retryable error: %w", err)
		}

		// Don't wait after the last attempt
		if attempt == config.MaxAttempts {
			break
		}

		// Calculate delay with exponential backoff
		delay := time.Duration(float64(config.InitialDelay) * math.Pow(config.BackoffMultiplier, float64(attempt-1)))
		if delay > config.MaxDelay {
			delay = config.MaxDelay
		}

		log.Printf("Attempt %d failed, retrying in %v: %v", attempt, delay, err)

		// Wait with context cancellation support
		select {
		case <-ctx.Done():
			return result, fmt.Errorf("retry cancelled: %w", ctx.Err())
		case <-time.After(delay):
			// Continue to next attempt
		}
	}

	log.Printf("All %d attempts failed", config.MaxAttempts)
	return result, fmt.Errorf("retry exhausted after %d attempts, last error: %w", config.MaxAttempts, lastErr)
}

// Common retry predicates

// DefaultRetryableErrors returns true for common transient errors
func DefaultRetryableErrors(err error) bool {
	if err == nil {
		return false
	}

	errStr := err.Error()

	// Network-related errors
	if contains(errStr, "connection refused") ||
		contains(errStr, "connection reset") ||
		contains(errStr, "connection timeout") ||
		contains(errStr, "temporary failure") ||
		contains(errStr, "service unavailable") ||
		contains(errStr, "timeout") {
		return true
	}

	// AWS service errors
	if contains(errStr, "ThrottlingException") ||
		contains(errStr, "ServiceUnavailableException") ||
		contains(errStr, "InternalServerError") ||
		contains(errStr, "RequestTimeout") {
		return true
	}

	return false
}

// S3RetryableErrors checks for S3-specific retryable errors
func S3RetryableErrors(err error) bool {
	if DefaultRetryableErrors(err) {
		return true
	}

	errStr := err.Error()
	return contains(errStr, "ConcurrentModificationException") ||
		contains(errStr, "ReadOnlyViolationException") ||
		contains(errStr, "ConstraintViolationException")
}

// DynamoDBRetryableErrors checks for DynamoDB-specific retryable errors
func DynamoDBRetryableErrors(err error) bool {
	if DefaultRetryableErrors(err) {
		return true
	}

	errStr := err.Error()
	return contains(errStr, "ProvisionedThroughputExceededException") ||
		contains(errStr, "RequestLimitExceeded") ||
		contains(errStr, "UnprocessedItems")
}

// OpenRouterRetryableErrors checks for OpenRouter API retryable errors
func OpenRouterRetryableErrors(err error) bool {
	if DefaultRetryableErrors(err) {
		return true
	}

	errStr := err.Error()
	return contains(errStr, "rate limit") ||
		contains(errStr, "429") || // Too Many Requests
		contains(errStr, "502") || // Bad Gateway
		contains(errStr, "503") || // Service Unavailable
		contains(errStr, "504") // Gateway Timeout
}

// contains is a simple string contains helper
func contains(s, substr string) bool {
	return len(s) >= len(substr) && (s == substr || contains(s[1:], substr))
}

// CircuitBreaker implements the circuit breaker pattern for failing services
type CircuitBreaker struct {
	maxFailures  int
	resetTimeout time.Duration
	failureCount int
	lastFailTime time.Time
	state        CircuitState
}

// CircuitState represents the circuit breaker state
type CircuitState int

const (
	CircuitClosed   CircuitState = iota // Normal operation
	CircuitOpen                         // Failing, reject requests
	CircuitHalfOpen                     // Testing if service recovered
)

// NewCircuitBreaker creates a new circuit breaker
func NewCircuitBreaker(maxFailures int, resetTimeout time.Duration) *CircuitBreaker {
	return &CircuitBreaker{
		maxFailures:  maxFailures,
		resetTimeout: resetTimeout,
		state:        CircuitClosed,
	}
}

// Execute runs a function through the circuit breaker
func (cb *CircuitBreaker) Execute(ctx context.Context, fn func() error) error {
	// Check if we should attempt to reset the circuit
	if cb.state == CircuitOpen && time.Since(cb.lastFailTime) > cb.resetTimeout {
		cb.state = CircuitHalfOpen
		log.Printf("Circuit breaker transitioning to half-open state")
	}

	// Reject requests if circuit is open
	if cb.state == CircuitOpen {
		return fmt.Errorf("circuit breaker is open, rejecting request")
	}

	// Execute the function
	err := fn()

	if err != nil {
		cb.onFailure()
		return err
	}

	cb.onSuccess()
	return nil
}

// onFailure handles function execution failure
func (cb *CircuitBreaker) onFailure() {
	cb.failureCount++
	cb.lastFailTime = time.Now()

	if cb.failureCount >= cb.maxFailures {
		cb.state = CircuitOpen
		log.Printf("Circuit breaker opened after %d failures", cb.failureCount)
	}
}

// onSuccess handles function execution success
func (cb *CircuitBreaker) onSuccess() {
	cb.failureCount = 0

	if cb.state == CircuitHalfOpen {
		cb.state = CircuitClosed
		log.Printf("Circuit breaker closed - service recovered")
	}
}

// GetState returns the current circuit breaker state
func (cb *CircuitBreaker) GetState() CircuitState {
	return cb.state
}
