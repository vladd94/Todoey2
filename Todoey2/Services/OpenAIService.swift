import Foundation

class OpenAIService {
    private let apiKey: String
    private let endpoint = "https://api.openai.com/v1/chat/completions"
    
    init() {
        // Get API key from configuration
        guard let key = APIKeys.getKey(for: "openAI") else {
            fatalError("OpenAI API key not found in configuration")
        }
        self.apiKey = key
    }
    
    func generateInspiringOptions(text: String) async throws -> [String] {
        // Don't make API call for very short inputs
        guard text.count >= 3 else {
            return []
        }
        
        let parameters = AISettings.getAPIParameters(prompt: """
            Transform this todo item into 3 different inspiring versions:
            Original: \(text)
            3 Inspiring versions:
            """)
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = AISettings.getAPIHeaders(apiKey: apiKey)
        request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        
        let (data, urlResponse) = try await URLSession.shared.data(for: request)
        
        // Check HTTP response
        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            throw NSError(domain: "OpenAI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])
        }
        
        guard httpResponse.statusCode == 200 else {
            // Print error response if available
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("OpenAI Error Response: \(errorJson)")
            }
            throw NSError(domain: "OpenAI", 
                         code: httpResponse.statusCode, 
                         userInfo: [NSLocalizedDescriptionKey: "API call failed with status code: \(httpResponse.statusCode)"])
        }
        
        // Try to decode the response
        let decodedResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        let options = decodedResponse.choices.first?.message.content
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            .components(separatedBy: "|")
            .map { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
            .filter { !$0.isEmpty } ?? []
        
        return options.count == 3 ? options : []
    }
}

// Response models
struct OpenAIResponse: Codable {
    let choices: [Choice]
}

struct Choice: Codable {
    let message: Message
}

struct Message: Codable {
    let content: String
} 
