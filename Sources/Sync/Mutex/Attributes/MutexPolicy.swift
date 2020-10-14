import Foundation

public enum MutexPolicy: Int32, RawRepresentable {
    public typealias RawValue = Int32

    case fairShare = 1
    case firstFit = 3

    public static let `default`: Self = .firstFit

    public var rawValue: RawValue {
        switch self {
        case .fairShare:
            return PTHREAD_MUTEX_POLICY_FAIRSHARE_NP
        case .firstFit:
            return PTHREAD_MUTEX_POLICY_FIRSTFIT_NP
        }
    }

    public init?(rawValue: RawValue) {
        switch rawValue {
        case PTHREAD_MUTEX_POLICY_FAIRSHARE_NP:
            self = .fairShare
        case PTHREAD_MUTEX_POLICY_FIRSTFIT_NP:
            self = .firstFit
        case _:
            return nil
        }
    }
}
