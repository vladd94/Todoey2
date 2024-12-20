import Foundation

/// Manages AI-related settings and configurations for the app
struct AISettings {
    // MARK: - OpenAI Configuration
    
    /// Default model to use for text generation
    static let defaultModel = "gpt-3.5-turbo"
    
    /// Temperature setting for text generation (0.0 - 1.0)
    /// Higher values make output more random, lower values more deterministic
    static let temperature: Double = 0.7
    
    /// Maximum tokens to generate in response
    static let maxTokens: Int = 100
    
    /// System prompt for task suggestions
    static let taskSuggestionPrompt = """
    You are a motivational assistant. Provide exactly 3 brief inspiring versions of tasks, \
    separated by '|' characters. Keep each version under 5 words.
    """
    
    // MARK: - UI Settings
    
    /// Loading message shown while generating suggestions
    static let loadingMessage = "Generating inspiring options..."
    
    /// Error message shown when API call fails
    static let errorMessage = "Failed to generate suggestions"
    
    /// Maximum number of suggestions to show
    static let maxSuggestions = 3
    
    // MARK: - Validation
    
    /// Maximum length for a task title
    static let maxTaskLength = 100
    
    /// Validates if a task title is within acceptable length
    static func isValidTaskLength(_ text: String) -> Bool {
        text.count <= maxTaskLength
    }
    
    // MARK: - API Configuration
    
    /// Headers required for OpenAI API calls
    static func getAPIHeaders(apiKey: String) -> [String: String] {
        [
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json"
        ]
    }
    
    /// Constructs the parameters for OpenAI API call
    static func getAPIParameters(prompt: String) -> [String: Any] {
        [
            "model": defaultModel,
            "messages": [
                ["role": "system", "content": taskSuggestionPrompt],
                ["role": "user", "content": prompt]
            ],
            "max_tokens": maxTokens,
            "temperature": temperature
        ]
    }
} 