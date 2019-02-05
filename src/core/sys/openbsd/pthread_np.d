/**
 * D header file for OpenBSD.
 */
module core.sys.openbsd.pthread_np;

version (OpenBSD):
extern (C) nothrow @nogc:

public import core.sys.posix.sys.types;
import core.sys.posix.signal : stack_t;

alias pthread_switch_routine_t = void function(pthread_t, pthread_t);

int pthread_mutexattr_getkind_np(pthread_mutexattr_t);
int pthread_mutexattr_setkind_np(pthread_mutexattr_t *, int);
void pthread_set_name_np(pthread_t, const(char)*);
int pthread_stackseg_np(pthread_t, stack_t*);
int pthread_main_np();

