module core.sys.wasi.signal;

version (WebAssembly)
{
    enum SIGHUP    = 1;
    enum SIGQUIT   = 3;
    enum SIGTRAP   = 5;
    enum SIGBUS    = 7;
    enum SIGKILL   = 9;
    enum SIGUSR1   = 10;
    enum SIGUSR2   = 12;
    enum SIGPIPE   = 13;
    enum SIGALRM   = 14;
    enum SIGCHLD   = 16;
    enum SIGCONT   = 17;
    enum SIGSTOP   = 18;
    enum SIGTSTP   = 19;
    enum SIGTTIN   = 20;
    enum SIGTTOU   = 21;
    enum SIGURG    = 22;
    enum SIGXCPU   = 23;
    enum SIGXFSZ   = 24;
    enum SIGVTALRM = 25;
    enum SIGPROF   = 26;
    enum SIGWINCH  = 27;
    enum SIGPOLL   = 28;
    enum SIGPWR    = 29;
    enum SIGSYS    = 30;


    struct sigaltstack {
        void *ss_sp;
        int ss_flags;
        size_t ss_size;
    }
    alias stack_t = sigaltstack;

    struct timespec {
        time_t tv_sec;
        c_long tv_nsec;
    }
