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

// MARK: - Major/Minor Extraction

extension POSIX.Kernel.Device {
    /// The major device number (identifies device type/driver).
    ///
    /// This uses the standard Linux encoding for dev_t.
    @inlinable
    public var major: UInt32 {
        UInt32((rawValue >> 8) & 0xFFF)
    }

    /// The minor device number (identifies specific device instance).
    ///
    /// This uses the standard Linux encoding for dev_t.
    @inlinable
    public var minor: UInt32 {
        UInt32((rawValue & 0xFF) | ((rawValue >> 12) & 0xFFF00))
    }

    /// Creates a device ID from major and minor numbers.
    @inlinable
    public init(major: UInt32, minor: UInt32) {
        let majorPart = UInt64(major & 0xFFF) << 8
        let minorLow = UInt64(minor & 0xFF)
        let minorHigh = UInt64((minor & 0xFFF00)) << 12
        self.init(rawValue: majorPart | minorLow | minorHigh)
    }
}

// MARK: - Typed Major/Minor

extension POSIX.Kernel.Device {
    /// Type-safe wrapper for a major device number.
    ///
    /// This is a semantic wrapper only, not a validated range.
    /// Construction does not enforce kernel limits.
    public struct Major: RawRepresentable, Sendable, Equatable, Hashable {
        public let rawValue: UInt32

        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
    }

    /// Type-safe wrapper for a minor device number.
    ///
    /// This is a semantic wrapper only, not a validated range.
    /// Construction does not enforce kernel limits.
    public struct Minor: RawRepresentable, Sendable, Equatable, Hashable {
        public let rawValue: UInt32

        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
    }

    /// Typed major device number.
    public var typedMajor: Major {
        Major(rawValue: major)
    }

    /// Typed minor device number.
    public var typedMinor: Minor {
        Minor(rawValue: minor)
    }

    /// Creates a device ID from typed major and minor numbers.
    public init(major: Major, minor: Minor) {
        self.init(major: major.rawValue, minor: minor.rawValue)
    }
}

// MARK: - CustomStringConvertible

extension POSIX.Kernel.Device: CustomStringConvertible {
    /// Returns "major:minor" format for POSIX device IDs.
    public var description: String {
        "\(major):\(minor)"
    }
}
