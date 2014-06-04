/**
 * Contains a struct for storing GC statistics.
 *
 * Copyright: Copyright Digital Mars 2005 - 2013.
 * License:   <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors:   Walter Bright, Sean Kelly
 */

/*          Copyright Digital Mars 2005 - 2013.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */
module gc.stats;
import core.time;

/**
 *
 */
struct GCStats
{
    short ver = 1;
    long bytesFreedInCollections;
    long bytesUsedInCollections;
    long totalCollections;
    TickDuration elapsedInCollections;
    long bytesReqBigAllocations;
    long bytesBigAllocations;
    long totalBigAllocations;
    TickDuration elapsedInBigAllocations;
    long bytesReqSmallAllocations;
    long bytesSmallAllocations;
    long totalSmallAllocations;
    TickDuration elapsedInSmallAllocations;
    long bytesUsedCurrently;
    long bytesFreeCurrently;
    long maxBytesUsed;
    long maxBytesFree;
    long bytesFreedToOS;
    long totalFreeToOS;
    TickDuration elapsedInFreeToOS;
    TickDuration elapsed;
}