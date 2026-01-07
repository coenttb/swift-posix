// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-posix open source project
//
// Copyright (c) 2024-2025 Coen ten Thije Boonkkamp and the swift-posix project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

public import Kernel_Primitives
public import POSIX_Primitives

#if canImport(Darwin)
    public import Darwin
#elseif canImport(Glibc)
    public import Glibc
#elseif canImport(Musl)
    public import Musl
#endif

extension POSIX.Kernel.Process.Wait {
    /// Options for wait operations.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Non-blocking wait
    /// let result = try POSIX.Kernel.Process.Wait.wait(.any, options: .no.hang)
    ///
    /// // Wait for stopped children
    /// let result = try POSIX.Kernel.Process.Wait.wait(.any, options: .untraced)
    ///
    /// // Combine options
    /// let result = try POSIX.Kernel.Process.Wait.wait(.any, options: [.no.hang, .untraced])
    /// ```
    public struct Options: OptionSet, Sendable, Hashable {
        public let rawValue: Int32

        public init(rawValue: Int32) {
            self.rawValue = rawValue
        }

        // MARK: - Nest.Name Pattern for Compound Identifiers

        /// Accessor for `no.hang` (WNOHANG).
        public static var no: No { No() }

        /// No-hang option accessor (Nest.Name pattern).
        public struct No: Sendable {

            public init() {}

            /// Don't block if no child has exited (WNOHANG).
            ///
            /// When specified, `wait` returns `nil` if no child has
            /// changed state, instead of blocking.

            public var hang: Options { Options(rawValue: WNOHANG) }
        }

        // MARK: - Direct Options

        /// Report stopped children (WUNTRACED).
        ///
        /// Also report status for children that are stopped but not
        /// yet reported (traced children stop on any signal).
        public static let untraced = Options(rawValue: WUNTRACED)

        /// Report continued children (WCONTINUED).
        ///
        /// Also report status for children that have been continued
        /// from a stopped state by delivery of SIGCONT.
        public static let continued = Options(rawValue: WCONTINUED)
    }
}
