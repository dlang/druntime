/**
Contains types to differentiate arrays with sentinel values.
*/
module core.sentinel;

/**
Selects the default sentinel value for a type `T`.

It has a special case for the char types, and also allows
the type to define its own default sentinel value if it
has the member `defaultSentinel`. Otherwise, it uses `T.init`.
*/
private template defaultSentinel(T)
{
         static if (is(Unqual!T ==  char)) enum defaultSentinel = '\0';
    else static if (is(Unqual!T == wchar)) enum defaultSentinel = cast(wchar)'\0';
    else static if (is(Unqual!T == dchar)) enum defaultSentinel = cast(dchar)'\0';
    else static if (__traits(hasMember, T, "defaultSentinel")) enum defaultSentinel = T.defaultSentinel;
    else                                   enum defaultSentinel = T.init;
}

// NOTE: T should be unqalified (not const/immutable etc)
//       This "unqualification" of T is done by the `SentinelPtr` and `SentinelArray` templates.
private template SentinelTemplate(T, immutable T sentinelValue)
{
    private enum CommonPtrMembers = q{
        /**
        Converts the ptr to an array by "walking" it for the sentinel value to determine its length.

        Returns:
            the ptr as a SentinelArray
        */
        inout(ArrayType) toArray() inout
        {
            ArrayType array = void;
            array.array = cast(typeof(array.array))ptr[0 .. walkLength()];
            return cast(inout(ArrayType))array;
        }

        /**
        Return the current value pointed to by `ptr`.
        */
        auto front() inout { return *ptr; }
    };
    struct MutablePtr
    {
        alias ArrayType = MutableArray;

        union
        {
            T* ptr;
            ConstPtr asConst;
        }
        alias asConst this; // facilitates implicit conversion to const type
        // alias ptr this; // NEED MULTIPLE ALIAS THIS!!!
        mixin(CommonPtrMembers);

        /**
        Coerce the given `array` to a `SentinelPtr`. It checks and asserts
        if the given array does not contain the sentinel value at `array.ptr[array.length]`.
        */
        this(T[] array) @system
        in { assert(array.ptr[array.length] == sentinelValue,
            "array does not end with sentinel value"); } do
        {
            this.ptr = array.ptr;
        }
    }
    struct ImmutablePtr
    {
        alias ArrayType = ImmutableArray;

        union
        {
            immutable(T)* ptr;
            ConstPtr asConst;
        }
        alias asConst this; // facilitates implicit conversion to const type
        // alias ptr this; // NEED MULTIPLE ALIAS THIS!!!
        mixin(CommonPtrMembers);

        /**
        Coerce the given `array` to a `SentinelPtr`. It checks and asserts
        if the given array does not contain the sentinel value at `array.ptr[array.length]`.
        */
        this(immutable(T)[] array) @system
        in { assert(array.ptr[array.length] == sentinelValue,
            "array does not end with sentinel value"); } do
        {
            this.ptr = array.ptr;
        }
    }
    struct ConstPtr
    {
        alias ArrayType = ConstArray;

        const(T)* ptr;
        alias ptr this;
        mixin(CommonPtrMembers);

        /**
        Coerce the given `array` to a `SentinelPtr`. It checks and asserts
        if the given array does not contain the sentinel value at `array.ptr[array.length]`.
        */
        this(const(T)[] array) @system
        in { assert(array.ptr[array.length] == sentinelValue,
            "array does not end with sentinel value"); } do
        {
            this.ptr = array.ptr;
        }

        /**
        Returns true if `ptr` is pointing at the sentinel value.
        */
        @property bool empty() const { return *this == sentinelValue; }

        /**
        Move ptr to the next value.
        */
        void popFront() { ptr++; }

        /**
        Walks the array to determine its length.

        Returns:
            the length of the array
        */
        size_t walkLength() const
        {
            for(size_t i = 0; ; i++)
            {
                if (ptr[i] == sentinelValue)
                {
                    return i;
                }
            }
        }
    }

    private enum CommonArrayMembers = q{
        /**
        A no-op that just returns the array as is.  This is to be useful for templates that can accept
        normal arrays an sentinel arrays. The function is marked as `@system` not because it is unsafe
        but because it should only be called in unsafe code, mirroring the interface of the free function
        version of asSentinelArray.

        Returns:
            this
        */
        pragma(inline) auto asSentinelArray() @system inout { return this; }
        /// ditto
        pragma(inline) auto asSentinelArrayUnchecked() @system inout { return this; }
    };
    struct MutableArray
    {
        union
        {
            // TODO: assert and make sure the length/ptr has the same alignment as array
            union
            {
                struct
                {
                    size_t length;
                    MutablePtr ptr;
                }
                T[] array;
            }
            ConstArray asConst;
        }
        alias asConst this; // facilitates implicit conversion to const type
        // alias array this; // NEED MULTIPLE ALIAS THIS!!!
        mixin(CommonArrayMembers);

        /**
        Coerce the given `array` to a `SentinelArray`. It checks and asserts
        if the given array does not contain the sentinel value at `array.ptr[array.length]`.
        */
        this(T[] array) @system
        in { assert(array.ptr[array.length] == sentinelValue,
            "array does not end with sentinel value"); } do
        {
            this.array = array;
        }
    }
    struct ImmutableArray
    {
        union
        {
            // TODO: assert and make sure the length/ptr has the same alignment as array
            union
            {
                struct
                {
                    size_t length;
                    ImmutablePtr ptr;
                }
                immutable(T)[] array;
            }
            ConstArray asConst;
        }
        alias asConst this; // facilitates implicit conversion to const type
        // alias array this; // NEED MULTIPLE ALIAS THIS!!!
        mixin(CommonArrayMembers);

        /**
        Coerce the given `array` to a `SentinelArray`. It checks and asserts
        if the given array does not contain the sentinel value at `array.ptr[array.length]`.
        */
        this(immutable(T)[] array) @system
        in { assert(array.ptr[array.length] == sentinelValue,
            "array does not end with sentinel value"); } do
        {
            this.array = array;
        }
    }
    struct ConstArray
    {
        union
        {
            // TODO: assert and make sure the length/ptr has the same alignment as array
            struct
            {
                size_t length;
                ConstPtr ptr;
            }
            const(T)[] array;
        }
        alias array this;
        mixin(CommonArrayMembers);

        /**
        Coerce the given `array` to a `SentinelArray`. It checks and asserts
        if the given array does not contain the sentinel value at `array.ptr[array.length]`.
        */
        this(const(T)[] array) @system
        in { assert(array.ptr[array.length] == sentinelValue,
            "array does not end with sentinel value"); } do
        {
            this.array = array;
        }

        bool opEquals(const(T)[] other) const
        {
            return array == other;
        }
    }
}

/**
A pointer to an array with a sentinel value.
*/
template SentinelPtr(T, T sentinelValue = defaultSentinel!T)
{
         static if (is(T U ==     const U)) alias SentinelPtr = SentinelTemplate!(U, sentinelValue).ConstPtr;
    else static if (is(T U == immutable U)) alias SentinelPtr = SentinelTemplate!(U, sentinelValue).ImmutablePtr;
    else                                    alias SentinelPtr = SentinelTemplate!(T, sentinelValue).MutablePtr;
}

/**
An array with the extra requirement that it ends with a sentinel value at `ptr[length]`.
*/
template SentinelArray(T, T sentinelValue = defaultSentinel!T)
{
         static if (is(T U ==     const U)) alias SentinelArray = SentinelTemplate!(U, sentinelValue).ConstArray;
    else static if (is(T U == immutable U)) alias SentinelArray = SentinelTemplate!(U, sentinelValue).ImmutableArray;
    else                                    alias SentinelArray = SentinelTemplate!(T, sentinelValue).MutableArray;
}

/**
Coerce the given `array` to a `SentinelPtr`. It checks and asserts
if the given array does not contain the sentinel value at `array.ptr[array.length]`.
*/
@property auto asSentinelPtr(T)(T[] array) @system
{
    return SentinelPtr!T(array);
}
/// ditto
@property auto asSentinelPtr(alias sentinelValue, T)(T[] array) @system
    if (is(typeof(sentinelValue == T.init)))
{
    return SentinelPtr!(T, sentinelValue)(array);
}

/**
Coerce the given `array` to a `SentinelPtr` without verifying that it
contains the sentinel value at `array.ptr[array.length]`.
*/
@property auto asSentinelPtrUnchecked(T)(T[] array) @system
{
    SentinelPtr!T sp = void;
    sp.ptr = array.ptr;
    return sp;
}
@property auto asSentinelPtrUnchecked(alias sentinelValue, T)(T[] array) @system
    if (is(typeof(sentinelValue == T.init)))
{
    SentinelPtr!T sp = void;
    sp.ptr = array.ptr;
    return sp;
}
/**
Create a SentinelPtr from a normal pointer without checking
that the array it is pointing to contains the sentinel value.
*/
@property auto asSentinelPtrUnchecked(T)(T* ptr) @system
{
    SentinelPtr!T sp = void;
    sp.ptr = ptr;
    return sp;
}

unittest
{
    auto s1 = "abcd".asSentinelPtr;
    auto s2 = "abcd".asSentinelPtrUnchecked;
    auto s3 = "abcd".ptr.asSentinelPtrUnchecked;

    auto full = "abcd-";
    auto s = full[0..4];
    auto s4 = s.asSentinelPtr!'-';
    auto s5 = s.asSentinelPtrUnchecked!'-';
}

/**
Coerce the given `array` to a `SentinelArray`. It checks and asserts
if the given array does not contain the sentinel value at `array.ptr[array.length]`.
*/
@property auto asSentinelArray(T)(T[] array) @system
{
    return SentinelArray!T(array);
}
/// ditto
@property auto asSentinelArray(alias sentinelValue, T)(T[] array) @system
    if (is(typeof(sentinelValue == T.init)))
{
    return SentinelArray!(T, sentinelValue)(array);
}

/**
Coerce the given `array` to a `SentinelArray` without verifying that it
contains the sentinel value at `array.ptr[array.length]`.
*/
@property auto asSentinelArrayUnchecked(T)(T[] array) @system
{
    SentinelArray!T sa = void;
    sa.array = array;
    return sa;
}
/// ditto
@property auto asSentinelArrayUnchecked(alias sentinelValue, T)(T[] array) @system
    if (is(typeof(sentinelValue == T.init)))
{
    SentinelArray!T sa = void;
    sa.array = array;
    return sa;
}

unittest
{
    auto s1 = "abcd".asSentinelArray;
    auto s2 = "abcd".asSentinelArrayUnchecked;

    auto full = "abcd-";
    auto s = full[0..4];
    auto s3 = s.asSentinelArray!'-';
    auto s4 = s.asSentinelArrayUnchecked!'-';
}

// test as ranges
unittest
{
    {
        auto s = "abcd".asSentinelPtr;
        size_t count = 0;
        foreach(c; s) { count++; }
        assert(count == 4);
    }
    {
        auto s = "abcd".asSentinelArray;
        size_t count = 0;
        foreach(c; s) { count++; }
        assert(count == 4);
    }
    auto abcd = "abcd";
    {
        auto s = abcd[0..3].asSentinelPtr!'d';
        size_t count = 0;
        foreach(c; s) { count++; }
        assert(count == 3);
    }
    {
        auto s = abcd[0..3].asSentinelArray!'d';
        size_t count = 0;
        foreach(c; s) { count++; }
        assert(count == 3);
    }
}


/**
A is a pointer to an array of characters ended with a null-terminator.
*/
alias cstring = SentinelPtr!(const(char));
/// ditto
alias cwstring = SentinelPtr!(const(wchar));
/// ditto
alias cdstring = SentinelPtr!(const(dchar));

unittest
{
    auto p1 = "hello".asSentinelPtr;
    auto p2 = "hello".asSentinelPtrUnchecked;
    assert(p1.walkLength() == 5);
    assert(p2.walkLength() == 5);

    assert(p1.toArray() == "hello");
    assert(p2.toArray() == "hello");
}

version(unittest)
{
    // demonstrate that C functions can be redefined using SentinelPtr
    extern(C) size_t strlen(cstring str);
}

unittest
{
    assert(5 == strlen(StringLiteral!"hello".ptr));

    // NEED MULTIPLE ALIAS THIS to allow SentinelArray to implicitly convert to SentinelPtr
    //assert(5 == strlen(StringLiteral!"hello"));

    // type of string literals should be changed to SentinelString in order for this to work
    //assert(5 == strlen("hello".ptr");

    // this requires both conditions above to work
    //assert(5 == strlen("hello"));
}

unittest
{
    char[10] buffer = void;
    buffer[0 .. 5] = "hello";
    buffer[5] = '\0';
    SentinelArray!char hello = buffer[0..5].asSentinelArray;
    assert(5 == strlen(hello.ptr));
}

// Check that sentinel types can be passed to functions
// with mutable/immutable implicitly converting to const
unittest
{
    static void immutableFooString(SentinelString str) { }
    immutableFooString("hello".asSentinelArray);
    immutableFooString(StringLiteral!"hello");
    // NOTE: this only works if type of string literals is changed to SentinelString
    //immutableFooString("hello");

    static void mutableFooArray(SentinelArray!char str) { }
    mutableFooArray((cast(char[])"hello").asSentinelArray);

    static void constFooArray(SentinelArray!(const(char)) str) { }
    constFooArray("hello".asSentinelArray);
    constFooArray(StringLiteral!"hello");
    constFooArray((cast(const(char)[])"hello").asSentinelArray);
    constFooArray((cast(char[])"hello").asSentinelArray);

    // NOTE: this only works if type of string literals is changed to SentinelString
    //constFooArray("hello");

    static void immutableFooCString(cstring str) { }
    immutableFooCString("hello".asSentinelArray.ptr);
    immutableFooCString(StringLiteral!"hello".ptr);

    static void mutableFooPtr(SentinelPtr!char str) { }
    mutableFooPtr((cast(char[])"hello").asSentinelArray.ptr);

    static void fooPtr(cstring str) { }
    fooPtr("hello".asSentinelArray.ptr);
    fooPtr(StringLiteral!"hello".ptr);
    fooPtr((cast(const(char)[])"hello").asSentinelArray.ptr);
    fooPtr((cast(char[])"hello").asSentinelArray.ptr);
}

// Check that sentinel array/ptr implicitly convert to non-sentinel array/ptr
unittest
{
    static void mutableFooArray(char[] str) { }
    // NEED MULTIPLE ALIAS THIS !!!
    //mutableFooArray((cast(char[])"hello").asSentinelArray);

    static void immutableFooArray(string str) { }
    // NEED MULTIPLE ALIAS THIS !!!
    //immutableFooArray("hello".asSentinelArray);
    //immutableFooArray(StringLiteral!"hello");

    static void constFooArray(const(char)[] str) { }
    constFooArray((cast(char[])"hello").asSentinelArray);
    constFooArray((cast(const(char)[])"hello").asSentinelArray);
    constFooArray("hello".asSentinelArray);
    constFooArray(StringLiteral!"hello");

    static void mutableFooPtr(char* str) { }
    // NEED MULTIPLE ALIAS THIS !!!
    //mutableFooPtr((cast(char[])"hello").asSentinelArray.ptr);

    static void immutableFooPtr(immutable(char)* str) { }
    // NEED MULTIPLE ALIAS THIS !!!
    //immutableFooPtr("hello".asSentinelArray.ptr);
    //immutableFooPtr(StringLiteral!"hello");

    static void constFooPtr(const(char)* str) { }
    constFooPtr((cast(char[])"hello").asSentinelArray.ptr);
    constFooPtr((cast(const(char)[])"hello").asSentinelArray.ptr);
    constFooPtr("hello".asSentinelArray.ptr);
    constFooPtr(StringLiteral!"hello".ptr);
}

/**
An array of characters that contains a null-terminator at the `length` index.

NOTE: the type of string literals could be changed to SentinelString
*/
alias SentinelString = SentinelArray!(immutable(char));
alias SentinelWstring = SentinelArray!(immutable(wchar));
alias SentinelDstring = SentinelArray!(immutable(dchar));

unittest
{
    {
        auto s1 = "hello".asSentinelArray;
        auto s2 = "hello".asSentinelArrayUnchecked;
    }
    {
        SentinelString s = "hello";
    }
}

/**
A template that coerces a string literal to a SentinelString.
Note that this template becomes unnecessary if the type of string literal
is changed to SentinelString.
*/
pragma(inline) @property SentinelString StringLiteral(string s)() @trusted
{
   SentinelString ss = void;
   ss.array = s;
   return ss;
}
/// ditto
pragma(inline) @property SentinelWstring StringLiteral(wstring s)() @trusted
{
   SentinelWstring ss = void;
   ss.array = s;
   return ss;
}
/// ditto
pragma(inline) @property SentinelDstring StringLiteral(dstring s)() @trusted
{
   SentinelDstring ss = void;
   ss.array = s;
   return ss;
}

unittest
{
    // just instantiate for now to make sure they compile
    auto sc = StringLiteral!"hello";
    auto sw = StringLiteral!"hello"w;
    auto sd = StringLiteral!"hello"d;
}

/**
This function converts an array to a SentinelArray.  It requires that the last element `array[$-1]`
be equal to the sentinel value. This differs from the function `asSentinelArray` which requires
the first value outside of the bounds of the array `array[$]` to be equal to the sentinel value.
This function does not require the array to "own" elements outside of its bounds.
*/
@property auto reduceToSentinelArray(T)(T[] array) @trusted
in {
    assert(array.length > 0);
    assert(array[$ - 1] == defaultSentinel!T);
   } do
{
    return asSentinelArrayUnchecked(array[0 .. $-1]);
}
/// ditto
@property auto reduceToSentinelArray(alias sentinelValue, T)(T[] array) @trusted
    if (is(typeof(sentinelValue == T.init)))
    in {
        assert(array.length > 0);
        assert(array[$ - 1] == sentinelValue);
    } do
{
    return array[0 .. $ - 1].asSentinelArrayUnchecked!sentinelValue;
}

///
@safe unittest
{
    auto s1 = "abc\0".reduceToSentinelArray;
    assert(s1.length == 3);
    () @trusted {
        assert(s1.ptr[s1.length] == '\0');
    }();

    auto s2 = "foobar-".reduceToSentinelArray!'-';
    assert(s2.length == 6);
    () @trusted {
        assert(s2.ptr[s2.length] == '-');
    }();
}

// poor mans Unqual
private template Unqual(T)
{
         static if (is(T U ==     const U)) alias Unqual = U;
    else static if (is(T U == immutable U)) alias Unqual = U;
    else                                    alias Unqual = T;
}
