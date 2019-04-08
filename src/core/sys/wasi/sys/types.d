module core.sys.wasi.sys.types;

// private import core.sys.posix.config;
private import core.stdc.stdint;
public import core.stdc.stddef;

version (WebAssembly) {
  alias ubyte pthread_attr_t;
  alias ubyte pthread_mutex_t;
  alias ubyte mtx_t;
  alias ubyte pthread_cond_t;
  alias ubyte cnd_t;
  alias ubyte pthread_rwlock_t;
  alias ubyte pthread_barrier_t;
  alias int pthread_once_t;
  alias uint pthread_key_t;
  alias int pthread_spinlock_t;
  struct pthread_mutexattr_t { uint __attr; } ;
  struct pthread_condattr_t { uint __attr; } ;
  struct pthread_barrierattr_t{ uint __attr; } ;
  struct pthread_rwlockattr_t{ uint[2] __attr; } ;

  alias long      blksize_t;
  alias ulong     nlink_t;
  alias long      dev_t;
  alias long      blkcnt_t;
  alias ulong     ino_t;
  alias long      off_t;
  alias int       _Addr;
  alias int       pid_t;
  alias uint      uid_t;
  alias uint      gid_t;
  alias long      time_t;
  alias long      clock_t;
  alias ulong     pthread_t;
  alias _Addr     ssize_t;

}
