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

import StandardsTestSupport
import Testing

@testable import POSIX_Kernel
#if !os(Windows)
// @testable import Kernel_POSIX  // Not available in primitives package
#endif

extension POSIX.Kernel.Library.Dynamic {
    #TestSuites
}

// MARK: - Unit Tests

extension POSIX.Kernel.Library.Dynamic.Test.Unit {
    @Test("Dynamic namespace exists")
    func namespaceExists() {
        _ = POSIX.Kernel.Library.Dynamic.self
    }

    @Test("Handle type exists")
    func handleTypeExists() {
        _ = POSIX.Kernel.Library.Dynamic.Handle.self
    }

    @Test("Error type exists")
    func errorTypeExists() {
        _ = POSIX.Kernel.Library.Dynamic.Error.self
    }

    @Test("Message type exists")
    func messageTypeExists() {
        _ = POSIX.Kernel.Library.Dynamic.Message.self
    }
}

// MARK: - POSIX Tests

#if !os(Windows)

    extension POSIX.Kernel.Library.Dynamic.Test.Unit {
        @Test("Options type exists")
        func optionsTypeExists() {
            _ = POSIX.Kernel.Library.Dynamic.Options.self
        }

        @Test("Scope type exists")
        func scopeTypeExists() {
            _ = POSIX.Kernel.Library.Dynamic.Scope.self
        }

        @Test("Options.now is default (fail-early)")
        func optionsNowIsDefault() {
            // Verify .now exists and is distinct from .lazy
            let now = POSIX.Kernel.Library.Dynamic.Options.now
            let lazy = POSIX.Kernel.Library.Dynamic.Options.lazy
            #expect(now != lazy)
        }

        @Test("Opening nonexistent library throws with message")
        func openNonexistentLibraryThrows() {
            "/nonexistent/library.so".withCString { path in
                #expect(throws: POSIX.Kernel.Library.Dynamic.Error.self) {
                    _ = try POSIX.Kernel.Library.Dynamic.open(path: path, options: .now)
                }
            }
        }

        @Test("Error message is non-empty on failure")
        func errorMessageIsNonEmpty() {
            "/nonexistent/library.so".withCString { path in
                do {
                    _ = try POSIX.Kernel.Library.Dynamic.open(path: path, options: .now)
                    Issue.record("Expected open to throw")
                } catch let error as POSIX.Kernel.Library.Dynamic.Error {
                    if case .open(let msg) = error {
                        #expect(!msg.text.isEmpty, "error message should be non-empty")
                    } else {
                        Issue.record("Expected .open error case")
                    }
                } catch {
                    Issue.record("Unexpected error type: \(error)")
                }
            }
        }

        @Test("Symbol not found throws with message")
        func symbolNotFoundThrows() {
            "____nonexistent_symbol_xyz____".withCString { name in
                #expect(throws: POSIX.Kernel.Library.Dynamic.Error.self) {
                    _ = try POSIX.Kernel.Library.Dynamic.symbol(name: name, in: .default)
                }
            }
        }

    }

#endif

// MARK: - Windows Tests

#if os(Windows)

    extension POSIX.Kernel.Library.Dynamic.Test.Unit {
        @Test("Open kernel32.dll and lookup symbol")
        func openKernel32() throws {
            let handle = try "kernel32.dll".withCString(encodedAs: UTF16.self) { path in
                try POSIX.Kernel.Library.Dynamic.open(path: path)
            }
            defer { try? POSIX.Kernel.Library.Dynamic.close(handle) }

            let proc = try "GetCurrentProcessId".withCString { name in
                try POSIX.Kernel.Library.Dynamic.symbol(name: name, in: handle)
            }
            // Just verify we got a pointer
            _ = proc
        }

        @Test("Opening nonexistent DLL throws with code")
        func openNonexistentDLLThrows() {
            #expect(throws: POSIX.Kernel.Library.Dynamic.Error.self) {
                _ = try "____nonexistent____.dll".withCString(encodedAs: UTF16.self) { path in
                    try POSIX.Kernel.Library.Dynamic.open(path: path)
                }
            }
        }

        @Test("Error includes Windows error code")
        func errorIncludesWindowsCode() {
            "____nonexistent____.dll".withCString(encodedAs: UTF16.self) { path in
                do {
                    _ = try POSIX.Kernel.Library.Dynamic.open(path: path)
                    Issue.record("Expected open to throw")
                } catch let error as POSIX.Kernel.Library.Dynamic.Error {
                    if case .open(let msg) = error {
                        #expect(msg.code != nil, "Windows error should include code")
                        #expect(msg.code?.win32 != nil, "Should be a win32 code")
                    } else {
                        Issue.record("Expected .open error case")
                    }
                } catch {
                    Issue.record("Unexpected error type: \(error)")
                }
            }
        }
    }

#endif
