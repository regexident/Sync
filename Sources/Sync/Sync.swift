// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

public protocol Sync {
    associatedtype Wrapped
    associatedtype WouldBlockError: Swift.Error

    /// Performs a blocking read.
    ///
    /// - Important:
    ///
    ///   The wrapped value MUST NOT escape the closure.
    ///
    /// - Parameter closure:
    ///   A closure with an argument that points to the mutex' wrapped value.
    ///   The argument is valid only for the duration of the closure’s execution.
    /// - Throws:
    ///   The errors thrown are specific to the given implementation
    ///   or the error thrown by `closure`
    /// - Returns:
    ///   The value returned by `closure`.
    @discardableResult
    func read<T>(
        _ closure: (Wrapped) throws -> T
    ) throws -> T

    /// Performs a non-blocking read.
    ///
    /// - Important:
    ///
    ///   The wrapped value MUST NOT escape the closure.
    ///
    /// - Parameter closure:
    ///   A closure with an argument that points to the mutex' wrapped value.
    ///   The argument is valid only for the duration of the closure’s execution.
    /// - Throws:
    ///   The errors thrown are specific to the given implementation
    ///   or the error thrown by `closure`
    /// - Returns:
    ///   The value returned by `closure`, or `WouldBlockError`.
    @discardableResult
    func tryRead<T>(
        _ closure: (Wrapped) throws -> T
    ) throws -> Result<T, WouldBlockError>

    /// Performs a blocking write.
    ///
    /// - Important:
    ///
    ///   The wrapped value MUST NOT escape the closure.
    ///
    /// - Parameter closure:
    ///   A closure with an argument that provides access to the mutex' wrapped value.
    ///   The argument is valid only for the duration of the closure’s execution.
    /// - Throws:
    ///   The errors thrown are specific to the given implementation
    ///   or the error thrown by `closure`
    /// - Returns:
    ///   The value returned by `closure`.
    @discardableResult
    func write<T>(
        _ closure: (ScopedAccess<Wrapped>) throws -> T
    ) throws -> T

    /// Performs a non-blocking write.
    ///
    /// - Important:
    ///
    ///   The wrapped value MUST NOT escape the closure.
    ///
    /// - Parameter closure:
    ///   A closure with an argument that provides access to the mutex' wrapped value.
    ///   The argument is valid only for the duration of the closure’s execution.
    /// - Throws:
    ///   The errors thrown are specific to the given implementation
    ///   or the error thrown by `closure`
    /// - Returns:
    ///   The value returned by `closure`, or `WouldBlockError`.
    @discardableResult
    func tryWrite<T>(
        _ closure: (ScopedAccess<Wrapped>) throws -> T
    ) throws -> Result<T, WouldBlockError>

    /// Performs a blocking read and returns the wrapped value,
    /// while invalidating (i.e. consuming) the mutex for further use.
    ///
    /// - Important:
    ///
    ///   If the call succeeds the mutex MUST NOT be used any further.
    ///
    /// - Throws:
    ///   The errors thrown are specific to the given implementation
    /// - Returns:
    ///   The wrapped value.
    func unwrap() throws -> Wrapped

    /// Performs a non-blocking read and returns the wrapped value,
    /// while invalidating (i.e. consuming) the mutex for further use.
    ///
    /// - Important:
    ///
    ///   If the call succeeds the mutex MUST NOT be used any further.
    ///
    /// - Throws:
    ///   The errors thrown are specific to the given implementation
    /// - Returns:
    ///   The wrapped value, or `WouldBlockError`.
    func tryUnwrap() throws -> Result<Wrapped, WouldBlockError>
}
