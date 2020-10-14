import Foundation

public final class Mutex<Wrapped> {
    public typealias Access = ScopedAccess<Wrapped>

    private var mutex: pthread_mutex_t
    private var wrapped: Wrapped

    private var access: Access

    public let type: MutexType
    public let priorityProtocol: MutexPriorityProtocol
    public let processShared: MutexProcessShared
    public let policy: MutexPolicy

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

    @discardableResult
    public func read<T>(
        _ closure: (Wrapped) throws -> T
    ) throws -> T {
        try self.lock()

        let result = try self.readAssumingLocked(closure)

        try self.unlock()

        return try result.get()
    }

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

    @discardableResult
    public func write<T>(
        _ closure: (Access) throws -> T
    ) throws -> T {
        try self.lock()

        let result = try self.writeAssumingLocked(closure)

        try self.unlock()

        return try result.get()
    }

    @discardableResult
    public func tryWrite<T>(
        _ closure: (Access) throws -> T
    ) throws -> Result<T, MutexWouldBlockError> {
        if case .failure(let error) = try self.tryLock() {
            return .failure(error)
        }

        let result = try self.writeAssumingLocked(closure)

        try self.unlock()

        return .success(try result.get())
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

        defer {
            pthread_mutexattr_destroy(&attr)
        }

        pthread_mutexattr_settype(&attr, self.type.rawValue)
        pthread_mutexattr_setprioceiling(&attr, priorityCeiling.rawValue)
        pthread_mutexattr_setprotocol(&attr, self.priorityProtocol.rawValue)
        pthread_mutexattr_setpshared(&attr, self.processShared.rawValue)
        pthread_mutexattr_setpolicy_np(&attr, self.policy.rawValue)

        status = pthread_mutex_init(&self.mutex, &attr)

        if let error = MutexInitError(rawValue: status) {
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
        Result { try closure(self.wrapped) }
    }

    private func writeAssumingLocked<T>(
        _ closure: (Access) throws -> T
    ) rethrows -> Result<T, Swift.Error> {
        Result { try closure(self.access) }
    }
}
