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

#if canImport(Darwin)
    public import Darwin
#elseif canImport(Glibc)
    public import Glibc
#elseif canImport(Musl)
    public import Musl
#endif

extension POSIX.Kernel.Signal.Action {
    /// Sets the signal action, returning the previous configuration.
    ///
    /// - Parameters:
    ///   - signal: The signal to configure.
    ///   - configuration: The new signal action configuration.
    /// - Returns: The previous signal action configuration.
    /// - Throws: `Error.action` on failure.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Install a custom handler
    /// let config = Configuration(handler: .custom(myHandler), flags: .restart)
    /// let previous = try POSIX.Kernel.Signal.Action.set(signal: .user1, config)
    ///
    /// // Always restore on cleanup
    /// defer { _ = try? POSIX.Kernel.Signal.Action.set(signal: .user1, previous) }
    /// ```
    @discardableResult

    public static func set(
        signal: POSIX.Kernel.Signal.Number,
        _ configuration: Configuration
    ) throws(POSIX.Kernel.Signal.Error) -> Configuration {
        var newAction = sigaction(configuration)
        var oldAction = sigaction()

        guard sigaction(signal.rawValue, &newAction, &oldAction) == 0 else {
            throw .action(POSIX.Kernel.Error.captureErrno())
        }

        return Configuration(oldAction)
    }

    /// Gets the current signal action configuration.
    ///
    /// - Parameter signal: The signal to query.
    /// - Returns: The current signal action configuration.
    /// - Throws: `Error.action` on failure.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let config = try POSIX.Kernel.Signal.Action.get(signal: .user1)
    /// switch config.handler {
    /// case .default: print("Using default action")
    /// case .ignore: print("Signal ignored")
    /// case .custom: print("Custom handler installed")
    /// case .customInfo: print("Custom handler with siginfo")
    /// }
    /// ```

    public static func get(
        signal: POSIX.Kernel.Signal.Number
    ) throws(POSIX.Kernel.Signal.Error) -> Configuration {
        var action = sigaction()

        guard sigaction(signal.rawValue, nil, &action) == 0 else {
            throw .action(POSIX.Kernel.Error.captureErrno())
        }

        return Configuration(action)
    }
}

// MARK: - sigaction ← Configuration

extension sigaction {
    /// Creates a sigaction struct from a Configuration.
    internal init(_ configuration: POSIX.Kernel.Signal.Action.Configuration) {
        self.init()

        // Set mask
        self.sa_mask = configuration.mask.storage

        // Set flags
        self.sa_flags = configuration.flags.rawValue

        // Set handler based on type
        #if canImport(Darwin)
            switch configuration.handler {
            case .default:
                self.__sigaction_u.__sa_handler = SIG_DFL
            case .ignore:
                self.__sigaction_u.__sa_handler = SIG_IGN
            case .custom(let handler):
                self.__sigaction_u.__sa_handler = handler
            case .customInfo(let handler):
                self.__sigaction_u.__sa_sigaction = handler
            }
        #elseif canImport(Glibc)
            switch configuration.handler {
            case .default:
                self.__sigaction_handler.sa_handler = SIG_DFL
            case .ignore:
                self.__sigaction_handler.sa_handler = SIG_IGN
            case .custom(let handler):
                self.__sigaction_handler.sa_handler = handler
            case .customInfo(let handler):
                self.__sigaction_handler.sa_sigaction = handler
            }
        #elseif canImport(Musl)
            switch configuration.handler {
            case .default:
                self.sa_handler = SIG_DFL
            case .ignore:
                self.sa_handler = SIG_IGN
            case .custom(let handler):
                self.sa_handler = handler
            case .customInfo(let handler):
                self.sa_sigaction = handler
            }
        #endif
    }
}

// MARK: - Configuration ← sigaction

extension POSIX.Kernel.Signal.Action.Configuration {
    /// Creates a Configuration from a raw sigaction struct.
    internal init(_ action: sigaction) {
        let flags = POSIX.Kernel.Signal.Action.Flags(rawValue: action.sa_flags)
        let mask = POSIX.Kernel.Signal.Set(storage: action.sa_mask)

        // Determine handler type
        let handler: POSIX.Kernel.Signal.Action.Handler

        #if canImport(Darwin)
            let handlerPtr = action.__sigaction_u.__sa_handler
            let sigactionPtr = action.__sigaction_u.__sa_sigaction
        #elseif canImport(Glibc)
            let handlerPtr = action.__sigaction_handler.sa_handler
            let sigactionPtr = action.__sigaction_handler.sa_sigaction
        #elseif canImport(Musl)
            let handlerPtr = action.sa_handler
            let sigactionPtr = action.sa_sigaction
        #endif

        if flags.contains(.sigInfo) {
            // SA_SIGINFO set, use sa_sigaction
            if let ptr = sigactionPtr {
                handler = .customInfo(ptr)
            } else {
                // Shouldn't happen, but fallback to default
                handler = .default
            }
        } else {
            // Check for special handler values using raw pointer comparison
            // SIG_DFL and SIG_IGN are special constants (typically 0 and 1)
            let handlerRaw = unsafeBitCast(handlerPtr, to: Int.self)
            let sigDflRaw = unsafeBitCast(SIG_DFL, to: Int.self)
            let sigIgnRaw = unsafeBitCast(SIG_IGN, to: Int.self)

            if handlerRaw == sigDflRaw {
                handler = .default
            } else if handlerRaw == sigIgnRaw {
                handler = .ignore
            } else if let ptr = handlerPtr {
                handler = .custom(ptr)
            } else {
                handler = .default
            }
        }

        // Use unchecked init - kernel state has correct handler/flags relationship
        self.init(__unchecked: (), handler: handler, mask: mask, flags: flags)
    }
}
