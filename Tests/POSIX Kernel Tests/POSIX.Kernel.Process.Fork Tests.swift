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

    extension Kernel.Process.Fork.Test.Integration {
        @Test("fork creates child process that can exit")
        func forkAndExit() throws {
            switch try Kernel.Process.Fork.fork() {
            case .child:
                // In child: exit immediately with code 42
                Kernel.Process.Exit.now(42)
            case .parent(let child):
                // In parent: wait for child and verify exit code
                let result = try Kernel.Process.Wait.wait(.process(child))
                #expect(result != nil)
                #expect(result?.pid == child)
                #expect(result?.status.exited == true)
                #expect(result?.status.exit.code == 42)
            }
        }

        @Test("fork returns different results in parent and child")
        func forkResultsCorrect() throws {
            switch try Kernel.Process.Fork.fork() {
            case .child:
                // If we're here, we're in the child - exit 0 to signal success
                Kernel.Process.Exit.now(0)
            case .parent(let child):
                // Child PID must be positive
                #expect(child.rawValue > 0)
                // Clean up
                _ = try? Kernel.Process.Wait.wait(.process(child))
            }
        }

        @Test("child PID matches wait result PID")
        func childPIDConsistent() throws {
            switch try Kernel.Process.Fork.fork() {
            case .child:
                Kernel.Process.Exit.now(0)
            case .parent(let child):
                let result = try Kernel.Process.Wait.wait(.process(child))
                #expect(result?.pid == child)
            }
        }
    }

#endif
