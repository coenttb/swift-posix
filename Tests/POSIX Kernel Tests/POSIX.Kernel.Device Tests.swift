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

#if !os(Windows)

    import StandardsTestSupport
    import Testing

    import Kernel_Primitives
    @testable import POSIX_Kernel

    extension POSIX.Kernel.Device {
        #TestSuites
    }

    // MARK: - Major/Minor Tests

    extension POSIX.Kernel.Device.Test.Unit {
        @Test("Device major/minor extraction")
        func majorMinorExtraction() {
            // Create a device with known major/minor
            let device = POSIX.Kernel.Device(major: 8, minor: 1)
            #expect(device.major == 8)
            #expect(device.minor == 1)
        }

        @Test("Device major/minor roundtrip")
        func majorMinorRoundtrip() {
            let major: UInt32 = 253
            let minor: UInt32 = 42
            let device = POSIX.Kernel.Device(major: major, minor: minor)
            #expect(device.major == major)
            #expect(device.minor == minor)
        }
    }

    // MARK: - Typed Major/Minor Tests

    extension POSIX.Kernel.Device.Test.Unit {
        @Test("Device typed major/minor")
        func typedMajorMinor() {
            let device = POSIX.Kernel.Device(major: 8, minor: 16)
            let major = device.typedMajor
            let minor = device.typedMinor
            #expect(major.rawValue == 8)
            #expect(minor.rawValue == 16)
        }

        @Test("Device init from typed major/minor")
        func initFromTypedMajorMinor() {
            let major = POSIX.Kernel.Device.Major(rawValue: 253)
            let minor = POSIX.Kernel.Device.Minor(rawValue: 42)
            let device = POSIX.Kernel.Device(major: major, minor: minor)
            #expect(device.major == 253)
            #expect(device.minor == 42)
        }
    }

    // MARK: - CustomStringConvertible Tests

    extension POSIX.Kernel.Device.Test.Unit {
        @Test("Device description contains colon")
        func descriptionContainsColon() {
            let device = POSIX.Kernel.Device(major: 8, minor: 1)
            #expect(device.description.contains(":"))
        }

        @Test("Device description format")
        func descriptionFormat() {
            let device = POSIX.Kernel.Device(major: 8, minor: 1)
            #expect(device.description == "8:1")
        }
    }

#endif
