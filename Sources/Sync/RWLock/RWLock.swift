// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

/// A reader-writer lock
///
/// This type of lock allows a number of readers or at most one writer
/// at any point in time. The write portion of this lock typically allows
/// modification of the underlying data (exclusive access) and the read
/// portion of this lock typically allows for read-only access (shared access).
///
/// In comparison, a `RWLock` does not distinguish between readers or writers
/// that acquire the lock, therefore blocking any threads waiting for the
/// lock to become available. An `RWLock` will allow any number of readers
/// to acquire the lock as long as a writer is not holding the lock.
///
/// Note: The implementation is based on `pthread_rwlock_t` (200 bytes).
///
/// **Important**: `RWLock` does not support priority inversion avoidance.
public final class RWLock<Wrapped>: Sync {
    public typealias WouldBlockError = RWLockWouldBlockError
    
    private enum State {
        case normal
        case consumed
    }

    private var rwlock: pthread_rwlock_t
    private var wrapped: Wrapped
    private var state: State

    public let processShared: RWLockProcessShared

    /// Creates a read-write lock corresponding to the provided attributes.
    public init(
        _ wrapped: Wrapped,
        processShared: RWLockProcessShared = .default
    ) throws {
        self.rwlock = .init()
        self.wrapped = wrapped
        self.state = .normal

        self.processShared = processShared

        try self.initialize()
    }

    deinit {
        try! self.destroy()
    }

    /// Performs a blocking non-exclusive read.
    ///
    /// - Important:
    ///
    ///   The wrapped value MUST NOT escape the closure.
    ///
    /// - Parameter closure:
    ///   A closure with an argument that points to the mutex' wrapped value.
    ///   The argument is valid only for the duration of the closure’s execution.
    /// - Throws:
    ///   `RWLockLockError`, `RWLockInvalidatedError`, `RWLockUnlockError`,
    ///   or the error thrown by `closure`
    /// - Returns:
    ///   The value returned by `closure`.
    @discardableResult
    public func read<T>(
        _ closure: (Wrapped) throws -> T
    ) throws -> T {
        try self.readLock()

        let result = try self.readAssumingLocked(closure)

        try self.unlock()

        return try result.get()
    }

    /// Performs a non-blocking non-exclusive read.
    ///
    /// - Important:
    ///
    ///   The wrapped value MUST NOT escape the closure.
    ///
    /// - Parameter closure:
    ///   A closure with an argument that points to the mutex' wrapped value.
    ///   The argument is valid only for the duration of the closure’s execution.
    /// - Throws:
    ///   `RWLockLockError`, `RWLockInvalidatedError`, `RWLockUnlockError`,
    ///   or the error thrown by `closure`
    /// - Returns:
    ///   The value returned by `closure`, or `RWLockWouldBlockError`.
    @discardableResult
    public func tryRead<T>(
        _ closure: (Wrapped) throws -> T
    ) throws -> Result<T, RWLockWouldBlockError> {
        if case .failure(let error) = try self.tryReadLock() {
            return .failure(error)
        }

        let result = try self.readAssumingLocked(closure)

        try self.unlock()

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
    ///   `RWLockLockError`, `RWLockInvalidatedError`, `RWLockUnlockError`,
    ///   or the error thrown by `closure`
    /// - Returns:
    ///   The value returned by `closure`.
    @discardableResult
    public func write<T>(
        _ closure: (ScopedAccess<Wrapped>) throws -> T
    ) throws -> T {
        try self.writeLock()

        let result = try self.writeAssumingLocked(closure)

        try self.unlock()

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
    ///   `RWLockLockError`, `RWLockInvalidatedError`, `RWLockUnlockError`,
    ///   or the error thrown by `closure`
    /// - Returns:
    ///   The value returned by `closure`, or `RWLockWouldBlockError`.
    @discardableResult
    public func tryWrite<T>(
        _ closure: (ScopedAccess<Wrapped>) throws -> T
    ) throws -> Result<T, RWLockWouldBlockError> {
        if case .failure(let error) = try self.tryWriteLock() {
            return .failure(error)
        }

        let result = try self.writeAssumingLocked(closure)

        try self.unlock()

        return .success(try result.get())
    }

    /// Performs a blocking non-exclusive read and returns the wrapped value,
    /// while invalidating (i.e. consuming) the mutex for further use.
    ///
    /// - Important:
    ///
    ///   If the call succeeds the mutex MUST NOT be used any further.
    ///
    /// - Throws:
    ///   `RWLockLockError`, `RWLockInvalidatedError`, or `RWLockUnlockError`
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
    ///   `RWLockLockError`, `RWLockInvalidatedError`, or `RWLockUnlockError`
    /// - Returns:
    ///   The wrapped value, or `RWLockWouldBlockError`.
    public func tryUnwrap() throws -> Result<Wrapped, RWLockWouldBlockError> {
        try self.tryRead { wrapped in
            self.state = .consumed

            return wrapped
        }
    }

    private func initialize() throws {
        var attr = pthread_rwlockattr_t()

        try withUnsafeMutablePointer(to: &attr) { attrPtr in
            var status: Int32

            status = pthread_rwlockattr_init(attrPtr)

            if let error = RWLockAttributeInitError(rawValue: status) {
                throw error
            }

            pthread_rwlockattr_setpshared(attrPtr, self.processShared.rawValue)

            status = pthread_rwlock_init(&self.rwlock, attrPtr)

            let rwlockInitError = RWLockInitError(rawValue: status)

            status = pthread_rwlockattr_destroy(attrPtr)

            let rwlockAttributeDestroyError = RWLockAttributeDestroyError(rawValue: status)

            if let error = rwlockInitError {
                throw error
            }

            if let error = rwlockAttributeDestroyError {
                throw error
            }
        }
    }

    private func destroy() throws {
        let status = pthread_rwlock_destroy(&self.rwlock)

        if let error = RWLockDestroyError(rawValue: status) {
            throw error
        }
    }

    private func tryReadLock() throws -> Result<(), RWLockWouldBlockError> {
        let status = pthread_rwlock_tryrdlock(&self.rwlock)

        if let error = RWLockTryReadLockError(rawValue: status) {
            switch error {
            case .busy: return .failure(.init())
            case _: throw error
            }
        }

        return .success(())
    }

    private func readLock() throws {
        let status = pthread_rwlock_rdlock(&self.rwlock)

        if let error = RWLockReadLockError(rawValue: status) {
            throw error
        }
    }

    private func tryWriteLock() throws -> Result<(), RWLockWouldBlockError> {
        let status = pthread_rwlock_trywrlock(&self.rwlock)

        if let error = RWLockTryWriteLockError(rawValue: status) {
            switch error {
            case .busy: return .failure(.init())
            case _: throw error
            }
        }

        return .success(())
    }

    private func writeLock() throws {
        let status = pthread_rwlock_wrlock(&self.rwlock)

        if let error = RWLockWriteLockError(rawValue: status) {
            throw error
        }
    }

    private func unlock() throws {
        let status = pthread_rwlock_unlock(&self.rwlock)

        if let error = RWLockUnlockError(rawValue: status) {
            throw error
        }
    }

    private func readAssumingLocked<T>(
        _ closure: (Wrapped) throws -> T
    ) rethrows -> Result<T, Swift.Error> {
        switch self.state {
        case .normal:
            return Result { try closure(self.wrapped) }
        case .consumed:
            return .failure(RWLockInvalidatedError())
        }
    }

    private func writeAssumingLocked<T>(
        _ closure: (ScopedAccess<Wrapped>) throws -> T
    ) rethrows -> Result<T, Swift.Error> {
        switch self.state {
        case .normal:
            return Result {
                try withUnsafeMutablePointer(to: &self.wrapped) { pointer in
                    try closure(ScopedAccess(pointer))
                }
            }
        case .consumed:
            return .failure(RWLockInvalidatedError())
        }
    }
}
