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

/// POSIX Test Helper - Pure C executable for fork/process testing
///
/// This helper is a pure C executable (no Swift runtime) that tests can spawn
/// via posix_spawn to verify process behavior without triggering Swift runtime
/// lock corruption in multithreaded test environments.
///
/// ## Output Protocol
///
/// Emits machine-readable KV pairs to stdout:
/// ```
/// OK pid=123 ppid=456 pgid=123 sid=123 exit=0
/// ERR errno=1 msg=operation_failed
/// ```
///
/// ## Commands
///
/// - `exit <code>` - Exit with specified code
/// - `stop-exit <code>` - SIGSTOP self, exit code when continued
/// - `verify-parent <ppid>` - Verify getppid() == expected
/// - `create-session` - setsid()
/// - `double-setsid` - setsid() twice, verify 2nd fails EPERM
/// - `become-group-leader` - setpgid(0,0)
/// - `setpgid-explicit` - setpgid(pid, pid)
/// - `fork-exit <code>` - fork child that exits with code

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <errno.h>
#include <sys/wait.h>

/// Prints status line with process info to stdout.
static void print_status(const char *status, int exit_code) {
    pid_t pid = getpid();
    pid_t ppid = getppid();
    pid_t pgid = getpgid(0);
    pid_t sid = getsid(0);
    printf("%s pid=%d ppid=%d pgid=%d sid=%d exit=%d\n",
           status, pid, ppid, pgid, sid, exit_code);
    fflush(stdout);
}

/// Prints error with errno info.
static void print_error(int err, const char *msg) {
    printf("ERR errno=%d msg=%s\n", err, msg);
    fflush(stdout);
}

int main(int argc, char *argv[]) {
    if (argc < 2) {
        fprintf(stderr, "Usage: posix-test-helper <command> [args...]\n");
        fprintf(stderr, "Commands:\n");
        fprintf(stderr, "  exit <code>           Exit with specified code\n");
        fprintf(stderr, "  stop-exit <code>      SIGSTOP, then exit when continued\n");
        fprintf(stderr, "  verify-parent <ppid>  Verify parent PID\n");
        fprintf(stderr, "  create-session        Create new session (setsid)\n");
        fprintf(stderr, "  double-setsid         setsid twice, verify EPERM\n");
        fprintf(stderr, "  become-group-leader   setpgid(0,0)\n");
        fprintf(stderr, "  setpgid-explicit      setpgid(pid, pid)\n");
        fprintf(stderr, "  fork-exit <code>      Fork child that exits\n");
        return 1;
    }

    const char *cmd = argv[1];

    // exit <code> - Exit with specified code
    if (strcmp(cmd, "exit") == 0) {
        int code = argc >= 3 ? atoi(argv[2]) : 0;
        print_status("OK", code);
        return code;
    }

    // stop-exit <code> - SIGSTOP self, exit when continued
    if (strcmp(cmd, "stop-exit") == 0) {
        int code = argc >= 3 ? atoi(argv[2]) : 0;
        // Send SIGSTOP to self - parent will SIGCONT
        raise(SIGSTOP);
        // After being continued, exit with code
        print_status("OK", code);
        return code;
    }

    // verify-parent <ppid> - Verify getppid() matches expected
    if (strcmp(cmd, "verify-parent") == 0) {
        if (argc < 3) {
            fprintf(stderr, "verify-parent requires <ppid> argument\n");
            return 1;
        }
        pid_t expected = (pid_t)atoi(argv[2]);
        pid_t actual = getppid();
        int ok = (actual == expected);
        if (ok) {
            print_status("OK", 0);
        } else {
            printf("ERR errno=0 msg=ppid_mismatch expected=%d actual=%d\n", expected, actual);
            fflush(stdout);
        }
        return ok ? 0 : 1;
    }

    // create-session - setsid()
    if (strcmp(cmd, "create-session") == 0) {
        pid_t sid = setsid();
        if (sid > 0) {
            print_status("OK", 0);
            return 0;
        } else {
            print_error(errno, "setsid_failed");
            return 1;
        }
    }

    // double-setsid - setsid twice, verify 2nd fails with EPERM
    if (strcmp(cmd, "double-setsid") == 0) {
        pid_t first = setsid();
        if (first <= 0) {
            print_error(errno, "first_setsid_failed");
            return 1;
        }

        // Second setsid should fail with EPERM (already session leader)
        pid_t second = setsid();
        int second_failed_eperm = (second < 0 && errno == EPERM);

        if (second_failed_eperm) {
            print_status("OK", 0);
            return 0;
        } else {
            print_error(errno, "second_setsid_should_fail_eperm");
            return 1;
        }
    }

    // become-group-leader - setpgid(0,0)
    if (strcmp(cmd, "become-group-leader") == 0) {
        if (setpgid(0, 0) != 0) {
            print_error(errno, "setpgid_failed");
            return 1;
        }

        // Verify we are now group leader (pgid == pid)
        pid_t pid = getpid();
        pid_t pgid = getpgid(0);
        int ok = (pgid == pid);

        if (ok) {
            print_status("OK", 0);
            return 0;
        } else {
            printf("ERR errno=0 msg=not_group_leader pid=%d pgid=%d\n", pid, pgid);
            fflush(stdout);
            return 1;
        }
    }

    // setpgid-explicit - setpgid(pid, pid)
    if (strcmp(cmd, "setpgid-explicit") == 0) {
        pid_t pid = getpid();
        if (setpgid(pid, pid) != 0) {
            print_error(errno, "setpgid_explicit_failed");
            return 1;
        }

        // Verify pgid was set
        pid_t pgid = getpgid(pid);
        int ok = (pgid == pid);

        if (ok) {
            print_status("OK", 0);
            return 0;
        } else {
            printf("ERR errno=0 msg=pgid_not_set pid=%d pgid=%d\n", pid, pgid);
            fflush(stdout);
            return 1;
        }
    }

    // fork-exit <code> - Fork child that exits with code
    if (strcmp(cmd, "fork-exit") == 0) {
        int code = argc >= 3 ? atoi(argv[2]) : 0;

        pid_t child = fork();
        if (child < 0) {
            print_error(errno, "fork_failed");
            return 1;
        }

        if (child == 0) {
            // Child process - exit immediately
            _exit(code);
        }

        // Parent - wait for child
        int status;
        pid_t waited = waitpid(child, &status, 0);
        if (waited != child) {
            print_error(errno, "waitpid_failed");
            return 1;
        }

        int child_exit = WIFEXITED(status) ? WEXITSTATUS(status) : -1;
        printf("OK pid=%d child=%d child_exit=%d\n", getpid(), child, child_exit);
        fflush(stdout);
        return 0;
    }

    fprintf(stderr, "Unknown command: %s\n", cmd);
    return 1;
}
