import Foundation

/// Configuration manager for API endpoints and environment-specific settings
struct Configuration {
    
    // MARK: - API Endpoints
    
    /// Backend API base URL - configurable via environment variables or Info.plist
    static var backendBaseURL: String {
        // First check environment variables
        if let envURL = ProcessInfo.processInfo.environment["BACKEND_BASE_URL"] {
            return envURL
        }
        
        // Fallback to Info.plist configuration
        if let plistURL = Bundle.main.object(forInfoDictionaryKey: "BackendBaseURL") as? String {
            return plistURL
        }
        
        // Development default
        return "http://localhost:3000"
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
}
