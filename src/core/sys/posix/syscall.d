///
/// D header file for POSIX.
///
/// License:   $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
/// Authors:   Arun Chandrasekaran <aruncxy@gmail.com>
///

module core.sys.posix.syscall;

version (Posix):
extern (C):
@system:
@nogc:
nothrow:

/// Standard function to call when platform specific wrappers are not available.
/// For instance, Glibc doesn't provide a wrapper for `gettid`. But suggests to
/// use `syscall` instead.
size_t syscall(int number, ...);

