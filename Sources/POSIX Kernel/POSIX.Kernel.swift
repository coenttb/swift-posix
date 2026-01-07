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

extension POSIX {
    /// POSIX kernel mechanisms.
    ///
    /// This is a typealias to `Kernel_Primitives.Kernel`, allowing POSIX-specific
    /// extensions to be added to the shared Kernel type.
    ///
    /// Low-level POSIX syscall wrappers for:
    /// - Signal handling (sigaction, sigprocmask, kill)
    /// - Process control (fork, exec, wait, exit)
    /// - Memory locking (mlockall)
    /// - Dynamic library loading (dlopen, dlsym, dlclose)
    public typealias Kernel = Kernel_Primitives.Kernel
}
