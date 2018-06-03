/**
 * D header file for POSIX.
 *
 * Copyright: Copyright Sean Kelly 2005 - 2009.
 * License:   $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
 * Authors:   Sean Kelly, Alex Rønne Petersen
 * Standards: The Open Group Base Specifications Issue 6, IEEE Std 1003.1, 2004 Edition
 */

/*          Copyright Sean Kelly 2005 - 2009.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */
module core.sys.posix.fcntl;

private import core.sys.posix.config;
private import core.stdc.stdint;
public import core.sys.posix.sys.types; // for off_t, mode_t
public import core.sys.posix.sys.stat;  // for S_IFMT, etc.
public import core.sys.posix.fcntl_c;

version (OSX)
    version = Darwin;
else version (iOS)
    version = Darwin;
else version (TVOS)
    version = Darwin;
else version (WatchOS)
    version = Darwin;

version (Posix):
extern (C):

nothrow:
@nogc:

//
// Required
//
/*
F_DUPFD
F_GETFD
F_SETFD
F_GETFL
F_SETFL
F_GETLK
F_SETLK
F_SETLKW
F_GETOWN
F_SETOWN

FD_CLOEXEC

F_RDLCK
F_UNLCK
F_WRLCK

O_CREAT
O_EXCL
O_NOCTTY
O_TRUNC

O_APPEND
O_DSYNC
O_NONBLOCK
O_RSYNC
O_SYNC

O_ACCMODE
O_RDONLY
O_RDWR
O_WRONLY

struct flock
{
    short   l_type;
    short   l_whence;
    off_t   l_start;
    off_t   l_len;
    pid_t   l_pid;
}

int creat(in char*, mode_t);
int fcntl(int, int, ...);
int open(in char*, int, ...);
*/
version( CRuntime_Glibc )
{
    struct flock
    {
        short   l_type;
        short   l_whence;
        off_t   l_start;
        off_t   l_len;
        pid_t   l_pid;
    }

    static if( __USE_FILE_OFFSET64 )
    {
        int   creat64(in char*, mode_t);
        alias creat64 creat;

        int   open64(in char*, int, ...);
        alias open64 open;
    }
    else
    {
        int   creat(in char*, mode_t);
        int   open(in char*, int, ...);
    }
}
else version( Darwin )
{
    struct flock
    {
        off_t   l_start;
        off_t   l_len;
        pid_t   l_pid;
        short   l_type;
        short   l_whence;
    }

    int creat(in char*, mode_t);
    int open(in char*, int, ...);
}
else version( FreeBSD )
{
    struct flock
    {
        off_t   l_start;
        off_t   l_len;
        pid_t   l_pid;
        short   l_type;
        short   l_whence;
        int     l_sysid;
    }

    struct oflock
    {
        off_t   l_start;
        off_t   l_len;
        pid_t   l_pid;
        short   l_type;
        short   l_whence;
    }

    int creat(in char*, mode_t);
    int open(in char*, int, ...);
}
else version( OpenBSD )
{
    struct flock
    {
        off_t   l_start;
        off_t   l_len;
        pid_t   l_pid;
        short   l_type;
        short   l_whence;
    }

    int creat(in char*, mode_t);
    int open(in char*, int, ...);
}
else version(NetBSD)
{
    struct flock
    {
        off_t   l_start;
        off_t   l_len;
        pid_t   l_pid;
        short   l_type;
        short   l_whence;
    }


    int creat(in char*, mode_t);
    int open(in char*, int, ...);
}
else version( DragonFlyBSD )
{

    enum FCNTLFLAGS = (FAPPEND|FASYNC|FFSYNC|FNONBLOCK|FPOSIXSHM|O_DIRECT);
    struct flock
    {
        off_t   l_start;
        off_t   l_len;
        pid_t   l_pid;
        short   l_type;
        short   l_whence;
    }

    alias oflock = flock;

    int creat(in char*, mode_t);
    int open(in char*, int, ...);
    //int fcntl(int, int, ...);  /*defined below*/
    //int flock(int, int);
}
else version (Solaris)
{
    struct flock
    {
        short l_type;
        short l_whence;
        off_t l_start;
        off_t l_len;
        int l_sysid;
        pid_t l_pid;
        c_long[4] l_pad;
    }

    static if (__USE_LARGEFILE64)
    {
        struct flock64
        {
            short       l_type;
            short       l_whence;
            off64_t     l_start;
            off64_t     l_len;
            int         l_sysid;
            pid_t       l_pid;
            c_long[4]   l_pad;
        }
    }

    version (D_LP64)
    {
        int creat(in char*, mode_t);
        int open(in char*, int, ...);

        static if (__USE_LARGEFILE64)
        {
            alias creat creat64;
            alias open open64;
        }
    }
    else
    {
        static if (__USE_LARGEFILE64)
        {
            int creat64(in char*, mode_t);
            alias creat64 creat;

            int open64(in char*, int, ...);
            alias open64 open;
        }
        else
        {
            int creat(in char*, mode_t);
            int open(in char*, int, ...);
        }
    }
}
else version( CRuntime_Bionic )
{
    struct flock
    {
        short   l_type;
        short   l_whence;
        off_t   l_start;
        off_t   l_len;
        pid_t   l_pid;
    }

    int   creat(in char*, mode_t);
    int   open(in char*, int, ...);
}
else version( CRuntime_Musl )
{
    enum {
        O_CREAT         = 0x40,     // octal     0100
        O_EXCL          = 0x80,     // octal     0200
        O_NOCTTY        = 0x100,    // octal     0400
        O_TRUNC         = 0x200,    // octal    01000

        O_APPEND        = 0x400,    // octal    02000
        O_NONBLOCK      = 0x800,    // octal    04000
        O_DSYNC         = 0x1000,   // octal   010000
        O_SYNC          = 0x101000, // octal 04010000
        O_RSYNC         = O_SYNC,
        O_DIRECTORY     = 0x10000,
        O_NOFOLLOW      = 0x20000,
        O_CLOEXEC       = 0x80000,

        O_ASYNC         = 0x2000,
        O_DIRECT        = 0x4000,
        O_LARGEFILE     =      0,
        O_NOATIME       = 0x40000,
        O_PATH          = 0x200000,
        O_TMPFILE       = 0x410000,
        O_NDELAY        = O_NONBLOCK,
        O_SEARCH        = O_PATH,
        O_EXEC          = O_PATH,

        O_ACCMODE       = (03|O_SEARCH),
        O_RDONLY        = 00,
        O_WRONLY        = 01,
        O_RDWR          = 02,
    }
    enum {
        F_DUPFD        = 0,
        F_GETFD        = 1,
        F_SETFD        = 2,
        F_GETFL        = 3,
        F_SETFL        = 4,
        F_GETLK        = 5,
        F_SETLK        = 6,
        F_SETLKW       = 7,
        F_SETOWN       = 8,
        F_GETOWN       = 9,
    }
    enum {
        F_RDLCK        = 0,
        F_WRLCK        = 1,
        F_UNLCK        = 2,
    }
    struct flock
    {
        short   l_type;
        short   l_whence;
        off_t   l_start;
        off_t   l_len;
        pid_t   l_pid;
    }
    enum FD_CLOEXEC     = 1;
    int open(in char*, int, ...);

    enum AT_FDCWD = -100;
}
else version( CRuntime_UClibc )
{
    enum F_DUPFD        = 0;
    enum F_GETFD        = 1;
    enum F_SETFD        = 2;
    enum F_GETFL        = 3;
    enum F_SETFL        = 4;

    version(X86_64)
    {
        enum F_GETLK        = 5;
        enum F_SETLK        = 6;
        enum F_SETLKW       = 7;
    }
    else static if (__USE_FILE_OFFSET64)
    {
        enum F_GETLK        = 5;
        enum F_SETLK        = 6;
        enum F_SETLKW       = 7;
    }
    else
    {
        enum F_GETLK        = 12;
        enum F_SETLK        = 13;
        enum F_SETLKW       = 14;
    }

    enum F_GETOWN       = 9;
    enum F_SETOWN       = 8;

    enum FD_CLOEXEC     = 1;

    enum F_RDLCK        = 0;
    enum F_UNLCK        = 2;
    enum F_WRLCK        = 1;

    version (X86_64)
    {
        enum O_CREAT        = 0x40;     // octal     0100
        enum O_EXCL         = 0x80;     // octal     0200
        enum O_NOCTTY       = 0x100;    // octal     0400
        enum O_TRUNC        = 0x200;    // octal    01000

        enum O_APPEND       = 0x400;    // octal    02000
        enum O_NONBLOCK     = 0x800;    // octal    04000
        enum O_SYNC         = 0x1000;   // octal    010000
        enum O_NDELAY       = O_NONBLOCK;
        enum O_FSYNC        = O_SYNC;
        enum O_ASYNC        = 0x2000;   // octal    020000
    }
    else version (MIPS32)
    {
        enum O_CREAT        = 0x0100;
        enum O_EXCL         = 0x0400;
        enum O_NOCTTY       = 0x0800;
        enum O_TRUNC        = 0x0200;

        enum O_APPEND       = 0x0008;
        enum O_SYNC         = 0x0010;
        enum O_NONBLOCK     = 0x0080;
        enum O_NDELAY       = O_NONBLOCK;
        enum O_FSYNC        = O_SYNC;
        enum O_ASYNC        = 0x1000;
    }
    else version (ARM)
    {
        enum O_CREAT        = 0x40;     // octal     0100
        enum O_EXCL         = 0x80;     // octal     0200
        enum O_NOCTTY       = 0x100;    // octal     0400
        enum O_TRUNC        = 0x200;    // octal    01000

        enum O_APPEND       = 0x400;    // octal    02000
        enum O_NONBLOCK     = 0x800;    // octal    04000
        enum O_SYNC         = 0x1000;   // octal    010000
        enum O_NDELAY       = O_NONBLOCK;
        enum O_FSYNC        = O_SYNC;
        enum O_ASYNC        = 0x2000;     // octal 020000
    }
    else
        static assert(0, "unimplemented");

    enum O_ACCMODE      = 0x3;
    enum O_RDONLY       = 0x0;
    enum O_WRONLY       = 0x1;
    enum O_RDWR         = 0x2;

    struct flock
    {
        short   l_type;
        short   l_whence;
        static if (__USE_FILE_OFFSET64)
        {
            off64_t   l_start;
            off64_t   l_len;
        }
        else
        {
            off_t   l_start;
            off_t   l_len;
        }
        pid_t   l_pid;
    }

    static if( __USE_FILE_OFFSET64 )
    {
        int   creat64(in char*, mode_t);
        alias creat64 creat;

        int   open64(in char*, int, ...);
        alias open64 open;
    }
    else
    {
        int   creat(in char*, mode_t);
        int   open(in char*, int, ...);
    }

    enum AT_SYMLINK_NOFOLLOW    = 0x100;
    enum AT_FDCWD               = -100;
}
else
{
    static assert(false, "Unsupported platform");
}

//int creat(in char*, mode_t);
int fcntl(int, int, ...);
//int open(in char*, int, ...);

// Generic Posix fallocate
int posix_fallocate(int, off_t, off_t);

//
// Advisory Information (ADV)
//
/*
POSIX_FADV_NORMAL
POSIX_FADV_SEQUENTIAL
POSIX_FADV_RANDOM
POSIX_FADV_WILLNEED
POSIX_FADV_DONTNEED
POSIX_FADV_NOREUSE

int posix_fadvise(int, off_t, off_t, int);
*/
