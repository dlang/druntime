module core.sys.wasi.time;

// private import core.sys.posix.config;
public import core.stdc.time;
// public import core.sys.posix.sys.types;
// public import core.sys.posix.signal; // for sigevent

version (WebAssembly):
extern (C):
nothrow:
@nogc:

//
// Required (defined in core.stdc.time)
//
/*
char* asctime(in tm*);
clock_t clock();
char* ctime(in time_t*);
double difftime(time_t, time_t);
tm* gmtime(in time_t*);
tm* localtime(in time_t*);
time_t mktime(tm*);
size_t strftime(char*, size_t, in char*, in tm*);
time_t time(time_t*);
*/

enum CLOCK_MONOTONIC = 1;
