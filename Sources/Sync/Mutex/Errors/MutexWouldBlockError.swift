import Foundation

public struct MutexWouldBlockError: Swift.Error {
    public var localizedDescription: String {
        return "Mutex is already locked."
    }
}
