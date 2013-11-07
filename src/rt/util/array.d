/**
Array utilities.

Copyright: Denis Shelomovskij 2013
License: $(HTTP boost.org/LICENSE_1_0.txt, Boost License 1.0).
Authors: Denis Shelomovskij
Source: $(DRUNTIMESRC src/rt/util/_array.d)
*/
module rt.util.array;


import rt.util.string;


@safe /* pure dmd @@@BUG11461@@@ */ nothrow:

void enforceTypedArraysConformable(T)(in char[] action,
    in T[] a1, in T[] a2, in bool allowOverlap = false)
{
    _enforceSameLength(action, a1.length, a2.length);
    if(!allowOverlap)
        _enforceNoOverlap(action, a1.ptr, a2.ptr, T.sizeof * a1.length);
}

void enforceRawArraysConformable(in char[] action, in size_t elementSize,
    in void[] a1, in void[] a2, in bool allowOverlap = false)
{
    _enforceSameLength(action, a1.length, a2.length);
    if(!allowOverlap)
        _enforceNoOverlap(action, a1.ptr, a2.ptr, elementSize * a1.length);
}

private void _enforceSameLength(in char[] action,
    in size_t length1, in size_t length2)
{
    if(length1 == length2)
        return;

    throw new Error(format!"Array lengths don't match for ^: ^ != ^."
        (action, length1, length2));
}

private void _enforceNoOverlap(in char[] action,
    in void* ptr1, in void* ptr2, in size_t bytes)
{
    const d = ptr1 > ptr2 ? ptr1 - ptr2 : ptr2 - ptr1;
    if(d >= bytes)
        return;
    const overlappedBytes = bytes - d;

    throw new Error(format!"Overlapping arrays in ^: ^ byte^ overlap of ^."
        (action, overlappedBytes, overlappedBytes == 1 ? "" : "s", bytes));
}
