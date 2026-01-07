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

#if canImport(Darwin)
    internal import Darwin
#elseif canImport(Glibc)
    internal import Glibc
#elseif canImport(Musl)
    internal import Musl
#endif

extension POSIX.Kernel.Error {
    /// Captures current errno as a `Kernel.Error.Code`.
    ///
    /// Must be called immediately after a failing syscall, before any other libc call.
    @usableFromInline
    internal static func captureErrno() -> Kernel.Error.Code {
        .posix(errno)
    }
}
