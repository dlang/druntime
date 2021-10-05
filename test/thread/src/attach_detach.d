version (Posix)
{

import core.thread;
import core.sys.posix.pthread;
import core.stdc.stdlib;
import core.stdc.time;

// This program creates threads that are started outside of D runtime and
// stresses attaching and detaching those threads to the D runtime.

struct MyThread
{
    pthread_t t;
    bool stopRequested;
}

enum totalThreads = 4;

enum runTimeSeconds = 5;    // Must be less than timelimit's
MyThread[totalThreads] threads;

auto exerciseGC() {
    int[] arr;
    foreach (i; 0 .. 1000)
        arr ~= i;
    return arr;
}

// This represents an API function of a non-D framework. Since we don't have any
// control on the lifetime of this thread, we have to attach upon entry and
// detach upon exit.
void api_foo()
{
    auto t = thread_attachThis();
    scope(exit)
    {
        // Pick a detachment method
        final switch (rand() % 3)
        {
        case 0:
            thread_detachThis();
            break;
        case 1:
            thread_detachByAddr(t.id);
            // thread_setThis must be called by the detached thread; it happens
            // to be the case in this test.
            thread_setThis(null);
            break;
        case 2:
            thread_detachInstance(t);
            // thread_setThis must be called by the detached thread; it happens
            // to be the case in this test.
            thread_setThis(null);
            break;
        }
    }

    assert_thread_is_attached(t.id);
    cast(void)exerciseGC();
}

// Make calls to an api function and exit when requested
extern(C) void * thread_func(void * arg)
{
    MyThread *t = cast(MyThread*)arg;

    while (!t.stopRequested)
        api_foo();

    return arg;
}

void start_thread(ref MyThread t)
{
    pthread_attr_t attr;
    int err = pthread_attr_init(&attr);
    assert(!err);

    t.stopRequested = false;
    err = pthread_create(&t.t, &attr, &thread_func, cast(void*)&t);
    assert(!err);

    err = pthread_attr_destroy(&attr);
    assert(!err);
}

void start_threads()
{
    foreach (ref t; threads)
        start_thread(t);
}

void stop_thread(ref MyThread t)
{
    t.stopRequested = true;
    const err = pthread_join(t.t, null);
    assert(!err);

    assert_thread_is_gone(t.t);
}

void stop_threads()
{
    foreach (ref t; threads)
        stop_thread(t);
}

void assert_thread_is_attached(pthread_t tid)
{
    size_t found = 0;
    foreach (t; Thread.getAll())
        if (tid == t.id)
        {
            ++found;
        }
    assert(found == 1);
}

void assert_thread_is_gone(pthread_t tid)
{
    foreach (t; Thread.getAll())
        assert(tid != t.id);
}

// Occasionally stop threads and start new ones
void watch_threads()
{
    const start = time(null);

    while ((time(null) - start) < runTimeSeconds)
    {
        foreach (ref t; threads)
        {
            const shouldStop = ((rand() % 100) == 0);
            if (shouldStop)
            {
                stop_thread(t);
                start_thread(t);
            }
        }
    }
}

void main()
{
    start_threads();
    watch_threads();
    stop_threads();
}

} // version (Posix)
else
{

void main()
{
}

}
