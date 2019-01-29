/**
 * D header file for OpenBSD
 *
 * https://cvsweb.openbsd.org/src/sys/sys/event.h
 */
module core.sys.openbsd.sys.event;

version (OpenBSD):
    extern (C):

    import core.stdc.stdint;
    import core.sys.posix.time;

    enum
    {
        EVFILT_READ     =  -1,
        EVFILT_WRITE    =  -2,
        EVFILT_AIO      =  -3, /* attached to aio requests */
        EVFILT_VNODE    =  -4, /* attached to vnodes */
        EVFILT_PROC     =  -5, /* attached to struct process */
        EVFILT_SIGNAL   =  -6, /* attached to struct process */
        EVFILT_TIMER    =  -7, /* timers */
        EVFILT_DEVICE   =  -8, /* devices */
        EVFILT_SYSCOUNT =   8,
    }

    extern(D) void EV_SET(kevent_t* kevp, typeof(kevent_t.tupleof) args)
    {
        *kevp = kevent_t(args);
    }

    struct kevent_t
    {
        uintptr_t    ident;     // identifier for this event
        short        filter;    // filter for event
        ushort       flags;     // action flags for kqueue
        uint         fflags;    // filter flag value
        ulong        data;      // filter data value
        void         *udata;    // opaque user data identifier
    }

    enum
    {
        /* actions */
        EV_ADD      = 0x0001,   // add event to kq (implies enable)
        EV_DELETE   = 0x0002,   // delete event from kq
        EV_ENABLE   = 0x0004,   // enable event
        EV_DISABLE  = 0x0008,   // disable event (not reported)

        /* flags */
        EV_ONESHOT  = 0x0010,   // only report one occurrence
        EV_CLEAR    = 0x0020,   // clear event state after reporting
        EV_RECEIPT  = 0x0040,   // force EV_ERROR on success, data=0
        EV_DISPATCH = 0x0080,   // diable event after reporting

        EV_SYSFLAGS = 0xF000,   // reserved by system
        EV_FLAG1    = 0x2000,   // filter-specific flag

        /* returned values */
        EV_EOF      = 0x8000,   // EOF detected
        EV_ERROR    = 0x4000    // error, data contains errno
    }
    
    enum
    {
        /*
         * data/hint flags for EVFILT_{READ|WRITE}, shared with userspace
         */
        NOTE_LOWAT      = 0x0001,       // low water mark
        NOTE_EOF        = 0x0002,       // return on EOF

        /*
         * data/hint flags for EVFILT_VNODE, shared with userspace
         */
        NOTE_DELETE     = 0x0001,       // vnode was removed
        NOTE_WRITE      = 0x0002,       // data contents changed
        NOTE_EXTEND     = 0x0004,       // size increased
        NOTE_ATTRIB     = 0x0008,       // attributes changed
        NOTE_LINK       = 0x0010,       // link count changed
        NOTE_RENAME     = 0x0020,       // vnode was renamed
        NOTE_REVOKE     = 0x0040,       // vnode access was revoked
        NOTE_TRUNCATE   = 0x0080,       // vnode was truncated
        /*
         * data/hint flags for EVFILT_PROC, shared with userspace
         */
        NOTE_EXIT       = 0x80000000,   // process exited
        NOTE_FORK       = 0x40000000,   // process forked
        NOTE_EXEC       = 0x20000000,   // process exec'd
        NOTE_PCTRLMASK  = 0xf0000000,   // mask for hint bits
        NOTE_PDATAMASK  = 0x000fffff,   // mask for pid

        /* additional flags for EVFILT_PROC */
        NOTE_TRACK      = 0x00000001,   // follow across forks
        NOTE_TRACKERR   = 0x00000002,   // could not track child
        NOTE_CHILD      = 0x00000004,   // am a child process

        /* data/hint flags for EVFILT_DEVICE, shared with userspace */
        NOTE_CHANGE     = 0x00000001,   // device change event
    }

    int kqueue();
    int kevent(int kq, const kevent_t *changelist, int nchanges,
                kevent_t *eventlist, int nevents,
                const timespec *timeout);

