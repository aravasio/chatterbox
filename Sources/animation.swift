import Foundation

class ProcessingIndicator {
    private let frames: [String] = ["[o     ]", "[ o    ]", "[  o   ]", "[   o  ]", "[    o ]", "[     o]", "[    o ]", "[   o  ]", "[  o   ]", "[ o    ]"]
    private var currentFrame: Int = 0
    private var isAnimating: Bool = false
    private var animationThread: Thread?

    // Start animation in a new thread
    func start() {
        guard !isAnimating else { return }
        isAnimating = true
        animationThread = Thread {
            while self.isAnimating {
                self.displayNextFrame()
                Thread.sleep(forTimeInterval: 0.2) // Adjust speed as necessary
            }
        }
        animationThread?.start()
    }

    // Stop the animation and clean up
    func stop() {
        isAnimating = false
        animationThread?.cancel()
        clearLine()
        print() // Print a new line to separate from the response
    }

    // Display the next frame of the animation
    private func displayNextFrame() {
        clearLine()
        print(frames[currentFrame], terminator: "")
        fflush(stdout) // Ensure the frame is printed immediately
        currentFrame = (currentFrame + 1) % frames.count
    }

    // Clear the current line in the terminal
    private func clearLine() {
        print("\r", terminator: "")
    }
}
