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
