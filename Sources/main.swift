import Foundation

let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)

Task {
    await Chatterbox.start()
    semaphore.signal()
}

semaphore.wait()
