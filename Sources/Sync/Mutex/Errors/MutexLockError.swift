import Foundation

public enum MutexLockError: RawRepresentable, Swift.Error {
    /// `EDEADLK`
    case deadlock
    /// `EINVAL`
    case invalid
    case unknown(Int32)

    public var rawValue: Int32 {
        switch self {
        case .deadlock:
            return EDEADLK
        case .invalid:
            return EINVAL
        case .unknown(let errorCode):
            return errorCode
        }
    }

    public var localizedDescription: String {
        switch self {
        case .deadlock:
            return "A deadlock would occur if the thread blocked waiting for mutex."
        case .invalid:
            return "The value specified by mutex is invalid."
        case .unknown(let errorCode):
            return "Enexpected error \(errorCode)"
        }
    }

    public init?(rawValue: Int32) {
        switch rawValue {
        case 0:
            return nil
        case EDEADLK:
            self = .deadlock
        case EINVAL:
            self = .invalid
        case _:
            self = .unknown(rawValue)
        }
    }
}
