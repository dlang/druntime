// Written in the D programming language.
/**
This module provides `rcslist`, a singly linked list type using reference
counting for automatic memory management not reliant on the GC.

License: $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).

Authors: Les De Ridder

Source: $(DRUNTIMESRC core/experimental/slist.d)
*/
module core.experimental.rc.slist;

import core.experimental.rc.slice;

///
pure nothrow @safe @nogc unittest
{
    import core.experimental.rc.slist;

    auto s = rcslist!int(1, 2, 3);
    assert(s.front == 1);

    s.removeFront();
    assert(s.front == 2);

    s.insertFront(5, 6);
    assert(s.front == 5);
}

/**
Creates an empty `rcslist`.

Returns:
     an empty `rcslist`
*/
auto make(List : rcslist!T, T)()
{
    return List();
}

/**
Creates an `rcslist` out of the given values.

Params:
    values = Any number of values, in the form of a list of values, or a
             built-in (static or dynamic) array.
*/
auto make(List : rcslist!T, U : T, T)(U[] values...)
{
    return List(values);
}

///
@safe unittest
{
    auto l1 = make!(rcslist!int);
    assert(l1.empty);

    auto l2 = make!(rcslist!int)(1, 2, 3);
    assert(l2 == [1, 2, 3]);
}

/**
Singly linked list type with deterministic control of memory, through reference
counting. Memory is automatically reclaimed when the last reference to the list
is destroyed; there is no reliance on the garbage collector.

Note:
    `rcslist` does not currently provide a range interface.
*/
struct rcslist(T)
{
    import core.lifetime : emplace;

    private static struct Node
    {
        import core.internal.traits : Unqual;

        __rcslice!(Node, onDeallocate, false) next;
        Unqual!T value;

        this(U)(typeof(next) next, U value)
        if (is(U : T))
        {
            this.next = next;
            this.value = value;
        }

        static void onDeallocate(Slice : __rcslice!(U, onDeallocate, false), U)(ref Slice slice)
        {
            import core.internal.traits : hasElaborateDestructor;
            static if (hasElaborateDestructor!(Unqual!T))
            {
                foreach (ref u; slice)
                {
                    u.value.__xdtor;
                }
            }
        }
    }

    private typeof(Node.next) head;

    /**
    Creates a linked list out of the given values.

    Params:
        values = Any number of values, in the form of a list of values, or a
                 built-in (static or dynamic) array.
    */
    this(U)(U[] values...)
    if (is(U : T))
    {
        insertFront(values);
    }

    /// Create an rcslist from a list of ints
    static if (is(T == int))
    @safe unittest
    {
        auto l = rcslist!int(1, 2, 3);
        assert(l == [1, 2, 3]);
    }

    /// Create an rcslist from an array of ints
    static if (is(T == int))
    @safe unittest
    {
        auto l = rcslist!int([1, 2, 3]);
        assert(l == [1, 2, 3]);
    }

    /**
    Inserts _values to the front of the list.

    Params:
        values = Any number of values, in the form of a list of values, or a
                 built-in (static or dynamic) array.
    */
    void insertFront(U)(U[] values...)
    if (is(U : T))
    {
        //TODO: Make this work with any input range

        foreach (i; 0 .. values.length)
        {
            insertFront(values[values.length - i - 1]);
        }
    }

    void insertFront(U)(U value)
    if (is(U : T))
    {
        auto newNode = typeof(head)(1);
        () @trusted { emplace(newNode.ptr, Node(head, value)); }();
        head = newNode;
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        rcslist!int l;
        assert(l.empty);

        l.insertFront(1);
        assert(l == [1]);

        l.insertFront([2, 3]);
        assert(l == [2, 3, 1]);

        l.insertFront(4, 5);
        assert(l == [4, 5, 2, 3, 1]);
    }

    void opAssign()(auto ref typeof(this) rhs)
    {
        this.head = rhs.head;
    }

    /**
    Checks for equality.

    Complexity: $(BIGOH min(n, n1)) where `n1` is the number of elements in rhs.
    */
    bool opEquals(U)(auto ref const U rhs)
    if (is(U : const V[], V) && is(typeof(T.init == V.init)))
    {
        auto node = head;
        auto i = 0;
        while (node != null)
        {
            if ((() @trusted => node.ptr.value)() != rhs[i++]) return false;

            () @trusted { node = node.ptr.next; }();
        }
        return rhs.length == i;
    }

    ///
    bool opEquals(U)(auto ref U rhs)
    if (is(U : typeof(this)))
    {
        auto node = head;
        auto rhsNode = rhs.head;
        while (node != null && rhsNode != null)
        {
            if ((() @trusted => node.ptr.value != rhsNode.ptr.value)()) return false;

            () @trusted { node = node.ptr.next; rhsNode = rhsNode.ptr.next; }();
        }
        return node == null && rhsNode == null;
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto a = [1, 2, 3];
        auto s = rcslist!int(a);
        assert(s == a);
    }

    /**
    Returns: true if the list is empty

    Complexity: $(BIGOH 1).
    */
    bool empty()
    {
        return head == null;
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        rcslist!int l;
        assert(l.empty);

        l.insertFront(1);
        assert(!l.empty);

        l.removeFront();
        assert(l.empty);
    }

    /**
    Returns: the value at the front of the list

    Complexity: $(BIGOH 1).
    */
    ref T front()
    {
        assert(!empty, "rcslist.front: list is empty");

        return (ref () @trusted => head.ptr.value)();
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto s = rcslist!int(1, 2, 3);
        assert(s.front == 1);
        s.front = 42;
        assert(s.front == 42);
    }

    /**
    Removes the value at the front of the list.

    Complexity: $(BIGOH 1).
    */
    void removeFront()
    {
        assert(!empty, "rcslist.removeFront: list is empty");

        auto old = head;

        () @trusted {
            head = head.ptr.next;
            old.ptr.next = null;
        }();
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto l = rcslist!int(1);
        l.removeFront();
        assert(l.empty);
    }

    /**
    Finds the first instance of value in the list.

    Returns: pointer to the value if it was found, or null

    Warning:

    This function may be removed in the future when a range interface is
    implemented.
    */
    T* find(U)(U value) return scope
    {
        if (head == null)
        {
            return null;
        }

        auto node = head;

        while (node != null)
        {
            if (node.ptr.value == value)
            {
                return &node.ptr.value;
            }

            node = node.ptr.next;
        }

        return null;
    }

    ///
    static if (is(T == int))
    unittest
    {
        auto l = rcslist!int(1, 2, 3);
        assert(l == [1, 2, 3]);

        auto p = l.find(2);
        assert(p !is null);
        *p = 0;
        assert(l == [1, 0, 3]);

        p = l.find(4);
        assert(p is null);
    }

    /**
    Removes the first instance of value found in the list.

    Returns: true if a value was removed
    */
    @trusted
    bool remove(U)(U value)
    {
        auto previous = head;
        auto node = head;

        while (node != null)
        {
            if (node.ptr.value == value)
            {
                if (node.ptr == head.ptr)
                {
                    head = node.ptr.next;
                    node.ptr.next = null;
                }
                else
                {
                    previous.ptr.next = node.ptr.next;
                    node.ptr.next = null;
                }

                return true;
            }

            previous = node;
            node = node.ptr.next;
        }

        return false;
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto l = rcslist!int(1, 2, 3, 2, 4);
        auto b = l.remove(2);
        assert(b == true);
        assert(l == [1, 3, 2, 4]);
        b = l.remove(2);
        assert(b == true);
        assert(l == [1, 3, 4]);
        b = l.remove(2);
        assert(b == false);
        assert(l == [1, 3, 4]);
    }

    /**
    Perform a copy of the list. This will create a new list that will copy
    the elements of the current list. This will `NOT` call `dup` on the
    elements of the list, regardless if `T` defines it or not.

    Returns: a new mutable list.

    Complexity: $(BIGOH n).
    */
    auto dup()
    {
        auto newList = rcslist!T();
        typeof(head) previous;

        auto from = head;

        while (from != null)
        {
            if (newList.head == null)
            {
                newList.head = typeof(head)(1);
                () @trusted { emplace(newList.head.ptr, Node(typeof(head)(), from.ptr.value)); }();
                previous = newList.head;
            }
            else
            {
                auto next = typeof(head)(1);
                () @trusted { emplace(next.ptr, Node(typeof(head)(), from.ptr.value)); }();
                () @trusted { previous.ptr.next = next; }();
                previous = next;
            }

            () @trusted { from = from.ptr.next; }();
        }

        return newList;
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto s = rcslist!int([4, 6, 8, 12, 16]);
        auto d = s.dup;
        assert(d !is s);
        assert(d == s);
    }

    /**
    Removes all elements from the list.

    Complexity: $(BIGOH n).
    */
    void clear()
    {
        while (!empty)
        {
            removeFront();
        }
    }

    ///
    static if (is(T == int))
    @safe unittest
    {
        auto l = rcslist!int(1, 2, 3);
        assert(!l.empty);
        l.clear();
        assert(l.empty);
    }

    ~this()
    {
        clear();
    }
}

version (CoreUnittest)
{
    @safe unittest
    {
        auto e = rcslist!int();
        auto b = e.remove(2);
        assert(b == false);
        assert(e.empty);
        auto a = rcslist!int(-1, 1, 2, 1, 3, 4);
        b = a.remove(1);
        assert(a == [-1, 2, 1, 3, 4]);
        assert(b == true);
        b = a.remove(-1);
        assert(b == true);
        assert(a == [2, 1, 3, 4]);
        b = a.remove(1);
        assert(b == true);
        assert(a == [2, 3, 4]);
        b = a.remove(2);
        assert(b == true);
        b = a.remove(20);
        assert(b == false);
        assert(a == [3, 4]);
        b = a.remove(4);
        assert(b == true);
        assert(a == [3]);
        b = a.remove(3);
        assert(b == true);
        assert(a.empty);
        a.remove(3);
    }

    @safe unittest
    {
        auto a = rcslist!int(5);
        auto b = a;
        a.insertFront(1);
        assert(a == [1, 5]);
        assert(b == [5]);
        b.insertFront(2);
        assert(a == [1, 5]);
        assert(b == [2, 5]);
    }

    @safe unittest
    {
        auto s = rcslist!int(1, 2, 3, 4);
        s.insertFront([42, 43]);
        assert(s == rcslist!int(42, 43, 1, 2, 3, 4));
    }

    @safe unittest
    {
        auto e = make!(rcslist!int)();
        assert(e.empty);

        auto s = make!(rcslist!int)(1, 2, 3);
        assert(s == [1, 2, 3]);
    }

    @safe unittest
    {
        auto s = rcslist!int([1, 2, 3]);
        s.front = 5;
        assert(s.front == 5);
    }

    @safe unittest
    {
        rcslist!int s;
        assert(s.empty);
        s.clear();
        assert(s.empty);
    }
}
