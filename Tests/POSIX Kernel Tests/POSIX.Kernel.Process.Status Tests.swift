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

    extension Kernel.Process.Status {
        #TestSuites
    }

    // MARK: - Unit Tests

    extension Kernel.Process.Status.Test.Unit {
        @Test("status is RawRepresentable")
        func isRawRepresentable() {
            let status = Kernel.Process.Status(rawValue: 0)
            #expect(status.rawValue == 0)
        }

        @Test("status is Sendable")
        func isSendable() {
            let status: any Sendable = Kernel.Process.Status(rawValue: 0)
            #expect(status is Kernel.Process.Status)
        }

        @Test("status is Equatable")
        func isEquatable() {
            #expect(Kernel.Process.Status(rawValue: 0) == Kernel.Process.Status(rawValue: 0))
            #expect(Kernel.Process.Status(rawValue: 0) != Kernel.Process.Status(rawValue: 1))
        }

        @Test("status is Hashable")
        func isHashable() {
            let status = Kernel.Process.Status(rawValue: 42)
            var set = Set<Kernel.Process.Status>()
            set.insert(status)
            #expect(set.contains(status))
        }
    }

    // MARK: - Nest.Name Accessor Tests

    extension Kernel.Process.Status.Test.Unit {
        @Test("exit accessor returns Exit struct")
        func exitAccessor() {
            let status = Kernel.Process.Status(rawValue: 0)
            let exit = status.exit
            #expect(exit is Kernel.Process.Status.Exit)
        }

        @Test("terminating accessor returns Terminating struct")
        func terminatingAccessor() {
            let status = Kernel.Process.Status(rawValue: 0)
            let terminating = status.terminating
            #expect(terminating is Kernel.Process.Status.Terminating)
        }

        @Test("stop accessor returns Stop struct")
        func stopAccessor() {
            let status = Kernel.Process.Status(rawValue: 0)
            let stop = status.stop
            #expect(stop is Kernel.Process.Status.Stop)
        }

        @Test("core accessor returns Core struct")
        func coreAccessor() {
            let status = Kernel.Process.Status(rawValue: 0)
            let core = status.core
            #expect(core is Kernel.Process.Status.Core)
        }
    }

    // MARK: - Classification Tests

    extension Kernel.Process.Status.Test.Unit {
        @Test("Classification cases are distinct")
        func classificationCasesDistinct() {
            let signal = Kernel.Signal.Number(rawValue: 9)  // SIGKILL
            let cases: [Kernel.Process.Status.Classification] = [
                .exited(code: 0),
                .signaled(signal: signal, false),
                .stopped(signal: signal),
                .continued,
            ]

            for (i, a) in cases.enumerated() {
                for (j, b) in cases.enumerated() {
                    if i != j {
                        #expect(a != b, "Cases at index \(i) and \(j) should be different")
                    }
                }
            }
        }

        @Test("exited classifications with different codes are different")
        func exitedCodesDifferent() {
            #expect(
                Kernel.Process.Status.Classification.exited(code: 0)
                    != Kernel.Process.Status.Classification.exited(code: 1)
            )
        }

        @Test("signaled classifications with different signals are different")
        func signaledSignalsDifferent() {
            let sig9 = Kernel.Signal.Number(rawValue: 9)
            let sig15 = Kernel.Signal.Number(rawValue: 15)
            #expect(
                Kernel.Process.Status.Classification.signaled(signal: sig9, false)
                    != Kernel.Process.Status.Classification.signaled(signal: sig15, false)
            )
        }

        @Test("signaled classifications with different core dump are different")
        func signaledCoreDifferent() {
            let sig = Kernel.Signal.Number(rawValue: 9)
            #expect(
                Kernel.Process.Status.Classification.signaled(signal: sig, false)
                    != Kernel.Process.Status.Classification.signaled(signal: sig, true)
            )
        }
    }

#endif
