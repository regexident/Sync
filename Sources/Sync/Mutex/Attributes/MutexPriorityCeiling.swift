import Foundation

public struct MutexPriorityCeiling: RawRepresentable {
    public typealias RawValue = Int32

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
