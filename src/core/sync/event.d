/**
 * The event module provides a primitive for lightweight signaling of other threads
 * (emulating Windows events on Posix)
 *
 * Copyright: Copyright (c) 2019 D Language Foundation
 * License: Distributed under the
 *    $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
 *    (See accompanying file LICENSE)
 * Authors: Rainer Schuetze
 * Source:    $(DRUNTIMESRC core/sync/event.d)
 */
module core.sync.event;

version (Windows)
{
    import core.sys.windows.basetsd /+: HANDLE +/;
    import core.sys.windows.winerror /+: WAIT_TIMEOUT +/;
    import core.sys.windows.winbase /+: CreateEvent, CloseHandle, SetEvent, ResetEvent,
        WaitForSingleObject, INFINITE, WAIT_OBJECT_0+/;
}
else version (Posix)
{
    import core.sys.posix.pthread;
    import core.sys.posix.sys.types;
}
else
{
    static assert(false, "Platform not supported");
}

import core.time;
import core.internal.abort : abort;

/**
 * represents an event. Clients of an event are suspended while waiting
 * for the event to be "signaled".
 *
 * Implemented using `pthread_mutex` and `pthread_condition` on Posix and
 * `CreateEvent` and `SetEvent` on Windows.
 */
struct Event
{
    // Posix version inspired by http://www.it.uu.se/katalog/larme597/win32eoposix
nothrow @nogc:
    /**
     * Creates an event object.
     *
     * Params:
     *  manualReset  = the state of the event is not reset automatically after resuming waiting clients
     *  initialState = initial state of the signal
     */
    this(bool manualReset, bool initialState)
    {
        initialize(manualReset, initialState);
    }

    /**
     * Initializes an event object. Does nothing if the event is already initialized.
     *
     * Params:
     *  manualReset  = the state of the event is not reset automatically after resuming waiting clients
     *  initialState = initial state of the signal
     */
    void initialize(bool manualReset, bool initialState)
    {
        version (Windows)
        {
            if (m_event)
                return;
            m_event = CreateEvent(null, manualReset, initialState, null);
            m_event || abort("Error: CreateEvent failed.");
        }
        else version (Posix)
        {
            if (m_initalized)
                return;
            !pthread_mutex_init(cast(pthread_mutex_t*) &m_mutex, null) ||
                abort("Error: pthread_mutex_init failed.");
            m_state = initialState;
            m_manualReset = manualReset;
            m_initalized = true;
        }
    }

    // copying not allowed, can produce resource leaks
    @disable this(this);
    @disable void opAssign(Event);

    ~this()
    {
        terminate();
    }

    /**
     * deinitialize event. Does nothing if the event is not initialized. There must not be
     * threads currently waiting for the event to be signaled.
    */
    void terminate()
    {
        version (Windows)
        {
            if (m_event)
                CloseHandle(m_event);
            m_event = null;
        }
        else version (Posix)
        {
            if (m_initalized)
            {
                assert(!m_waiter);
                pthread_mutex_destroy(&m_mutex) == 0 ||
                    abort("Error: pthread_mutex_destroy failed.");
                m_initalized = false;
            }
        }
    }


    /// Set the event to "signaled", so that waiting clients are resumed
    void set()
    {
        version (Windows)
        {
            if (m_event)
                SetEvent(m_event);
        }
        else version (Posix)
        {
            if (m_initalized)
            {
                pthread_mutex_lock(&m_mutex);
                m_state = true;
                for (auto waiter = m_waiter; waiter != null; waiter = waiter.next)
                {
                    pthread_mutex_lock(&waiter.mutex);
                    pthread_cond_signal(&waiter.cond);
                    pthread_mutex_unlock(&waiter.mutex);
                }
                pthread_mutex_unlock(&m_mutex);
            }
        }
    }

    /// Reset the event manually
    void reset()
    {
        version (Windows)
        {
            if (m_event)
                ResetEvent(m_event);
        }
        else version (Posix)
        {
            if (m_initalized)
            {
                pthread_mutex_lock(&m_mutex);
                m_state = false;
                pthread_mutex_unlock(&m_mutex);
            }
        }
    }

    /**
     * Wait for the event to be signaled without timeout.
     *
     * Returns:
     *  `true` if the event is in signaled state, `false` if the event is uninitialized or another error occured
     */
    bool wait()
    {
        version (Windows)
        {
            return m_event && WaitForSingleObject(m_event, INFINITE) == WAIT_OBJECT_0;
        }
        else version (Posix)
        {
            return wait(Duration.max);
        }
    }

    /**
     * Wait for the event to be signaled with timeout.
     *
     * Params:
     *  tmout = the maximum time to wait
     * Returns:
     *  `true` if the event is in signaled state, `false` if the event was nonsignaled for the given time or
     *  the event is uninitialized or another error occured
     */
    bool wait(Duration tmout)
    {
        version (Windows)
        {
            if (!m_event)
                return false;

            auto maxWaitMillis = dur!("msecs")(uint.max - 1);

            while (tmout > maxWaitMillis)
            {
                auto res = WaitForSingleObject(m_event, uint.max - 1);
                if (res != WAIT_TIMEOUT)
                    return res == WAIT_OBJECT_0;
                tmout -= maxWaitMillis;
            }
            auto ms = cast(uint)(tmout.total!"msecs");
            return WaitForSingleObject(m_event, ms) == WAIT_OBJECT_0;
        }
        else version (Posix)
        {
            if (!m_initalized)
                return false;

            pthread_mutex_lock(&m_mutex);

            int result = 0;
            if (!m_state)
            {
                list_element le;
                pthread_mutex_init(&le.mutex, null) == 0 ||
                    abort("Error: pthread_mutex_init failed.");
                pthread_cond_init(&le.cond, null) == 0 ||
                    abort("Error: pthread_cond_init failed.");

                addWaiter(&le);
                pthread_mutex_unlock(&m_mutex);

                if (tmout == Duration.max)
                {
                    result = pthread_cond_wait(&le.cond, &le.mutex);
                }
                else
                {
                    import core.sync.config;

                    timespec t = void;
                    mktspec(t, tmout);

                    result = pthread_cond_timedwait(&le.cond, &le.mutex, &t);
                }

                pthread_mutex_lock(&m_mutex);
                removeWaiter(&le);

                pthread_mutex_destroy(&le.mutex);
                pthread_cond_destroy(&le.cond);
            }
            if (result == 0 && !m_manualReset)
                m_state = false;

            pthread_mutex_unlock(&m_mutex);

            return result == 0;
        }
    }

private:
    version (Windows)
    {
        HANDLE m_event;
    }
    else version (Posix)
    {
        pthread_mutex_t m_mutex;
        list_element* m_waiter;
        bool m_initalized;
        bool m_state;
        bool m_manualReset;

        static struct list_element
        {
            pthread_mutex_t mutex;  // mutex for the conditional wait
            pthread_cond_t cond;
            list_element *next;
        }

        void addWaiter(list_element* le)
        {
            le.next = m_waiter;
            m_waiter = le;
        }

        void removeWaiter(list_element* le)
        {
            for (auto pwaiter = &m_waiter; *pwaiter; pwaiter = &(*pwaiter).next)
                if (*pwaiter == le)
                {
                    *pwaiter = le.next;
                    return;
                }
            assert(false);
        }
    }
}

// Test single-thread (non-shared) use.
@nogc nothrow unittest
{
    // auto-reset, initial state false
    Event ev1 = Event(false, false);
    assert(!ev1.wait(1.dur!"msecs"));
    ev1.set();
    assert(ev1.wait());
    assert(!ev1.wait(1.dur!"msecs"));

    // manual-reset, initial state true
    Event ev2 = Event(true, true);
    assert(ev2.wait());
    assert(ev2.wait());
    ev2.reset();
    assert(!ev2.wait(1.dur!"msecs"));
}

unittest
{
    import core.thread;

    auto event      = new Event(true, false);
    int  numThreads = 10;

    void testFn()
    {
        event.wait(8.dur!"seconds"); // timeout below limit for druntime test_runner
    }

    auto group = new ThreadGroup;

    for (int i = 0; i < numThreads; ++i)
        group.create(&testFn);

    auto start = MonoTime.currTime;

    event.set();
    group.joinAll();

    assert(MonoTime.currTime - start < 5.dur!"seconds");

    delete event;
}
