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

    extension Kernel.Process.Error {
        #TestSuites
    }

    extension Kernel.Process.Error.Test {
        @Suite struct Integration {}
    }

    // MARK: - Unit Tests

    extension Kernel.Process.Error.Test.Unit {
        @Test("error conforms to Swift.Error")
        func conformsToError() {
            let error: any Swift.Error = Kernel.Process.Error.fork(.posix(1))
            #expect(error is Kernel.Process.Error)
        }

        @Test("error is Sendable")
        func isSendable() {
            let error: any Sendable = Kernel.Process.Error.fork(.posix(1))
            #expect(error is Kernel.Process.Error)
        }

        @Test("error is Equatable")
        func isEquatable() {
            let code = Kernel.Error.Code.posix(1)
            #expect(Kernel.Process.Error.fork(code) == Kernel.Process.Error.fork(code))
            #expect(Kernel.Process.Error.fork(code) != Kernel.Process.Error.wait(code))
        }

        @Test("code accessor returns underlying code")
        func codeAccessor() {
            let code = Kernel.Error.Code.posix(42)
            let errors: [Kernel.Process.Error] = [
                .fork(code),
                .execute(code),
                .wait(code),
                .session(code),
                .group(code),
            ]

            for error in errors {
                #expect(error.code == code)
            }
        }

        @Test("isInterrupted returns true for EINTR")
        func isInterruptedCheck() {
            let code = Kernel.Error.Code.posix(EINTR)
            let error = Kernel.Process.Error.wait(code)
            #expect(error.isInterrupted)

            let nonInterrupted = Kernel.Process.Error.wait(.posix(1))
            #expect(!nonInterrupted.isInterrupted)
        }

        @Test("all error cases are distinct")
        func casesDistinct() {
            let code = Kernel.Error.Code.posix(1)
            let cases: [Kernel.Process.Error] = [
                .fork(code),
                .execute(code),
                .wait(code),
                .session(code),
                .group(code),
            ]

            for (i, a) in cases.enumerated() {
                for (j, b) in cases.enumerated() {
                    if i != j {
                        #expect(a != b, "Cases at index \(i) and \(j) should be different")
                    }
                }
            }
        }
    }

    // MARK: - Semantic Tests

    extension Kernel.Process.Error.Test.Unit {
        @Test("semantic classification works")
        func semanticClassification() {
            let resourceLimit = Kernel.Process.Error.fork(.posix(EAGAIN))
            #expect(resourceLimit.semantic == .resourceLimit)

            let noPermission = Kernel.Process.Error.session(.posix(EPERM))
            #expect(noPermission.semantic == .noPermission)

            let noSuchProcess = Kernel.Process.Error.wait(.posix(ESRCH))
            #expect(noSuchProcess.semantic == .noSuchProcess)

            let noChild = Kernel.Process.Error.wait(.posix(ECHILD))
            #expect(noChild.semantic == .noSuchProcess)

            let interrupted = Kernel.Process.Error.wait(.posix(EINTR))
            #expect(interrupted.semantic == .interrupted)

            let invalidArg = Kernel.Process.Error.wait(.posix(EINVAL))
            #expect(invalidArg.semantic == .invalidArgument)
        }
    }

#endif
