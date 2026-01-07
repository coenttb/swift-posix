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

// MARK: - POSIX-Specific Typed API

extension POSIX.Kernel.Memory.Lock {
    /// Locks all current and/or future pages using typed flags.
    ///
    /// - Parameter flags: Typed flags for mlockall.
    /// - Throws: `Error.lockAll` on failure.

    public static func lockAll(_ flags: All.Flags) throws(Error) {
        try lockAll(flags: flags.rawValue)
    }
}
