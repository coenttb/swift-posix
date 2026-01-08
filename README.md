# POSIX Kernel

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)
[![CI](https://github.com/coenttb/swift-posix/workflows/CI/badge.svg)](https://github.com/coenttb/swift-posix/actions/workflows/ci.yml)

Type-safe POSIX syscall wrappers for Swift. Signals, process management, and dynamic library loading with typed throws and full Sendable compliance.

---

## Key Features

- **Typed throws end-to-end** – `Signal.Error`, `Process.Error`, `Library.Dynamic.Error` with semantic accessors
- **Swift 6 strict concurrency** – Full `Sendable` compliance with documented thread-safety guarantees
- **Type-safe signals** – `Signal.Number` constants, `Signal.Set`, `Signal.Mask`, `Signal.Action`
- **Process management** – Fork, exec, wait with type-safe selectors replacing magic values
- **Dynamic loading** – `dlopen`/`dlsym`/`dlclose` with typed handles and scopes
- **Cross-platform** – Darwin, Linux (Glibc, Musl), Windows (dynamic loading only)
- **Policy-free design** – Raw syscall semantics without retry policies; EINTR returned to caller

---

## Installation

### Package.swift dependency

```swift
dependencies: [
    .package(url: "https://github.com/coenttb/swift-posix.git", from: "0.1.0")
]
```

### Target dependency

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "POSIX Kernel", package: "swift-posix")
    ]
)
```

### Requirements

- Swift 6.2+
- macOS 26+ / iOS 26+ / tvOS 26+ / watchOS 26+ / Linux

---

## Quick Start

```swift
import POSIX_Kernel

// Fork a child process and wait for it
switch try POSIX.Kernel.Process.Fork.fork() {
case .child:
    // Child process: execute /bin/ls
    "/bin/ls".withCString { path in
        let argv: [UnsafePointer<CChar>?] = [path, nil]
        let envp: [UnsafePointer<CChar>?] = [nil]
        argv.withUnsafeBufferPointer { argvBuf in
            envp.withUnsafeBufferPointer { envpBuf in
                try? POSIX.Kernel.Process.Execute.execve(
                    path: path,
                    argv: argvBuf.baseAddress!,
                    envp: envpBuf.baseAddress!
                )
            }
        }
    }
    POSIX.Kernel.Process.Exit.now(127)  // exec failed

case .parent(let child):
    // Parent process: wait for child
    let result = try POSIX.Kernel.Process.Wait.wait(.process(child))
    if let code = result?.status.exit.code {
        print("Child exited with code: \(code)")
    }
}
```

---

## Architecture

| Type | Description |
|------|-------------|
| `POSIX.Kernel.Signal.Number` | Type-safe signal numbers with named constants |
| `POSIX.Kernel.Signal.Set` | Signal set operations (sigset_t wrapper) |
| `POSIX.Kernel.Signal.Mask` | Thread signal mask control (pthread_sigmask) |
| `POSIX.Kernel.Signal.Action` | Signal handler installation (sigaction) |
| `POSIX.Kernel.Signal.Send` | Signal sending (kill, raise) |
| `POSIX.Kernel.Process.Fork` | Process forking with typed result |
| `POSIX.Kernel.Process.Execute` | execve wrapper |
| `POSIX.Kernel.Process.Wait` | waitpid with typed selectors |
| `POSIX.Kernel.Process.Status` | Exit status interpretation (WIFEXITED, etc.) |
| `POSIX.Kernel.Process.Group` | Process group operations (setpgid, getpgid) |
| `POSIX.Kernel.Process.Session` | Session operations (setsid, getsid) |
| `POSIX.Kernel.Library.Dynamic` | dlopen/dlsym/dlclose with typed handles |

---

## Platform Support

| Platform         | CI  | Status       |
|------------------|-----|--------------|
| macOS            | ✅  | Full support |
| Linux            | ✅  | Full support |
| iOS/tvOS/watchOS | —   | Supported    |
| Windows          | —   | Dynamic loading only |

---

## Related Packages

### Dependencies

- [swift-kernel-primitives](https://github.com/coenttb/swift-kernel-primitives): Base kernel type and error codes

### Used By

- [swift-kernel](https://github.com/coenttb/swift-kernel): Higher-level kernel abstractions

---

## License

This project is licensed under the Apache License v2.0. See [LICENSE.md](LICENSE.md) for details.
