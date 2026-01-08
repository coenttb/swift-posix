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

/// Test helper utilities for spawning the posix-test-helper executable.
///
/// The posix-test-helper is a pure C executable that performs process operations
/// (fork, setsid, setpgid, etc.) without Swift runtime involvement, making it
/// safe to use from multithreaded Swift Testing environments.
///
/// ## Usage
///
/// ```swift
/// let child = try POSIXTestHelper.spawn("exit", "42")
/// let result = try Kernel.Process.Wait.wait(.process(child))
/// #expect(result?.status.exit.code == 42)
/// ```

#if os(macOS) || os(Linux)

#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#endif

import Kernel_Primitives
@testable import POSIX_Kernel

// MARK: - POSIXTestHelper

enum POSIXTestHelper {
    /// Path to the posix-test-helper executable.
    ///
    /// Resolution order:
    /// 1. `POSIX_TEST_HELPER` environment variable (CI-friendly)
    /// 2. `.build/debug/` relative to package root via #filePath (SwiftPM)
    /// 3. Xcode DerivedData via environment variables
    static func executablePath(filePath: StaticString = #filePath) -> String {
        let helperName = "posix-test-helper"

        // 1. Prefer explicit env var (CI-friendly)
        if let envPath = getenv("POSIX_TEST_HELPER") {
            return String(cString: envPath)
        }

        // 2. Use #filePath to find package root, then .build/debug/
        //    filePath: .../swift-posix/Tests/POSIX Kernel Tests/POSIX.TestHelper.swift
        //    package root: .../swift-posix/
        //    helper: .../swift-posix/.build/debug/posix-test-helper
        var path = filePath.description
        // Go up: POSIX.TestHelper.swift -> POSIX Kernel Tests -> Tests -> swift-posix
        for _ in 0..<3 {
            if let lastSlash = path.lastIndex(of: "/") {
                path = String(path[..<lastSlash])
            }
        }
        let swiftPMPath = "\(path)/.build/debug/\(helperName)"
        if isExecutable(swiftPMPath) {
            return swiftPMPath
        }

        // 3. Try __XPC_DYLD_FRAMEWORK_PATH (set by Xcode test runner)
        if let xpcPath = getenv("__XPC_DYLD_FRAMEWORK_PATH") {
            let candidate = "\(String(cString: xpcPath))/\(helperName)"
            if isExecutable(candidate) {
                return candidate
            }
        }

        // 4. Try DYLD_FRAMEWORK_PATH (also set by Xcode)
        if let dyldPath = getenv("DYLD_FRAMEWORK_PATH") {
            let candidate = "\(String(cString: dyldPath))/\(helperName)"
            if isExecutable(candidate) {
                return candidate
            }
        }

        // Fallback: return helperName and let spawn fail with clear error
        return helperName
    }

    /// Check if path is an executable file using withCString for proper C interop.
    private static func isExecutable(_ path: String) -> Bool {
        path.withCString { cPath in
            access(cPath, X_OK) == 0
        }
    }

    /// Spawns the test helper with the given arguments.
    ///
    /// - Parameter args: Command and arguments (e.g., "exit", "42").
    /// - Returns: The process ID of the spawned helper.
    /// - Throws: `POSIX.Kernel.Process.Error.spawn` on failure.
    ///
    /// ## Commands
    ///
    /// - `exit <code>` - Exit with specified code
    /// - `stop-exit <code>` - SIGSTOP, then exit when continued
    /// - `verify-parent <ppid>` - Verify parent PID
    /// - `create-session` - setsid()
    /// - `double-setsid` - setsid twice, verify EPERM
    /// - `become-group-leader` - setpgid(0,0)
    /// - `setpgid-explicit` - setpgid(pid, pid)
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Test exit code handling
    /// let child = try POSIXTestHelper.spawn("exit", "77")
    /// let result = try Kernel.Process.Wait.wait(.process(child))
    /// #expect(result?.status.exit.code == 77)
    ///
    /// // Test stop/continue handling
    /// let child = try POSIXTestHelper.spawn("stop-exit", "42")
    /// let stopped = try Kernel.Process.Wait.wait(.process(child), options: [.untraced])
    /// #expect(stopped?.status.stopped == true)
    /// try POSIX.Kernel.Signal.Send.toProcess(.cont, pid: child)
    /// let exited = try Kernel.Process.Wait.wait(.process(child))
    /// #expect(exited?.status.exit.code == 42)
    /// ```
    static func spawn(_ args: String...) throws -> Kernel.Process.ID {
        try spawn(args)
    }

    /// Spawns the test helper with the given arguments array.
    ///
    /// - Parameter args: Command and arguments.
    /// - Returns: The process ID of the spawned helper.
    /// - Throws: `POSIX.Kernel.Process.Error.spawn` on failure.
    static func spawn(_ args: [String]) throws -> Kernel.Process.ID {
        let path = executablePath()
        let allArgs = [path] + args
        let envp: [String] = []

        return try Kernel.Path.scope(path) { pathPtr in
            try Kernel.Path.scope.array(allArgs, envp) { argvPtr, envpPtr in
                try POSIX.Kernel.Process.Spawn.spawn(
                    path: pathPtr.unsafeCString,
                    argv: argvPtr,
                    envp: envpPtr
                )
            }
        }
    }
}

#endif
