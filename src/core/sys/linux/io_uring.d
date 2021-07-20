/**
 * D header file for the io_uring interface.
 * Available since Linux 5.1
 *
 * Copyright: Copyright Jens Axboe 2019,
 *            Copyright Christoph Hellwig 2019.
 * License : $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 * Authors : Luís Ferreira
 */
module core.sys.linux.io_uring;

version (linux):

import core.sys.linux.fs : __kernel_rwf_t;

extern (C):
@system:
@nogc:
nothrow:
@system:

/*
 * IO submission data structure (Submission Queue Entry)
 */
struct io_uring_sqe
{
    ubyte opcode; /* type of operation for this sqe */
    ubyte flags; /* IOSQE_ flags */
    ushort ioprio; /* ioprio for the request */
    int fd; /* file descriptor to do IO on */
    union
    {
        ulong off; /* offset into file */
        ulong addr2;
    }

    union
    {
        ulong addr; /* pointer to buffer or iovecs */
        ulong splice_off_in;
    }

    uint len; /* buffer size or number of iovecs */
    union
    {
        __kernel_rwf_t rw_flags;
        uint fsync_flags;
        ushort poll_events; /* compatibility */
        uint poll32_events; /* word-reversed for BE */
        uint sync_range_flags;
        uint msg_flags;
        uint timeout_flags;
        uint accept_flags;
        uint cancel_flags;
        uint open_flags;
        uint statx_flags;
        uint fadvise_advice;
        uint splice_flags;
        uint rename_flags;
        uint unlink_flags;
    }

    ulong user_data; /* data to be passed back at completion time */
    union
    {
        struct
        {
            /* pack this to avoid bogus arm OABI complaints */
            union
            {
                align (1):

                /* index into fixed buffers, if used */
                ushort buf_index;
                /* for grouped buffer selection */
                ushort buf_group;
            }

            /* personality to use, if used */
            ushort personality;
            int splice_fd_in;
        }

        ulong[3] __pad2;
    }
}

enum
{
    IOSQE_FIXED_FILE_BIT = 0,
    IOSQE_IO_DRAIN_BIT = 1,
    IOSQE_IO_LINK_BIT = 2,
    IOSQE_IO_HARDLINK_BIT = 3,
    IOSQE_ASYNC_BIT = 4,
    IOSQE_BUFFER_SELECT_BIT = 5
}

/*
 * sqe->flags
 */
/* use fixed fileset */
enum IOSQE_FIXED_FILE = 1U << IOSQE_FIXED_FILE_BIT;
/* issue after inflight IO */
enum IOSQE_IO_DRAIN = 1U << IOSQE_IO_DRAIN_BIT;
/* links next sqe */
enum IOSQE_IO_LINK = 1U << IOSQE_IO_LINK_BIT;
/* like LINK, but stronger */
enum IOSQE_IO_HARDLINK = 1U << IOSQE_IO_HARDLINK_BIT;
/* always go async */
enum IOSQE_ASYNC = 1U << IOSQE_ASYNC_BIT;
/* select buffer from sqe->buf_group */
enum IOSQE_BUFFER_SELECT = 1U << IOSQE_BUFFER_SELECT_BIT;

/*
 * io_uring_setup() flags
 */
enum IORING_SETUP_IOPOLL = 1U << 0; /* io_context is polled */
enum IORING_SETUP_SQPOLL = 1U << 1; /* SQ poll thread */
enum IORING_SETUP_SQ_AFF = 1U << 2; /* sq_thread_cpu is valid */
enum IORING_SETUP_CQSIZE = 1U << 3; /* app defines CQ size */
enum IORING_SETUP_CLAMP = 1U << 4; /* clamp SQ/CQ ring sizes */
enum IORING_SETUP_ATTACH_WQ = 1U << 5; /* attach to existing wq */
enum IORING_SETUP_R_DISABLED = 1U << 6; /* start with ring disabled */

enum
{
    IORING_OP_NOP = 0,
    IORING_OP_READV = 1,
    IORING_OP_WRITEV = 2,
    IORING_OP_FSYNC = 3,
    IORING_OP_READ_FIXED = 4,
    IORING_OP_WRITE_FIXED = 5,
    IORING_OP_POLL_ADD = 6,
    IORING_OP_POLL_REMOVE = 7,
    IORING_OP_SYNC_FILE_RANGE = 8,
    IORING_OP_SENDMSG = 9,
    IORING_OP_RECVMSG = 10,
    IORING_OP_TIMEOUT = 11,
    IORING_OP_TIMEOUT_REMOVE = 12,
    IORING_OP_ACCEPT = 13,
    IORING_OP_ASYNC_CANCEL = 14,
    IORING_OP_LINK_TIMEOUT = 15,
    IORING_OP_CONNECT = 16,
    IORING_OP_FALLOCATE = 17,
    IORING_OP_OPENAT = 18,
    IORING_OP_CLOSE = 19,
    IORING_OP_FILES_UPDATE = 20,
    IORING_OP_STATX = 21,
    IORING_OP_READ = 22,
    IORING_OP_WRITE = 23,
    IORING_OP_FADVISE = 24,
    IORING_OP_MADVISE = 25,
    IORING_OP_SEND = 26,
    IORING_OP_RECV = 27,
    IORING_OP_OPENAT2 = 28,
    IORING_OP_EPOLL_CTL = 29,
    IORING_OP_SPLICE = 30,
    IORING_OP_PROVIDE_BUFFERS = 31,
    IORING_OP_REMOVE_BUFFERS = 32,
    IORING_OP_TEE = 33,
    IORING_OP_SHUTDOWN = 34,
    IORING_OP_RENAMEAT = 35,
    IORING_OP_UNLINKAT = 36,

    /* this goes last, obviously */
    IORING_OP_LAST = 37
}

/*
 * sqe->fsync_flags
 */
enum IORING_FSYNC_DATASYNC = 1U << 0;

/*
 * sqe->timeout_flags
 */
enum IORING_TIMEOUT_ABS = 1U << 0;
enum IORING_TIMEOUT_UPDATE = 1U << 1;

/*
 * sqe->splice_flags
 * extends splice(2) flags
 */
enum SPLICE_F_FD_IN_FIXED = 1U << 31; /* the last bit of __u32 */

/*
 * IO completion data structure (Completion Queue Entry)
 */
struct io_uring_cqe
{
    ulong user_data; /* sqe->data submission passed back */
    int res; /* result code for this event */
    uint flags;
}

/*
 * cqe->flags
 *
 * IORING_CQE_F_BUFFER If set, the upper 16 bits are the buffer ID
 */
enum IORING_CQE_F_BUFFER = 1U << 0;

enum
{
    IORING_CQE_BUFFER_SHIFT = 16
}

/*
 * Magic offsets for the application to mmap the data it needs
 */
enum IORING_OFF_SQ_RING = 0UL;
enum IORING_OFF_CQ_RING = 0x8000000UL;
enum IORING_OFF_SQES = 0x10000000UL;

/*
 * Filled with the offset for mmap(2)
 */
struct io_sqring_offsets
{
    uint head;
    uint tail;
    uint ring_mask;
    uint ring_entries;
    uint flags;
    uint dropped;
    uint array;
    uint resv1;
    ulong resv2;
}

/*
 * sq_ring->flags
 */
enum IORING_SQ_NEED_WAKEUP = 1U << 0; /* needs io_uring_enter wakeup */
enum IORING_SQ_CQ_OVERFLOW = 1U << 1; /* CQ ring is overflown */

struct io_cqring_offsets
{
    uint head;
    uint tail;
    uint ring_mask;
    uint ring_entries;
    uint overflow;
    uint cqes;
    uint flags;
    uint resv1;
    ulong resv2;
}

/*
 * cq_ring->flags
 */

/* disable eventfd notifications */
enum IORING_CQ_EVENTFD_DISABLED = 1U << 0;

/*
 * io_uring_enter(2) flags
 */
enum IORING_ENTER_GETEVENTS = 1U << 0;
enum IORING_ENTER_SQ_WAKEUP = 1U << 1;
enum IORING_ENTER_SQ_WAIT = 1U << 2;
enum IORING_ENTER_EXT_ARG = 1U << 3;

/*
 * Passed in for io_uring_setup(2). Copied back with updated info on success
 */
struct io_uring_params
{
    uint sq_entries;
    uint cq_entries;
    uint flags;
    uint sq_thread_cpu;
    uint sq_thread_idle;
    uint features;
    uint wq_fd;
    uint[3] resv;
    io_sqring_offsets sq_off;
    io_cqring_offsets cq_off;
}

/*
 * io_uring_params->features flags
 */
enum IORING_FEAT_SINGLE_MMAP = 1U << 0;
enum IORING_FEAT_NODROP = 1U << 1;
enum IORING_FEAT_SUBMIT_STABLE = 1U << 2;
enum IORING_FEAT_RW_CUR_POS = 1U << 3;
enum IORING_FEAT_CUR_PERSONALITY = 1U << 4;
enum IORING_FEAT_FAST_POLL = 1U << 5;
enum IORING_FEAT_POLL_32BITS = 1U << 6;
enum IORING_FEAT_SQPOLL_NONFIXED = 1U << 7;
enum IORING_FEAT_EXT_ARG = 1U << 8;

/*
 * io_uring_register(2) opcodes and arguments
 */
enum
{
    IORING_REGISTER_BUFFERS = 0,
    IORING_UNREGISTER_BUFFERS = 1,
    IORING_REGISTER_FILES = 2,
    IORING_UNREGISTER_FILES = 3,
    IORING_REGISTER_EVENTFD = 4,
    IORING_UNREGISTER_EVENTFD = 5,
    IORING_REGISTER_FILES_UPDATE = 6,
    IORING_REGISTER_EVENTFD_ASYNC = 7,
    IORING_REGISTER_PROBE = 8,
    IORING_REGISTER_PERSONALITY = 9,
    IORING_UNREGISTER_PERSONALITY = 10,
    IORING_REGISTER_RESTRICTIONS = 11,
    IORING_REGISTER_ENABLE_RINGS = 12,

    /* this goes last */
    IORING_REGISTER_LAST = 13
}

struct io_uring_files_update
{
    uint offset;
    uint resv;
    /* __s32 * */
    ulong fds;
}

enum IO_URING_OP_SUPPORTED = 1U << 0;

struct io_uring_probe_op
{
    ubyte op;
    ubyte resv;
    ushort flags; /* IO_URING_OP_* flags */
    uint resv2;
}

struct io_uring_probe
{
    ubyte last_op; /* last opcode supported */
    ubyte ops_len; /* length of ops[] array below */
    ushort resv;
    uint[3] resv2;
    io_uring_probe_op[0] ops;
}

struct io_uring_restriction
{
    ushort opcode;

    union
    {
        ubyte register_op; /* IORING_RESTRICTION_REGISTER_OP */
        ubyte sqe_op; /* IORING_RESTRICTION_SQE_OP */
        ubyte sqe_flags; /* IORING_RESTRICTION_SQE_FLAGS_* */
    }

    ubyte resv;
    uint[3] resv2;
}

/*
 * io_uring_restriction->opcode values
 */
enum
{
    /* Allow an io_uring_register(2) opcode */
    IORING_RESTRICTION_REGISTER_OP = 0,

    /* Allow an sqe opcode */
    IORING_RESTRICTION_SQE_OP = 1,

    /* Allow sqe flags */
    IORING_RESTRICTION_SQE_FLAGS_ALLOWED = 2,

    /* Require sqe flags (these flags must be set on each submission) */
    IORING_RESTRICTION_SQE_FLAGS_REQUIRED = 3,

    IORING_RESTRICTION_LAST = 4
}

struct io_uring_getevents_arg
{
    ulong sigmask;
    uint sigmask_sz;
    uint pad;
    ulong ts;
}
