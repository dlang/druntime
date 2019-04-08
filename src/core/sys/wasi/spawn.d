module core.sys.wasi.spawn;

struct posix_spawnattr_t
{
    int __flags;
    pid_t __pgrp;
    sigset_t __def, __mask;
    int __prio, __pol;
    void *__fn;
    char[64-(void *).sizeof] __pad;
}

struct posix_spawn_file_actions_t
{
    int[2] __pad0;
    void *__actions;
    int[16] __pad;
}
