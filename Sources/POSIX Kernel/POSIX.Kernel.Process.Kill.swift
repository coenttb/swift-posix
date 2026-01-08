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

extension POSIX.Kernel.Process {
    /// Kill operations namespace.
    public enum Kill {}
}

// MARK: - Signal

extension POSIX.Kernel.Process {
    /// POSIX signals for process control.
    ///
    /// This is a focused subset of signals used for process management.
    /// Additional signals can be added as needed.
    public struct Signal: RawRepresentable, Sendable, Equatable, Hashable {
        public let rawValue: Int32

        public init(rawValue: Int32) {
            self.rawValue = rawValue
        }
    }
}

extension POSIX.Kernel.Process.Signal {
    /// Stop process (cannot be caught or ignored).
    public static var stop: Self { Self(rawValue: SIGSTOP) }

    /// Continue if stopped.
    public static var cont: Self { Self(rawValue: SIGCONT) }

    /// Kill process (cannot be caught or ignored).
    public static var kill: Self { Self(rawValue: SIGKILL) }

    /// Termination signal.
    public static var term: Self { Self(rawValue: SIGTERM) }

    /// Interrupt from keyboard (Ctrl+C).
    public static var int: Self { Self(rawValue: SIGINT) }

    /// Hangup detected on controlling terminal.
    public static var hup: Self { Self(rawValue: SIGHUP) }
}

// MARK: - Kill Operation

extension POSIX.Kernel.Process.Kill {
    /// Sends a signal to a process.
    ///
    /// - Parameters:
    ///   - process: The target process ID.
    ///   - signal: The signal to send.
    /// - Throws: `POSIX.Kernel.Process.Error.kill` on failure.
    ///
    /// ## Common Errors
    ///
    /// - `.noPermission` (EPERM): Caller lacks permission to send signal.
    /// - `.noSuchProcess` (ESRCH): No process with the specified ID exists.
    /// - `.invalidArgument` (EINVAL): Invalid signal number.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Send SIGTERM to gracefully terminate a process
    /// try POSIX.Kernel.Process.Kill.kill(childPID, .term)
    ///
    /// // Stop a process (for debugging or synchronization)
    /// try POSIX.Kernel.Process.Kill.kill(childPID, .stop)
    ///
    /// // Continue a stopped process
    /// try POSIX.Kernel.Process.Kill.kill(childPID, .cont)
    /// ```
    public static func kill(
        _ process: Kernel.Process.ID,
        _ signal: POSIX.Kernel.Process.Signal
    ) throws(POSIX.Kernel.Process.Error) {
        #if canImport(Darwin)
            let rc = Darwin.kill(process.rawValue, signal.rawValue)
        #elseif canImport(Glibc)
            let rc = Glibc.kill(process.rawValue, signal.rawValue)
        #elseif canImport(Musl)
            let rc = Musl.kill(process.rawValue, signal.rawValue)
        #endif

        if rc == -1 {
            throw .kill(POSIX.Kernel.Error.captureErrno())
        }
    }
}
