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

    extension Kernel.Process.Group {
        #TestSuites
    }

    extension Kernel.Process.Group.Test {
        @Suite struct Integration {}
    }

    // MARK: - Unit Tests

    extension Kernel.Process.Group.Test.Unit {
        @Test("Group.ID is type alias for Tagged")
        func groupIDIsTagged() {
            let id = Kernel.Process.Group.ID(123)
            #expect(id.rawValue == 123)
        }

        @Test("Group.Process cases are distinct")
        func processCasesDistinct() {
            let pid = Kernel.Process.ID(42)
            #expect(Kernel.Process.Group.Process.current != Kernel.Process.Group.Process.id(pid))
        }

        @Test("Group.Target cases are distinct")
        func targetCasesDistinct() {
            let pgid = Kernel.Process.Group.ID(42)
            #expect(Kernel.Process.Group.Target.same != Kernel.Process.Group.Target.id(pgid))
        }
    }

    // MARK: - Integration Tests
    //
    // NOTE: These tests use posix_spawn via POSIXTestHelper instead of fork() directly
    // to avoid Swift runtime lock corruption in multithreaded test environments.

    extension Kernel.Process.Group.Test.Integration {
        @Test("getpgid returns current process group")
        func getpgidReturnsGroup() throws {
            let currentPID = Kernel.Process.ID.current
            let pgid = try Kernel.Process.Group.id(of: currentPID)
            // Process group ID should be positive
            #expect(pgid.rawValue > 0)
        }

        @Test("spawned child can create new process group with setpgid(0,0)")
        func childCanCreateGroupWithSame() throws {
            // Spawn helper that calls setpgid(0, 0) and verifies pgid == pid
            let child = try POSIXTestHelper.spawn("become-group-leader")

            let result = try Kernel.Process.Wait.wait(.process(child))
            #expect(result?.status.exit.code == 0, "Child should become process group leader")
        }

        @Test("setpgid with explicit IDs works")
        func setpgidWithExplicitIDs() throws {
            // Spawn helper that calls setpgid(pid, pid) explicitly
            let child = try POSIXTestHelper.spawn("setpgid-explicit")

            let result = try Kernel.Process.Wait.wait(.process(child))
            #expect(result?.status.exit.code == 0, "setpgid with explicit IDs should work")
        }

        @Test("getpgid for nonexistent process throws ESRCH")
        func getpgidNonexistentThrows() throws {
            // Use a PID that's unlikely to exist
            let unlikelyPID = Kernel.Process.ID(999999)
            do {
                _ = try Kernel.Process.Group.id(of: unlikelyPID)
                Issue.record("Expected ESRCH error")
            } catch {
                #expect(error.semantic == .noSuchProcess)
            }
        }
    }

#endif
