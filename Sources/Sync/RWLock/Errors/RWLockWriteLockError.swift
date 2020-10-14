import Foundation

public enum RWLockWriteLockError: RawRepresentable, Swift.Error {
    case again
    case deadlock
    case invalid
    case noMemory
    case unknown(Int32)

    public var rawValue: Int32 {
        switch self {
        case .again:
            return EAGAIN
        case .deadlock:
            return EDEADLK
        case .invalid:
            return EINVAL
        case .noMemory:
            return ENOMEM
        case .unknown(let errorCode):
            return errorCode
        }
    }

    public var localizedDescription: String {
        switch self {
        case .again:
            return "The lock could not be acquired, because the maximum number of read locks against lock has been exceeded."
        case .deadlock:
            return "The current thread already owns rwlock for writing."
        case .invalid:
            return "The value specified by rwlock is invalid."
        case .noMemory:
            return "Insufficient memory exists to initialize the lock (applies to statically initialized locks only)."
        case .unknown(let errorCode):
            return "Enexpected error \(errorCode)"
        }
    }

    public init?(rawValue: Int32) {
        switch rawValue {
        case 0:
            return nil
        case EAGAIN:
            self = .again
        case EDEADLK:
            self = .deadlock
        case EINVAL:
            self = .invalid
        case ENOMEM:
            self = .noMemory
        case _:
            self = .unknown(rawValue)
        }
    }
}
