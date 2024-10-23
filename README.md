# Chatterbox

**Chatterbox** is a Swift-based command-line interface (CLI) tool that allows users to interact with OpenAI's GPT models from their terminal. This tool provides functionalities for sending messages, starting new chat sessions, specifying models, and configuring response settings. It also supports logging and archiving chat histories.

## Table of Contents

- [Features](#features)
- [Installation](#installation)
  - [Build the Project](#build-the-project)
  - [Install the Executable Globally](#install-the-executable-globally)
- [Configuration](#configuration)
- [Usage](#usage)
  - [Send a Message](#send-a-message)
  - [Start a New Chat Session](#start-a-new-chat-session)
  - [Specify a Model](#specify-a-model)
  - [Set Response Temperature](#set-response-temperature)
  - [Verbose Mode](#verbose-mode)
  - [Read Input from a File](#read-input-from-a-file)
- [Logging and Chat History](#logging-and-chat-history)
- [Error Handling](#error-handling)
- [Troubleshooting](#troubleshooting)
- [Enhancing Chatterbox with .stitchrc](#enhancing-chatterbox-with-stitchrc)
- [License](#license)

---

## Features

- Interact with OpenAI GPT models via terminal.
- Send messages or start new chat sessions.
- Use various OpenAI models (e.g., `gpt-3.5-turbo`, `gpt-4`).
- Adjust response temperature to control randomness.
- Archive and log chat histories.
- Read user input from files or directly from terminal.

---

## Installation

### Build the Project

You need to build the project using Swift Package Manager. Run the following command from the project directory:

```bash
swift build -c release
```

This will create a release build in the `.build/release/` directory.

### Install the Executable Globally

Once the project is built, you can create a symbolic link to make the executable globally available from the terminal. Run the following commands:

```bash
sudo ln -s "$(pwd)/.build/release/chatterbox" /usr/local/bin/chatterbox
```

This will allow you to use `chatterbox` from anywhere in the terminal.

---

## Configuration

Before using Chatterbox, you need to set up a configuration file at:

```
~/.chatterbox/config.json
```

### Example `config.json`:

```json
{
  "apiKey": "your-openai-api-key",
  "defaultModel": "gpt-4",
  "temperature": 0.7,
  "maxTokens": 150,
  "logDirectory": "/home/username/.chatterbox/logs"
}
```

### Configuration Parameters:

- **`apiKey`**: Your OpenAI API key.
- **`defaultModel`**: The default GPT model to use (e.g., `gpt-3.5-turbo`, `gpt-4`).
- **`temperature`**: Controls response randomness. Values between 0.0 (deterministic) and 1.0 (creative).
- **`maxTokens`**: The maximum number of tokens in the response.
- **`logDirectory`**: Path to store chat logs. Ensure this directory exists.

### Steps to Create the Configuration File:

1. **Navigate to the Configuration Directory**:
   ```bash
   mkdir -p ~/.chatterbox
   cd ~/.chatterbox
   ```

2. **Create the `config.json` File**:
   ```bash
   touch config.json
   ```

3. **Edit the File**:
   Open `config.json` in your favorite text editor and add your API key, model, and other settings as shown in the example.

4. **Ensure the API Key is Set**:
   Make sure you have a valid OpenAI API key in the `apiKey` field.

---

## Usage

Once Chatterbox is installed and the configuration is set up, you can interact with it using various commands from the terminal.

### Send a Message

To send a message to the assistant:

```bash
chatterbox "Hello, how are you?"
```

### Start a New Chat Session

To start a new chat session:

```bash
chatterbox --new "Tell me a joke."
```

### Specify a Model

To specify which GPT model to use:

```bash
chatterbox --model gpt-4 "Explain quantum mechanics."
```

### Set Response Temperature

To control how random or creative the assistant's responses are, set the temperature:

```bash
chatterbox --temperature 0.5 "What is the capital of France?"
```

### Verbose Mode

To enable verbose logging for detailed output:

```bash
chatterbox --verbose "Summarize the book '1984'."
```

### Read Input from a File

To read the input message from a file:

```bash
chatterbox --file path/to/input.txt
```

---

## Logging and Chat History

Chatterbox automatically saves chat histories in the directory specified in your configuration (`logDirectory`).

### Logs Location

By default, logs are stored in:

```
~/.chatterbox/logs/
```

- Chat logs are saved as JSON files with timestamps.
- When a new chat session is started, the old session is archived.

---

## Error Handling

If the configuration file (`~/.chatterbox/config.json`) is missing, Chatterbox will return an error message similar to the following:

```
Configuration file is missing at /home/username/.chatterbox/config.json. Please refer to the README.md for instructions on how to create the config.json file.
```

This ensures that you know where the issue lies and can fix it by setting up the necessary configuration.

---

## Troubleshooting

- **Command Not Found**: Ensure you created the symlink to `/usr/local/bin/chatterbox` and that `/usr/local/bin` is in your system’s `PATH`.
- **Invalid API Key**: Verify your API key is correct in the `config.json` file.
- **Logging Issues**: Ensure the `logDirectory` specified in the configuration exists and that Chatterbox has permission to write to it.

---

## Enhancing Chatterbox with .stitchrc

The `.stitchrc` file provides a Zsh function named `stitch` that can be used to combine multiple code files from a specified directory into a single, formatted output. This can be useful for preparing code snippets or documentation.

### Setting Up `.stitchrc`

1. **Add the `stitch` Function to Your `.zshrc`**:
   Copy the content of `.stitchrc` into your `.zshrc` file to make the `stitch` function available in your terminal sessions.

2. **Create a Soft Link to Home**:
   If you have a separate `.stitchrc` file, you can create a symbolic link to it in your home directory:

   ```bash
   ln -s /path/to/.stitchrc ~/.stitchrc
   ```

3. **Source the `.stitchrc` in Your `.zshrc`**:
   Add the following line to your `.zshrc` to source the `.stitchrc` file:

   ```bash
   source ~/.stitchrc
   ```

4. **Reload Your Zsh Configuration**:
   After updating your `.zshrc`, reload it with:

   ```bash
   source ~/.zshrc
   ```

### Using the `stitch` Function

- **Combine Files**: Use `stitch` to combine files in a directory:

  ```bash
  stitch src
  ```

- **Recursive Combination**: Combine files recursively:

  ```bash
  stitch -r src
  ```

- **Output to Clipboard**: Combine files and copy to clipboard:

  ```bash
  stitch -o clipboard src
  ```

This function respects `.gitignore` files and can skip binary files, making it a powerful tool for managing code snippets and documentation.

---

## License

This project is licensed under the MIT License. See the LICENSE file for more details.