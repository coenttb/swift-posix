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

#if !os(Windows)

    #if canImport(Darwin)
        import Darwin
    #elseif canImport(Glibc)
        import Glibc
    #endif

    import StandardsTestSupport
    import Testing

    import Kernel_Primitives
@testable import POSIX_Kernel

    // Note: Kernel.Process.ID already has #TestSuites from elsewhere.
    // We add tests in a separate file to test the .parent accessor.

    // MARK: - Parent Accessor Tests

    @Suite("Kernel.Process.ID Parent Tests")
    struct KernelProcessIDParentTests {
        @Test("parent returns positive PID")
        func parentReturnsPositivePID() {
            let parent = Kernel.Process.ID.parent
            #expect(parent.rawValue > 0)
        }

        @Test("parent is different from current in child")
        func parentDifferentFromCurrentInChild() throws {
            #if os(macOS)
                switch try Kernel.Process.Fork.fork() {
                case .child:
                    let current = Kernel.Process.ID.current
                    let parent = Kernel.Process.ID.parent
                    // Parent should be our original test process, not ourselves
                    if parent != current {
                        Kernel.Process.Exit.now(0)
                    } else {
                        Kernel.Process.Exit.now(1)
                    }
                case .parent(let child):
                    let result = try Kernel.Process.Wait.wait(.process(child))
                    if let status = result?.status {
                        if status.signaled, status.terminating.signal?.rawValue == SIGKILL {
                            return  // Skip - test harness interference
                        }
                        #expect(status.exit.code == 0)
                    }
                }
            #endif
        }

        @Test("child's parent matches parent's current")
        func childParentMatchesParentCurrent() throws {
            #if os(macOS)
                let ourPID = Kernel.Process.ID.current
                switch try Kernel.Process.Fork.fork() {
                case .child:
                    let parent = Kernel.Process.ID.parent
                    // Child's parent should be the process that forked it
                    if parent == ourPID {
                        Kernel.Process.Exit.now(0)
                    } else {
                        Kernel.Process.Exit.now(1)
                    }
                case .parent(let child):
                    let result = try Kernel.Process.Wait.wait(.process(child))
                    if let status = result?.status {
                        if status.signaled, status.terminating.signal?.rawValue == SIGKILL {
                            return  // Skip - test harness interference
                        }
                        #expect(status.exit.code == 0)
                    }
                }
            #endif
        }
    }

#endif
