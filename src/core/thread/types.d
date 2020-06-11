/**
 * The osthread module provides types used in threads modules.
 *
 * Copyright: Copyright Sean Kelly 2005 - 2012.
 * License: Distributed under the
 *      $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
 *    (See accompanying file LICENSE)
 * Authors:   Sean Kelly, Walter Bright, Alex Rønne Petersen, Martin Nowak
 * Source:    $(DRUNTIMESRC core/thread/osthread.d)
 */

module core.thread.types;

/**
 * Represents the ID of a thread, as returned by $(D Thread.)$(LREF id).
 * The exact type varies from platform to platform.
 */
version (Windows)
    alias ThreadID = uint;
else
version (Posix)
{
    import core.sys.posix.pthread;

    alias ThreadID = pthread_t;
}

struct ll_ThreadData
{
    ThreadID tid;
    version (Windows)
        void delegate() nothrow cbDllUnload;
}

version (GNU)
{
    import gcc.builtins;

    version (GNU_StackGrowsDown)
        enum isStackGrowsDown = true;
    else
        enum isStackGrowsDown = false;
}
else
{
    // this should be true for most architectures
    enum isStackGrowsDown = true;
}

import core.thread.osthread : Thread;

package __gshared align(Thread.alignof) void[__traits(classInstanceSize, Thread)] _mainThreadStore;
