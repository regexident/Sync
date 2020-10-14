import Foundation

public enum MutexAttributeInitError: RawRepresentable, Swift.Error {
    case noMemory
    case invalid
    case unknown(Int32)

    public var rawValue: Int32 {
        switch self {
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
        case .noMemory:
            return "Out of memory."
        case .invalid:
            return "Invalid value for attr."
        case .unknown(let errorCode):
            return "Enexpected error \(errorCode)"
        }
    }

    public init?(rawValue: Int32) {
        switch rawValue {
        case 0:
            return nil
        case EINVAL:
            self = .invalid
        case ENOMEM:
            self = .noMemory
        case _:
            self = .unknown(rawValue)
        }
    }
}
