/**
 * Dynamic array.
 *
 * This module contains a simple dynamic array implementation for use in the
 * Naive Garbage Collector. Standard D dynamic arrays can't be used because
 * they rely on the GC itself.
 *
 * See_Also:  gc module
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   Leandro Lucarella <llucax@gmail.com>
 */

module gc.concurrent.dynarray;

import core.stdc.stdlib: realloc;
import core.stdc.string: memmove;


private void Invariant(T)(const(DynArray!(T))* a)
{
        assert ((a._data && a._capacity)
                    || ((a._data is null) && (a._capacity == 0)));
        assert (a._capacity >= a._size);
}


package:

/**
 * Dynamic array.
 *
 * This is a simple dynamic array implementation. D dynamic arrays can't be
 * used because they rely on the GC, and we are implementing the GC.
 */
struct DynArray(T)
{

private:

    /// Memory block to hold the array.
    T* _data = null;

    /// Total array capacity, in number of elements.
    size_t _capacity = 0;

    /// Current array size, in number of elements.
    size_t _size = 0;


public:

    invariant()
    {
        .Invariant!(T)(&this);
    }

    void Invariant()
    {
        .Invariant!(T)(&this);
    }

    /**
     * Get the array size.
     */
    size_t length()
    {
        return this._size;
    }

    /**
     * Get the array capacity.
     */
    size_t capacity()
    {
        return this._capacity;
    }

    /**
     * Get the total ammount of bytes the elements consumes (capacity included).
     */
    size_t elements_sizeof()
    {
        return this._capacity * (T.sizeof + (T*).sizeof);
    }

    /**
     * Get the pointer to the array's data.
     *
     * Use with care, the data belongs to the array and you should not
     * realloc() or free() it, you should only use it a as a read-only chunk of
     * memory.
     */
    T* ptr()
    {
        return this._data;
    }

    /**
     * Access an element by index.
     *
     * Bear in mind that a copy of the element is returned. If you need
     * a pointer, you can always get it through a.ptr + i (but be careful if
     * you use the insert_sorted() method).
     */
    T opIndex(size_t i)
    {
        assert (i < this._size);
        return this._data[i];
    }

    /**
     * Append a copy of the element x at the end of the array.
     *
     * This can trigger an allocation if the array is not big enough.
     *
     * Returns a pointer to the newly appended element if the append was
     * successful, null otherwise (i.e. an allocation was triggered but the
     * allocation failed) in which case the internal state is not changed.
     */
    T* append(T x)
    {
        if (this._size == this._capacity)
            if (!this.resize())
                return null;
        this._data[this._size] = x;
        this._size++;
        return this._data + this._size - 1;
    }

    /**
     * Insert an element preserving the array sorted.
     *
     * This assumes the array was previously sorted. The "cmp" template
     * argument can be used to specify a custom comparison expression as "a"
     * string (where a is the element in the array and "b" is the element
     * passed as a parameter "x"). Using a template to specify the comparison
     * method is a hack to cope with compilers that have trouble inlining
     * a delegate (i.e. DMD).
     *
     * This can trigger an allocation if the array is not big enough and moves
     * memory around, so you have to be specially careful if you are taking
     * pointers into the array's data.
     *
     * Returns a pointer to the newly inserted element if the append was
     * successful, null otherwise (i.e. an allocation was triggered but the
     * allocation failed) in which case the internal state is not changed.
     */
    T* insert_sorted(string cmp = "a < b")(T x)
    {
        size_t i = 0;
        for (; i < this._size; i++) {
            T a = this._data[i];
            alias x b;
            if (mixin(cmp))
                continue;
            break;
        }
        if ((this._size == this._capacity) && !this.resize())
            return null;
        memmove(this._data + i + 1, this._data + i,
                (this._size - i) * T.sizeof);
        this._data[i] = x;
        this._size++;
        return this._data + i;
    }

    /**
     * Remove the element at position pos.
     */
    void remove_at(size_t pos)
    {
        this._size--;
        // move the rest of the items one place to the front
        memmove(this._data + pos, this._data + pos + 1,
                (this._size - pos) * T.sizeof);
    }

    /**
     * Remove the first occurrence of the element x from the array.
     */
    bool remove(in T x)
    {
        for (size_t i = 0; i < this._size; i++) {
            if (this._data[i] == x) {
                this.remove_at(i);
                return true;
            }
        }
        return false;
    }

    /**
     * Change the current capacity of the array to new_capacity.
     *
     * This can enlarge or shrink the array, depending on the current capacity.
     * If new_capacity is 0, the array is enlarged to hold double the current
     * size. If new_capacity is less than the current size, the current size is
     * truncated, and the (size - new_capacity) elements at the end are lost.
     *
     * Returns true if the resize was successful, false otherwise (and the
     * internal state is not changed).
     */
    bool resize(size_t new_capacity = 0)
    {
        // adjust new_capacity if necessary
        if (new_capacity == 0)
            new_capacity = this._size * 2;
            if (new_capacity == 0)
                new_capacity = 16;
        // reallocate the memory with the new_capacity
        T* new_data = cast(T*) realloc(this._data, new_capacity * T.sizeof);
        if (new_data is null)
            return false;
        this._data = new_data;
        this._capacity = new_capacity;
        // truncate the size if necessary
        if (this._size > this._capacity)
            this._size = this._capacity;
        return true;
    }

    /**
     * Remove all the elements of the array and set the capacity to 0.
     */
    void free()
    {
        this._data = cast(T*) realloc(this._data, 0);
        assert (this._data is null);
        this._size = 0;
        this._capacity = 0;
    }

}


unittest // DynArray
{
    DynArray!(int) array;
    assert (array.length == 0);
    assert (array.capacity == 0);
    assert (array.ptr is null);
    assert (array.append(5));
    assert (array.length == 1);
    assert (array.capacity >= 1);
    assert (array.ptr !is null);
    for (auto i = 0; i < array.length; i++)
        assert (array[i] == 5);
    assert (array.append(6));
    assert (array.length == 2);
    assert (array.capacity >= 2);
    assert (array.ptr !is null);
    int j = 0;
    while (j < array.length)
        assert (array[j] == (5 + j++));
    assert (j == 2);
    array.remove(5);
    assert (array.length == 1);
    assert (array.capacity >= 1);
    assert (array.ptr !is null);
    for (auto i = 0; i < array.length; i++)
        assert (array[i] == 6);
    assert (array.resize(100));
    assert (array.length == 1);
    assert (array.capacity >= 100);
    assert (array.ptr !is null);
    array.free();
    assert (array.length == 0);
    assert (array.capacity == 0);
    assert (array.ptr is null);
}


// vim: set et sw=4 sts=4 :
