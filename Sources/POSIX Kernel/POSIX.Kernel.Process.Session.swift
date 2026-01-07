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

extension POSIX.Kernel.Process {
    /// Session operations namespace.
    public enum Session {}
}

// MARK: - Session ID

extension POSIX.Kernel.Process.Session {
    /// Session ID wrapper.
    ///
    /// A type-safe wrapper for session identifiers.
    public typealias ID = Tagged<POSIX.Kernel.Process.Session, pid_t>
}

// MARK: - Session Operations

extension POSIX.Kernel.Process.Session {
    /// Creates a new session with the calling process as leader.
    ///
    /// - Returns: The new session ID.
    /// - Throws: `POSIX.Kernel.Process.Error.session` on failure.
    ///
    /// ## Behavior
    ///
    /// The calling process becomes:
    /// - The leader of a new session
    /// - The leader of a new process group
    /// - Detached from any controlling terminal
    ///
    /// ## Common Errors
    ///
    /// - `.noPermission` (EPERM): The calling process is already a
    ///   process group leader, or the process group ID of another
    ///   process matches the PID of the calling process.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Daemonize: create new session to detach from terminal
    /// switch try POSIX.Kernel.Process.Fork.fork() {
    /// case .child:
    ///     let sid = try POSIX.Kernel.Process.Session.create()
    ///     // Now running in new session, detached from terminal
    /// case .parent:
    ///     break
    /// }
    /// ```
    @inlinable
    public static func create() throws(POSIX.Kernel.Process.Error) -> ID {
        let result = setsid()
        guard result != -1 else {
            throw .session(POSIX.Kernel.Error.captureErrno())
        }
        return ID(result)
    }

    /// Gets the session ID of a process.
    ///
    /// - Parameter pid: Process ID (use `.current` for calling process).
    /// - Returns: The session ID.
    /// - Throws: `POSIX.Kernel.Process.Error.session` on failure.
    ///
    /// ## Common Errors
    ///
    /// - `.noSuchProcess` (ESRCH): No process with the specified PID exists.
    /// - `.noPermission` (EPERM): Permission denied (implementation-defined).
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Get session ID of current process
    /// let sid = try POSIX.Kernel.Process.Session.id(of: .current)
    ///
    /// // Get session ID of another process
    /// let sid = try POSIX.Kernel.Process.Session.id(of: somePid)
    /// ```
    @inlinable
    public static func id(of pid: Kernel.Process.ID) throws(POSIX.Kernel.Process.Error) -> ID {
        let result = getsid(pid.rawValue)
        guard result != -1 else {
            throw .session(POSIX.Kernel.Error.captureErrno())
        }
        return ID(result)
    }
}

