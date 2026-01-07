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
    /// Signal-related errors.
    ///
    /// Uses operation carriers with semantic accessors to keep the enum stable
    /// while providing rich error introspection.
    public enum Error: Swift.Error, Sendable, Equatable, Hashable {
        /// Operation interrupted by signal (EINTR).
        ///
        /// Retained as a convenience case for cross-cutting EINTR scenarios.
        case interrupted

        /// Signal set operation failed (sigaddset/sigdelset/sigismember).
        case set(Kernel.Error.Code)

        /// Signal mask operation failed (pthread_sigmask/sigpending).
        case mask(Kernel.Error.Code)

        /// Signal action operation failed (sigaction).
        case action(Kernel.Error.Code)

        /// Signal send operation failed (kill/raise).
        case send(Kernel.Error.Code)
    }
}

// MARK: - Error Code Mapping

extension POSIX.Kernel.Signal.Error {
    /// Creates a signal error from an error code.
    ///
    /// Maps EINTR to `.interrupted`. Returns `nil` for non-signal error codes.
    public init?(code: Kernel.Error.Code) {
        guard case .posix(let errno) = code else { return nil }
        switch errno {
        case EINTR:
            self = .interrupted
        default:
            return nil
        }
    }
}

// MARK: - Semantic Accessors

extension POSIX.Kernel.Signal.Error {
    /// The underlying error code, if any.
    public var code: Kernel.Error.Code? {
        switch self {
        case .interrupted:
            return nil
        case .set(let c), .mask(let c), .action(let c), .send(let c):
            return c
        }
    }

    /// Whether this is an interrupted operation (EINTR).
    ///
    /// Returns `true` for the `.interrupted` case or any operation carrier
    /// with EINTR as the underlying POSIX error code.
    public var isInterrupted: Bool {
        if case .interrupted = self { return true }
        if let code, code.posix == EINTR { return true }
        return false
    }

    /// Semantic classification of signal errors.
    public enum Semantic: Sendable {
        /// Invalid signal number (EINVAL).
        case invalidSignal

        /// Operation not permitted (EPERM).
        case noPermission

        /// No such process (ESRCH).
        case noSuchProcess

        /// Interrupted by signal (EINTR).
        case interrupted
    }

    /// Semantic meaning of the error, if mappable.
    ///
    /// Returns `nil` for unrecognized POSIX error codes.
    public var semantic: Semantic? {
        if case .interrupted = self { return .interrupted }
        guard let posix = code?.posix else { return nil }
        switch posix {
        case EINVAL: return .invalidSignal
        case EPERM: return .noPermission
        case ESRCH: return .noSuchProcess
        case EINTR: return .interrupted
        default: return nil
        }
    }
}

// MARK: - CustomStringConvertible

extension POSIX.Kernel.Signal.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .interrupted:
            return "interrupted by signal"
        case .set(let code):
            return "signal set operation failed: \(code)"
        case .mask(let code):
            return "signal mask operation failed: \(code)"
        case .action(let code):
            return "signal action operation failed: \(code)"
        case .send(let code):
            return "signal send operation failed: \(code)"
        }
    }
}
