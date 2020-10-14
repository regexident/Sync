import Foundation

public struct RWLockWouldBlockError: Swift.Error {
    public var localizedDescription: String {
        return "RWLock is already locked."
    }
}
