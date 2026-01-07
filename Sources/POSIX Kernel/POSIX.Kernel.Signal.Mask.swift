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


#if canImport(Darwin)
    public import Darwin
#elseif canImport(Glibc)
    public import Glibc
#elseif canImport(Musl)
    public import Musl
#endif

extension POSIX.Kernel.Signal.Mask {
    /// Changes the signal mask for the calling thread.
    ///
    /// - Parameters:
    ///   - how: How to modify the mask (block, unblock, or replace).
    ///   - signals: The signals to block, unblock, or set as the new mask.
    /// - Returns: The previous signal mask.
    /// - Throws: `Error.mask` on failure.
    ///
    /// ## Implementation
    ///
    /// Uses `pthread_sigmask` (thread-safe), not `sigprocmask`.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Block SIGINT and SIGTERM
    /// var toBlock = POSIX.Kernel.Signal.Set()
    /// try toBlock.insert(.interrupt)
    /// try toBlock.insert(.terminate)
    ///
    /// let previous = try POSIX.Kernel.Signal.Mask.change(.block, signals: toBlock)
    /// defer { _ = try? POSIX.Kernel.Signal.Mask.change(.set, signals: previous) }
    ///
    /// // Critical section where signals are blocked
    /// ```
    @inlinable
    public static func change(
        _ how: How,
        signals: POSIX.Kernel.Signal.Set
    ) throws(POSIX.Kernel.Signal.Error) -> POSIX.Kernel.Signal.Set {
        var previous = sigset_t()
        sigemptyset(&previous)

        // pthread_sigmask returns error number directly, not via errno
        let error = signals.withUnsafePointer { setPtr in
            pthread_sigmask(how.rawValue, setPtr, &previous)
        }

        guard error == 0 else {
            throw .mask(.posix(error))
        }

        return POSIX.Kernel.Signal.Set(storage: previous)
    }

    /// Returns the set of pending signals (blocked but raised).
    ///
    /// A signal is pending if it has been raised but is currently blocked
    /// by the thread's signal mask.
    ///
    /// - Returns: The set of pending signals.
    /// - Throws: `Error.mask` on failure.
    ///
    /// ## Implementation
    ///
    /// Uses `sigpending`.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Check if any signals are pending
    /// let pending = try POSIX.Kernel.Signal.Mask.pending()
    /// if try pending.contains(.interrupt) {
    ///     // SIGINT was raised while blocked
    /// }
    /// ```
    @inlinable
    public static func pending() throws(POSIX.Kernel.Signal.Error) -> POSIX.Kernel.Signal.Set {
        var set = sigset_t()
        sigemptyset(&set)

        guard sigpending(&set) == 0 else {
            throw .mask(POSIX.Kernel.Error.captureErrno())
        }

        return POSIX.Kernel.Signal.Set(storage: set)
    }
}

