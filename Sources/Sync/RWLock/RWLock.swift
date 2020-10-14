import Foundation

public final class RWLock<Wrapped> {
    public typealias Access = Sync.ScopedAccess<Wrapped>

    private var rwlock: pthread_rwlock_t
    private var wrapped: Wrapped

    fileprivate let access: Access

    public let processShared: RWLockProcessShared

    public init(
        _ wrapped: Wrapped,
        processShared: RWLockProcessShared = .default
    ) throws {
        self.rwlock = .init()
        self.wrapped = wrapped

        self.access = .init(&self.wrapped)

        self.processShared = processShared

        try self.initialize()
    }

    deinit {
        try! self.destroy()
    }

    @discardableResult
    public func read<T>(
        _ closure: (Wrapped) throws -> T
    ) throws -> T {
        try self.readLock()

        let result = try self.readAssumingLocked(closure)

        try self.unlock()

        return try result.get()
    }

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

    @discardableResult
    public func write<T>(
        _ closure: (Access) throws -> T
    ) throws -> T {
        try self.writeLock()

        let result = try self.writeAssumingLocked(closure)

        try self.unlock()

        return try result.get()
    }

    @discardableResult
    public func tryWrite<T>(
        _ closure: (Access) throws -> T
    ) throws -> Result<T, RWLockWouldBlockError> {
        if case .failure(let error) = try self.tryWriteLock() {
            return .failure(error)
        }

        let result = try self.writeAssumingLocked(closure)

        try self.unlock()

        return .success(try result.get())
    }

    private func initialize() throws {
        var attr = pthread_rwlockattr_t()

        var status: Int32

        status = pthread_rwlockattr_init(&attr)

        if let error = RWLockAttributeInitError(rawValue: status) {
            throw error
        }

        defer {
            pthread_rwlockattr_destroy(&attr)
        }

        pthread_rwlockattr_setpshared(&attr, self.processShared.rawValue)

        status = pthread_rwlock_init(&self.rwlock, &attr)

        if let error = RWLockInitError(rawValue: status) {
            throw error
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
        Result { try closure(self.wrapped) }
    }

    private func writeAssumingLocked<T>(
        _ closure: (Access) throws -> T
    ) rethrows -> Result<T, Swift.Error> {
        Result { try closure(self.access) }
    }
}
