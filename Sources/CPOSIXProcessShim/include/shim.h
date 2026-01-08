#ifndef CPOSIX_PROCESS_SHIM_H
#define CPOSIX_PROCESS_SHIM_H

#if defined(__APPLE__) || defined(__linux__)

#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

// fork() wrapper - on Darwin, fork() is marked unavailable in Swift's overlay.
// We provide a wrapper to bypass the Swift annotation.

#if defined(__APPLE__)
static inline pid_t swift_fork(void) {
    return fork();
}
#endif

// POSIX wait status macros - Swift cannot import C macros directly.
// These wrapper functions expose the macros to Swift.

static inline int swift_WIFEXITED(int status) {
    return WIFEXITED(status);
}

static inline int swift_WEXITSTATUS(int status) {
    return WEXITSTATUS(status);
}

static inline int swift_WIFSIGNALED(int status) {
    return WIFSIGNALED(status);
}

static inline int swift_WTERMSIG(int status) {
    return WTERMSIG(status);
}

static inline int swift_WIFSTOPPED(int status) {
    return WIFSTOPPED(status);
}

static inline int swift_WSTOPSIG(int status) {
    return WSTOPSIG(status);
}

static inline int swift_WIFCONTINUED(int status) {
    return WIFCONTINUED(status);
}

#ifdef WCOREDUMP
static inline int swift_WCOREDUMP(int status) {
    return WCOREDUMP(status);
}
#endif

// Process management wrapper - execve expects mutable pointers but never modifies them.
// We provide a const-correct wrapper for Swift.

#if defined(__linux__)
// Forward declaration to avoid including <unistd.h> which causes fd_set conflicts on Linux
extern int execve(const char *__path, char *const __argv[], char *const __envp[]) __attribute__((__nothrow__, __leaf__));
#else
#include <unistd.h>
#endif

static inline int swift_execve(
    const char *path,
    const char *const argv[],
    const char *const envp[]
) {
    // Cast away const-ness for execve's legacy signature.
    // execve does NOT modify the strings, this is safe.
    return execve(path, (char *const *)argv, (char *const *)envp);
}

// posix_spawn wrapper - similar to execve, expects const pointers.
// posix_spawn does NOT modify the strings, this is safe.

#include <spawn.h>

static inline int swift_posix_spawn(
    pid_t *pid,
    const char *path,
    const posix_spawn_file_actions_t *file_actions,
    const posix_spawnattr_t *attrp,
    const char *const argv[],
    const char *const envp[]
) {
    return posix_spawn(pid, path, file_actions, attrp, (char *const *)argv, (char *const *)envp);
}

#endif /* __APPLE__ || __linux__ */

#endif /* CPOSIX_PROCESS_SHIM_H */
