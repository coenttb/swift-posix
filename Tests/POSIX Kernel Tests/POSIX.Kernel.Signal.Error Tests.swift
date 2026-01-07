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

// Signal.Error only exists on POSIX platforms
#if canImport(Darwin) || canImport(Glibc) || canImport(Musl)

    import StandardsTestSupport
    import Testing

    import Kernel_Primitives
    @testable import POSIX_Kernel

    extension Kernel.Signal.Error {
        #TestSuites
    }

    // MARK: - Signal.Error Tests

    extension Kernel.Signal.Error.Test.Unit {
        @Test("interrupted case exists")
        func interruptedCaseExists() {
            let error = Kernel.Signal.Error.interrupted
            if case .interrupted = error {
                // Expected
            } else {
                Issue.record("Expected .interrupted case")
            }
        }

        @Test("Signal.Error conforms to Swift.Error")
        func conformsToSwiftError() {
            let error: any Swift.Error = Kernel.Signal.Error.interrupted
            #expect(error is Kernel.Signal.Error)
        }

        @Test("Signal.Error is Sendable")
        func isSendable() {
            let error: any Sendable = Kernel.Signal.Error.interrupted
            #expect(error is Kernel.Signal.Error)
        }

        @Test("Signal.Error is Equatable")
        func isEquatable() {
            let a = Kernel.Signal.Error.interrupted
            let b = Kernel.Signal.Error.interrupted

            #expect(a == b)
        }

        @Test("Signal.Error is Hashable")
        func isHashable() {
            var set = Set<Kernel.Signal.Error>()
            set.insert(.interrupted)
            set.insert(.interrupted)  // duplicate

            #expect(set.count == 1)
            #expect(set.contains(.interrupted))
        }

        @Test("description returns meaningful string")
        func descriptionMeaningful() {
            let error = Kernel.Signal.Error.interrupted
            #expect(error.description == "interrupted by signal")
        }

        @Test("CustomStringConvertible conformance")
        func customStringConvertibleConformance() {
            let error = Kernel.Signal.Error.interrupted
            let description = String(describing: error)
            #expect(!description.isEmpty)
            #expect(description.contains("interrupt"))
        }
    }

#endif
