/**
 * D header file to interface with the Linux timefd API <http://man7.org/linux/man-pages/man2/timerfd_create.2.html>
 * Available since Linux 2.6
 *
 * License : $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 */
module core.sys.linux.timerfd;

version (linux):

public import core.sys.posix.time;

extern (C):
@system:
@nogc:
nothrow:

static if (CRuntime_Musl_Needs_Time64_Compat_Layer)
{
    int __timerfd_settime64(int fd, int flags, const itimerspec* new_value, itimerspec* old_value);
    int __timerfd_gettime64(int fd, itimerspec* curr_value);

    alias timerfd_settime = __timerfd_settime64;
    alias timerfd_gettime = __timerfd_gettime64;
}
else
{
    int timerfd_settime(int fd, int flags, const itimerspec* new_value, itimerspec* old_value);
    int timerfd_gettime(int fd, itimerspec* curr_value);
}

int timerfd_create(int clockid, int flags);

enum TFD_TIMER_ABSTIME = 1 << 0;
enum TFD_TIMER_CANCEL_ON_SET = 1 << 1;
enum TFD_CLOEXEC       = 0x80000;
enum TFD_NONBLOCK      = 0x800;
