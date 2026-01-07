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
    /// Signal sending operations.
    public enum Send {}
}

extension POSIX.Kernel.Signal.Send {
    /// Sends a signal to a process.
    ///
    /// - Parameters:
    ///   - signal: The signal to send.
    ///   - pid: The target process ID.
    /// - Throws: `POSIX.Kernel.Signal.Error.send` on failure.
    ///
    /// ## Common Errors
    ///
    /// - `.noPermission` (EPERM): Caller lacks permission to send signal to target.
    /// - `.noSuchProcess` (ESRCH): No process with the specified PID exists.
    /// - `.invalidSignal` (EINVAL): Invalid signal number.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Send SIGTERM to a process
    /// try POSIX.Kernel.Signal.Send.toProcess(.terminate, pid: targetPid)
    /// ```

    public static func toProcess(
        _ signal: POSIX.Kernel.Signal.Number,
        pid: Kernel.Process.ID
    ) throws(POSIX.Kernel.Signal.Error) {
        guard kill(pid.rawValue, signal.rawValue) == 0 else {
            throw .send(POSIX.Kernel.Error.captureErrno())
        }
    }

    /// Sends a signal to the calling process.
    ///
    /// - Parameter signal: The signal to send.
    /// - Throws: `POSIX.Kernel.Signal.Error.send` on failure.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Send SIGUSR1 to self
    /// try POSIX.Kernel.Signal.Send.toSelf(.user1)
    /// ```

    public static func toSelf(
        _ signal: POSIX.Kernel.Signal.Number
    ) throws(POSIX.Kernel.Signal.Error) {
        guard raise(signal.rawValue) == 0 else {
            throw .send(POSIX.Kernel.Error.captureErrno())
        }
    }

    /// Sends a signal to a process group.
    ///
    /// - Parameters:
    ///   - signal: The signal to send.
    ///   - pgid: The target process group ID.
    /// - Throws: `POSIX.Kernel.Signal.Error.send` on failure.
    ///
    /// ## Implementation
    ///
    /// Uses `kill(-pgid, sig)` where the negative PID indicates a process group.
    ///
    /// ## Common Errors
    ///
    /// - `.noPermission` (EPERM): Caller lacks permission to send signal.
    /// - `.noSuchProcess` (ESRCH): No process group with the specified ID exists.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Send SIGTERM to current process group
    /// try POSIX.Kernel.Signal.Send.toGroup(.terminate, pgid: .current)
    /// ```

    public static func toGroup(
        _ signal: POSIX.Kernel.Signal.Number,
        pgid: POSIX.Kernel.Process.Group.ID
    ) throws(POSIX.Kernel.Signal.Error) {
        // Negative PID means process group
        guard kill(-pgid.rawValue, signal.rawValue) == 0 else {
            throw .send(POSIX.Kernel.Error.captureErrno())
        }
    }
}

