import Foundation

public enum MutexAttributeDestroyError: RawRepresentable, Swift.Error {
    case invalid
    case unknown(Int32)

    public var rawValue: Int32 {
        switch self {
        case .invalid:
            return EINVAL
        case .unknown(let errorCode):
            return errorCode
        }
    }

    public var localizedDescription: String {
        switch self {
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
        case _:
            self = .unknown(rawValue)
        }
    }
}
