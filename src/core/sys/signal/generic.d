/**
 * D header file for POSIX.
 *
 * Copyright: Copyright Iain Buclaw 2015.
 * License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 * Authors:   Iain Buclaw
 * Standards: The Open Group Base Specifications Issue 6, IEEE Std 1003.1, 2004 Edition
 * Source:    $(DRUNTIMESRC core/sys/signal/_package.d)
 */

module core.sys.signal.generic;

version (Posix):
extern (C):
//nothrow:  // this causes Issue 12738

//
// Required
//
/*
SIG_DFL (defined in core.stdc.signal)
SIG_ERR (defined in core.stdc.signal)
SIG_IGN (defined in core.stdc.signal)

sig_atomic_t (defined in core.stdc.signal)

SIGEV_NONE
SIGEV_SIGNAL
SIGEV_THREAD

union sigval
{
    int   sival_int;
    void* sival_ptr;
}

SIGRTMIN
SIGRTMAX

SIGABRT (defined in core.stdc.signal)
SIGALRM
SIGBUS
SIGCHLD
SIGCONT
SIGFPE (defined in core.stdc.signal)
SIGHUP
SIGILL (defined in core.stdc.signal)
SIGINT (defined in core.stdc.signal)
SIGKILL
SIGPIPE
SIGQUIT
SIGSEGV (defined in core.stdc.signal)
SIGSTOP
SIGTERM (defined in core.stdc.signal)
SIGTSTP
SIGTTIN
SIGTTOU
SIGUSR1
SIGUSR2
SIGURG

struct sigaction_t
{
    sigfn_t     sa_handler;
    sigset_t    sa_mask;
    sigactfn_t  sa_sigaction;
}

sigfn_t signal(int sig, sigfn_t func); (defined in core.stdc.signal)
int raise(int sig);                    (defined in core.stdc.signal)
*/

//SIG_DFL (defined in core.stdc.signal)
//SIG_ERR (defined in core.stdc.signal)
//SIG_IGN (defined in core.stdc.signal)

//sig_atomic_t (defined in core.stdc.signal)

//
// C Extension (CX)
//
/*
SIG_HOLD

sigset_t
pid_t   (defined in core.sys.types)

SIGABRT (defined in core.stdc.signal)
SIGFPE  (defined in core.stdc.signal)
SIGILL  (defined in core.stdc.signal)
SIGINT  (defined in core.stdc.signal)
SIGSEGV (defined in core.stdc.signal)
SIGTERM (defined in core.stdc.signal)

SA_NOCLDSTOP (CX|XSI)
SIG_BLOCK
SIG_UNBLOCK
SIG_SETMASK

struct siginfo_t
{
    int     si_signo;
    int     si_code;

    version( XSI )
    {
        int     si_errno;
        pid_t   si_pid;
        uid_t   si_uid;
        void*   si_addr;
        int     si_status;
        c_long  si_band;
    }
    version( RTS )
    {
        sigval  si_value;
    }
}

SI_USER
SI_QUEUE
SI_TIMER
SI_ASYNCIO
SI_MESGQ

int kill(pid_t, int);
int sigaction(int, in sigaction_t*, sigaction_t*);
int sigaddset(sigset_t*, int);
int sigdelset(sigset_t*, int);
int sigemptyset(sigset_t*);
int sigfillset(sigset_t*);
int sigismember(in sigset_t*, int);
int sigpending(sigset_t*);
int sigprocmask(int, in sigset_t*, sigset_t*);
int sigsuspend(in sigset_t*);
int sigwait(in sigset_t*, int*);
*/

//
// XOpen (XSI)
//
/*
SIGPOLL
SIGPROF
SIGSYS
SIGTRAP
SIGVTALRM
SIGXCPU
SIGXFSZ

SA_ONSTACK
SA_RESETHAND
SA_RESTART
SA_SIGINFO
SA_NOCLDWAIT
SA_NODEFER
SS_ONSTACK
SS_DISABLE
MINSIGSTKSZ
SIGSTKSZ

ucontext_t // from ucontext
mcontext_t // from ucontext

struct stack_t
{
    void*   ss_sp;
    size_t  ss_size;
    int     ss_flags;
}

struct sigstack
{
    int   ss_onstack;
    void* ss_sp;
}

ILL_ILLOPC
ILL_ILLOPN
ILL_ILLADR
ILL_ILLTRP
ILL_PRVOPC
ILL_PRVREG
ILL_COPROC
ILL_BADSTK

FPE_INTDIV
FPE_INTOVF
FPE_FLTDIV
FPE_FLTOVF
FPE_FLTUND
FPE_FLTRES
FPE_FLTINV
FPE_FLTSUB

SEGV_MAPERR
SEGV_ACCERR

BUS_ADRALN
BUS_ADRERR
BUS_OBJERR

TRAP_BRKPT
TRAP_TRACE

CLD_EXITED
CLD_KILLED
CLD_DUMPED
CLD_TRAPPED
CLD_STOPPED
CLD_CONTINUED

POLL_IN
POLL_OUT
POLL_MSG
POLL_ERR
POLL_PRI
POLL_HUP

sigfn_t bsd_signal(int sig, sigfn_t func);
sigfn_t sigset(int sig, sigfn_t func);

int killpg(pid_t, int);
int sigaltstack(in stack_t*, stack_t*);
int sighold(int);
int sigignore(int);
int siginterrupt(int, int);
int sigpause(int);
int sigrelse(int);
*/

//
// Timer (TMR)
//
/*
NOTE: This should actually be defined in core.sys.posix.time.
      It is defined here instead to break a circular import.

struct timespec
{
    time_t  tv_sec;
    int     tv_nsec;
}
*/

//
// Realtime Signals (RTS)
//
/*
struct sigevent
{
    int             sigev_notify;
    int             sigev_signo;
    sigval          sigev_value;
    void(*)(sigval) sigev_notify_function;
    pthread_attr_t* sigev_notify_attributes;
}

int sigqueue(pid_t, int, in sigval);
int sigtimedwait(in sigset_t*, siginfo_t*, in timespec*);
int sigwaitinfo(in sigset_t*, siginfo_t*);
*/

//
// Threads (THR)
//
/*
int pthread_kill(pthread_t, int);
int pthread_sigmask(int, in sigset_t*, sigset_t*);
*/

static assert(false, "core.sys.posix.signal unimplemented for this architechture");

