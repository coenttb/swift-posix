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

extension POSIX.Kernel.Memory.Lock {
    /// Locks all current and/or future pages in the process address space.
    ///
    /// - Parameter flags: Raw flags for mlockall (MCL_CURRENT, MCL_FUTURE, etc.).
    /// - Throws: `Error.lockAll` on failure.
    public static func lockAll(flags: Int32) throws(Error) {
        guard mlockall(flags) == 0 else {
            throw .lockAll(.captureErrno())
        }
    }

    /// Unlocks all pages in the process address space.
    ///
    /// - Throws: `Error.unlockAll` on failure.
    public static func unlockAll() throws(Error) {
        guard munlockall() == 0 else {
            throw .unlockAll(.captureErrno())
        }
    }
}
