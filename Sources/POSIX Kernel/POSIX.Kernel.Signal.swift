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

extension POSIX.Kernel {
    /// POSIX signal handling.
    ///
    /// Signal handling operations including:
    /// - Signal sets (sigset_t operations)
    /// - Signal masks (pthread_sigmask)
    /// - Signal actions (sigaction)
    /// - Signal sending (kill, raise)
    ///
    /// ## Design
    ///
    /// POSIX.Kernel does NOT automatically retry on EINTR. Higher layers
    /// decide retry policy based on their semantics.
    public enum Signal: Sendable {}
}
