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
    /// ## Threading
    ///
    /// All signal operations are thread-safe (kernel provides synchronization).
    /// Signal masks are per-thread; use `pthread_sigmask` (wrapped by `Signal.Mask`)
    /// rather than `sigprocmask` for multithreaded programs.
    ///
    /// ## Blocking Behavior
    ///
    /// Operations are synchronous and non-blocking (immediate kernel calls).
    /// No operation in this namespace waits for signals to arrive.
    ///
    /// ## Cancellation
    ///
    /// POSIX signal syscalls are not cancellable. EINTR is returned as
    /// `Signal.Error.interrupted` for caller-determined retry policy.
    ///
    /// ## Design
    ///
    /// POSIX.Kernel does NOT automatically retry on EINTR. Higher layers
    /// decide retry policy based on their semantics.
    public enum Signal: Sendable {}
}
