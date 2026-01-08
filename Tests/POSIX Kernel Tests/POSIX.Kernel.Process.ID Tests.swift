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

    import StandardsTestSupport
    import Testing

    import Kernel_Primitives
    @testable import POSIX_Kernel

    // Note: Kernel.Process.ID already has #TestSuites from elsewhere.
    // We add tests in a separate file to test the .parent accessor.

    // MARK: - Parent Accessor Tests
    //
    // NOTE: These tests use posix_spawn via POSIXTestHelper instead of fork() directly
    // to avoid Swift runtime lock corruption in multithreaded test environments.

    @Suite("Kernel.Process.ID Parent Tests")
    struct KernelProcessIDParentTests {
        @Test("parent returns positive PID")
        func parentReturnsPositivePID() {
            let parent = Kernel.Process.ID.parent
            #expect(parent.rawValue > 0)
        }

        @Test("spawned child's parent matches spawner's current")
        func childParentMatchesSpawnerCurrent() throws {
            #if os(macOS)
                let ourPID = Kernel.Process.ID.current

                // Spawn helper that verifies its parent PID matches ours
                let child = try POSIXTestHelper.spawn("verify-parent", "\(ourPID.rawValue)")

                let result = try Kernel.Process.Wait.wait(.process(child))
                #expect(result?.status.exit.code == 0, "Child's parent should match spawner's PID")
            #endif
        }
    }

#endif
