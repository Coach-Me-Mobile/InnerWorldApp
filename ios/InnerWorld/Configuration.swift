import Foundation
import os.log

/// Configuration manager for API endpoints and environment-specific settings
struct Configuration {
    
    // MARK: - Logging
    
    /// Centralized logger for API operations
    static let logger = Logger(subsystem: "com.innerworld.app", category: "api")
    
    // MARK: - Rate Limiting
    
    /// Rate limiter for API requests to prevent abuse
    private static let rateLimitSemaphore = DispatchSemaphore(value: 10) // Max 10 concurrent requests
    private static var lastRequestTime: Date = Date.distantPast
    private static let minRequestInterval: TimeInterval = 0.1 // Throttle: min 100ms between requests
    
    // MARK: - API Endpoints
    
    /// Backend API base URL - configurable via environment variables or Info.plist
    static var backendBaseURL: String {
        let baseURL: String
        
        // First check environment variables
        if let envURL = ProcessInfo.processInfo.environment["BACKEND_BASE_URL"] {
            baseURL = envURL
        }
        // Fallback to Info.plist configuration
        else if let plistURL = Bundle.main.object(forInfoDictionaryKey: "BackendBaseURL") as? String {
            baseURL = plistURL
        }
        // Development default
        else {
            baseURL = "http://localhost:3000"
        }
        
        // Add API versioning - append /v1 if not already present
        if !baseURL.contains("/v1") && !baseURL.contains("/v2") {
            return baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/v1"
        }
        
        return baseURL
    }
    
    /// WebSocket endpoint for real-time communication
    static var websocketURL: String {
        if let envURL = ProcessInfo.processInfo.environment["WEBSOCKET_URL"] {
            return envURL
        }
        
        if let plistURL = Bundle.main.object(forInfoDictionaryKey: "WebSocketURL") as? String {
            return plistURL
        }
        
        return "ws://localhost:3000/ws"
    }
    
    /// AWS Cognito User Pool ID for authentication
    static var cognitoUserPoolId: String {
        if let envPoolId = ProcessInfo.processInfo.environment["COGNITO_USER_POOL_ID"] {
            return envPoolId
        }
        
        if let plistPoolId = Bundle.main.object(forInfoDictionaryKey: "CognitoUserPoolId") as? String {
            return plistPoolId
        }
        
        return "us-west-2_example123"
    }
    
    /// AWS Cognito App Client ID
    static var cognitoClientId: String {
        if let envClientId = ProcessInfo.processInfo.environment["COGNITO_CLIENT_ID"] {
            return envClientId
        }
        
        if let plistClientId = Bundle.main.object(forInfoDictionaryKey: "CognitoClientId") as? String {
            return plistClientId
        }
        
        return "example123clientid"
    }
    
    // MARK: - Environment Detection
    
    /// Current app environment (development, staging, production)
    static var environment: Environment {
        if let envString = ProcessInfo.processInfo.environment["APP_ENVIRONMENT"],
           let env = Environment(rawValue: envString) {
            return env
        }
        
        if let plistEnv = Bundle.main.object(forInfoDictionaryKey: "AppEnvironment") as? String,
           let env = Environment(rawValue: plistEnv) {
            return env
        }
        
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }
    
    /// Current API version for backward compatibility
    static var apiVersion: String {
        if let envVersion = ProcessInfo.processInfo.environment["API_VERSION"] {
            return "v" + envVersion
        }
        
        if let plistVersion = Bundle.main.object(forInfoDictionaryKey: "ApiVersion") as? String {
            return "v" + plistVersion
        }
        
        return "v1" // Default API version
    }
    
    /// Is debugging enabled
    static var isDebugEnabled: Bool {
        if let envDebug = ProcessInfo.processInfo.environment["DEBUG_ENABLED"] {
            return envDebug.lowercased() == "true"
        }
        
        if let plistDebug = Bundle.main.object(forInfoDictionaryKey: "DebugEnabled") as? Bool {
            return plistDebug
        }
        
        return environment == .development
    }
    
    // MARK: - Request Configuration
    
    /// Default request timeout interval in seconds
    static var requestTimeout: TimeInterval {
        if let envTimeout = ProcessInfo.processInfo.environment["REQUEST_TIMEOUT"],
           let timeout = Double(envTimeout) {
            return timeout
        }
        
        if let plistTimeout = Bundle.main.object(forInfoDictionaryKey: "RequestTimeout") as? Double {
            return plistTimeout
        }
        
        return 30.0
    }
    
    /// Maximum retry attempts for failed requests
    static var maxRetryAttempts: Int {
        if let envRetries = ProcessInfo.processInfo.environment["MAX_RETRY_ATTEMPTS"],
           let retries = Int(envRetries) {
            return retries
        }
        
        if let plistRetries = Bundle.main.object(forInfoDictionaryKey: "MaxRetryAttempts") as? Int {
            return plistRetries
        }
        
        return 3
    }
}

// MARK: - Environment Enum

extension Configuration {
    enum Environment: String, CaseIterable {
        case development = "development"
        case staging = "staging"
        case production = "production"
        
        var isProduction: Bool {
            return self == .production
        }
        
        var shouldLogRequests: Bool {
            return self != .production
        }
    }
}

// MARK: - Validation

extension Configuration {
    /// Validates that all required configuration values are properly set
    static func validateConfiguration() throws {
        guard !backendBaseURL.isEmpty else {
            throw ConfigurationError.missingValue("BACKEND_BASE_URL")
        }
        
        guard !cognitoUserPoolId.isEmpty else {
            throw ConfigurationError.missingValue("COGNITO_USER_POOL_ID")
        }
        
        guard !cognitoClientId.isEmpty else {
            throw ConfigurationError.missingValue("COGNITO_CLIENT_ID")
        }
        
        guard requestTimeout > 0 else {
            throw ConfigurationError.invalidValue("REQUEST_TIMEOUT must be greater than 0")
        }
        
        guard maxRetryAttempts >= 0 else {
            throw ConfigurationError.invalidValue("MAX_RETRY_ATTEMPTS must be non-negative")
        }
    }
}

// MARK: - Configuration Errors

enum ConfigurationError: LocalizedError {
    case missingValue(String)
    case invalidValue(String)
    
    var errorDescription: String? {
        switch self {
        case .missingValue(let key):
            return "Missing required configuration value: \(key)"
        case .invalidValue(let message):
                    return "Invalid configuration value: \(message)"
    }
}

// MARK: - API Request Utilities

extension Configuration {
    
    /// Rate limit API requests to prevent abuse and control costs
    static func rateLimit<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        // Acquire semaphore to limit concurrent requests
        rateLimitSemaphore.wait()
        defer { rateLimitSemaphore.signal() }
        
        // Throttle requests to prevent rapid fire
        let now = Date()
        let timeSinceLastRequest = now.timeIntervalSince(lastRequestTime)
        if timeSinceLastRequest < minRequestInterval {
            let delay = minRequestInterval - timeSinceLastRequest
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        lastRequestTime = Date()
        
        logger.log(level: .info, "API request rate limited and throttled")
        
        return try await operation()
    }
    
    /// Debounce API calls to reduce unnecessary requests
    static func debounce<T>(delay: TimeInterval = 0.5, operation: @escaping () async throws -> T) async throws -> T {
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        logger.log(level: .debug, "API request debounced for \(delay) seconds")
        return try await operation()
    }
    
    /// Log API requests for debugging and monitoring
    static func logAPIRequest(url: String, method: String, statusCode: Int? = nil) {
        if statusCode != nil {
            logger.log(level: .info, "API Response: \(method) \(url) -> \(statusCode!)")
        } else {
            logger.log(level: .info, "API Request: \(method) \(url)")
        }
    }
    
    /// Build versioned API URL with proper version path
    static func buildAPIURL(endpoint: String, version: String? = nil) -> String {
        let baseURL = backendBaseURL
        let apiVersion = version ?? self.apiVersion
        
        // Ensure endpoint starts with /
        let cleanEndpoint = endpoint.hasPrefix("/") ? endpoint : "/" + endpoint
        
        // Build versioned URL: baseURL/v1/endpoint
        let versionedURL = "\(baseURL)/\(apiVersion)\(cleanEndpoint)"
        
        logger.log(level: .debug, "Built versioned API URL: \(versionedURL)")
        return versionedURL
    }
}
