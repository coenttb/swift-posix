// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-kernel open source project
//
// Copyright (c) 2024-2025 Coen ten Thije Boonkkamp and the swift-kernel project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

#if os(macOS)

    import Darwin
    import StandardsTestSupport
    import Testing

    import Kernel_Primitives
    @testable import POSIX_Kernel

    extension Kernel.Process.Execute {
        #TestSuites
    }

    extension Kernel.Process.Execute.Test {
        @Suite struct Integration {}
    }

    // MARK: - Integration Tests
    //
    // NOTE: These tests use posix_spawn instead of fork+exec to avoid Swift runtime
    // lock corruption in multithreaded test environments. posix_spawn does NOT
    // duplicate the parent's address space, making it safe for concurrent tests.

    extension Kernel.Process.Execute.Test.Integration {
        /// Finds an executable "true" command, trying common paths.
        private static func findTruePath() -> String {
            for path in ["/usr/bin/true", "/bin/true"] {
                if access(path, X_OK) == 0 {
                    return path
                }
            }
            return "/usr/bin/true"  // Fallback, may fail
        }

        @Test("spawn with /usr/bin/true or /bin/true succeeds")
        func spawnTrue() throws {
            let path = Self.findTruePath()
            let argv = [path]
            let envp: [String] = []

            let child = try Kernel.Path.scope(path) { pathPtr in
                try Kernel.Path.scope.array(argv, envp) { argvPtr, envpPtr in
                    try POSIX.Kernel.Process.Spawn.spawn(
                        path: pathPtr.unsafeCString,
                        argv: argvPtr,
                        envp: envpPtr
                    )
                }
            }

            let result = try Kernel.Process.Wait.wait(.process(child))
            #expect(result != nil, "Wait should return a result")
            #expect(result?.status.exit.code == 0, "true should exit with 0")
        }

        @Test("spawn with invalid path throws ENOENT")
        func spawnInvalidPath() throws {
            let path = "/nonexistent/path/to/binary"
            let argv = [path]
            let envp: [String] = []

            // Use a typed helper to preserve error type through Swift's type inference
            func doSpawn() throws(Kernel.Path.String.Error<POSIX.Kernel.Process.Error>) -> Kernel.Process.ID {
                try Kernel.Path.scope.array(argv, envp) {
                    (argvPtr: UnsafePointer<UnsafePointer<CChar>?>, envpPtr: UnsafePointer<UnsafePointer<CChar>?>) throws(POSIX.Kernel.Process.Error) -> Kernel.Process.ID in
                    // argv[0] is already the path, use it directly
                    try POSIX.Kernel.Process.Spawn.spawn(
                        path: argvPtr[0]!,
                        argv: argvPtr,
                        envp: envpPtr
                    )
                }
            }

            do {
                _ = try doSpawn()
                Issue.record("Expected spawn to throw for invalid path")
            } catch {
                // With pass-through overloads, error is single-layer: .body(.spawn(...))
                guard case .body(.spawn(let code)) = error else {
                    Issue.record("Expected .body(.spawn(...)), got \(error)")
                    return
                }
                #expect(code.posix == ENOENT, "Expected ENOENT, got \(code)")
            } 
        }

        @Test("spawn passes arguments to program")
        func spawnPassesArguments() throws {
            let path = "/bin/sh"
            let argv = ["/bin/sh", "-c", "exit 42"]
            let envp: [String] = []

            let child = try Kernel.Path.scope(path) { pathPtr in
                try Kernel.Path.scope.array(argv, envp) { argvPtr, envpPtr in
                    try POSIX.Kernel.Process.Spawn.spawn(
                        path: pathPtr.unsafeCString,
                        argv: argvPtr,
                        envp: envpPtr
                    )
                }
            }

            let result = try Kernel.Process.Wait.wait(.process(child))
            #expect(result?.status.exit.code == 42, "Shell should exit with code 42")
        }

        @Test("spawn passes environment to program")
        func spawnPassesEnvironment() throws {
            // Use sh -c with direct variable expansion
            // The shell reads TEST_EXIT_CODE from its environment and uses it as exit code
            let path = "/bin/sh"
            let argv = ["/bin/sh", "-c", "exit ${TEST_EXIT_CODE:-99}"]
            let envp = ["TEST_EXIT_CODE=77"]

            let child = try Kernel.Path.scope(path) { pathPtr in
                try Kernel.Path.scope.array(argv, envp) { argvPtr, envpPtr in
                    try POSIX.Kernel.Process.Spawn.spawn(
                        path: pathPtr.unsafeCString,
                        argv: argvPtr,
                        envp: envpPtr
                    )
                }
            }

            let result = try Kernel.Process.Wait.wait(.process(child))
            #expect(result?.status.exit.code == 77, "Shell should exit with env value 77")
        }
    }

#endif
