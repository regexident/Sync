// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

public enum RWLockUnlockError: RawRepresentable, Swift.Error {
    case invalid
    case permissions
    case unknown(Int32)

    public var rawValue: Int32 {
        switch self {
        case .invalid:
            return EINVAL
        case .permissions:
            return EPERM
        case .unknown(let errorCode):
            return errorCode
        }
    }

    public var localizedDescription: String {
        switch self {
        case .invalid:
            return "The value specified by rwlock is invalid."
        case .permissions:
            return "The current thread does not own the read/write lock."
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
        case EPERM:
            self = .permissions
        case _:
            self = .unknown(rawValue)
        }
    }
}
