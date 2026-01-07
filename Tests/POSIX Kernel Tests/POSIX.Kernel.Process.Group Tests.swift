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

    extension Kernel.Process.Group.Test.Integration {
        @Test("getpgid returns current process group")
        func getpgidReturnsGroup() throws {
            let currentPID = Kernel.Process.ID.current
            let pgid = try Kernel.Process.Group.id(of: currentPID)
            // Process group ID should be positive
            #expect(pgid.rawValue > 0)
        }

        @Test("child can create new process group with .same")
        func childCanCreateGroupWithSame() throws {
            switch try Kernel.Process.Fork.fork() {
            case .child:
                // Use setpgid(0, 0) via .current and .same
                do {
                    try Kernel.Process.Group.set(.current, to: .same)
                    // Verify we're now our own group leader
                    let ourPID = Kernel.Process.ID.current
                    let ourPGID = try Kernel.Process.Group.id(of: ourPID)
                    if ourPGID.rawValue == ourPID.rawValue {
                        Kernel.Process.Exit.now(0)  // Success
                    } else {
                        Kernel.Process.Exit.now(1)  // PGID mismatch
                    }
                } catch {
                    Kernel.Process.Exit.now(2)  // setpgid failed
                }
            case .parent(let child):
                let result = try Kernel.Process.Wait.wait(.process(child))
                #expect(result?.status.exit.code == 0)
            }
        }

        @Test("setpgid with explicit IDs works")
        func setpgidWithExplicitIDs() throws {
            switch try Kernel.Process.Fork.fork() {
            case .child:
                let ourPID = Kernel.Process.ID.current
                let targetPGID = Kernel.Process.Group.ID(ourPID.rawValue)
                do {
                    try Kernel.Process.Group.set(.id(ourPID), to: .id(targetPGID))
                    // Verify
                    let newPGID = try Kernel.Process.Group.id(of: ourPID)
                    if newPGID == targetPGID {
                        Kernel.Process.Exit.now(0)
                    } else {
                        Kernel.Process.Exit.now(1)
                    }
                } catch {
                    Kernel.Process.Exit.now(2)
                }
            case .parent(let child):
                let result = try Kernel.Process.Wait.wait(.process(child))
                #expect(result?.status.exit.code == 0)
            }
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
