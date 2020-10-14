import Foundation

public struct RWLockInvalidatedError: Swift.Error {
    public var localizedDescription: String {
        return "RWLock has previously been invalidated (probably by consuming)."
    }
}
