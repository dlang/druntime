module test.stdcpp.array;

import core.stdcpp.array;

unittest
{
    array!(int, 5) arr;
    arr[] = [0, 2, 3, 4, 5];
    ++arr.front;

    assert(arr.size == 5);
    assert(arr.length == 5);
    assert(arr.max_size == 5);
    assert(arr.empty == false);
    assert(arr.front == 1);

    assert(sumOfElements_val(arr) == 40);
    assert(sumOfElements_ref(arr) == 15);

    array!(int, 0) arr2;
    assert(arr2.size == 0);
    assert(arr2.length == 0);
    assert(arr2.max_size == 0);
    assert(arr2.empty == true);
    assert(arr2[] == []);
}


extern(C++):

// test the ABI for calls to C++
int sumOfElements_val(array!(int, 5) arr);
int sumOfElements_ref(ref const(array!(int, 5)) arr);

// test the ABI for calls from C++
int fromC_val(array!(int, 5) arr)
{
    assert(arr[] == [1, 2, 3, 4, 5]);
    assert(arr.front == 1);
    assert(arr.back == 5);
    assert(arr.at(2) == 3);

    arr.fill(2);

    int r;
    foreach (e; arr)
        r += e;

    assert(r == 10);
    return r;
}

int fromC_ref(ref const(array!(int, 5)) arr)
{
    int r;
    foreach (e; arr)
        r += e;
    return r;
}
