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

public import POSIX_Primitives
public import Kernel_Primitives

extension POSIX.Kernel.Library.Dynamic {
    /// Errors from dynamic library syscalls.
    ///
    /// Unlike most kernel errors, these carry the platform's
    /// error message string (from dlerror/FormatMessage) rather
    /// than an error code, because dlopen/dlsym don't set errno.
    public enum Error: Swift.Error, Sendable, Equatable {
        /// dlopen/LoadLibraryW failed.
        case open(Message)

        /// dlclose/FreeLibrary failed.
        case close(Message)

        /// dlsym/GetProcAddress failed.
        case symbol(Message)
    }
}

extension POSIX.Kernel.Library.Dynamic {
    /// An owned error message from the platform.
    ///
    /// Always contains a human-readable `text` (never empty).
    /// On Windows, also captures the error `code` for programmatic use.
    public struct Message: Sendable, Equatable, Hashable {
        /// Human-readable error text.
        /// Always non-empty (worst case: "unknown error" or formatted code).
        public let text: String

        /// Platform error code (Windows only).
        /// - POSIX: Always `nil` (dlerror returns string, not errno)
        /// - Windows: Always set
        public let code: Kernel.Error.Code?

        @inlinable
        public init(_ text: String, code: Kernel.Error.Code? = nil) {
            self.text = text
            self.code = code
        }
    }
}

// MARK: - CustomStringConvertible

extension POSIX.Kernel.Library.Dynamic.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .open(let msg):
            return "library open failed: \(msg.text)"
        case .close(let msg):
            return "library close failed: \(msg.text)"
        case .symbol(let msg):
            return "symbol lookup failed: \(msg.text)"
        }
    }
}

extension POSIX.Kernel.Library.Dynamic.Message: CustomStringConvertible {
    public var description: String { text }
}
