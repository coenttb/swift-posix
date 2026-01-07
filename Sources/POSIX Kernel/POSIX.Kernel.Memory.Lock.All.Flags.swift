// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-posix open source project
//
// Copyright (c) 2024 Coen ten Thije Boonkkamp and the swift-posix project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

public import Kernel_Primitives
public import POSIX_Primitives

#if canImport(Darwin)
    internal import Darwin
#elseif canImport(Glibc)
    public import Glibc
    public import CLinuxShim
#elseif canImport(Musl)
    public import Musl
#endif

extension POSIX.Kernel.Memory.Lock.All {
    /// Flags for mlockall().
    public struct Flags: Sendable, Equatable, Hashable {
        public let rawValue: Int32

    
        public init(rawValue: Int32) {
            self.rawValue = rawValue
        }

        /// Lock all pages currently mapped into the address space.
        public static let current = Flags(rawValue: MCL_CURRENT)

        /// Lock all pages that become mapped in the future.
        public static let future = Flags(rawValue: MCL_FUTURE)

        #if os(Linux)
            /// Lock pages when they are faulted in (Linux 4.4+).
            ///
            /// This avoids the overhead of faulting in all pages immediately.
            public static let onFault = Flags(rawValue: MCL_ONFAULT)
        #endif

        /// Combines multiple flags.
    
        public static func | (lhs: Flags, rhs: Flags) -> Flags {
            Flags(rawValue: lhs.rawValue | rhs.rawValue)
        }

        /// Checks if this contains another flag.
    
        public func contains(_ other: Flags) -> Bool {
            (rawValue & other.rawValue) == other.rawValue
        }
    }
}

