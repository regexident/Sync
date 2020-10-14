import Foundation

public struct MutexInvalidatedError: Swift.Error {
    public var localizedDescription: String {
        return "Mutex has previously been invalidated (probably by consuming)."
    }
}
