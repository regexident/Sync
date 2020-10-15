// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

/// Scoped read/write access of a wrapped value.
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
