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

internal import Kernel_Primitives

#if os(Windows)
    public import WinSDK
#endif

extension POSIX.POSIX.Kernel.Library.Dynamic {
    /// Opaque handle to a loaded dynamic library.
    ///
    /// Returned by `open`, consumed by `close`. This type represents
    /// an actual loaded library, NOT a lookup sentinel.
    ///
    /// ## Thread Safety
    ///
    /// Handle values can be safely passed between threads (`Sendable`).
    /// However, callers must externally synchronize `close` vs in-flight
    /// `symbol` lookups on the same handle.
    ///
    /// ## Validity
    ///
    /// After `close(handle)`, the handle is invalid and must not be used.
    /// Any symbol pointers obtained from this library are also invalid.
    #if os(Windows)
        public struct Handle: @unchecked Sendable, Equatable {
            /// The underlying Windows module handle (HMODULE).
            @usableFromInline
            let rawValue: HMODULE

            /// Creates a handle from a Windows HMODULE.
            @inlinable
            public init(rawValue: HMODULE) {
                self.rawValue = rawValue
            }
        }
    #else
        public struct Handle: @unchecked Sendable, Equatable {
            /// The underlying dlopen handle.
            @usableFromInline
            package let rawValue: UnsafeMutableRawPointer

            /// Creates a handle from a dlopen result.
            @inlinable
            public init(rawValue: UnsafeMutableRawPointer) {
                self.rawValue = rawValue
            }
        }
    #endif
}
