import Foundation

public enum MutexTryLockError: RawRepresentable, Swift.Error {
    /// `EBUSY`
    case busy
    /// `EINVAL`
    case invalid
    case unknown(Int32)

    public var rawValue: Int32 {
        switch self {
        case .busy:
            return EBUSY
        case .invalid:
            return EINVAL
        case .unknown(let errorCode):
            return errorCode
        }
    }

    public var localizedDescription: String {
        switch self {
        case .busy:
            return "Mutex is already locked."
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
        case EBUSY:
            self = .busy
        case EINVAL:
            self = .invalid
        case _:
            self = .unknown(rawValue)
        }
    }
}
