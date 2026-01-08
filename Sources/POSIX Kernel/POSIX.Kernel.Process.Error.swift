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
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(Musl)
    import Musl
#endif

extension POSIX.Kernel.Process {
    /// Process-related errors.
    ///
    /// Uses operation carriers with semantic accessors. No dedicated `.interrupted`
    /// case — EINTR is represented only via `Kernel.Error.Code`.
    public enum Error: Swift.Error, Sendable, Equatable, Hashable {
        /// fork() failed.
        case fork(Kernel.Error.Code)

        /// execute*() failed.
        case execute(Kernel.Error.Code)

        /// wait*() failed.
        case wait(Kernel.Error.Code)

        /// kill() failed.
        case kill(Kernel.Error.Code)

        /// Session operation failed (setsid, getsid).
        case session(Kernel.Error.Code)

        /// Process group operation failed (setpgid, getpgid).
        case group(Kernel.Error.Code)

        /// posix_spawn() failed.
        case spawn(Kernel.Error.Code)
    }
}

// MARK: - Semantic Accessors

extension POSIX.Kernel.Process.Error {
    /// The underlying error code.
    public var code: Kernel.Error.Code {
        switch self {
        case .fork(let c), .execute(let c), .wait(let c), .kill(let c),
            .session(let c), .group(let c), .spawn(let c):
            return c
        }
    }

    /// Whether this is an interrupted operation (EINTR).
    ///
    /// Derived from code, not a separate case.
    public var isInterrupted: Bool {
        code.posix == EINTR
    }

    /// Semantic classification of process errors.
    public enum Semantic: Sendable {
        /// Resource limit reached (EAGAIN, ENOMEM).
        case resourceLimit

        /// Operation not permitted (EPERM).
        case noPermission

        /// No such process (ESRCH, ECHILD).
        case noSuchProcess

        /// Interrupted by signal (EINTR).
        case interrupted

        /// Invalid argument (EINVAL).
        case invalidArgument
    }

    /// Semantic meaning of the error, if mappable.
    ///
    /// Returns `nil` for unrecognized POSIX error codes.
    public var semantic: Semantic? {
        guard let posix = code.posix else { return nil }
        switch posix {
        case EAGAIN, ENOMEM:
            return .resourceLimit
        case EPERM:
            return .noPermission
        case ESRCH, ECHILD:
            return .noSuchProcess
        case EINTR:
            return .interrupted
        case EINVAL:
            return .invalidArgument
        default:
            return nil
        }
    }
}

// MARK: - CustomStringConvertible

extension POSIX.Kernel.Process.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .fork(let code):
            return "fork failed: \(code)"
        case .execute(let code):
            return "execute failed: \(code)"
        case .wait(let code):
            return "wait failed: \(code)"
        case .kill(let code):
            return "kill failed: \(code)"
        case .session(let code):
            return "session operation failed: \(code)"
        case .group(let code):
            return "process group operation failed: \(code)"
        case .spawn(let code):
            return "spawn failed: \(code)"
        }
    }
}
