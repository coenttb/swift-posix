// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-posix open source project
//
// Copyright (c) 2024-2025 Coen ten Thije Boonkkamp and the swift-posix project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

public import Kernel_Primitives
public import POSIX_Primitives

#if canImport(Darwin)
    internal import Darwin
#elseif canImport(Glibc)
    internal import Glibc
#elseif canImport(Musl)
    internal import Musl
#endif

extension POSIX.Kernel.Signal {
    /// A set of signals.
    ///
    /// Wraps `sigset_t` with type-safe Swift operations.
    ///
    /// ## Sendable Rationale
    ///
    /// `sigset_t` is a fixed-size value type (no pointers) on all POSIX platforms:
    /// - Darwin: `UInt32`
    /// - Linux: `__sigset_t` (array of unsigned long)
    ///
    /// The storage is trivially copyable, making `Sendable` conformance safe.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Create a set with specific signals
    /// var signals = POSIX.Kernel.Signal.Set()
    /// try signals.insert(.user1)
    /// try signals.insert(.user2)
    ///
    /// // Block these signals
    /// let previous = try POSIX.Kernel.Signal.Mask.change(.block, signals: signals)
    /// defer { _ = try? POSIX.Kernel.Signal.Mask.change(.set, signals: previous) }
    /// ```
    public struct Set: Sendable {
        internal var storage: sigset_t

        /// Creates an empty signal set.
        ///
        /// Equivalent to `sigemptyset()`.

        public init() {
            self.storage = sigset_t()
            sigemptyset(&self.storage)
        }

        /// Creates a set containing all signals.
        ///
        /// Equivalent to `sigfillset()`.
        public static var all: Self {
            var set = Self()
            sigfillset(&set.storage)
            return set
        }

        /// Creates a set containing a single signal.
        ///
        /// - Parameter signal: The signal to include.
        /// - Throws: `Error.set` if the signal number is invalid.

        public init(_ signal: Number) throws(Error) {
            self.init()
            guard sigaddset(&self.storage, signal.rawValue) == 0 else {
                throw .set(POSIX.Kernel.Error.captureErrno())
            }
        }

        /// Creates a set containing multiple signals.
        ///
        /// - Parameter signals: The signals to include.
        /// - Throws: `Error.set` on first invalid signal (deterministic failure point).

        public init(_ signals: some Sequence<Number>) throws(Error) {
            self.init()
            for signal in signals {
                guard sigaddset(&self.storage, signal.rawValue) == 0 else {
                    throw .set(POSIX.Kernel.Error.captureErrno())
                }
            }
        }

        /// Creates a set containing a single signal without validation.
        ///
        /// **Warning**: Bypasses signal number validation. Only use for:
        /// - Static constants (`.user1`, `.terminate`)
        /// - Pre-validated signal numbers
        /// - Internal construction after validation
        ///
        /// For user-provided signal numbers, use the throwing `init(_:)`.

        public init(__unchecked: Void, _ signal: Number) {
            self.init()
            _ = sigaddset(&self.storage, signal.rawValue)
        }

        /// Adds a signal to the set.
        ///
        /// - Parameter signal: The signal to add.
        /// - Throws: `Error.set` if the signal number is invalid.

        public mutating func insert(_ signal: Number) throws(Error) {
            guard sigaddset(&self.storage, signal.rawValue) == 0 else {
                throw .set(POSIX.Kernel.Error.captureErrno())
            }
        }

        /// Removes a signal from the set.
        ///
        /// - Parameter signal: The signal to remove.
        /// - Throws: `Error.set` if the signal number is invalid.

        public mutating func remove(_ signal: Number) throws(Error) {
            guard sigdelset(&self.storage, signal.rawValue) == 0 else {
                throw .set(POSIX.Kernel.Error.captureErrno())
            }
        }

        /// Returns whether the set contains the signal.
        ///
        /// - Parameter signal: The signal to check.
        /// - Returns: `true` if the signal is in the set.
        /// - Throws: `Error.set` if the signal number is invalid.
        ///
        /// **Design note:** Throwing on error rather than returning `false` prevents
        /// silent failures when checking invalid signal numbers.

        public func contains(_ signal: Number) throws(Error) -> Bool {
            var mutableStorage = storage
            let result = sigismember(&mutableStorage, signal.rawValue)
            guard result >= 0 else {
                throw .set(POSIX.Kernel.Error.captureErrno())
            }
            return result == 1
        }
    }
}

// MARK: - Internal Access

extension POSIX.Kernel.Signal.Set {
    /// Provides read access to the underlying `sigset_t` for syscall interop.
    internal func withUnsafePointer<R>(_ body: (UnsafePointer<sigset_t>) throws -> R) rethrows -> R {
        try Swift.withUnsafePointer(to: storage, body)
    }

    /// Provides mutable access to the underlying `sigset_t` for syscall interop.
    internal mutating func withUnsafeMutablePointer<R>(_ body: (UnsafeMutablePointer<sigset_t>) throws -> R) rethrows -> R {
        try Swift.withUnsafeMutablePointer(to: &storage, body)
    }

    /// Creates a set from a raw `sigset_t`.
    ///
    /// Used internally when receiving a set from syscalls.
    internal init(storage: sigset_t) {
        self.storage = storage
    }
}
