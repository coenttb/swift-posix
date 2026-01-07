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

    extension Kernel.Process.Wait {
        #TestSuites
    }

    extension Kernel.Process.Wait.Test {
        @Suite(.serialized) struct Integration {}
    }

    // MARK: - Selector Tests

    extension Kernel.Process.Wait.Test.Unit {
        @Test("Selector cases are distinct")
        func selectorCasesDistinct() {
            let pid = Kernel.Process.ID(123)
            let pgid = Kernel.Process.Group.ID(456)

            let cases: [Kernel.Process.Wait.Selector] = [
                .any,
                .process(pid),
                .group(pgid),
                .current,
            ]

            for (i, a) in cases.enumerated() {
                for (j, b) in cases.enumerated() {
                    if i != j {
                        #expect(a != b, "Cases at index \(i) and \(j) should be different")
                    }
                }
            }
        }

        @Test("Selector is Sendable")
        func selectorIsSendable() {
            let selector: any Sendable = Kernel.Process.Wait.Selector.any
            #expect(selector is Kernel.Process.Wait.Selector)
        }

        @Test("Selector is Equatable")
        func selectorIsEquatable() {
            let pid = Kernel.Process.ID(42)
            #expect(Kernel.Process.Wait.Selector.any == Kernel.Process.Wait.Selector.any)
            #expect(
                Kernel.Process.Wait.Selector.process(pid)
                    == Kernel.Process.Wait.Selector.process(pid)
            )
        }
    }

    // MARK: - Options Tests

    extension Kernel.Process.Wait.Test.Unit {
        @Test("Options is OptionSet")
        func optionsIsOptionSet() {
            let options: Kernel.Process.Wait.Options = [.untraced, .continued]
            #expect(options.contains(.untraced))
            #expect(options.contains(.continued))
        }

        @Test("no.hang accessor works")
        func noHangAccessor() {
            let noHang = Kernel.Process.Wait.Options.no.hang
            #expect(noHang.rawValue != 0)
        }
    }

    // MARK: - Result Tests

    extension Kernel.Process.Wait.Test.Unit {
        @Test("Result is Sendable")
        func resultIsSendable() {
            let result: any Sendable = Kernel.Process.Wait.Result(
                pid: Kernel.Process.ID(1),
                status: Kernel.Process.Status(rawValue: 0)
            )
            #expect(result is Kernel.Process.Wait.Result)
        }

        @Test("Result is Equatable")
        func resultIsEquatable() {
            let result1 = Kernel.Process.Wait.Result(
                pid: Kernel.Process.ID(42),
                status: Kernel.Process.Status(rawValue: 0)
            )
            let result2 = Kernel.Process.Wait.Result(
                pid: Kernel.Process.ID(42),
                status: Kernel.Process.Status(rawValue: 0)
            )
            let result3 = Kernel.Process.Wait.Result(
                pid: Kernel.Process.ID(99),
                status: Kernel.Process.Status(rawValue: 0)
            )

            #expect(result1 == result2)
            #expect(result1 != result3)
        }
    }

    // MARK: - Integration Tests

    extension Kernel.Process.Wait.Test.Integration {
        @Test("wait(.any) collects child status")
        func waitAnyCollectsChild() throws {
            switch try Kernel.Process.Fork.fork() {
            case .child:
                Kernel.Process.Exit.now(99)
            case .parent(let childPID):
                let result = try Kernel.Process.Wait.wait(.any)
                #expect(result != nil)
                #expect(result?.pid == childPID)
                #expect(result?.status.exit.code == 99)
            }
        }

        @Test("wait(.process(id)) waits for specific child")
        func waitProcessSpecific() throws {
            switch try Kernel.Process.Fork.fork() {
            case .child:
                Kernel.Process.Exit.now(77)
            case .parent(let child):
                let result = try Kernel.Process.Wait.wait(.process(child))
                #expect(result?.pid == child)
                #expect(result?.status.exit.code == 77)
            }
        }

        @Test("wait with no.hang returns nil when no child ready")
        func waitNoHangReturnsNil() throws {
            // No children to wait for
            do {
                let result = try Kernel.Process.Wait.wait(.any, options: .no.hang)
                // Either nil or ECHILD error
                #expect(result == nil)
            } catch {
                // ECHILD is expected when no children exist
                #expect(error.semantic == .noSuchProcess)
            }
        }

        @Test("ECHILD when no children exist")
        func echldWhenNoChildren() throws {
            // Fork a child that exits immediately, then wait for it
            // After that, waiting again should give ECHILD
            switch try Kernel.Process.Fork.fork() {
            case .child:
                Kernel.Process.Exit.now(0)
            case .parent(let child):
                // First collect the child
                _ = try Kernel.Process.Wait.wait(.process(child))
                // Now try to wait again - should fail with ECHILD
                do {
                    _ = try Kernel.Process.Wait.wait(.process(child))
                    Issue.record("Expected ECHILD error")
                } catch let error as Kernel.Process.Error {
                    #expect(error.semantic == .noSuchProcess)
                }
            }
        }

        @Test("status classification matches exited")
        func statusClassificationExited() throws {
            switch try Kernel.Process.Fork.fork() {
            case .child:
                Kernel.Process.Exit.now(55)
            case .parent(let child):
                let result = try Kernel.Process.Wait.wait(.process(child))
                #expect(result != nil)
                if case .exited(let code) = result?.status.classification {
                    #expect(code == 55)
                } else {
                    Issue.record("Expected .exited classification")
                }
            }
        }
    }

#endif
