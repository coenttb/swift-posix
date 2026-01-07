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

public import Kernel_Primitives
public import POSIX_Primitives

#if canImport(Darwin)
    internal import Darwin
    internal import CDarwinShim
    internal import CPosixShim
#elseif canImport(Glibc)
    internal import Glibc
    internal import CPosixShim
#elseif canImport(Musl)
    internal import Musl
    internal import CPosixShim
#endif

extension POSIX.Kernel.Library.Dynamic {
    /// Lookup scope for symbol resolution.
    ///
    /// Used with `symbol(name:in:)` to specify where to search.
    /// Special scopes (`.default`, `.next`) are NOT closable —
    /// they are lookup sentinels, not library handles.
    ///
    /// ## Design
    ///
    /// This enum separates closable `Handle` values from lookup-only sentinels.
    /// This makes `close(.default)` a **compile-time error** rather than
    /// a runtime failure.
    ///
    /// ## Pointer Lifetime
    ///
    /// - For `.handle(h)`: returned pointer validity is bounded by that handle's lifetime
    /// - For `.default`/`.next`/`.main`: lookups are not tied to a specific library lifetime,
    ///   but returned pointers can be invalidated by unloading a library that owns the symbol
    /// - **Never assume** `.default` means "stable forever"
    public enum Scope: Sendable, Equatable {
        /// Search in a specific loaded library.
        case handle(Handle)

        /// Search default library paths (RTLD_DEFAULT).
        ///
        /// Finds symbol in any loaded library, following load order.
        /// On Darwin, includes main executable and all linked libraries.
        /// On Linux, searches all loaded shared objects.
        case `default`

        /// Search in next library after caller (RTLD_NEXT).
        ///
        /// Used for interposition/wrapping: finds the next occurrence
        /// of a symbol in the load order after the current object.
        case next

        #if canImport(Darwin)
            /// Search in main executable only (RTLD_MAIN_ONLY).
            ///
            /// Darwin-specific. Restricts search to symbols exported
            /// by the main executable, excluding dynamically loaded libraries.
            case main
        #endif
    }
}

// MARK: - Internal Conversion

extension POSIX.Kernel.Library.Dynamic.Scope {
    /// Converts scope to dlsym handle pointer.
    ///
    /// Uses platform constants from dlfcn.h via C shims.
    /// NEVER hardcodes sentinel bit patterns (I3.1).
    @usableFromInline
    internal var dlsymHandle: UnsafeMutableRawPointer? {
        switch self {
        case .handle(let h):
            return h.rawValue
        case .default:
            return swift_RTLD_DEFAULT()
        case .next:
            return swift_RTLD_NEXT()
        #if canImport(Darwin)
            case .main:
                return swift_RTLD_MAIN_ONLY()
        #endif
        }
    }
}
