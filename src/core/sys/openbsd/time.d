//Written in the D programming language

/++
    D header file for OpenBSD's extensions to POSIX's time.h.

    https://github.com/openbsd/src/blob/master/sys/sys/_time.h
 +/
module core.sys.netbsd.time;

public import core.sys.posix.time;

version (OpenBSD):

enum CLOCK_REALTIME              = 0;
enum CLOCK_PROCESS_CPUTIME_ID    = 2;
enum CLOCK_MONOTONIC             = 3;
enum CLOCK_THREAD_CPUTIME_ID     = 4;
enum CLOCK_UPTIME                = 5;
enum CLOCK_BOOTTIME              = 6;
