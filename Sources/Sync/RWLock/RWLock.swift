import Foundation

public final class RWLock<Wrapped> {
    public final class ReadAccess {
        private var pointer: UnsafePointer<Wrapped>

        fileprivate init(_ pointer: UnsafePointer<Wrapped>) {
            self.pointer = pointer
        }

        public func callAsFunction<T>(
            _ closure: (Wrapped) throws -> T
        ) rethrows -> T {
            try closure(self.pointer.pointee)
        }
    }

    public final class WriteAccess {
        private var pointer: UnsafeMutablePointer<Wrapped>

        fileprivate init(_ pointer: UnsafeMutablePointer<Wrapped>) {
            self.pointer = pointer
        }

        public func callAsFunction<T>(
            _ closure: (inout Wrapped) throws -> T
        ) rethrows -> T {
            try closure(&self.pointer.pointee)
        }
    }

    fileprivate final class Access {
        fileprivate var wrapped: Wrapped

        fileprivate let read: ReadAccess
        fileprivate let write: WriteAccess

        fileprivate init(_ wrapped: Wrapped) {
            self.wrapped = wrapped

            self.read = .init(&self.wrapped)
            self.write = .init(&self.wrapped)
        }
    }

    private var rwlock: pthread_rwlock_t
    private var access: Access

    public let processShared: RWLockProcessShared

    public init(
        _ wrapped: Wrapped,
        processShared: RWLockProcessShared = .default
    ) throws {
        self.rwlock = .init()
        self.access = .init(wrapped)
        self.processShared = processShared

        try self.initialize()
    }

    deinit {
        try! self.destroy()
    }

    @discardableResult
    public func read<T>(
        _ closure: (ReadAccess) throws -> T
    ) throws -> T {
        try self.readLock()

        let result = Result {
            try closure(self.access.read)
        }

        try self.unlock()

        return try result.get()
    }

    @discardableResult
    public func tryRead<T>(
        _ closure: (ReadAccess) throws -> T
    ) throws -> Result<T, RWLockWouldBlockError> {
        if case .failure(let error) = try self.tryReadLock() {
            return .failure(error)
        }

        let result = Result {
            try closure(self.access.read)
        }

        try self.unlock()

        return .success(try result.get())
    }

    @discardableResult
    public func write<T>(
        _ closure: (WriteAccess) throws -> T
    ) throws -> T {
        try self.writeLock()

        let result = Result {
            try closure(self.access.write)
        }

        try self.unlock()

        return try result.get()
    }

    @discardableResult
    public func tryWrite<T>(
        _ closure: (WriteAccess) throws -> T
    ) throws -> Result<T, RWLockWouldBlockError> {
        if case .failure(let error) = try self.tryWriteLock() {
            return .failure(error)
        }

        let result = Result {
            try closure(self.access.write)
        }

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
}
