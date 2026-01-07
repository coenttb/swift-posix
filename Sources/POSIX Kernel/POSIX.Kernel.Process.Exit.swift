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
    /// Exit operations namespace.
    public enum Exit {}
}

// MARK: - Exit Operation

extension POSIX.Kernel.Process.Exit {
    /// Terminates the calling process immediately.
    ///
    /// - Parameter status: Exit status code (0-255 meaningful).
    ///
    /// ## Important
    ///
    /// - This function does NOT return.
    /// - Uses `_exit()`, NOT `exit()` — no atexit handlers, no stdio flush.
    /// - Safe to call after `fork()` in the child process.
    ///
    /// ## Exit Code Conventions
    ///
    /// - `0`: Success
    /// - `1-125`: Application-defined errors
    /// - `126`: Command found but not executable
    /// - `127`: Command not found
    /// - `128+N`: Terminated by signal N
    ///
    /// ## Usage
    ///
    /// ```swift
    /// switch try POSIX.Kernel.Process.Fork.fork() {
    /// case .child:
    ///     // Do work in child
    ///     POSIX.Kernel.Process.Exit.now(0)
    /// case .parent(let child):
    ///     let result = try POSIX.Kernel.Process.Wait.wait(.process(child))
    /// }
    /// ```
    @inlinable
    public static func now(_ status: Int32) -> Never {
        _exit(status)
    }
}

