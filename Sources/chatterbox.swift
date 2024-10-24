import Foundation
import ArgumentParser

struct Chatterbox: AsyncParsableCommand {

    static func start() async {
        do {
            var box: Chatterbox = try parse()
            try await box.run()
        } catch {
            exit(withError: error)
        }
    }

    @Argument(help: "The message to send to the assistant.")
    var message: String?

    @Option(name: .shortAndLong, help: "Save the assistant's output to a file.")
    var output: String?
    
    @Flag(name: .shortAndLong, help: "Start a new chat.")
    var new: Bool = false

    @Option(name: .shortAndLong, help: "Specify the AI model.")
    var model: String?

    @Option(name: .shortAndLong, help: "Set the temperature for response randomness.")
    var temperature: Double?

    @Option(name: .shortAndLong, help: "Set the nucleus sampling probability for response diversity.")
    var topP: Double?

    @Option(name: .shortAndLong, help: "Set a custom system message for a new chat.")
    var systemMessage: String?

    @Flag(name: .shortAndLong, help: "Enable verbose logging.")
    var verbose: Bool = false

    @Option(name: .shortAndLong, help: "Read input from a file.")
    var file: String?

    mutating func run() async throws {
        // Load configuration
        let config: Config = try Config.load()
        try ensureDirectoriesExist(config: config)
        let apiKey: String = config.apiKey

         // Check if a custom system message is provided without the -n flag
        if systemMessage != nil && !new {
            throw ValidationError("Error: Custom system message can only be set when starting a new chat with the -n flag.")
        }

        // Handle starting a new chat
        var messages: [ChatMessage]
        if new {
            try await archiveChatLog(config: config, apiKey: apiKey)
            messages = [ChatMessage(role: .system, content: systemMessage ?? "You are a helpful assistant.")]
        } else {
            // Load existing chat history or start a new one
            do {
                messages = try loadChatLog(config: config)
            } catch {
                messages = [ChatMessage(role: .system, content: "You are a helpful assistant.")]
            }
        }

        // Read all input from stdin until EOF
        let userInput: String
        if isPipedInput() {
            var inputData: String = ""
            while let line: String = readLine() {
                inputData += line + "\n" // Accumulate input until EOF
            }
            userInput = inputData.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if let message: String = message {
            userInput = message
        } else if let filePath: String = file {
            userInput = try String(contentsOfFile: filePath, encoding: .utf8)
        } else {
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
        let topPToUse: Double = topP ?? config.topP
        let maxTokensToUse: Int = config.maxTokens

        // Start the processing indicator
        print() // Empty print to create a new-line for clearer spacing.
        let indicator: ProcessingIndicator = ProcessingIndicator()
        indicator.start()

        // Send request to OpenAI API
        do {
            let assistantResponse: String = try await sendMessage(
                messages: messages,
                apiKey: apiKey,
                model: modelToUse,
                temperature: temperatureToUse,
                topP: topPToUse,
                maxTokens: maxTokensToUse
            )

            indicator.stop()
            print() // Empty print to create a new-line for clearer spacing.

            // Append assistant response
            let assistantMessage: ChatMessage = ChatMessage(role: .assistant, content: assistantResponse)
            messages.append(assistantMessage)

            try saveChatLog(messages: messages, config: config)
            print(assistantResponse)

            // Save response to the file if the output option is provided
            if let filePath = output {
                try assistantResponse.write(toFile: filePath, atomically: true, encoding: .utf8)
            }
        } catch {
            indicator.stop()
            print() // Empty print to create a new-line for clearer spacing.
            handleOpenAIError(error)
        }

    }
}
