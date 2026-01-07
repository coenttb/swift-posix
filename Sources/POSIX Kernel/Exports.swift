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
@_exported import POSIX_Primitives

/// Re-export Kernel namespace from primitives for use within POSIX module.
public typealias Kernel = Kernel_Primitives.Kernel
