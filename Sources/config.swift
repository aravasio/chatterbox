import Foundation

struct Config: Codable {
    let apiKey: String
    let defaultModel: String
    let temperature: Double
    let topP: Double
    let maxTokens: Int
    let logDirectory: String

    static func load() throws -> Config {
        let fileManager: FileManager = FileManager.default
        let homeDirectory: String = NSHomeDirectory()
        let configDirectory: URL = URL(fileURLWithPath: homeDirectory).appendingPathComponent(".chatterbox/")
        let configFileURL: URL = configDirectory.appendingPathComponent("config.json")

        if !fileManager.fileExists(atPath: configFileURL.path) {
            throw NSError(
                domain: "Config",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey:
                    """
                    Configuration file not found at \(configFileURL.path).
                    Please refer to the README.md for instructions on how to create the config.json file.
                    """
                ]
            )
        }

        let data: Data = try Data(contentsOf: configFileURL)
        let decoder: JSONDecoder = JSONDecoder()
        let config: Config = try decoder.decode(Config.self, from: data)
        return config
    }
}
