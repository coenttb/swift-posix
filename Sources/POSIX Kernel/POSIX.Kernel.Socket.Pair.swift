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

#if canImport(Darwin)
    internal import Darwin
#elseif canImport(Glibc)
    internal import Glibc
#elseif canImport(Musl)
    internal import Musl
#endif

extension POSIX.Kernel.Socket {
    /// Socket pair operations for bidirectional inter-process communication.
    ///
    /// Creates a pair of connected Unix domain sockets. Unlike pipes, socket pairs
    /// are bidirectional—both ends can read and write. Commonly used for:
    /// - Full-duplex IPC between related processes
    /// - Event notification with bidirectional acknowledgment
    /// - Testing network code without actual network I/O
    ///
    /// ## Descriptor Lifecycle
    /// Both descriptors must be closed explicitly via ``Kernel/Close/close(_:)``.
    /// Closing one end causes reads on the other to return EOF and writes to fail.
    public enum Pair: Sendable {}
}

extension POSIX.Kernel.Socket.Pair {
    /// Errors from socket pair operations.
    public enum Error: Swift.Error, Sendable, Equatable {
        /// Platform-specific error.
        case platform(Platform)

        /// Platform-specific error details.
        public enum Platform: Sendable, Equatable {
            /// A POSIX errno value.
            case posix(Int32)
        }
    }

    /// Creates the current error from errno.
    static func currentError() -> Error {
        .platform(.posix(errno))
    }
}

extension POSIX.Kernel.Socket.Pair.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .platform(let p):
            switch p {
            case .posix(let code):
                return "socketpair failed: errno \(code)"
            }
        }
    }
}

extension POSIX.Kernel.Socket.Pair {
    /// Creates a connected pair of Unix domain stream sockets.
    ///
    /// Both sockets are `AF_UNIX` / `SOCK_STREAM` and can be used for
    /// bidirectional communication. Data written to one socket can be read
    /// from the other, and vice versa.
    ///
    /// ## Threading
    /// The socketpair syscall is atomic and does not block. The returned
    /// descriptors are created in blocking mode by default.
    ///
    /// ## Blocking Behavior
    /// - **Read**: Blocks until data is available or the peer is closed (EOF)
    /// - **Write**: Blocks if the socket buffer is full
    ///
    /// ## Descriptor Lifecycle
    /// Both descriptors must be closed explicitly. They are independent—closing
    /// one does not automatically close the other.
    ///
    /// ## Errors
    /// - ``Error/platform(_:)``: socketpair syscall failed
    ///
    /// - Returns: A tuple containing two connected socket descriptors.
    /// - Throws: ``Error`` on failure.
    public static func create() throws(Error) -> (Kernel.Socket.Descriptor, Kernel.Socket.Descriptor) {
        var fds: [Int32] = [0, 0]
        #if canImport(Darwin)
            let result = Darwin.socketpair(AF_UNIX, SOCK_STREAM, 0, &fds)
        #elseif canImport(Glibc)
            let result = Glibc.socketpair(AF_UNIX, Int32(SOCK_STREAM.rawValue), 0, &fds)
        #elseif canImport(Musl)
            let result = Musl.socketpair(AF_UNIX, SOCK_STREAM, 0, &fds)
        #endif
        guard result == 0 else {
            throw currentError()
        }
        return (Kernel.Socket.Descriptor(rawValue: fds[0]), Kernel.Socket.Descriptor(rawValue: fds[1]))
    }
}
