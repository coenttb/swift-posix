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
    //
    // NOTE: These tests use posix_spawn via POSIXTestHelper instead of fork() directly
    // to avoid Swift runtime lock corruption in multithreaded test environments.

    extension Kernel.Process.Session.Test.Integration {
        @Test("getsid returns current session ID")
        func getsidReturnsSessionID() throws {
            let currentPID = Kernel.Process.ID.current
            let sessionID = try Kernel.Process.Session.id(of: currentPID)
            // Session ID should be positive
            #expect(sessionID.rawValue > 0)
        }

        @Test("spawned child can create new session")
        func childCanCreateSession() throws {
            // Spawn helper that calls setsid and verifies new session ID equals its PID
            let child = try POSIXTestHelper.spawn("create-session")

            let result = try Kernel.Process.Wait.wait(.process(child))
            #expect(result?.status.exit.code == 0, "Child should successfully create new session")
        }

        @Test("setsid fails if already group leader")
        func setsidFailsIfGroupLeader() throws {
            // Spawn helper that calls setsid twice - second should fail with EPERM
            let child = try POSIXTestHelper.spawn("double-setsid")

            let result = try Kernel.Process.Wait.wait(.process(child))
            #expect(result?.status.exit.code == 0, "Second setsid should fail with EPERM")
        }
    }

#endif
