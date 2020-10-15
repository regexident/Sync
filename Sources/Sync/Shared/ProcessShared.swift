// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

/// Process sharing mode.
public enum ProcessShared: Int32, RawRepresentable {
    public typealias RawValue = Int32

    case shared = 1
    case `private` = 2

    /// The system's default process sharing mode.
    public static let `default`: Self = .private

    public var rawValue: RawValue {
        switch self {
        case .shared:
            return PTHREAD_PROCESS_SHARED
        case .private:
            return PTHREAD_PROCESS_PRIVATE
        }
    }

    public init?(rawValue: RawValue) {
        switch rawValue {
        case PTHREAD_PROCESS_SHARED:
            self = .shared
        case PTHREAD_PROCESS_PRIVATE:
            self = .private
        case _:
            return nil
        }
    }
}
