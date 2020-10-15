// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

/// The type of a mutex.
public enum MutexType: Int32, RawRepresentable {
    public typealias RawValue = Int32

    /// `PTHREAD_MUTEX_NORMAL`
    ///
    /// `.normal` mutexes do not check for usage errors. `.normal`
    /// mutexes will deadlock if reentered, and result in undefined
    /// behavior if a locked mutex is unlocked by another thread.
    /// Attempts to unlock an already unlocked `.normal` mutex
    /// will result in undefined behavior.
    case normal = 0

    /// `PTHREAD_MUTEX_ERRORCHECK`
    ///
    /// `.errorCheck` mutexes do check for usage errors.
    /// If an attempt is made to relock a `.errorCheck` mutex
    /// without first dropping the lock, an error will be returned.
    /// If a thread attempts to unlock a `.errorCheck` mutex that
    /// is locked by another thread, an error will be returned.
    /// If a thread attempts to unlock a `.errorCheck` thread
    /// that is unlocked, an error will be returned.
    case errorCheck = 1

    /// `PTHREAD_MUTEX_RECURSIVE`
    ///
    /// `.recursive` mutexes allow recursive locking.
    /// An attempt to relock a `.recursive` mutex that is
    /// already locked by the same thread succeeds.
    /// An equivalent number of `unlock()` calls are needed
    /// before the mutex will wake another thread waiting on
    /// this lock. If a thread attempts to unlock a `.recursive`
    /// mutex that is locked by another thread, an error will
    /// be returned. If a thread attemps to unlock a `.recursive`
    /// thread that is unlocked, an error will be returned.
    case recursive = 2

    /// The system's default mutex type.
    public static let `default`: Self = .normal

    public var rawValue: RawValue {
        switch self {
        case .normal:
            return PTHREAD_MUTEX_NORMAL
        case .errorCheck:
            return PTHREAD_MUTEX_ERRORCHECK
        case .recursive:
            return PTHREAD_MUTEX_RECURSIVE
        }
    }

    public init?(rawValue: RawValue) {
        switch rawValue {
        case PTHREAD_MUTEX_NORMAL:
            self = .normal
        case PTHREAD_MUTEX_ERRORCHECK:
            self = .errorCheck
        case PTHREAD_MUTEX_RECURSIVE:
            self = .recursive
        case _:
            return nil
        }
    }
}
