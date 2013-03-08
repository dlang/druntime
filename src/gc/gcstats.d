/**
 * Contains a struct for storing GC statistics.
 *
 * Copyright: Copyright Digital Mars 2005 - 2009.
 * License:   <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors:   Walter Bright, Sean Kelly
 */

/*          Copyright Digital Mars 2005 - 2009.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */
module gc.gcstats;


/**
 *
 */
struct GCStats
{
    size_t poolSize = size_t.min;        // total size of pool
    size_t usedSize = size_t.min;        // bytes allocated
    size_t freeBlocks = size_t.min;      // number of blocks marked FREE
    size_t freeListSize = size_t.min;    // total of memory on free lists
    size_t pageBlocks = size_t.min;      // number of blocks marked PAGE
    size_t fullCollections = size_t.min; // number of full collections
}
