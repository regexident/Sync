// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

public enum MutexUnlockError: RawRepresentable, Swift.Error {
    /// `EPERM`
    case permissions
    /// `EINVAL`
    case invalid
    case unknown(Int32)

    public var rawValue: Int32 {
        switch self {
        case .permissions:
            return EPERM
        case .invalid:
            return EINVAL
        case .unknown(let errorCode):
            return errorCode
        }
    }

    public var localizedDescription: String {
        switch self {
        case .permissions:
            return "The current thread does not hold a lock on mutex."
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
        case EPERM:
            self = .permissions
        case EINVAL:
            self = .invalid
        case _:
            self = .unknown(rawValue)
        }
    }
}
