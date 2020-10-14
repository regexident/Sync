import Foundation

public enum RWLockTryWriteLockError: RawRepresentable, Swift.Error {
    case busy
    case deadlock
    case invalid
    case noMemory
    case unknown(Int32)

    public var rawValue: Int32 {
        switch self {
        case .busy:
            return EBUSY
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
        case .busy:
            return "The calling thread is not able to acquire the lock without blocking."
        case .deadlock:
            return "The calling thread already owns the read/write lock (for reading or writing)."
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
        case EBUSY:
            self = .busy
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
