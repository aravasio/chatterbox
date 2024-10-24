import Foundation
import AsyncHTTPClient
import NIOCore
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

func ensureDirectoriesExist(config: Config) throws {
    let fileManager: FileManager = FileManager.default
    let expandedLogDirectory: String = expandTildeInPath(config.logDirectory)
    let baseDirectory: URL = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".chatterbox/")
    let logDirectory: URL = URL(fileURLWithPath: expandedLogDirectory)

    if !fileManager.fileExists(atPath: baseDirectory.path) {
        try fileManager.createDirectory(at: baseDirectory, withIntermediateDirectories: true, attributes: nil)
    }

    if !fileManager.fileExists(atPath: logDirectory.path) {
        try fileManager.createDirectory(at: logDirectory, withIntermediateDirectories: true, attributes: nil)
    }
}

func loadChatLog(config: Config) throws -> [ChatMessage] {
    let expandedLogDirectory: String = expandTildeInPath(config.logDirectory)
    let logURL: URL = URL(fileURLWithPath: expandedLogDirectory).appendingPathComponent("chat.log")
    
    if !FileManager.default.fileExists(atPath: logURL.path) {
        return [ChatMessage(role: .system, content: "You are a helpful assistant.")]
    }
    
    let data: Data = try Data(contentsOf: logURL)
    return try JSONDecoder().decode([ChatMessage].self, from: data)
}

func saveChatLog(messages: [ChatMessage], config: Config) throws {
    let expandedLogDirectory: String = expandTildeInPath(config.logDirectory)
    let logURL: URL = URL(fileURLWithPath: expandedLogDirectory).appendingPathComponent("chat.log")
    let encoder: JSONEncoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let data: Data = try encoder.encode(messages)
    try data.write(to: logURL)
}

func archiveChatLog(config: Config, apiKey: String) async throws {
    let expandedLogDirectory: String = expandTildeInPath(config.logDirectory)
    let logURL: URL = URL(fileURLWithPath: expandedLogDirectory).appendingPathComponent("chat.log")
    
    guard FileManager.default.fileExists(atPath: logURL.path) else { 
        return 
    }

    // Load existing messages
    let messages: [ChatMessage] = try loadChatLog(config: config)

    // Generate summary
    let summary: String = try await generateSummary(messages: messages, apiKey: apiKey)

    // Generate archive filename
    let dateFormatter: DateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyyMMddHHmmss"
    let dateString: String = dateFormatter.string(from: Date())

    let sanitizedSummary: String = summary
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: " ", with: "_")
        .replacingOccurrences(of: "/", with: "_")

    let archiveFileName: String = "\(dateString)_\(sanitizedSummary).old.log"
    let archiveURL: URL = URL(fileURLWithPath: expandedLogDirectory).appendingPathComponent(archiveFileName)

    // Move the file
    try FileManager.default.moveItem(at: logURL, to: archiveURL)
}

func generateSummary(messages: [ChatMessage], apiKey: String) async throws -> String {
    // Prepare conversation text
    let conversationText: String = messages.map { "\($0.role.rawValue): \($0.content)" }.joined(separator: "\n")

    // Create summarization prompt
    let summaryPrompt: String = "Summarize the following conversation in less than 5 words:\n\n\(conversationText)"

    // Create request
    let requestBody: OpenAIRequest = OpenAIRequest(
        model: Model.gpt3_5Turbo.rawValue, // This is the cheapest model rn, which should make do for summarization
        messages: [
            ChatMessage(role: .system, content: "You are a helpful assistant."),
            ChatMessage(role: .user, content: summaryPrompt)
        ],
        max_tokens: 10,
        temperature: 0.5,
        top_p: 0.5
    )

    // Send request and parse response
    let summary: String = try await sendOpenAIRequest(requestBody: requestBody, apiKey: apiKey)
    return summary
}

func sendMessage(
    messages: [ChatMessage],
    apiKey: String,
    model: Model,
    temperature: Double,
    topP: Double,
    maxTokens: Int?
) async throws -> String {
    let requestBody: OpenAIRequest = OpenAIRequest(
        model: model.rawValue,
        messages: messages,
        max_tokens: maxTokens,
        temperature: temperature,
        top_p: topP
    )
    return try await sendOpenAIRequest(requestBody: requestBody, apiKey: apiKey)
}

func sendOpenAIRequest(
    requestBody: OpenAIRequest,
    apiKey: String
) async throws -> String {
    let client: HTTPClient = HTTPClient.shared

    let url: String = "https://api.openai.com/v1/chat/completions"
    var request: HTTPClientRequest = HTTPClientRequest(url: url)
    request.method = .POST
    request.headers.add(name: "Authorization", value: "Bearer \(apiKey)")
    request.headers.add(name: "Content-Type", value: "application/json")

    // Encode request body to JSON data
    let encoder: JSONEncoder = JSONEncoder()
    let jsonData: Data = try encoder.encode(requestBody)
    request.body = .bytes(ByteBuffer(bytes: [UInt8](jsonData)))

    let response: HTTPClientResponse = try await client.execute(request, timeout: .seconds(30))

    guard response.status == .ok else {
        switch response.status {
        case .tooManyRequests:
            throw OpenAIError.rateLimitExceeded
        case .unauthorized:
            throw OpenAIError.invalidAPIKey
        default:
            let errorMessage: String = response.status.reasonPhrase
            throw OpenAIError.other("HTTP Error \(response.status.code): \(errorMessage)")
        }
    }

    let responseBody: ByteBuffer = try await response.body.collect(upTo: 2048 * 2048)

    let decoder: JSONDecoder = JSONDecoder()
    let data: ByteBufferView = responseBody.readableBytesView
    let openAIResponse: OpenAIResponse = try decoder.decode(OpenAIResponse.self, from: Data(data))

    return openAIResponse.choices.first?.message.content ?? ""
}

func readFromStandardInput() -> String {
    let data: Data = FileHandle.standardInput.availableData
    return String(decoding: data, as: UTF8.self)
}

enum OpenAIError: Error {
    case rateLimitExceeded
    case invalidAPIKey
    case other(String)
}

func handleOpenAIError(_ error: Error) {
    if let openAIError: OpenAIError = error as? OpenAIError {
        switch openAIError {
        case .rateLimitExceeded:
            print("Error: Rate limit exceeded. Please wait and try again later.")
        case .invalidAPIKey:
            print("Error: Invalid API key. Please check your configuration.")
        case .other(let message):
            print("Error: \(message)")
        }
    } else {
        print("An unexpected error occurred: \(error.localizedDescription)")
        print("Error details: \(error)")
    }
}

// Helper function to expand '~' in file paths
private func expandTildeInPath(_ path: String) -> String {
    if path.hasPrefix("~") {
        // Replace '~' with the user's home directory path
        let homeDirectory: String = NSHomeDirectory()
        return path.replacingOccurrences(of: "~", with: homeDirectory)
    } else {
        return path
    }
}

func isPipedInput() -> Bool {
    return isatty(fileno(stdin)) == 0
}
