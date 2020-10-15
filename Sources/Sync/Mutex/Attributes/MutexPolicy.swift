// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

/// Policy of a mutex.
public enum MutexPolicy: Int32, RawRepresentable {
    public typealias RawValue = Int32

    /// `PTHREAD_MUTEX_POLICY_FAIRSHARE_NP`
    case fairShare = 1
    /// `PTHREAD_MUTEX_POLICY_FIRSTFIT_NP`
    case firstFit = 3

    /// The system's default mutex policy.
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
