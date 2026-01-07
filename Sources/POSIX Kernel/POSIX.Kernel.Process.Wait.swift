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

extension POSIX.Kernel.Process {
    /// Wait operations namespace.
    public enum Wait {}
}

// MARK: - Selector

extension POSIX.Kernel.Process.Wait {
    /// Selector for which child(ren) to wait for.
    ///
    /// Replaces POSIX magic values (-1, 0, <-1) with explicit cases.
    ///
    /// ## Mapping to waitpid
    ///
    /// | Selector | waitpid pid argument |
    /// |----------|----------------------|
    /// | `.any` | -1 |
    /// | `.process(id)` | id.rawValue |
    /// | `.group(pgid)` | -pgid.rawValue |
    /// | `.current` | 0 |
    public enum Selector: Sendable, Equatable {
        /// Wait for any child process (waitpid pid=-1).
        case any

        /// Wait for a specific child process.
        case process(Kernel.Process.ID)

        /// Wait for any child in a specific process group.
        case group(POSIX.Kernel.Process.Group.ID)

        /// Wait for any child in the calling process's group (waitpid pid=0).
        case current
    }
}

// MARK: - Result

extension POSIX.Kernel.Process.Wait {
    /// Result of a wait operation.
    public struct Result: Sendable, Equatable {
        /// The process ID that changed state.
        public let pid: Kernel.Process.ID

        /// The status of the process.
        public let status: POSIX.Kernel.Process.Status

        public init(pid: Kernel.Process.ID, status: POSIX.Kernel.Process.Status) {
            self.pid = pid
            self.status = status
        }
    }
}

// MARK: - Wait Operation

extension POSIX.Kernel.Process.Wait {
    /// Waits for child process(es) to change state.
    ///
    /// - Parameters:
    ///   - selector: Which child(ren) to wait for.
    ///   - options: Wait options (default: blocking).
    /// - Returns: Result, or `nil` if `no.hang` and no child changed state.
    /// - Throws: `POSIX.Kernel.Process.Error.wait` on failure.
    ///
    /// ## Common Errors
    ///
    /// - `.noSuchProcess` (ECHILD): No child processes exist, or
    ///   the specified process/group doesn't match any children.
    /// - `.interrupted` (EINTR): Signal interrupted the wait.
    /// - `.invalidArgument` (EINVAL): Invalid options.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Wait for any child
    /// let result = try POSIX.Kernel.Process.Wait.wait(.any)
    /// print("PID \(result.pid) exited with \(result.status.exit.code ?? -1)")
    ///
    /// // Non-blocking wait
    /// if let result = try POSIX.Kernel.Process.Wait.wait(.any, options: .no.hang) {
    ///     print("Child \(result.pid) ready")
    /// } else {
    ///     print("No children ready")
    /// }
    ///
    /// // Wait for specific child
    /// let result = try POSIX.Kernel.Process.Wait.wait(.process(childPid))
    /// ```

    public static func wait(
        _ selector: Selector,
        options: Options = []
    ) throws(POSIX.Kernel.Process.Error) -> Result? {
        let pid: pid_t =
            switch selector {
            case .any:
                -1
            case .process(let id):
                id.rawValue
            case .group(let pgid):
                -pgid.rawValue
            case .current:
                0
            }

        var status: Int32 = 0
        let result = waitpid(pid, &status, options.rawValue)

        if result == -1 {
            throw .wait(POSIX.Kernel.Error.captureErrno())
        }

        // WNOHANG: returns 0 if no child changed state
        if result == 0 {
            return nil
        }

        return Result(
            pid: Kernel.Process.ID(result),
            status: POSIX.Kernel.Process.Status(rawValue: status)
        )
    }
}
