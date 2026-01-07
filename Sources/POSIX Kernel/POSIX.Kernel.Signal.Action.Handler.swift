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
    public import Darwin
#elseif canImport(Glibc)
    public import Glibc
#elseif canImport(Musl)
    public import Musl
#endif

extension POSIX.Kernel.Signal {
    /// Signal action operations namespace.
    public enum Action {}
}

extension POSIX.Kernel.Signal.Action {
    /// Handler disposition for a signal.
    ///
    /// Specifies what happens when a signal is delivered: use the default action,
    /// ignore the signal, or call a custom handler function.
    ///
    /// ## Async-Signal-Safety
    ///
    /// Custom handlers (`custom` and `customInfo`) must only call async-signal-safe
    /// functions. Safe operations include:
    /// - `write()` to a file descriptor
    /// - Setting a `sig_atomic_t` / volatile flag
    ///
    /// Unsafe operations include:
    /// - Memory allocation (`malloc`, Swift allocations)
    /// - Locks (mutex, semaphore)
    /// - Swift runtime calls (including `print`)
    /// - Most libc functions
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Ignore SIGPIPE
    /// let config = POSIX.Kernel.Signal.Action.Configuration(handler: .ignore)
    /// try POSIX.Kernel.Signal.Action.set(signal: .pipe, config)
    ///
    /// // Custom handler
    /// let handler: @convention(c) (Int32) -> Void = { sig in
    ///     // Only async-signal-safe operations here
    /// }
    /// let config = POSIX.Kernel.Signal.Action.Configuration(handler: .custom(handler))
    /// ```
    public enum Handler: Sendable {
        /// Use the default action for this signal.
        ///
        /// - POSIX: `SIG_DFL`
        case `default`

        /// Ignore the signal.
        ///
        /// - POSIX: `SIG_IGN`
        /// - Note: `SIGKILL` and `SIGSTOP` cannot be ignored.
        case ignore

        /// Call a simple handler (receives only signal number).
        ///
        /// - POSIX: Uses `sa_handler` field
        /// - Parameter handler: C function pointer receiving the signal number.
        case custom(@convention(c) (Int32) -> Void)

        /// Call a handler with extended signal information.
        ///
        /// - POSIX: Uses `sa_sigaction` field (requires `SA_SIGINFO` flag)
        /// - Parameters:
        ///   - handler: C function pointer receiving:
        ///     - `Int32`: Signal number
        ///     - `siginfo_t*`: Extended signal information (sender PID, etc.)
        ///     - `void*`: User context (platform-specific, typically `ucontext_t`)
        ///
        /// - Note: The `Configuration` initializer automatically adds the `.sigInfo`
        ///   flag when using this handler type.
        case customInfo(@convention(c) (Int32, UnsafeMutablePointer<siginfo_t>?, UnsafeMutableRawPointer?) -> Void)
    }
}

// MARK: - Handler Sendable Conformance

// @convention(c) function pointers are inherently Sendable because they're
// just memory addresses with no captured state. The Sendable conformance
// on the enum is safe.

// MARK: - Internal Helpers

extension POSIX.Kernel.Signal.Action.Handler {
    /// Whether this handler requires the SA_SIGINFO flag.
    internal var requiresSigInfo: Bool {
        if case .customInfo = self { return true }
        return false
    }
}

