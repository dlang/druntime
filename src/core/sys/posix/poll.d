/**
 * D header file for POSIX.
 *
 * Copyright: Copyright Sean Kelly 2005 - 2009.
 * License:   $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
 * Authors:   Sean Kelly
 * Standards: The Open Group Base Specifications Issue 6, IEEE Std 1003.1, 2004 Edition
 */

/*          Copyright Sean Kelly 2005 - 2009.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */
module core.sys.posix.poll;

private import core.sys.posix.config;
public import core.sys.posix.poll_c;

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
// XOpen (XSI)
//
/*
struct pollfd
{
    int     fd;
    short   events;
    short   revents;
}

nfds_t

POLLIN
POLLRDNORM
POLLRDBAND
POLLPRI
POLLOUT
POLLWRNORM
POLLWRBAND
POLLERR
POLLHUP
POLLNVAL

int poll(pollfd[], nfds_t, int);
*/

version( CRuntime_Glibc )
{
    struct pollfd
    {
        int     fd;
        short   events;
        short   revents;
    }

    alias c_ulong nfds_t;
    int poll(pollfd*, nfds_t, int);
}
else version( Darwin )
{
    struct pollfd
    {
        int     fd;
        short   events;
        short   revents;
    };
    int poll(pollfd*, nfds_t, int);
}
else version( FreeBSD )
{
    alias uint nfds_t;

    struct pollfd
    {
        int     fd;
        short   events;
        short   revents;
    };
    int poll(pollfd*, nfds_t, int);
}
else version(NetBSD)
{
    alias uint nfds_t;

    struct pollfd
    {
        int     fd;
        short   events;
        short   revents;
    };
    int poll(pollfd*, nfds_t, int);
}
else version( OpenBSD )
{
    alias uint nfds_t;

    struct pollfd
    {
        int     fd;
        short   events;
        short   revents;
    };
    int poll(pollfd*, nfds_t, int);
}
else version( DragonFlyBSD )
{
    alias uint nfds_t;

    struct pollfd
    {
        int     fd;
        short   events;
        short   revents;
    };
    int poll(pollfd*, nfds_t, int);
}
else version( Solaris )
{
    alias c_ulong nfds_t;

    struct pollfd
    {
        int     fd;
        short   events;
        short   revents;
    }
    int poll(pollfd*, nfds_t, int);
}
else version( CRuntime_Bionic )
{
    struct pollfd
    {
        int     fd;
        short   events;
        short   revents;
    }

    alias uint nfds_t;
    int poll(pollfd*, nfds_t, c_long);
}
else version( CRuntime_Musl )
{
    struct pollfd
    {
        int     fd;
        short   events;
        short   revents;
    }

    alias uint nfds_t;
    int poll(pollfd*, nfds_t, c_long);
}
