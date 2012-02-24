/**
 * Basic containers for internal usage.
 *
 * Copyright: Copyright Digital Mars 2011.
 * License:   <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors:   Martin Nowak
 */

/*          Copyright Digital Mars 2011.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE_1_0.txt or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */
module rt.util.container;

import core.stdc.stdlib;
import core.stdc.string;


struct Array(T)
{
    @disable this(this);

    ~this()
    {
        reset();
    }

    void reset()
    {
        _impl.reset();
    }

    @property bool empty() const
    {
        return !_impl._length;
    }

    @property size_t length() const
    {
        return _impl._length / T.sizeof;
    }

    @property void length(size_t nlength)
    {
        _impl.setLength(nlength * T.sizeof);
    }

    alias length opDollar;

    ref T opIndex(size_t i)
    in
    {
        assert(i < length);
    }
    body
    {
        return (cast(T*)_impl._ptr)[i];
    }

    T[] opSlice()
    {
        immutable len = length;
        return (cast(T*)_impl._ptr)[0 .. len];
    }

    T[] opSlice(size_t lo, size_t hi)
    in
    {
        assert(lo <= hi);
        assert(hi <= length);
    }
    body
    {
        return (cast(T*)_impl._ptr)[lo .. hi];
    }

    void insertBack(T value)
    {
        immutable len = _impl._length;
        _impl.setLength(len + T.sizeof);
        *(cast(T*)(_impl._ptr + len)) = value;
    }

    void popBack()
    {
        _impl.setLength(_impl._length - T.sizeof);
    }

    @property ref T back()
    {
        return *(cast(T*)(_impl._ptr + _impl._length - T.sizeof));
    }

    void opOpAssign(string op)(T value) if(op == "~")
    {
        insertBack(value);
    }

    void insertAt(size_t idx, T value)
    {
        length = length + 1;
        auto p = &this[idx];
        .memmove(p + 1, p, (length - idx - 1) * T.sizeof);
        *p = value;
    }

    void removeAt(size_t idx)
    {
        auto p = &this[idx];
        .memmove(p, p + 1, (length - idx - 1) * T.sizeof);
        length = length - 1;
    }

    void remove(T value)
    {
        bool eq(ref T other) { return other == value; }
        remove(&eq);
    }

    void remove(scope bool delegate(ref T value) dg)
    {
        immutable len = length;
        auto p = cast(T*)_impl._ptr;
        size_t idx;
        while (idx < len)
        {
            if (dg(p[idx]))
            {
                size_t ins = idx++;
                while (idx < len)
                {
                    if (!dg(p[idx]))
                        p[ins++] = p[idx];
                    ++idx;
                }
                length = ins;
                break;
            }
            ++idx;
        }
    }

private:
    ArrayImpl _impl;
}

private struct ArrayImpl
{
    void reset()
    {
        .free(_ptr);
        _ptr = null;
        _length = 0;
    }

    void setLength(size_t length)
    {
        _ptr = .realloc(_ptr, length);
        if (length > _length)
            .memset(_ptr + _length, 0, length - _length);
        _length = length;
    }

    void* _ptr;
    size_t _length;
}


unittest
{
    Array!int ary;
    assert(ary.empty);
    assert(ary.length == 0);
    ary.insertBack(5);
    assert(!ary.empty);
    assert(ary.length == 1);
    assert(ary.back == 5);
    assert(ary[0] == 5);
    ary ~= 8;
    assert(!ary.empty);
    assert(ary.length == 2);
    assert(ary.back == 8);
    assert(ary[0] == 5);
    assert(ary[1] == 8);
    assert(ary[] == [5, 8]);
    assert(ary[0 .. 1] == [5]);
    assert(ary[1 .. 2] == [8]);
    ary.popBack();
    assert(ary[] == [5]);
    ary.popBack();
    assert(ary.empty);
    ary ~= 1;
    ary ~= 2;
    assert(ary[] == [1, 2]);
    ary.reset();
    assert(ary.empty);
    ary ~= 1;
    ary ~= 2;
    assert(ary[] == [1, 2]);
    ary.insertAt(0, 7);
    assert(ary[] == [7, 1, 2]);
    ary.insertAt(2, 11);
    assert(ary[] == [7, 1, 11, 2]);
    ary.removeAt(1);
    assert(ary[] == [7, 11, 2]);
    ary.remove(11);
    assert(ary[] == [7, 2]);
    ary.remove((ref int val) => !!(val % 2));
    assert(ary[] == [2]);

    assert(!ary.empty);
    ary = Array!int();
    assert(ary.empty);

    Array!int ary2;
    static assert(!__traits(compiles, ary = ary2));
}


struct List(T)
{
    @disable this(this);

    ~this()
    {
        reset();
    }

    void reset()
    {
        _impl.reset();
    }

    @property ref T front()
    {
        return *cast(T*)_impl._head.value;
    }

    void insertFront(T value)
    {
        *(cast(T*)_impl.push(T.sizeof)) = value;
    }

    @property void popFront()
    {
        _impl.pop();
    }

    Array!T toArray()
    {
        Array!T ary;
        ary.length = count;
        size_t i;
        foreach(ref val; this)
            ary[i++] = val;
        return ary;
    }

    int opApply(scope int delegate(ref T) dg)
    {
        return _impl.opApply((ref ListImpl.Node* p) { return dg(*cast(T*)p.value); });
    }

    void remove(T value)
    {
        bool eq(ref T other) { return other == value; }
        remove(&eq);
    }

    void remove(scope bool delegate(ref T value) dg)
    {
        _impl.remove((void* value) => dg(*cast(T*)value));
    }

    ListImpl _impl;
    alias _impl this;
}

private struct ListImpl
{
    static struct Node
    {
        @property void* value()
        {
            return cast(void*)(&this + 1);
        }

        Node *_next;
        // payload
    }

    void reset()
    {
        while (_head)
        {
            auto p = _head;
            _head = p._next;
            .free(p);
        }
    }

    @property bool empty()
    {
        return _head is null;
    }

    @property size_t count() const
    {
        size_t cnt;
        for (const(Node)* p = _head; p; p = p._next)
            ++cnt;
        return cnt;
    }

    void* push(size_t nbytes)
    {
        auto p = cast(Node*).malloc(Node.sizeof + nbytes);
        p._next = _head;
        _head = p;
        return p.value;
    }

    void pop()
    {
        auto p = _head;
        _head = p._next;
        .free(p);
    }

    int opApply(scope int delegate(ref Node* p) dg)
    {
        for (auto p = _head; p; p = p._next)
        {
            if (auto res = dg(p))
                return res;
        }
        return 0;
    }

    void remove(scope bool delegate(void* value) dg)
    {
        auto pp = &_head;
        while (*pp)
        {
            auto p = *pp;
            if (dg(p.value))
            {
                *pp = p._next;
                .free(p);
            }
            else
                pp = &p._next;
        }
    }

    Node* _head;
}

unittest
{
    static bool equal(ref List!int list, int[] comp)
    {
        size_t idx;
        foreach(val; list)
        {
            if (val != comp[idx++])
                return false;
        }
        return idx == comp.length;
    }

    List!int list;

    assert(list.empty);

    foreach(i; 0 .. 10)
    {
        list.insertFront(i);
    }
    assert(!list.empty);

    foreach_reverse(i; 0 .. 10)
    {
        assert(list.front == i);
        list.popFront;
    }
    assert(list.empty);

    list.insertFront(3);
    list.insertFront(2);
    list.insertFront(1);
    list.insertFront(0);

    assert(!list.empty);
    int i = 0;
    foreach(val; list)
        assert(val == i++);

    assert(!list.empty);
    assert(list.count == 4);

    assert(equal(list, [0, 1, 2, 3]));
    list.remove(2);
    assert(equal(list, [0, 1, 3]));
    list.insertFront(3);
    assert(equal(list, [3, 0, 1, 3]));
    list.remove(3);
    assert(equal(list, [0, 1]));
    list.remove((ref int val) => !!(val % 2));
    assert(equal(list, [0]));

    assert(!list.empty);
    list.reset();
    assert(list.empty);

    list.insertFront(0);
    assert(!list.empty);
    list = List!int();
    assert(list.empty);

    List!int list2;
    static assert(!__traits(compiles, list = list2));
}
