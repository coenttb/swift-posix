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
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(Musl)
    import Musl
#endif

extension POSIX.Kernel.Signal {
    /// A signal number.
    ///
    /// Use named constants (`.interrupt`, `.terminate`, etc.) for portable code.
    /// Use `init(rawValue:)` as an escape hatch for platform-specific signals.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Use named constants for portability
    /// try POSIX.Kernel.Signal.Send.toSelf(.user1)
    ///
    /// // Escape hatch for platform-specific signals
    /// let platformSignal = POSIX.Kernel.Signal.Number(rawValue: 42)
    /// ```
    public struct Number: RawRepresentable, Sendable, Equatable, Hashable {
        public let rawValue: Int32

        /// Creates a signal number from a raw value.
        ///
        /// Prefer named constants when available. Use this initializer
        /// as an escape hatch for platform-specific signals.
        @inlinable
        public init(rawValue: Int32) {
            self.rawValue = rawValue
        }
    }
}

// MARK: - Standard POSIX Signals

extension POSIX.Kernel.Signal.Number {
    /// Hangup detected on controlling terminal or death of controlling process.
    ///
    /// - POSIX: `SIGHUP`
    public static let hangup = Self(rawValue: SIGHUP)

    /// Interrupt from keyboard (Ctrl+C).
    ///
    /// - POSIX: `SIGINT`
    public static let interrupt = Self(rawValue: SIGINT)

    /// Quit from keyboard (Ctrl+\).
    ///
    /// - POSIX: `SIGQUIT`
    public static let quit = Self(rawValue: SIGQUIT)

    /// Illegal instruction.
    ///
    /// - POSIX: `SIGILL`
    public static let illegal = Self(rawValue: SIGILL)

    /// Trace/breakpoint trap.
    ///
    /// - POSIX: `SIGTRAP`
    public static let trap = Self(rawValue: SIGTRAP)

    /// Abort signal from abort(3).
    ///
    /// - POSIX: `SIGABRT`
    public static let abort = Self(rawValue: SIGABRT)

    /// Bus error (bad memory access).
    ///
    /// - POSIX: `SIGBUS`
    public static let bus = Self(rawValue: SIGBUS)

    /// Floating-point exception.
    ///
    /// - POSIX: `SIGFPE`
    public static let floatingPoint = Self(rawValue: SIGFPE)

    /// Kill signal (cannot be caught or ignored).
    ///
    /// - POSIX: `SIGKILL`
    /// - Note: This signal cannot be caught, blocked, or ignored.
    public static let kill = Self(rawValue: SIGKILL)

    /// User-defined signal 1.
    ///
    /// - POSIX: `SIGUSR1`
    public static let user1 = Self(rawValue: SIGUSR1)

    /// Segmentation fault (invalid memory reference).
    ///
    /// - POSIX: `SIGSEGV`
    public static let segmentation = Self(rawValue: SIGSEGV)

    /// User-defined signal 2.
    ///
    /// - POSIX: `SIGUSR2`
    public static let user2 = Self(rawValue: SIGUSR2)

    /// Broken pipe: write to pipe with no readers.
    ///
    /// - POSIX: `SIGPIPE`
    public static let pipe = Self(rawValue: SIGPIPE)

    /// Timer signal from alarm(2).
    ///
    /// - POSIX: `SIGALRM`
    public static let alarm = Self(rawValue: SIGALRM)

    /// Termination signal.
    ///
    /// - POSIX: `SIGTERM`
    public static let terminate = Self(rawValue: SIGTERM)

    /// Child stopped or terminated.
    ///
    /// - POSIX: `SIGCHLD`
    public static let child = Self(rawValue: SIGCHLD)

    /// Continue if stopped.
    ///
    /// - POSIX: `SIGCONT`
    public static let `continue` = Self(rawValue: SIGCONT)

    /// Stop process (cannot be caught or ignored).
    ///
    /// - POSIX: `SIGSTOP`
    /// - Note: This signal cannot be caught, blocked, or ignored.
    public static let stop = Self(rawValue: SIGSTOP)

    /// Stop typed at terminal (Ctrl+Z).
    ///
    /// - POSIX: `SIGTSTP`
    public static let terminalStop = Self(rawValue: SIGTSTP)

    /// Terminal input for background process.
    ///
    /// - POSIX: `SIGTTIN`
    public static let terminalInput = Self(rawValue: SIGTTIN)

    /// Terminal output for background process.
    ///
    /// - POSIX: `SIGTTOU`
    public static let terminalOutput = Self(rawValue: SIGTTOU)

    /// Urgent condition on socket.
    ///
    /// - POSIX: `SIGURG`
    public static let urgent = Self(rawValue: SIGURG)

    /// CPU time limit exceeded.
    ///
    /// - POSIX: `SIGXCPU`
    public static let cpuLimit = Self(rawValue: SIGXCPU)

    /// File size limit exceeded.
    ///
    /// - POSIX: `SIGXFSZ`
    public static let fileLimit = Self(rawValue: SIGXFSZ)

    /// Virtual alarm clock.
    ///
    /// - POSIX: `SIGVTALRM`
    public static let virtualAlarm = Self(rawValue: SIGVTALRM)

    /// Profiling timer expired.
    ///
    /// - POSIX: `SIGPROF`
    public static let profiling = Self(rawValue: SIGPROF)

    /// Window resize signal.
    ///
    /// - POSIX: `SIGWINCH`
    public static let windowChange = Self(rawValue: SIGWINCH)

    /// I/O now possible.
    ///
    /// - POSIX: `SIGIO`
    public static let io = Self(rawValue: SIGIO)
}

// MARK: - CustomStringConvertible

extension POSIX.Kernel.Signal.Number: CustomStringConvertible {
    public var description: String {
        switch self {
        case .hangup: return "SIGHUP"
        case .interrupt: return "SIGINT"
        case .quit: return "SIGQUIT"
        case .illegal: return "SIGILL"
        case .trap: return "SIGTRAP"
        case .abort: return "SIGABRT"
        case .bus: return "SIGBUS"
        case .floatingPoint: return "SIGFPE"
        case .kill: return "SIGKILL"
        case .user1: return "SIGUSR1"
        case .segmentation: return "SIGSEGV"
        case .user2: return "SIGUSR2"
        case .pipe: return "SIGPIPE"
        case .alarm: return "SIGALRM"
        case .terminate: return "SIGTERM"
        case .child: return "SIGCHLD"
        case .continue: return "SIGCONT"
        case .stop: return "SIGSTOP"
        case .terminalStop: return "SIGTSTP"
        case .terminalInput: return "SIGTTIN"
        case .terminalOutput: return "SIGTTOU"
        case .urgent: return "SIGURG"
        case .cpuLimit: return "SIGXCPU"
        case .fileLimit: return "SIGXFSZ"
        case .virtualAlarm: return "SIGVTALRM"
        case .profiling: return "SIGPROF"
        case .windowChange: return "SIGWINCH"
        case .io: return "SIGIO"
        default: return "signal(\(rawValue))"
        }
    }
}

