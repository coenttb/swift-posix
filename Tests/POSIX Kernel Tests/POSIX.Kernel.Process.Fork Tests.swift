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

    import StandardsTestSupport
    import Testing

    import Kernel_Primitives
    @testable import POSIX_Kernel

    extension Kernel.Process.Fork {
        #TestSuites
    }

    extension Kernel.Process.Fork.Test {
        @Suite struct Integration {}
    }

    // MARK: - Unit Tests

    extension Kernel.Process.Fork.Test.Unit {
        @Test("Result.child is distinct from Result.parent")
        func resultCasesDistinct() {
            let child = Kernel.Process.Fork.Result.child
            let parent = Kernel.Process.Fork.Result.parent(child: Kernel.Process.ID(123))

            #expect(child != parent)
        }

        @Test("Result is Sendable")
        func resultIsSendable() {
            let result: any Sendable = Kernel.Process.Fork.Result.child
            #expect(result is Kernel.Process.Fork.Result)
        }

        @Test("Result is Equatable")
        func resultIsEquatable() {
            let pid = Kernel.Process.ID(42)
            #expect(Kernel.Process.Fork.Result.child == Kernel.Process.Fork.Result.child)
            #expect(
                Kernel.Process.Fork.Result.parent(child: pid)
                    == Kernel.Process.Fork.Result.parent(child: pid)
            )
            #expect(
                Kernel.Process.Fork.Result.parent(child: pid)
                    != Kernel.Process.Fork.Result.parent(child: Kernel.Process.ID(99))
            )
        }
    }

    // MARK: - Integration Tests
    //
    // NOTE: These tests use posix_spawn via POSIXTestHelper instead of fork() directly
    // to avoid Swift runtime lock corruption in multithreaded test environments.

    extension Kernel.Process.Fork.Test.Integration {
        @Test("spawned child process can exit with code")
        func spawnAndExit() throws {
            // Spawn helper that exits with code 42
            let child = try POSIXTestHelper.spawn("exit", "42")

            // Wait for child and verify exit code
            let result = try Kernel.Process.Wait.wait(.process(child))
            #expect(result != nil)
            #expect(result?.pid == child)
            #expect(result?.status.exited == true)
            #expect(result?.status.exit.code == 42)
        }

        @Test("spawned child PID is positive")
        func spawnedPIDIsPositive() throws {
            // Spawn helper that exits with code 0
            let child = try POSIXTestHelper.spawn("exit", "0")

            // Child PID must be positive
            #expect(child.rawValue > 0)

            // Clean up
            _ = try? Kernel.Process.Wait.wait(.process(child))
        }

        @Test("child PID matches wait result PID")
        func childPIDConsistent() throws {
            // Spawn helper that exits with code 0
            let child = try POSIXTestHelper.spawn("exit", "0")

            let result = try Kernel.Process.Wait.wait(.process(child))
            #expect(result?.pid == child)
        }
    }

#endif
