import Foundation

public final class ScopedAccess<Wrapped> {
    private var pointer: UnsafeMutablePointer<Wrapped>

    internal init(_ pointer: UnsafeMutablePointer<Wrapped>) {
        self.pointer = pointer
    }

    public func read() -> Wrapped {
        self.pointer.pointee
    }

    public func write<T>(
        _ closure: (inout Wrapped) throws -> T
    ) rethrows -> T {
        try closure(&self.pointer.pointee)
    }

    @inlinable
    @inline(__always)
    public func callAsFunction<T>(
        _ closure: (inout Wrapped) throws -> T
    ) rethrows -> T {
        try self.write(closure)
    }
}
