import Foundation

public enum MutexInitError: RawRepresentable, Swift.Error {
    case again
    case invalid
    case noMemory
    case unknown(Int32)

    public var rawValue: Int32 {
        switch self {
        case .again:
            return EAGAIN
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
            return "The system temporarily lacks the resources to create another mutex."
        case .invalid:
            return "The value specified by attr is invalid."
        case .noMemory:
            return "The process cannot allocate enough memory to create another mutex."
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
        case _:
            self = .unknown(rawValue)
        }
    }
}
