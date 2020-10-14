import Foundation

/// Errors returned by `pthread_mutexattr_init`.
public enum MutexAttributeInitError: RawRepresentable, Swift.Error {
    /// `ENOMEM`
    case noMemory
    case unknown(Int32)

    public var rawValue: Int32 {
        switch self {
        case .noMemory:
            return ENOMEM
        case .unknown(let errorCode):
            return errorCode
        }
    }

    public var localizedDescription: String {
        switch self {
        case .noMemory:
            return "Out of memory."
        case .unknown(let errorCode):
            return "Enexpected error \(errorCode)"
        }
    }

    public init?(rawValue: Int32) {
        switch rawValue {
        case 0:
            return nil
        case ENOMEM:
            self = .noMemory
        case _:
            self = .unknown(rawValue)
        }
    }
}
