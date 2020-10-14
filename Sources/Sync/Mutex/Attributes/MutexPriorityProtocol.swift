import Foundation

/// The priority protocol of a mutex.
public enum MutexPriorityProtocol: Int32, RawRepresentable {
    public typealias RawValue = Int32

    /// `PTHREAD_PRIO_NONE`
    case none = 0
    /// `PTHREAD_PRIO_INHERIT`
    case inherit = 1
    /// `PTHREAD_PRIO_PROTECT`
    case protect = 2

    /// The system's default mutex priority protocol.
    public static let `default`: Self = .none

    public var rawValue: RawValue {
        switch self {
        case .none:
            return PTHREAD_PRIO_NONE
        case .inherit:
            return PTHREAD_PRIO_INHERIT
        case .protect:
            return PTHREAD_PRIO_PROTECT
        }
    }

    public init?(rawValue: RawValue) {
        switch rawValue {
        case PTHREAD_PRIO_NONE:
            self = .none
        case PTHREAD_PRIO_INHERIT:
            self = .inherit
        case PTHREAD_PRIO_PROTECT:
            self = .protect
        case _:
            return nil
        }
    }
}
