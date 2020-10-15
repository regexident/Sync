// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

/// Priority ceiling of a mutex.
public struct MutexPriorityCeiling: RawRepresentable {
    public typealias RawValue = Int32

    /// The system's default mutex priority ceiling.
    public static let `default`: Self = Self(rawValue: 0)!

    public let rawValue: RawValue

    public init(_ rawValue: RawValue) {
        let clampedRawValue = Swift.max(Swift.min(rawValue, 999), -999)

        self.rawValue = clampedRawValue
    }

    public init?(rawValue: RawValue) {
        self.init(rawValue)
    }
}

extension MutexPriorityCeiling: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = Int32

    public init(integerLiteral value: Int32) {
        self.init(rawValue: value)!
    }
}
