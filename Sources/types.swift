import Foundation

enum Role: String, Codable {
    case system
    case user
    case assistant
}

enum Model: String {
    case gpt3_5Turbo = "gpt-3.5-turbo"
    case gpt4 = "gpt-4"
    case gpt4o = "gpt-4o"
}

struct ChatMessage: Codable {
    let role: Role
    let content: String
}

struct OpenAIRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let max_tokens: Int?
    let temperature: Double?
    let top_p: Double?
}

struct OpenAIResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let role: String
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}
