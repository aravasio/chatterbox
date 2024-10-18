import Foundation
import ArgumentParser

struct Chatterbox: AsyncParsableCommand {

    static func start() async {
        do {
            var box = try parse()
            try await box.run()
        } catch {
            exit(withError: error)
        }
    }

    @Argument(help: "The message to send to the assistant.")
    var message: String?

    @Flag(name: .shortAndLong, help: "Start a new chat.")
    var new: Bool = false

    @Option(name: .shortAndLong, help: "Specify the AI model.")
    var model: String?

    @Option(name: .shortAndLong, help: "Set the temperature for response randomness.")
    var temperature: Double?

    @Flag(name: .shortAndLong, help: "Enable verbose logging.")
    var verbose: Bool = false

    @Option(name: .shortAndLong, help: "Read input from a file.")
    var file: String?

    mutating func run() async throws {
        if isPipedInput() {
            print("Piped input received. Processing...")
        } else {
            print("Enter your message (end with EOF or Ctrl+D):")
        }

        // Load configuration
        let config: Config = try Config.load()
        try ensureDirectoriesExist(config: config)
        let apiKey: String = config.apiKey

        // Handle starting a new chat
        if new {
            try await archiveChatLog(config: config, apiKey: apiKey)
        }

        // Load existing chat history or start a new one
        var messages: [ChatMessage]
        do {
            messages = try loadChatLog(config: config)
        } catch {
            messages = [ChatMessage(role: .system, content: "You are a helpful assistant.")]
        }

        // Read user input
        let userInput: String
        if let message: String = message {
            userInput = message
        } else if let filePath: String = file {
            userInput = try String(contentsOfFile: filePath, encoding: .utf8)
        } else {
            // Adjust based on whether input is from a pipe or interactive
            userInput = readFromStandardInput()
        }

        // Append user message
        let userMessage: ChatMessage = ChatMessage(role: .user, content: userInput)
        messages.append(userMessage)

        // Determine model and parameters
        let modelToUse: Model
        if let modelArgument: String = model {
            guard let specifiedModel: Model = Model(rawValue: modelArgument) else {
                print("Error: Invalid model specified.")
                return
            }
            modelToUse = specifiedModel
        } else if let defaultModel: Model = Model(rawValue: config.defaultModel) {
            modelToUse = defaultModel
        } else {
            print("Error: Invalid default model in configuration.")
            return
        }

        let temperatureToUse: Double = temperature ?? config.temperature
        let maxTokensToUse: Int = config.maxTokens

        // Send request to OpenAI API
        do {
            let assistantResponse: String = try await sendMessage(
                messages: messages,
                apiKey: apiKey,
                model: modelToUse,
                temperature: temperatureToUse,
                maxTokens: maxTokensToUse
            )

            // Append assistant response
            let assistantMessage: ChatMessage = ChatMessage(role: .assistant, content: assistantResponse)
            messages.append(assistantMessage)

            try saveChatLog(messages: messages, config: config)
            print(assistantResponse)
        } catch {
            handleOpenAIError(error)
        }
    }
}