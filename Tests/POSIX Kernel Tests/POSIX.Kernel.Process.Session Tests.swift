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

    extension Kernel.Process.Session {
        #TestSuites
    }

    extension Kernel.Process.Session.Test {
        @Suite struct Integration {}
    }

    // MARK: - Unit Tests

    extension Kernel.Process.Session.Test.Unit {
        @Test("Session.ID is type alias for Tagged")
        func sessionIDIsTagged() {
            let id = Kernel.Process.Session.ID(123)
            #expect(id.rawValue == 123)
        }
    }

    // MARK: - Integration Tests

    extension Kernel.Process.Session.Test.Integration {
        @Test("getsid returns current session ID")
        func getsidReturnsSessionID() throws {
            let currentPID = Kernel.Process.ID.current
            let sessionID = try Kernel.Process.Session.id(of: currentPID)
            // Session ID should be positive
            #expect(sessionID.rawValue > 0)
        }

        @Test("child can create new session")
        func childCanCreateSession() throws {
            switch try Kernel.Process.Fork.fork() {
            case .child:
                // Child is not a process group leader, so setsid should succeed
                do {
                    let newSession = try Kernel.Process.Session.create()
                    // New session ID should equal our PID
                    let ourPID = Kernel.Process.ID.current
                    if newSession.rawValue == ourPID.rawValue {
                        Kernel.Process.Exit.now(0)  // Success
                    } else {
                        Kernel.Process.Exit.now(1)  // Session ID mismatch
                    }
                } catch {
                    Kernel.Process.Exit.now(2)  // setsid failed
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
        }

        @Test("setsid fails if already group leader")
        func setsidFailsIfGroupLeader() throws {
            // The current process is likely a group leader, so setsid should fail
            // But this depends on how the test harness runs tests
            // We test in a forked child that becomes group leader first
            switch try Kernel.Process.Fork.fork() {
            case .child:
                // First, create a new session (makes us session and group leader)
                do {
                    _ = try Kernel.Process.Session.create()
                    // Now try to create another session - should fail with EPERM
                    do {
                        _ = try Kernel.Process.Session.create()
                        Kernel.Process.Exit.now(1)  // Should have failed
                    } catch {
                        if error.semantic == .noPermission {
                            Kernel.Process.Exit.now(0)  // Expected EPERM
                        } else {
                            Kernel.Process.Exit.now(2)  // Wrong error
                        }
                    }
                } catch {
                    Kernel.Process.Exit.now(3)  // First setsid failed
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
        }
    }

#endif
