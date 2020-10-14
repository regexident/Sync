import Foundation

public enum RWLockDestroyError: RawRepresentable, Swift.Error {
    case permissions
    case busy
    case invalid
    case unknown(Int32)

    public var rawValue: Int32 {
        switch self {
        case .permissions:
            return EPERM
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
        case .permissions:
            return "The caller does not have the privilege to perform the operation."
        case .busy:
            return "The system has detected an attempt to destroy the object referenced by rwlock while it is locked."
        case .invalid:
            return "The value specified by rwlock is invalid."
        case .unknown(let errorCode):
            return "Enexpected error \(errorCode)"
        }
    }

    public init?(rawValue: Int32) {
        switch rawValue {
        case 0:
            return nil
        case EPERM:
            self = .permissions
        case EBUSY:
            self = .busy
        case EINVAL:
            self = .invalid
        case _:
            self = .unknown(rawValue)
        }
    }
}
