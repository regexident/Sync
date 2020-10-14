import Foundation

/// A mutual exclusion primitive useful for protecting shared data.
///
/// This mutex will block threads waiting for the lock to become available.
/// The mutex can also be statically initialized or created via a new
/// constructor. Each mutex has a type parameter which represents the data
/// that it is protecting. The data can only be accessed through the `access`
/// handle passed to the callback of `lock` and `tryLock`, which guarantees
/// that the data is only ever accessed when the mutex is locked.
public final class Mutex<Wrapped> {
    private enum State {
        case normal
        case consumed
    }

    private var mutex: pthread_mutex_t
    private var wrapped: Wrapped
    private var state: State

    private var access: ScopedAccess<Wrapped>

    public let type: MutexType
    public let priorityProtocol: MutexPriorityProtocol
    public let processShared: MutexProcessShared
    public let policy: MutexPolicy

    /// The priority ceiling of the mutex.
    public var priorityCeiling: MutexPriorityCeiling {
        get {
            var rawValue: Int32 = 0
            let status = pthread_mutex_getprioceiling(
                &self.mutex,
                &rawValue
            )
            assert(status == 0)
            return .init(rawValue)
        }
        set {
            let rawValue: Int32 = newValue.rawValue
            var oldRawValue: Int32 = 0
            let status = pthread_mutex_setprioceiling(
                &self.mutex,
                rawValue,
                &oldRawValue
            )
            assert(status == 0)
        }
    }

    /// Creates a mutex corresponding to the provided attributes.
    public init(
        _ wrapped: Wrapped,
        type: MutexType = .default,
        priorityCeiling: MutexPriorityCeiling = .default,
        priorityProtocol: MutexPriorityProtocol = .default,
        processShared: MutexProcessShared = .default,
        policy: MutexPolicy = .default
    ) throws {
        self.mutex = .init()
        self.wrapped = wrapped
        self.state = .normal

        self.access = .init(&self.wrapped)

        self.type = type
        self.priorityProtocol = priorityProtocol
        self.processShared = processShared
        self.policy = policy

        try self.initialize(
            priorityCeiling: priorityCeiling
        )
    }

    deinit {
        try! self.destroy()
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
        try self.lock()

        let result = try self.readAssumingLocked(closure)

        try self.unlock()

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
    ///   `MutexLockError`, `MutexInvalidatedError`, `MutexUnlockError`,
    ///   or the error thrown by `closure`
    /// - Returns:
    ///   The value returned by `closure`.
    @discardableResult
    public func write<T>(
        _ closure: (ScopedAccess<Wrapped>) throws -> T
    ) throws -> T {
        try self.lock()

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

        try self.unlock()

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

    private func initialize(
        priorityCeiling: MutexPriorityCeiling
    ) throws {
        var attr = pthread_mutexattr_t()

        var status: Int32

        status = pthread_mutexattr_init(&attr)

        if let error = MutexAttributeInitError(rawValue: status) {
            throw error
        }

        pthread_mutexattr_settype(&attr, self.type.rawValue)
        pthread_mutexattr_setprioceiling(&attr, priorityCeiling.rawValue)
        pthread_mutexattr_setprotocol(&attr, self.priorityProtocol.rawValue)
        pthread_mutexattr_setpshared(&attr, self.processShared.rawValue)
        pthread_mutexattr_setpolicy_np(&attr, self.policy.rawValue)

        status = pthread_mutex_init(&self.mutex, &attr)

        let mutexInitError = MutexInitError(rawValue: status)

        status = pthread_mutexattr_destroy(&attr)

        let mutexAttributeDestroyError = MutexAttributeDestroyError(rawValue: status)

        if let error = mutexInitError {
            throw error
        }

        if let error = mutexAttributeDestroyError {
            throw error
        }
    }

    private func destroy() throws {
        let status = pthread_mutex_destroy(&self.mutex)

        if let error = MutexDestroyError(rawValue: status) {
            throw error
        }
    }

    private func tryLock() throws -> Result<(), MutexWouldBlockError> {
        let status = pthread_mutex_trylock(&self.mutex)

        if let error = MutexTryLockError(rawValue: status) {
            switch error {
            case .busy: return .failure(.init())
            case _: throw error
            }
        }

        return .success(())
    }

    private func lock() throws {
        let status = pthread_mutex_lock(&self.mutex)

        if let error = MutexLockError(rawValue: status) {
            throw error
        }
    }

    private func unlock() throws {
        let status = pthread_mutex_unlock(&self.mutex)
        if let error = MutexUnlockError(rawValue: status) {
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
            return .failure(MutexInvalidatedError())
        }
    }

    private func writeAssumingLocked<T>(
        _ closure: (ScopedAccess<Wrapped>) throws -> T
    ) rethrows -> Result<T, Swift.Error> {
        switch self.state {
        case .normal:
            return Result { try closure(self.access) }
        case .consumed:
            return .failure(MutexInvalidatedError())
        }
    }
}
