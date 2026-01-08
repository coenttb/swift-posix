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
    /// Spawn operations namespace.
    public enum Spawn {}
}

// MARK: - Spawn Operation

extension POSIX.Kernel.Process.Spawn {
    /// Spawns a new process to execute the specified program.
    ///
    /// Unlike `fork()` followed by `exec()`, `posix_spawn()` does NOT duplicate the
    /// parent's address space. This makes it safe to use from multithreaded Swift
    /// processes (including those running Swift Testing).
    ///
    /// - Parameters:
    ///   - path: Path to the executable (null-terminated C string).
    ///   - argv: Argument vector (null-terminated array of C strings).
    ///   - envp: Environment vector (null-terminated array of C strings).
    /// - Returns: The process ID of the spawned child.
    /// - Throws: `POSIX.Kernel.Process.Error.spawn` on failure.
    ///
    /// ## Thread Safety
    ///
    /// This function is safe to call from multithreaded processes. Unlike `fork()`,
    /// it does not duplicate the parent's address space, so it avoids deadlocks
    /// with Swift runtime locks (e.g., `os_unfair_lock`).
    ///
    /// ## Common Errors
    ///
    /// - ENOENT: File not found.
    /// - EACCES: Permission denied.
    /// - ENOEXEC: Invalid executable format.
    /// - ENOMEM: Insufficient memory.
    /// - E2BIG: Argument list too long.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let argv = ["/usr/bin/true"]
    /// let envp: [String] = []
    ///
    /// let child = try Kernel.Path.scope("/usr/bin/true") { path in
    ///     try Kernel.Path.scope.array(argv, envp) { argvPtr, envpPtr in
    ///         try POSIX.Kernel.Process.Spawn.spawn(
    ///             path: path.unsafeCString,
    ///             argv: argvPtr,
    ///             envp: envpPtr
    ///         )
    ///     }
    /// }
    ///
    /// let result = try Kernel.Process.Wait.wait(.process(child))
    /// ```
    public static func spawn(
        path: UnsafePointer<CChar>,
        argv: UnsafePointer<UnsafePointer<CChar>?>,
        envp: UnsafePointer<UnsafePointer<CChar>?>
    ) throws(POSIX.Kernel.Process.Error) -> Kernel.Process.ID {
        var pid: pid_t = 0

        let rc = swift_posix_spawn(
            &pid,
            path,
            nil,  // file_actions
            nil,  // attrp
            argv,
            envp
        )

        // posix_spawn returns the error code directly (not via errno)
        guard rc == 0 else {
            throw .spawn(.posix(rc))
        }

        return Kernel.Process.ID(pid)
    }
}
