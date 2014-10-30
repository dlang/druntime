/**
 * D header file for POSIX.
 *
 * Copyright: Copyright Sean Kelly 2005 - 2009.
 * License:   $(WEB www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
 * Authors:   Sean Kelly,
              Alex Rønne Petersen
 * Standards: The Open Group Base Specifications Issue 6, IEEE Std 1003.1, 2004 Edition
 */

/*          Copyright Sean Kelly 2005 - 2009.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */
module core.sys.posix.sys.types;

private import core.sys.posix.config;
private import core.stdc.stdint;
public import core.stdc.stddef; // for size_t

version (Posix):
extern (C):

//
// bits/typesizes.h -- underlying types for *_t.
//
/*
__syscall_slong_t
__syscall_ulong_t
*/
version (linux)
{
    version (X86_64)
    {
        version (D_X32)
        {
            // X32 kernel interface is 64-bit.
            alias slong_t = long;
            alias ulong_t = ulong;
        }
        else
        {
            alias slong_t = c_long;
            alias ulong_t = c_ulong;
        }
    }
    else
    {
        alias slong_t = c_long;
        alias ulong_t = c_ulong;
    }
}
else
{
    alias slong_t = c_long;
    alias ulong_t = c_ulong;
}

//
// Required
//
/*
blkcnt_t
blksize_t
dev_t
gid_t
ino_t
mode_t
nlink_t
off_t
pid_t
size_t
ssize_t
time_t
uid_t
*/

version( linux )
{
  static if( __USE_FILE_OFFSET64 )
  {
    alias blkcnt_t = long;
    alias ino_t = ulong;
    alias off_t = long;
  }
  else
  {
    alias blkcnt_t = slong_t;
    alias ino_t = ulong_t;
    alias off_t = slong_t;
  }
    alias blksize_t = slong_t;
    alias dev_t = ulong;
    alias gid_t = uint;
    alias mode_t = uint;
    alias nlink_t = ulong_t;
    alias pid_t = int;
    //size_t (defined in core.stdc.stddef)
    alias ssize_t = c_long;
    alias time_t = slong_t;
    alias uid_t = uint;
}
else version( OSX )
{
    alias blkcnt_t = long;
    alias blksize_t = int;
    alias dev_t = int;
    alias gid_t = uint;
    version( DARWIN_USE_64_BIT_INODE ) {
        alias ino_t = ulong;
    } else {
        alias ino_t = uint;
    }
    alias mode_t = ushort;
    alias nlink_t = ushort;
    alias off_t = long;
    alias pid_t = int;
    //size_t (defined in core.stdc.stddef)
    alias ssize_t = c_long;
    alias time_t = c_long;
    alias uid_t = uint;
}
else version( FreeBSD )
{
    alias blkcnt_t = long;
    alias blksize_t = uint;
    alias dev_t = uint;
    alias gid_t = uint;
    alias ino_t = uint;
    alias mode_t = ushort;
    alias nlink_t = ushort;
    alias off_t = long;
    alias pid_t = int;
    //size_t (defined in core.stdc.stddef)
    alias ssize_t = c_long;
    alias time_t = c_long;
    alias uid_t = uint;
    alias fflags_t = uint;
}
else version (Solaris)
{
    alias caddr_t = char*;
    alias daddr_t = c_long;
    alias cnt_t = short;

    static if (__USE_FILE_OFFSET64)
    {
        alias blkcnt_t = long;
        alias ino_t = ulong;
        alias off_t = long;
    }
    else
    {
        alias blkcnt_t = c_long;
        alias ino_t = c_ulong;
        alias off_t = c_long;
    }

    version (D_LP64)
    {
        alias blkcnt64_t = blkcnt_t;
        alias ino64_t = ino_t;
        alias off64_t = off_t;
    }
    else
    {
        alias blkcnt64_t = long;
        alias ino64_t = ulong;
        alias off64_t = long;
    }

    alias blksize_t = uint;
    alias dev_t = c_ulong;
    alias gid_t = uid_t;
    alias mode_t = uint;
    alias nlink_t = uint;
    alias pid_t = int;
    alias ssize_t = c_long;
    alias time_t = c_long;
    alias uid_t = uint;
}
else version( Android )
{
    version(X86)
    {
        alias blkcnt_t = c_ulong;
        alias blksize_t = c_ulong;
        alias dev_t = uint;
        alias gid_t = uint;
        alias ino_t = c_ulong;
        alias mode_t = ushort;
        alias nlink_t = ushort;
        alias off_t = c_long;
        alias pid_t = int;
        alias ssize_t = c_long;
        alias time_t = c_long;
        alias uid_t = uint;
    }
    else
    {
        static assert(false, "Architecture not supported.");
    }
}
else
{
    static assert(false, "Unsupported platform");
}

//
// XOpen (XSI)
//
/*
clock_t
fsblkcnt_t
fsfilcnt_t
id_t
key_t
suseconds_t
useconds_t
*/

version( linux )
{
  static if( __USE_FILE_OFFSET64 )
  {
    alias fsblkcnt_t = ulong;
    alias fsfilcnt_t = ulong;
  }
  else
  {
    alias fsblkcnt_t = ulong_t;
    alias fsfilcnt_t = ulong_t;
  }
    alias clock_t = slong_t;
    alias id_t = uint;
    alias key_t = int;
    alias suseconds_t = slong_t;
    alias useconds_t = uint;
}
else version( OSX )
{
    alias fsblkcnt_t = uint;
    alias fsfilcnt_t = uint;
    alias clock_t = c_long;
    alias id_t = uint;
    // key_t
    alias suseconds_t = int;
    alias useconds_t = uint;
}
else version( FreeBSD )
{
    alias fsblkcnt_t = ulong;
    alias fsfilcnt_t = ulong;
    alias clock_t = c_long;
    alias id_t = long;
    alias key_t = c_long;
    alias suseconds_t = c_long;
    alias useconds_t = uint;
}
else version (Solaris)
{
    static if (__USE_FILE_OFFSET64)
    {
        alias fsblkcnt_t = ulong;
        alias fsfilcnt_t = ulong;
    }
    else
    {
        alias fsblkcnt_t = c_ulong;
        alias fsfilcnt_t = c_ulong;
    }

    alias clock_t = c_long;
    alias id_t = int;
    alias key_t = int;
    alias suseconds_t = c_long;
    alias useconds_t = uint;

    alias taskid_t = id_t;
    alias projid_t = id_t;
    alias poolid_t = id_t;
    alias zoneid_t = id_t;
    alias ctid_t = id_t;
}
else version( Android )
{
    version(X86)
    {
        alias fsblkcnt_t = c_ulong;
        alias fsfilcnt_t = c_ulong;
        alias clock_t = c_long;
        alias id_t = uint;
        alias key_t = int;
        alias suseconds_t = c_long;
        alias useconds_t = c_long;
    }
    else
    {
        static assert(false, "Architecture not supported.");
    }
}
else
{
    static assert(false, "Unsupported platform");
}

//
// Thread (THR)
//
/*
pthread_attr_t
pthread_cond_t
pthread_condattr_t
pthread_key_t
pthread_mutex_t
pthread_mutexattr_t
pthread_once_t
pthread_rwlock_t
pthread_rwlockattr_t
pthread_t
*/

version (linux)
{
    version (X86)
    {
        enum __SIZEOF_PTHREAD_ATTR_T = 36;
        enum __SIZEOF_PTHREAD_MUTEX_T = 24;
        enum __SIZEOF_PTHREAD_MUTEXATTR_T = 4;
        enum __SIZEOF_PTHREAD_COND_T = 48;
        enum __SIZEOF_PTHREAD_CONDATTR_T = 4;
        enum __SIZEOF_PTHREAD_RWLOCK_T = 32;
        enum __SIZEOF_PTHREAD_RWLOCKATTR_T = 8;
        enum __SIZEOF_PTHREAD_BARRIER_T = 20;
        enum __SIZEOF_PTHREAD_BARRIERATTR_T = 4;
    }
    else version (X86_64)
    {
        static if (__WORDSIZE == 64)
        {
            enum __SIZEOF_PTHREAD_ATTR_T = 56;
            enum __SIZEOF_PTHREAD_MUTEX_T = 40;
            enum __SIZEOF_PTHREAD_MUTEXATTR_T = 4;
            enum __SIZEOF_PTHREAD_COND_T = 48;
            enum __SIZEOF_PTHREAD_CONDATTR_T = 4;
            enum __SIZEOF_PTHREAD_RWLOCK_T = 56;
            enum __SIZEOF_PTHREAD_RWLOCKATTR_T = 8;
            enum __SIZEOF_PTHREAD_BARRIER_T = 32;
            enum __SIZEOF_PTHREAD_BARRIERATTR_T = 4;
        }
        else
        {
            enum __SIZEOF_PTHREAD_ATTR_T = 32;
            enum __SIZEOF_PTHREAD_MUTEX_T = 32;
            enum __SIZEOF_PTHREAD_MUTEXATTR_T = 4;
            enum __SIZEOF_PTHREAD_COND_T = 48;
            enum __SIZEOF_PTHREAD_CONDATTR_T = 4;
            enum __SIZEOF_PTHREAD_RWLOCK_T = 44;
            enum __SIZEOF_PTHREAD_RWLOCKATTR_T = 8;
            enum __SIZEOF_PTHREAD_BARRIER_T = 20;
            enum __SIZEOF_PTHREAD_BARRIERATTR_T = 4;
        }
    }
    else version (AArch64)
    {
        enum __SIZEOF_PTHREAD_ATTR_T = 64;
        enum __SIZEOF_PTHREAD_MUTEX_T = 48;
        enum __SIZEOF_PTHREAD_MUTEXATTR_T = 8;
        enum __SIZEOF_PTHREAD_COND_T = 48;
        enum __SIZEOF_PTHREAD_CONDATTR_T = 8;
        enum __SIZEOF_PTHREAD_RWLOCK_T = 56;
        enum __SIZEOF_PTHREAD_RWLOCKATTR_T = 8;
        enum __SIZEOF_PTHREAD_BARRIER_T = 32;
        enum __SIZEOF_PTHREAD_BARRIERATTR_T = 8;
    }
    else version (ARM)
    {
        enum __SIZEOF_PTHREAD_ATTR_T = 36;
        enum __SIZEOF_PTHREAD_MUTEX_T = 24;
        enum __SIZEOF_PTHREAD_MUTEXATTR_T = 4;
        enum __SIZEOF_PTHREAD_COND_T = 48;
        enum __SIZEOF_PTHREAD_CONDATTR_T = 4;
        enum __SIZEOF_PTHREAD_RWLOCK_T = 32;
        enum __SIZEOF_PTHREAD_RWLOCKATTR_T = 8;
        enum __SIZEOF_PTHREAD_BARRIER_T = 20;
        enum __SIZEOF_PTHREAD_BARRIERATTR_T = 4;
    }
    else version (IA64)
    {
        enum __SIZEOF_PTHREAD_ATTR_T = 56;
        enum __SIZEOF_PTHREAD_MUTEX_T = 40;
        enum __SIZEOF_PTHREAD_MUTEXATTR_T = 4;
        enum __SIZEOF_PTHREAD_COND_T = 48;
        enum __SIZEOF_PTHREAD_CONDATTR_T = 4;
        enum __SIZEOF_PTHREAD_RWLOCK_T = 56;
        enum __SIZEOF_PTHREAD_RWLOCKATTR_T = 8;
        enum __SIZEOF_PTHREAD_BARRIER_T = 32;
        enum __SIZEOF_PTHREAD_BARRIERATTR_T = 4;
    }
    else version (MIPS32)
    {
        enum __SIZEOF_PTHREAD_ATTR_T = 36;
        enum __SIZEOF_PTHREAD_MUTEX_T = 24;
        enum __SIZEOF_PTHREAD_MUTEXATTR_T = 4;
        enum __SIZEOF_PTHREAD_COND_T = 48;
        enum __SIZEOF_PTHREAD_CONDATTR_T = 4;
        enum __SIZEOF_PTHREAD_RWLOCK_T = 32;
        enum __SIZEOF_PTHREAD_RWLOCKATTR_T = 8;
        enum __SIZEOF_PTHREAD_BARRIER_T = 20;
        enum __SIZEOF_PTHREAD_BARRIERATTR_T = 4;
    }
    else version (MIPS64)
    {
        enum __SIZEOF_PTHREAD_ATTR_T = 56;
        enum __SIZEOF_PTHREAD_MUTEX_T = 40;
        enum __SIZEOF_PTHREAD_MUTEXATTR_T = 4;
        enum __SIZEOF_PTHREAD_COND_T = 48;
        enum __SIZEOF_PTHREAD_CONDATTR_T = 4;
        enum __SIZEOF_PTHREAD_RWLOCK_T = 56;
        enum __SIZEOF_PTHREAD_RWLOCKATTR_T = 8;
        enum __SIZEOF_PTHREAD_BARRIER_T = 32;
        enum __SIZEOF_PTHREAD_BARRIERATTR_T = 4;
    }
    else version (PPC)
    {
        enum __SIZEOF_PTHREAD_ATTR_T = 36;
        enum __SIZEOF_PTHREAD_MUTEX_T = 24;
        enum __SIZEOF_PTHREAD_MUTEXATTR_T = 4;
        enum __SIZEOF_PTHREAD_COND_T = 48;
        enum __SIZEOF_PTHREAD_CONDATTR_T = 4;
        enum __SIZEOF_PTHREAD_RWLOCK_T = 32;
        enum __SIZEOF_PTHREAD_RWLOCKATTR_T = 8;
        enum __SIZEOF_PTHREAD_BARRIER_T = 20;
        enum __SIZEOF_PTHREAD_BARRIERATTR_T = 4;
    }
    else version (PPC64)
    {
        enum __SIZEOF_PTHREAD_ATTR_T = 56;
        enum __SIZEOF_PTHREAD_MUTEX_T = 40;
        enum __SIZEOF_PTHREAD_MUTEXATTR_T = 4;
        enum __SIZEOF_PTHREAD_COND_T = 48;
        enum __SIZEOF_PTHREAD_CONDATTR_T = 4;
        enum __SIZEOF_PTHREAD_RWLOCK_T = 56;
        enum __SIZEOF_PTHREAD_RWLOCKATTR_T = 8;
        enum __SIZEOF_PTHREAD_BARRIER_T = 32;
        enum __SIZEOF_PTHREAD_BARRIERATTR_T = 4;
    }
    else version (S390)
    {
        enum __SIZEOF_PTHREAD_ATTR_T = 36;
        enum __SIZEOF_PTHREAD_MUTEX_T = 24;
        enum __SIZEOF_PTHREAD_MUTEXATTR_T = 4;
        enum __SIZEOF_PTHREAD_COND_T = 48;
        enum __SIZEOF_PTHREAD_CONDATTR_T = 4;
        enum __SIZEOF_PTHREAD_RWLOCK_T = 32;
        enum __SIZEOF_PTHREAD_RWLOCKATTR_T = 8;
        enum __SIZEOF_PTHREAD_BARRIER_T = 20;
        enum __SIZEOF_PTHREAD_BARRIERATTR_T = 4;
    }
    else version (S390X)
    {
        enum __SIZEOF_PTHREAD_ATTR_T = 56;
        enum __SIZEOF_PTHREAD_MUTEX_T = 40;
        enum __SIZEOF_PTHREAD_MUTEXATTR_T = 4;
        enum __SIZEOF_PTHREAD_COND_T = 48;
        enum __SIZEOF_PTHREAD_CONDATTR_T = 4;
        enum __SIZEOF_PTHREAD_RWLOCK_T = 56;
        enum __SIZEOF_PTHREAD_RWLOCKATTR_T = 8;
        enum __SIZEOF_PTHREAD_BARRIER_T = 32;
        enum __SIZEOF_PTHREAD_BARRIERATTR_T = 4;
    }
    else
    {
        static assert (false, "Unsupported platform");
    }

    union pthread_attr_t
    {
        byte[__SIZEOF_PTHREAD_ATTR_T] __size;
        c_long __align;
    }

    private alias __atomic_lock_t = int;

    private struct _pthread_fastlock
    {
        c_long          __status;
        __atomic_lock_t __spinlock;
    }

    private alias _pthread_descr = void*;

    union pthread_cond_t
    {
        byte[__SIZEOF_PTHREAD_COND_T] __size;
        long  __align;
    }

    union pthread_condattr_t
    {
        byte[__SIZEOF_PTHREAD_CONDATTR_T] __size;
        int __align;
    }

    alias pthread_key_t = uint;

    union pthread_mutex_t
    {
        byte[__SIZEOF_PTHREAD_MUTEX_T] __size;
        c_long __align;
    }

    union pthread_mutexattr_t
    {
        byte[__SIZEOF_PTHREAD_MUTEXATTR_T] __size;
        int __align;
    }

    alias pthread_once_t = int;

    struct pthread_rwlock_t
    {
        byte[__SIZEOF_PTHREAD_RWLOCK_T] __size;
        c_long __align;
    }

    struct pthread_rwlockattr_t
    {
        byte[__SIZEOF_PTHREAD_RWLOCKATTR_T] __size;
        c_long __align;
    }

    alias pthread_t = c_ulong;
}
else version( OSX )
{
    version( D_LP64 )
    {
        enum __PTHREAD_SIZE__               = 1168;
        enum __PTHREAD_ATTR_SIZE__          = 56;
        enum __PTHREAD_MUTEXATTR_SIZE__     = 8;
        enum __PTHREAD_MUTEX_SIZE__         = 56;
        enum __PTHREAD_CONDATTR_SIZE__      = 8;
        enum __PTHREAD_COND_SIZE__          = 40;
        enum __PTHREAD_ONCE_SIZE__          = 8;
        enum __PTHREAD_RWLOCK_SIZE__        = 192;
        enum __PTHREAD_RWLOCKATTR_SIZE__    = 16;
    }
    else
    {
        enum __PTHREAD_SIZE__               = 596;
        enum __PTHREAD_ATTR_SIZE__          = 36;
        enum __PTHREAD_MUTEXATTR_SIZE__     = 8;
        enum __PTHREAD_MUTEX_SIZE__         = 40;
        enum __PTHREAD_CONDATTR_SIZE__      = 4;
        enum __PTHREAD_COND_SIZE__          = 24;
        enum __PTHREAD_ONCE_SIZE__          = 4;
        enum __PTHREAD_RWLOCK_SIZE__        = 124;
        enum __PTHREAD_RWLOCKATTR_SIZE__    = 12;
    }

    struct pthread_handler_rec
    {
      void function(void*)  __routine;
      void*                 __arg;
      pthread_handler_rec*  __next;
    }

    struct pthread_attr_t
    {
        c_long                              __sig;
        byte[__PTHREAD_ATTR_SIZE__]         __opaque;
    }

    struct pthread_cond_t
    {
        c_long                              __sig;
        byte[__PTHREAD_COND_SIZE__]         __opaque;
    }

    struct pthread_condattr_t
    {
        c_long                              __sig;
        byte[__PTHREAD_CONDATTR_SIZE__]     __opaque;
    }

    alias pthread_key_t = c_ulong;

    struct pthread_mutex_t
    {
        c_long                              __sig;
        byte[__PTHREAD_MUTEX_SIZE__]        __opaque;
    }

    struct pthread_mutexattr_t
    {
        c_long                              __sig;
        byte[__PTHREAD_MUTEXATTR_SIZE__]    __opaque;
    }

    struct pthread_once_t
    {
        c_long                              __sig;
        byte[__PTHREAD_ONCE_SIZE__]         __opaque;
    }

    struct pthread_rwlock_t
    {
        c_long                              __sig;
        byte[__PTHREAD_RWLOCK_SIZE__]       __opaque;
    }

    struct pthread_rwlockattr_t
    {
        c_long                              __sig;
        byte[__PTHREAD_RWLOCKATTR_SIZE__]   __opaque;
    }

    private struct _opaque_pthread_t
    {
        c_long                  __sig;
        pthread_handler_rec*    __cleanup_stack;
        byte[__PTHREAD_SIZE__]  __opaque;
    }

    alias pthread_t = _opaque_pthread_t*;
}
else version( FreeBSD )
{
    alias lwpid_t = int;

    alias pthread_attr_t = void*;
    alias pthread_cond_t = void*;
    alias pthread_condattr_t = void*;
    alias pthread_key_t = void*;
    alias pthread_mutex_t = void*;
    alias pthread_mutexattr_t = void*;
    alias pthread_once_t = void*;
    alias pthread_rwlock_t = void*;
    alias pthread_rwlockattr_t = void*;
    alias pthread_t = void*;
}
else version (Solaris)
{
    alias pthread_t = uint;

    struct pthread_attr_t
    {
        void* __pthread_attrp;
    }

    struct pthread_cond_t
    {
        struct ___pthread_cond_flags
        {
            ubyte[4] __pthread_cond_flags;
            ushort __pthread_cond_type;
            ushort __pthread_cond_magic;
        }

        ___pthread_cond_flags __pthread_cond_flags;
        ulong __pthread_cond_data;
    }

    struct pthread_condattr_t
    {
        void* __pthread_condattrp;
    }

    struct pthread_rwlock_t
    {
        int __pthread_rwlock_readers;
        ushort __pthread_rwlock_type;
        ushort __pthread_rwlock_magic;
        pthread_mutex_t __pthread_rwlock_mutex;
        pthread_cond_t __pthread_rwlock_readercv;
        pthread_cond_t __pthread_rwlock_writercv;
    }

    struct pthread_rwlockattr_t
    {
        void* __pthread_rwlockattrp;
    }

    struct pthread_mutex_t
    {
        struct ___pthread_mutex_flags
        {
            ushort __pthread_mutex_flag1;
            ubyte __pthread_mutex_flag2;
            ubyte __pthread_mutex_ceiling;
            ushort __pthread_mutex_type;
            ushort __pthread_mutex_magic; 
        }

        ___pthread_mutex_flags __pthread_mutex_flags;

        union ___pthread_mutex_lock
        {
            struct ___pthread_mutex_lock64
            {
                ubyte[8] __pthread_mutex_pad;
            }

            ___pthread_mutex_lock64 __pthread_mutex_lock64;

            struct ___pthread_mutex_lock32
            {
                uint __pthread_ownerpid;
                uint __pthread_lockword;
            }

            ___pthread_mutex_lock32 __pthread_mutex_lock32;
            ulong __pthread_mutex_owner64;
        }

        ___pthread_mutex_lock __pthread_mutex_lock;
        ulong __pthread_mutex_data;
    }

    struct pthread_mutexattr_t
    {
        void* __pthread_mutexattrp;
    }

    struct pthread_once_t
    {
        ulong[4] __pthread_once_pad;
    }

    alias pthread_key_t = uint;
}
else version( Android )
{
    version(X86)
    {
        struct pthread_attr_t
        {
            uint    flags;
            void*   stack_base;
            size_t  stack_size;
            size_t  guard_size;
            int     sched_policy;
            int     sched_priority;
        }
    }
    else
    {
        static assert(false, "Architecture not supported.");
    }

    struct pthread_cond_t
    {
        int value; //volatile
    }

    alias pthread_condattr_t = c_long;
    alias pthread_key_t = int;

    struct pthread_mutex_t
    {
        int value; //volatile
    }

    alias pthread_mutexattr_t = c_long;
    alias pthread_once_t = int; //volatile

    struct pthread_rwlock_t
    {
        pthread_mutex_t  lock;
        pthread_cond_t   cond;
        int              numLocks;
        int              writerThreadId;
        int              pendingReaders;
        int              pendingWriters;
        void*[4]         reserved;
    }

    alias pthread_rwlockattr_t = int;
    alias pthread_t = c_long;
}
else
{
    static assert(false, "Unsupported platform");
}

//
// Barrier (BAR)
//
/*
pthread_barrier_t
pthread_barrierattr_t
*/

version( linux )
{
    struct pthread_barrier_t
    {
        byte[__SIZEOF_PTHREAD_BARRIER_T] __size;
        c_long __align;
    }

    struct pthread_barrierattr_t
    {
        byte[__SIZEOF_PTHREAD_BARRIERATTR_T] __size;
        int __align;
    }
}
else version( FreeBSD )
{
    alias pthread_barrier_t = void*;
    alias pthread_barrierattr_t = void*;
}
else version( OSX )
{
}
else version (Solaris)
{
    struct pthread_barrier_t
    {
        uint __pthread_barrier_count;
        uint __pthread_barrier_current;
        ulong __pthread_barrier_cycle;
        ulong __pthread_barrier_reserved;
        pthread_mutex_t __pthread_barrier_lock;
        pthread_cond_t __pthread_barrier_cond; 
    }

    struct pthread_barrierattr_t
    {
        void* __pthread_barrierattrp;
    }
}
else version( Android )
{
}
else
{
    static assert(false, "Unsupported platform");
}

//
// Spin (SPN)
//
/*
pthread_spinlock_t
*/

version( linux )
{
    alias pthread_spinlock_t = int; // volatile
}
else version( FreeBSD )
{
    alias pthread_spinlock_t = void*;
}
else version (Solaris)
{
    alias pthread_spinlock_t = pthread_mutex_t;
}

//
// Timer (TMR)
//
/*
clockid_t
timer_t
*/

//
// Trace (TRC)
//
/*
trace_attr_t
trace_event_id_t
trace_event_set_t
trace_id_t
*/
