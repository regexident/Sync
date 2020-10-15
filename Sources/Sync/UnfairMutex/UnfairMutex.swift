// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

/// An unfair mutual exclusion primitive useful for protecting shared data.
///
/// This mutex will block threads waiting for the lock to become available.
/// The mutex can also be statically initialized or created via a new
/// constructor. Each mutex has a type parameter which represents the data
/// that it is protecting. The data can only be accessed through the `access`
/// handle passed to the callback of `lock` and `tryLock`, which guarantees
/// that the data is only ever accessed when the mutex is locked.
///
/// Note: The implementation is based on `os_unfair_lock_s` (4 bytes).
@available(macOS 10.12, iOS 10.0, tvOS 10.0, watchOS 3.0, *)
public final class UnfairMutex<Wrapped>: Sync {
    public typealias WouldBlockError = MutexWouldBlockError

    private enum State {
        case normal
        case consumed
    }

    private var unfairLock: os_unfair_lock_s
    private var wrapped: Wrapped
    private var state: State

    private var access: ScopedAccess<Wrapped>

    /// Creates an unfair mutex corresponding to the provided attributes.
    public init(
        _ wrapped: Wrapped
    ) throws {
        self.unfairLock = .init()
        self.wrapped = wrapped
        self.state = .normal

        self.access = .init(&self.wrapped)
    }

    /// Performs a blocking exclusive read.
    ///
    /// - Important:
    ///
    ///   The wrapped value MUST NOT escape the closure.
    ///
    /// - Parameter closure:
    ///   A closure with an argument that points to the mutex' wrapped value.
    ///   The argument is valid only for the duration of the closure’s execution.
    /// - Throws:
    ///   `MutexLockError`, `MutexInvalidatedError`, `MutexUnlockError`,
    ///   or the error thrown by `closure`
    /// - Returns:
    ///   The value returned by `closure`.
    @discardableResult
    public func read<T>(
        _ closure: (Wrapped) throws -> T
    ) throws -> T {
        self.lock()

        let result = try self.readAssumingLocked(closure)

        self.unlock()

        return try result.get()
    }

    /// Performs a non-blocking exclusive read.
    ///
    /// - Important:
    ///
    ///   The wrapped value MUST NOT escape the closure.
    ///
    /// - Parameter closure:
    ///   A closure with an argument that points to the mutex' wrapped value.
    ///   The argument is valid only for the duration of the closure’s execution.
    /// - Throws:
    ///   `MutexLockError`, `MutexInvalidatedError`, `MutexUnlockError`,
    ///   or the error thrown by `closure`
    /// - Returns:
    ///   The value returned by `closure`, or `MutexWouldBlockError`.
    @discardableResult
    public func tryRead<T>(
        _ closure: (Wrapped) throws -> T
    ) throws -> Result<T, MutexWouldBlockError> {
        if case .failure(let error) = try self.tryLock() {
            return .failure(error)
        }

        let result = try self.readAssumingLocked(closure)

        self.unlock()

        return .success(try result.get())
    }

    /// Performs a blocking exclusive write.
    ///
    /// - Important:
    ///
    ///   The wrapped value MUST NOT escape the closure.
    ///
    /// - Parameter closure:
    ///   A closure with an argument that provides access to the mutex' wrapped value.
    ///   The argument is valid only for the duration of the closure’s execution.
    /// - Throws:
    ///   `MutexLockError`, `MutexInvalidatedError`, `MutexUnlockError`,
    ///   or the error thrown by `closure`
    /// - Returns:
    ///   The value returned by `closure`.
    @discardableResult
    public func write<T>(
        _ closure: (ScopedAccess<Wrapped>) throws -> T
    ) throws -> T {
        self.lock()

        let result = try self.writeAssumingLocked(closure)

        self.unlock()

        return try result.get()
    }

    /// Performs a non-blocking exclusive write.
    ///
    /// - Important:
    ///
    ///   The wrapped value MUST NOT escape the closure.
    ///
    /// - Parameter closure:
    ///   A closure with an argument that provides access to the mutex' wrapped value.
    ///   The argument is valid only for the duration of the closure’s execution.
    /// - Throws:
    ///   `MutexLockError`, `MutexInvalidatedError`, `MutexUnlockError`,
    ///   or the error thrown by `closure`
    /// - Returns:
    ///   The value returned by `closure`, or `MutexWouldBlockError`.
    @discardableResult
    public func tryWrite<T>(
        _ closure: (ScopedAccess<Wrapped>) throws -> T
    ) throws -> Result<T, MutexWouldBlockError> {
        if case .failure(let error) = try self.tryLock() {
            return .failure(error)
        }

        let result = try self.writeAssumingLocked(closure)

        self.unlock()

        return .success(try result.get())
    }

    /// Performs a blocking exclusive read and returns the wrapped value,
    /// while invalidating (i.e. consuming) the mutex for further use.
    ///
    /// - Important:
    ///
    ///   If the call succeeds the mutex MUST NOT be used any further.
    ///
    /// - Throws:
    ///   `MutexLockError`, `MutexInvalidatedError`, or `MutexUnlockError`
    /// - Returns:
    ///   The wrapped value.
    public func unwrap() throws -> Wrapped {
        try self.read { wrapped in
            self.state = .consumed

            return wrapped
        }
    }

    /// Performs a blocking exclusive read and returns the wrapped value,
    /// while invalidating (i.e. consuming) the mutex for further use.
    ///
    /// - Important:
    ///
    ///   If the call succeeds the mutex MUST NOT be used any further.
    ///
    /// - Throws:
    ///   `MutexLockError`, `MutexInvalidatedError`, or `MutexUnlockError`
    /// - Returns:
    ///   The wrapped value, or `MutexWouldBlockError`.
    public func tryUnwrap() throws -> Result<Wrapped, MutexWouldBlockError> {
        try self.tryRead { wrapped in
            self.state = .consumed

            return wrapped
        }
    }

    private func tryLock() throws -> Result<(), MutexWouldBlockError> {
        guard os_unfair_lock_trylock(&self.unfairLock) else {
            return .failure(MutexWouldBlockError())
        }

        return .success(())
    }

    private func lock() {
        os_unfair_lock_lock(&self.unfairLock)
    }

    private func unlock() {
        os_unfair_lock_unlock(&self.unfairLock)
    }

    private func readAssumingLocked<T>(
        _ closure: (Wrapped) throws -> T
    ) rethrows -> Result<T, Swift.Error> {
        os_unfair_lock_assert_owner(&self.unfairLock)

        switch self.state {
        case .normal:
            return Result { try closure(self.wrapped) }
        case .consumed:
            return .failure(MutexInvalidatedError())
        }
    }

    private func writeAssumingLocked<T>(
        _ closure: (ScopedAccess<Wrapped>) throws -> T
    ) rethrows -> Result<T, Swift.Error> {
        os_unfair_lock_assert_owner(&self.unfairLock)

        switch self.state {
        case .normal:
            return Result { try closure(self.access) }
        case .consumed:
            return .failure(MutexInvalidatedError())
        }
    }
}
