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

/// POSIX platform namespace.
///
/// Contains POSIX-specific kernel mechanisms including:
/// - Signal handling
/// - Process management (fork, exec, wait)
/// - Memory locking
/// - Dynamic library loading extensions
public enum POSIX: Sendable {}
