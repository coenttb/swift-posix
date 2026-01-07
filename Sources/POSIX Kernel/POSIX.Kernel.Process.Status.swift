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
    internal import CPOSIXProcessShim
#elseif canImport(Glibc)
    internal import Glibc
    internal import CPOSIXProcessShim
#elseif canImport(Musl)
    internal import Musl
    internal import CPOSIXProcessShim
#endif

extension POSIX.Kernel.Process {
    /// Exit status from wait operations.
    ///
    /// Wraps the raw status integer with typed accessors.
    /// All accessors use POSIX macros (via C shim wrappers), not bit manipulation.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let result = try POSIX.Kernel.Process.Wait.wait(.any)
    /// if result.status.exited {
    ///     print("Exit code: \(result.status.exit.code ?? 0)")
    /// }
    /// ```
    public struct Status: RawRepresentable, Sendable, Equatable, Hashable {
        public let rawValue: Int32

        public init(rawValue: Int32) {
            self.rawValue = rawValue
        }
    }
}

// MARK: - Boolean Status Checks

extension POSIX.Kernel.Process.Status {
    /// Whether process exited normally (WIFEXITED).
    public var exited: Bool {
        swift_WIFEXITED(rawValue) != 0
    }

    /// Whether process was terminated by signal (WIFSIGNALED).
    public var signaled: Bool {
        swift_WIFSIGNALED(rawValue) != 0
    }

    /// Whether process was stopped (WIFSTOPPED).
    public var stopped: Bool {
        swift_WIFSTOPPED(rawValue) != 0
    }

    /// Whether process was continued (WIFCONTINUED).
    public var continued: Bool {
        swift_WIFCONTINUED(rawValue) != 0
    }
}

// MARK: - Nest.Name Accessors

extension POSIX.Kernel.Process.Status {
    /// Nested accessor for exit code info.
    public var exit: Exit { Exit(self) }

    /// Exit code accessor (Nest.Name pattern).
    public struct Exit: Sendable {
        let status: POSIX.Kernel.Process.Status

        init(_ status: POSIX.Kernel.Process.Status) { self.status = status }

        /// The exit code (WEXITSTATUS).
        ///
        /// Returns `nil` if process did not exit normally.
        public var code: Int32? {
            guard status.exited else { return nil }
            return swift_WEXITSTATUS(status.rawValue)
        }
    }

    /// Nested accessor for terminating signal info.
    public var terminating: Terminating { Terminating(self) }

    /// Terminating signal accessor (Nest.Name pattern).
    public struct Terminating: Sendable {
        let status: POSIX.Kernel.Process.Status

        init(_ status: POSIX.Kernel.Process.Status) { self.status = status }

        /// The terminating signal (WTERMSIG).
        ///
        /// Returns `nil` if process was not terminated by signal.
        public var signal: POSIX.Kernel.Signal.Number? {
            guard status.signaled else { return nil }
            return POSIX.Kernel.Signal.Number(rawValue: swift_WTERMSIG(status.rawValue))
        }
    }

    /// Nested accessor for stop signal info.
    public var stop: Stop { Stop(self) }

    /// Stop signal accessor (Nest.Name pattern).
    public struct Stop: Sendable {
        let status: POSIX.Kernel.Process.Status

        init(_ status: POSIX.Kernel.Process.Status) { self.status = status }

        /// The stop signal (WSTOPSIG).
        ///
        /// Returns `nil` if process was not stopped.
        public var signal: POSIX.Kernel.Signal.Number? {
            guard status.stopped else { return nil }
            return POSIX.Kernel.Signal.Number(rawValue: swift_WSTOPSIG(status.rawValue))
        }
    }

    /// Nested accessor for core dump info.
    public var core: Core { Core(self) }

    /// Core dump accessor (Nest.Name pattern).
    public struct Core: Sendable {
        let status: POSIX.Kernel.Process.Status

        init(_ status: POSIX.Kernel.Process.Status) { self.status = status }

        /// Whether core dump was produced (WCOREDUMP).
        ///
        /// Returns `false` on platforms where WCOREDUMP is unavailable.
        public var dumped: Bool {
            #if canImport(Darwin)
                guard status.signaled else { return false }
                return swift_WCOREDUMP(status.rawValue) != 0
            #elseif canImport(Glibc)
                // WCOREDUMP may not be available on all Linux configurations
                guard status.signaled else { return false }
                #if _GNU_SOURCE
                    return swift_WCOREDUMP(status.rawValue) != 0
                #else
                    return false
                #endif
            #else
                return false
            #endif
        }
    }
}

// MARK: - Typed Classification

extension POSIX.Kernel.Process.Status {
    /// Typed classification for pattern matching.
    ///
    /// Derived from raw accessors — no information loss.
    /// Returns `nil` if status doesn't match any known classification.
    public enum Classification: Sendable, Equatable {
        /// Process exited normally with exit code.
        case exited(code: Int32)

        /// Process terminated by signal.
        ///
        /// The unlabeled `Bool` indicates whether a core dump was produced.
        /// Use `status.core.dumped` for the same value.
        case signaled(signal: POSIX.Kernel.Signal.Number, Bool)

        /// Process stopped by signal.
        case stopped(signal: POSIX.Kernel.Signal.Number)

        /// Process continued.
        case continued
    }

    /// Classifies the status for pattern matching.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// switch status.classification {
    /// case .exited(let code):
    ///     print("Exited with code \(code)")
    /// case .signaled(let signal, let core):
    ///     print("Killed by \(signal), core: \(core)")
    /// case .stopped(let signal):
    ///     print("Stopped by \(signal)")
    /// case .continued:
    ///     print("Continued")
    /// case nil:
    ///     print("Unknown status")
    /// }
    /// ```
    public var classification: Classification? {
        if exited, let code = exit.code {
            return .exited(code: code)
        }
        if signaled, let signal = terminating.signal {
            return .signaled(signal: signal, core.dumped)
        }
        if stopped, let signal = stop.signal {
            return .stopped(signal: signal)
        }
        if continued {
            return .continued
        }
        return nil
    }
}
