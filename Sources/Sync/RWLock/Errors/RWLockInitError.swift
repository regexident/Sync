import Foundation

public enum RWLockInitError: RawRepresentable, Swift.Error {
    case again
    case invalid
    case noMemory
    case permissions
    case busy
    case unknown(Int32)

    public var rawValue: Int32 {
        switch self {
        case .again:
            return EAGAIN
        case .invalid:
            return EINVAL
        case .noMemory:
            return ENOMEM
        case .permissions:
            return EPERM
        case .busy:
            return EBUSY
        case .unknown(let errorCode):
            return errorCode
        }
    }

    public var localizedDescription: String {
        switch self {
        case .again:
            return "The system lacked the necessary resources (other than memory) to initialize the lock."
        case .invalid:
            return "The value specified by attr is invalid."
        case .noMemory:
            return "Insufficient memory exists to initialize the lock."
        case .permissions:
            return "The caller does not have sufficient privilege to perform perform the operation."
        case .busy:
            return "The system has detected an attempt to re-initialize the object referenced by rwlock, a previously initialized but not yet destroyed read/write lock."
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
        case EINVAL:
            self = .invalid
        case ENOMEM:
            self = .noMemory
        case EPERM:
            self = .permissions
        case EBUSY:
            self = .busy
        case _:
            self = .unknown(rawValue)
        }
    }
}
