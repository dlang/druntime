/**
 * Contains traits for runtime internal usage.
 *
 * Copyright: Copyright Digital Mars 2014 -.
 * License:   $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
 * Authors:   Martin Nowak
 * Source: $(DRUNTIMESRC core/internal/_traits.d)
 */
module core.internal.traits;

/// taken from std.typetuple.TypeTuple
template TypeTuple(TList...)
{
    alias TypeTuple = TList;
}
alias AliasSeq = TypeTuple;

template FieldTypeTuple(T)
{
    static if (is(T == struct) || is(T == union))
        alias FieldTypeTuple = typeof(T.tupleof[0 .. $ - __traits(isNested, T)]);
    else static if (is(T == class))
        alias FieldTypeTuple = typeof(T.tupleof);
    else
    {
        alias FieldTypeTuple = TypeTuple!T;
    }
}

T trustedCast(T, U)(auto ref U u) @trusted pure nothrow
{
    return cast(T)u;
}

template Unconst(T)
{
         static if (is(T U ==   immutable U)) alias Unconst = U;
    else static if (is(T U == inout const U)) alias Unconst = U;
    else static if (is(T U == inout       U)) alias Unconst = U;
    else static if (is(T U ==       const U)) alias Unconst = U;
    else                                      alias Unconst = T;
}

/// taken from std.traits.Unqual
template Unqual(T)
{
    version (none) // Error: recursive alias declaration @@@BUG1308@@@
    {
             static if (is(T U ==     const U)) alias Unqual = Unqual!U;
        else static if (is(T U == immutable U)) alias Unqual = Unqual!U;
        else static if (is(T U ==     inout U)) alias Unqual = Unqual!U;
        else static if (is(T U ==    shared U)) alias Unqual = Unqual!U;
        else                                    alias Unqual =        T;
    }
    else // workaround
    {
             static if (is(T U ==          immutable U)) alias Unqual = U;
        else static if (is(T U == shared inout const U)) alias Unqual = U;
        else static if (is(T U == shared inout       U)) alias Unqual = U;
        else static if (is(T U == shared       const U)) alias Unqual = U;
        else static if (is(T U == shared             U)) alias Unqual = U;
        else static if (is(T U ==        inout const U)) alias Unqual = U;
        else static if (is(T U ==        inout       U)) alias Unqual = U;
        else static if (is(T U ==              const U)) alias Unqual = U;
        else                                             alias Unqual = T;
    }
}

// Substitute all `inout` qualifiers that appears in T to `const`
template substInout(T)
{
    static if (is(T == immutable))
    {
        alias substInout = T;
    }
    else static if (is(T : shared const U, U) || is(T : const U, U))
    {
        // U is top-unqualified
        mixin("alias substInout = "
            ~ (is(T == shared) ? "shared " : "")
            ~ (is(T == const) || is(T == inout) ? "const " : "")    // substitute inout to const
            ~ "substInoutForm!U;");
    }
    else
        static assert(0);
}

private template substInoutForm(T)
{
    static if (is(T == struct) || is(T == class) || is(T == union) || is(T == interface))
    {
        alias substInoutForm = T;   // prevent matching to the form of alias-this-ed type
    }
    else static if (is(T : V[K], K, V))        alias substInoutForm = substInout!V[substInout!K];
    else static if (is(T : U[n], U, size_t n)) alias substInoutForm = substInout!U[n];
    else static if (is(T : U[], U))            alias substInoutForm = substInout!U[];
    else static if (is(T : U*, U))             alias substInoutForm = substInout!U*;
    else                                       alias substInoutForm = T;
}

/// used to declare an extern(D) function that is defined in a different module
template externDFunc(string fqn, T:FT*, FT) if (is(FT == function))
{
    static if (is(FT RT == return) && is(FT Args == function))
    {
        import core.demangle : mangleFunc;
        enum decl = {
            string s = "extern(D) RT externDFunc(Args)";
            foreach (attr; __traits(getFunctionAttributes, FT))
                s ~= " " ~ attr;
            return s ~ ";";
        }();
        pragma(mangle, mangleFunc!T(fqn)) mixin(decl);
    }
    else
        static assert(0);
}

template staticIota(int beg, int end)
{
    static if (beg + 1 >= end)
    {
        static if (beg >= end)
        {
            alias staticIota = TypeTuple!();
        }
        else
        {
            alias staticIota = TypeTuple!(+beg);
        }
    }
    else
    {
        enum mid = beg + (end - beg) / 2;
        alias staticIota = TypeTuple!(staticIota!(beg, mid), staticIota!(mid, end));
    }
}

private struct __InoutWorkaroundStruct {}
@property T rvalueOf(T)(inout __InoutWorkaroundStruct = __InoutWorkaroundStruct.init);
@property ref T lvalueOf(T)(inout __InoutWorkaroundStruct = __InoutWorkaroundStruct.init);

// taken from std.traits.isAssignable
template isAssignable(Lhs, Rhs = Lhs)
{
    enum isAssignable = __traits(compiles, lvalueOf!Lhs = rvalueOf!Rhs) && __traits(compiles, lvalueOf!Lhs = lvalueOf!Rhs);
}

// taken from std.traits.isInnerClass
template isInnerClass(T) if (is(T == class))
{
    static if (is(typeof(T.outer)))
    {
        template hasOuterMember(T...)
        {
            static if (T.length == 0)
                enum hasOuterMember = false;
            else
                enum hasOuterMember = T[0] == "outer" || hasOuterMember!(T[1 .. $]);
        }
        enum isInnerClass = __traits(isSame, typeof(T.outer), __traits(parent, T)) && !hasOuterMember!(__traits(allMembers, T));
    }
    else
        enum isInnerClass = false;
}

template dtorIsNothrow(T)
{
    enum dtorIsNothrow = is(typeof(function{T t=void;}) : void function() nothrow);
}

// taken from std.meta.allSatisfy
template allSatisfy(alias F, T...)
{
    static foreach (Ti; T)
    {
        static if (!is(typeof(allSatisfy) == bool) && // not yet defined
                   !F!(Ti))
        {
            enum allSatisfy = false;
        }
    }
    static if (!is(typeof(allSatisfy) == bool)) // if not yet defined
    {
        enum allSatisfy = true;
    }
}

// taken from std.meta.anySatisfy
template anySatisfy(alias F, T...)
{
    static foreach (Ti; T)
    {
        static if (!is(typeof(anySatisfy) == bool) && // not yet defined
                   F!(Ti))
        {
            enum anySatisfy = true;
        }
    }
    static if (!is(typeof(anySatisfy) == bool)) // if not yet defined
    {
        enum anySatisfy = false;
    }
}

// simplified from std.traits.maxAlignment
template maxAlignment(U...)
{
    static if (U.length == 0)
        static assert(0);
    else static if (U.length == 1)
        enum maxAlignment = U[0].alignof;
    else static if (U.length == 2)
        enum maxAlignment = U[0].alignof > U[1].alignof ? U[0].alignof : U[1].alignof;
    else
    {
        enum a = maxAlignment!(U[0 .. ($+1)/2]);
        enum b = maxAlignment!(U[($+1)/2 .. $]);
        enum maxAlignment = a > b ? a : b;
    }
}

// std.traits.Fields
template Fields(T)
{
    static if (is(T == struct) || is(T == union))
        alias Fields = typeof(T.tupleof[0 .. $ - __traits(isNested, T)]);
    else static if (is(T == class))
        alias Fields = typeof(T.tupleof);
    else
        alias Fields = TypeTuple!T;
}

// std.traits.hasElaborateDestructor
template hasElaborateDestructor(S)
{
    static if (__traits(isStaticArray, S) && S.length)
    {
        enum bool hasElaborateDestructor = hasElaborateDestructor!(typeof(S.init[0]));
    }
    else static if (is(S == struct))
    {
        enum hasElaborateDestructor = __traits(hasMember, S, "__dtor")
            || anySatisfy!(.hasElaborateDestructor, Fields!S);
    }
    else
    {
        enum bool hasElaborateDestructor = false;
    }
}

// std.traits.hasElaborateCopyDestructor
template hasElaborateCopyConstructor(S)
{
    static if (__traits(isStaticArray, S) && S.length)
    {
        enum bool hasElaborateCopyConstructor = hasElaborateCopyConstructor!(typeof(S.init[0]));
    }
    else static if (is(S == struct))
    {
        enum hasElaborateCopyConstructor = __traits(hasMember, S, "__xpostblit");
    }
    else
    {
        enum bool hasElaborateCopyConstructor = false;
    }
}

template hasElaborateAssign(S)
{
    static if (__traits(isStaticArray, S) && S.length)
    {
        enum bool hasElaborateAssign = hasElaborateAssign!(typeof(S.init[0]));
    }
    else static if (is(S == struct))
    {
        enum hasElaborateAssign = is(typeof(S.init.opAssign(rvalueOf!S))) ||
                                  is(typeof(S.init.opAssign(lvalueOf!S))) ||
                                  anySatisfy!(.hasElaborateAssign, FieldTypeTuple!S);
    }
    else
    {
        enum bool hasElaborateAssign = false;
    }
}

// std.meta.Filter
template Filter(alias pred, TList...)
{
    static if (TList.length == 0)
    {
        alias Filter = TypeTuple!();
    }
    else static if (TList.length == 1)
    {
        static if (pred!(TList[0]))
            alias Filter = TypeTuple!(TList[0]);
        else
            alias Filter = TypeTuple!();
    }
    else
    {
        alias Filter =
            TypeTuple!(
                Filter!(pred, TList[ 0  .. $/2]),
                Filter!(pred, TList[$/2 ..  $ ]));
    }
}

// std.meta.staticMap
template staticMap(alias F, T...)
{
    static if (T.length == 0)
    {
        alias staticMap = TypeTuple!();
    }
    else static if (T.length == 1)
    {
        alias staticMap = TypeTuple!(F!(T[0]));
    }
    else
    {
        alias staticMap =
            TypeTuple!(
                staticMap!(F, T[ 0  .. $/2]),
                staticMap!(F, T[$/2 ..  $ ]));
    }
}

// std.exception.assertCTFEable
version (unittest) package(core)
void assertCTFEable(alias dg)()
{
    static assert({ cast(void) dg(); return true; }());
    cast(void) dg();
}

template DynamicArrayTypeOf(T)
{
    static if (is(AliasThisTypeOf!T AT) && !is(AT[] == AT))
        alias X = DynamicArrayTypeOf!AT;
    else
        alias X = OriginalType!T;

    static if (is(Unqual!X : E[], E) && !is(typeof({ enum n = X.length; })))
    {
        alias DynamicArrayTypeOf = X;
    }
    else
        static assert(0, T.stringof~" is not a dynamic array");
}

enum bool isAggregateType(T) = is(T == struct) || is(T == union) ||
                               is(T == class) || is(T == interface);
enum bool isDynamicArray(T) = is(DynamicArrayTypeOf!T) && !isAggregateType!T;
enum bool isStaticArray(T) = __traits(isStaticArray, T);
enum bool isPointer(T) = is(T == U*, U) && !isAggregateType!T;

/*
Checks whether a given source object contains pointers or references to a given
target object.

Params:
    source = The source object
    target = The target object

Bugs:
    The function is explicitly annotated `@nogc` because inference could fail,
    see $(LINK2 https://issues.dlang.org/show_bug.cgi?id=17084, issue 17084).

Returns: `true` if `source`'s representation embeds a pointer
that points to `target`'s representation or somewhere inside
it.

If `source` is or contains a dynamic array, then, then these functions will check
if there is overlap between the dynamic array and `target`'s representation.

If `source` is a class, then it will be handled as a pointer.

If `target` is a pointer, a dynamic array or a class, then these functions will only
check if `source` points to `target`, $(I not) what `target` references.

If `source` is or contains a union, then there may be either false positives or
false negatives:

`doesPointTo` will return `true` if it is absolutely certain
`source` points to `target`. It may produce false negatives, but never
false positives. This function should be prefered when trying to validate
input data.

`mayPointTo` will return `false` if it is absolutely certain
`source` does not point to `target`. It may produce false positives, but never
false negatives. This function should be prefered for defensively choosing a
code path.

Note: Evaluating $(D doesPointTo(x, x)) checks whether `x` has
internal pointers. This should only be done as an assertive test,
as the language is free to assume objects don't have internal pointers
(TDPL 7.1.3.5).
*/
bool doesPointTo(S, T, Tdummy=void)(auto ref const S source, ref const T target) @nogc @trusted pure nothrow
if (__traits(isRef, source) || isDynamicArray!S ||
    isPointer!S || is(S == class))
{
    static if (isPointer!S || is(S == class) || is(S == interface))
    {
        const m = *cast(void**) &source;
        const b = cast(void*) &target;
        const e = b + target.sizeof;
        return b <= m && m < e;
    }
    else static if (is(S == struct) || is(S == union))
    {
        foreach (i, Subobj; typeof(source.tupleof))
            static if (!isUnionAliased!(S, i))
                if (doesPointTo(source.tupleof[i], target)) return true;
        return false;
    }
    else static if (isStaticArray!S)
    {
        foreach (ref s; source)
            if (doesPointTo(s, target)) return true;
        return false;
    }
    else static if (isDynamicArray!S)
    {
        return overlap(cast(void[]) source, cast(void[])(&target)[0 .. 1]).length != 0;
    }
    else
    {
        return false;
    }
}

// for shared objects
/// ditto
bool doesPointTo(S, T)(auto ref const shared S source, ref const shared T target) @trusted pure nothrow
{
    return doesPointTo!(shared S, shared T, void)(source, target);
}

/+
Returns the overlapping portion, if any, of two arrays. Unlike `equal`,
`overlap` only compares the pointers and lengths in the
ranges, not the values referred by them. If `r1` and `r2` have an
overlapping slice, returns that slice. Otherwise, returns the null
slice.

Params:
    a = The first array to compare
    b = The second array to compare
Returns:
    The overlapping portion of the two arrays.
+/
CommonType!(T[], U[]) overlap(T, U)(T[] a, U[] b) @trusted
if (is(typeof(a.ptr < b.ptr) == bool))
{
    const aLen = a.ptr + a.length;
    const bLen = b.ptr + b.length;
    auto end = aLen < bLen ? aLen : bLen;
    // CTFE requires pairing pointer comparisons, which forces a
    // slightly inefficient implementation.
    if (a.ptr <= b.ptr && b.ptr < a.ptr + a.length)
    {
        return b.ptr[0 .. end - b.ptr];
    }

    if (b.ptr <= a.ptr && a.ptr < b.ptr + b.length)
    {
        return a.ptr[0 .. end - a.ptr];
    }

    return null;
}

///
@safe pure nothrow unittest
{
    int[] a = [ 10, 11, 12, 13, 14 ];
    int[] b = a[1 .. 3];
    assert(overlap(a, b) == [ 11, 12 ]);
    b = b.dup;
    // overlap disappears even though the content is the same
    assert(overlap(a, b).length == 0);

    static test()() @nogc
    {
        auto a = "It's three o'clock"d;
        auto b = a[5 .. 10];
        return b.overlap(a);
    }

    //works at compile-time
    static assert(test == "three"d);
}

@safe nothrow unittest
{
    static void test(L, R)(L l, R r)
    {
        assert(overlap(l, r) == [ 100, 12 ]);

        assert(overlap(l, l[0 .. 2]) is l[0 .. 2]);
        assert(overlap(l, l[3 .. 5]) is l[3 .. 5]);
        assert(overlap(l[0 .. 2], l) is l[0 .. 2]);
        assert(overlap(l[3 .. 5], l) is l[3 .. 5]);
    }

    int[] a = [ 10, 11, 12, 13, 14 ];
    int[] b = a[1 .. 3];
    a[1] = 100;

    immutable int[] c = a.idup;
    immutable int[] d = c[1 .. 3];

    test(a, b);
    assert(overlap(a, b.dup).length == 0);
    test(c, d);
    assert(overlap(c, d.idup).length == 0);
}

/+
Returns true if the field at index `i` in ($D T) shares its address with another field.

Note: This does not merelly check if the field is a member of an union, but also that
it is not a single child.
+/
enum isUnionAliased(T, size_t i) = isUnionAliasedImpl!T(T.tupleof[i].offsetof);
bool isUnionAliasedImpl(T)(size_t offset)
{
    int count = 0;
    foreach (i, U; typeof(T.tupleof))
        if (T.tupleof[i].offsetof == offset)
            ++count;
    return count >= 2;
}
//
@safe unittest
{
    static struct S
    {
        int a0; //Not aliased
        union
        {
            int a1; //Not aliased
        }
        union
        {
            int a2; //Aliased
            int a3; //Aliased
        }
        union A4
        {
            int b0; //Not aliased
        }
        A4 a4;
        union A5
        {
            int b0; //Aliased
            int b1; //Aliased
        }
        A5 a5;
    }

    static assert(!isUnionAliased!(S, 0)); //a0;
    static assert(!isUnionAliased!(S, 1)); //a1;
    static assert( isUnionAliased!(S, 2)); //a2;
    static assert( isUnionAliased!(S, 3)); //a3;
    static assert(!isUnionAliased!(S, 4)); //a4;
        static assert(!isUnionAliased!(S.A4, 0)); //a4.b0;
    static assert(!isUnionAliased!(S, 5)); //a5;
        static assert( isUnionAliased!(S.A5, 0)); //a5.b0;
        static assert( isUnionAliased!(S.A5, 1)); //a5.b1;
}


/*
Get the type that all types can be implicitly converted to. Useful
e.g. in figuring out an array type from a bunch of initializing
values. Returns $(D_PARAM void) if passed an empty list, or if the
types have no common type.
 */
template CommonType(T...)
{
    static if (!T.length)
    {
        alias CommonType = void;
    }
    else static if (T.length == 1)
    {
        static if (is(typeof(T[0])))
        {
            alias CommonType = typeof(T[0]);
        }
        else
        {
            alias CommonType = T[0];
        }
    }
    else static if (is(typeof(true ? T[0].init : T[1].init) U))
    {
        alias CommonType = CommonType!(U, T[2 .. $]);
    }
    else
        alias CommonType = void;
}

///
@safe unittest
{
    alias X = CommonType!(int, long, short);
    assert(is(X == long));
    alias Y = CommonType!(int, char[], short);
    assert(is(Y == void));
}

///
@safe unittest
{
    static assert(is(CommonType!(3) == int));
    static assert(is(CommonType!(double, 4, float) == double));
    static assert(is(CommonType!(string, char[]) == const(char)[]));
    static assert(is(CommonType!(3, 3U) == uint));
    static assert(is(CommonType!(double, int) == double));
}

/*
Returns `true` if and only if `T`'s representation includes at
least one of the following: $(OL $(LI a raw pointer `U*` and `U`
is not immutable;) $(LI an array `U[]` and `U` is not
immutable;) $(LI a reference to a class or interface type `C` and `C` is
not immutable.) $(LI an associative array that is not immutable.)
$(LI a delegate.))
*/
template hasAliasing(T...)
{
    static if (T.length && is(T[0] : Rebindable!R, R))
    {
        enum hasAliasing = hasAliasing!(R, T[1 .. $]);
    }
    else
    {
        template isAliasingDelegate(T)
        {
            enum isAliasingDelegate = isDelegate!T
                                  && !is(T == immutable)
                                  && !is(FunctionTypeOf!T == immutable);
        }
        enum hasAliasing = hasRawAliasing!T || hasObjects!T ||
            anySatisfy!(isAliasingDelegate, T, RepresentationTypeTuple!T);
    }
}

///
@safe unittest
{
    struct S1 { int a; Object b; }
    struct S2 { string a; }
    struct S3 { int a; immutable Object b; }
    struct S4 { float[3] vals; }
    static assert( hasAliasing!S1);
    static assert(!hasAliasing!S2);
    static assert(!hasAliasing!S3);
    static assert(!hasAliasing!S4);
}

@safe unittest
{
    static assert( hasAliasing!(uint[uint]));
    static assert(!hasAliasing!(immutable(uint[uint])));
    static assert( hasAliasing!(void delegate()));
    static assert( hasAliasing!(void delegate() const));
    static assert(!hasAliasing!(void delegate() immutable));
    static assert( hasAliasing!(void delegate() shared));
    static assert( hasAliasing!(void delegate() shared const));
    static assert( hasAliasing!(const(void delegate())));
    static assert( hasAliasing!(const(void delegate() const)));
    static assert(!hasAliasing!(const(void delegate() immutable)));
    static assert( hasAliasing!(const(void delegate() shared)));
    static assert( hasAliasing!(const(void delegate() shared const)));
    static assert(!hasAliasing!(immutable(void delegate())));
    static assert(!hasAliasing!(immutable(void delegate() const)));
    static assert(!hasAliasing!(immutable(void delegate() immutable)));
    static assert(!hasAliasing!(immutable(void delegate() shared)));
    static assert(!hasAliasing!(immutable(void delegate() shared const)));
    static assert( hasAliasing!(shared(const(void delegate()))));
    static assert( hasAliasing!(shared(const(void delegate() const))));
    static assert(!hasAliasing!(shared(const(void delegate() immutable))));
    static assert( hasAliasing!(shared(const(void delegate() shared))));
    static assert( hasAliasing!(shared(const(void delegate() shared const))));
    static assert(!hasAliasing!(void function()));

    interface I;
    static assert( hasAliasing!I);

    static assert( hasAliasing!(Rebindable!(const Object)));
    static assert(!hasAliasing!(Rebindable!(immutable Object)));
    static assert( hasAliasing!(Rebindable!(shared Object)));
    static assert( hasAliasing!(Rebindable!Object));

    struct S5
    {
        void delegate() immutable b;
        shared(void delegate() immutable) f;
        immutable(void delegate() immutable) j;
        shared(const(void delegate() immutable)) n;
    }
    struct S6 { typeof(S5.tupleof) a; void delegate() p; }
    static assert(!hasAliasing!S5);
    static assert( hasAliasing!S6);

    struct S7 { void delegate() a; int b; Object c; }
    class S8 { int a; int b; }
    class S9 { typeof(S8.tupleof) a; }
    class S10 { typeof(S8.tupleof) a; int* b; }
    static assert( hasAliasing!S7);
    static assert( hasAliasing!S8);
    static assert( hasAliasing!S9);
    static assert( hasAliasing!S10);
    struct S11 {}
    class S12 {}
    interface S13 {}
    union S14 {}
    static assert(!hasAliasing!S11);
    static assert( hasAliasing!S12);
    static assert( hasAliasing!S13);
    static assert(!hasAliasing!S14);

    class S15 { S15[1] a; }
    static assert( hasAliasing!S15);
    static assert(!hasAliasing!(immutable(S15)));
}

/*
Statically evaluates to `true` if and only if `T`'s
representation contains at least one field of pointer or array type.
Members of class types are not considered raw pointers. Pointers to
immutable objects are not considered raw aliasing.
*/
template hasRawAliasing(T...)
{
    template Impl(T...)
    {
        static if (T.length == 0)
        {
            enum Impl = false;
        }
        else
        {
            static if (is(T[0] foo : U*, U) && !isFunctionPointer!(T[0]))
                enum has = !is(U == immutable);
            else static if (is(T[0] foo : U[N], U, size_t N))
                // separate static ifs to avoid forward reference
                static if (is(U == class) || is(U == interface))
                    enum has = false;
                else
                    enum has = hasRawAliasing!U;
            else static if (is(T[0] foo : U[], U) && !isStaticArray!(T[0]))
                enum has = !is(U == immutable);
            else static if (isAssociativeArray!(T[0]))
                enum has = !is(T[0] == immutable);
            else
                enum has = false;

            enum Impl = has || Impl!(T[1 .. $]);
        }
    }

    enum hasRawAliasing = Impl!(RepresentationTypeTuple!T);
}

//
@safe unittest
{
    // simple types
    static assert(!hasRawAliasing!int);
    static assert( hasRawAliasing!(char*));
    // references aren't raw pointers
    static assert(!hasRawAliasing!Object);
    // built-in arrays do contain raw pointers
    static assert( hasRawAliasing!(int[]));
    // aggregate of simple types
    struct S1 { int a; double b; }
    static assert(!hasRawAliasing!S1);
    // indirect aggregation
    struct S2 { S1 a; double b; }
    static assert(!hasRawAliasing!S2);
}

// Issue 19228
@safe unittest
{
    static struct C
    {
        int*[1] a;
    }
    static assert(hasRawAliasing!C);
}

@safe unittest
{
    // struct with a pointer member
    struct S3 { int a; double * b; }
    static assert( hasRawAliasing!S3);
    // struct with an indirect pointer member
    struct S4 { S3 a; double b; }
    static assert( hasRawAliasing!S4);
    struct S5 { int a; Object z; int c; }
    static assert( hasRawAliasing!S3);
    static assert( hasRawAliasing!S4);
    static assert(!hasRawAliasing!S5);

    union S6 { int a; int b; }
    union S7 { int a; int * b; }
    static assert(!hasRawAliasing!S6);
    static assert( hasRawAliasing!S7);

    static assert(!hasRawAliasing!(void delegate()));
    static assert(!hasRawAliasing!(void delegate() const));
    static assert(!hasRawAliasing!(void delegate() immutable));
    static assert(!hasRawAliasing!(void delegate() shared));
    static assert(!hasRawAliasing!(void delegate() shared const));
    static assert(!hasRawAliasing!(const(void delegate())));
    static assert(!hasRawAliasing!(immutable(void delegate())));

    struct S8 { void delegate() a; int b; Object c; }
    class S12 { typeof(S8.tupleof) a; }
    class S13 { typeof(S8.tupleof) a; int* b; }
    static assert(!hasRawAliasing!S8);
    static assert(!hasRawAliasing!S12);
    static assert( hasRawAliasing!S13);

    enum S9 { a }
    static assert(!hasRawAliasing!S9);

    // indirect members
    struct S10 { S7 a; int b; }
    struct S11 { S6 a; int b; }
    static assert( hasRawAliasing!S10);
    static assert(!hasRawAliasing!S11);

    static assert( hasRawAliasing!(int[string]));
    static assert(!hasRawAliasing!(immutable(int[string])));
}

/*
Statically evaluates to `true` if and only if `T`'s
representation contains at least one non-shared field of pointer or
array type.  Members of class types are not considered raw pointers.
Pointers to immutable objects are not considered raw aliasing.
*/
template hasRawUnsharedAliasing(T...)
{
    template Impl(T...)
    {
        static if (T.length == 0)
        {
            enum Impl = false;
        }
        else
        {
            static if (is(T[0] foo : U*, U) && !isFunctionPointer!(T[0]))
                enum has = !is(U == immutable) && !is(U == shared);
            else static if (is(T[0] foo : U[], U) && !isStaticArray!(T[0]))
                enum has = !is(U == immutable) && !is(U == shared);
            else static if (isAssociativeArray!(T[0]))
                enum has = !is(T[0] == immutable) && !is(T[0] == shared);
            else
                enum has = false;

            enum Impl = has || Impl!(T[1 .. $]);
        }
    }

    enum hasRawUnsharedAliasing = Impl!(RepresentationTypeTuple!T);
}

//
@safe unittest
{
    // simple types
    static assert(!hasRawUnsharedAliasing!int);
    static assert( hasRawUnsharedAliasing!(char*));
    static assert(!hasRawUnsharedAliasing!(shared char*));
    // references aren't raw pointers
    static assert(!hasRawUnsharedAliasing!Object);
    // built-in arrays do contain raw pointers
    static assert( hasRawUnsharedAliasing!(int[]));
    static assert(!hasRawUnsharedAliasing!(shared int[]));
    // aggregate of simple types
    struct S1 { int a; double b; }
    static assert(!hasRawUnsharedAliasing!S1);
    // indirect aggregation
    struct S2 { S1 a; double b; }
    static assert(!hasRawUnsharedAliasing!S2);
    // struct with a pointer member
    struct S3 { int a; double * b; }
    static assert( hasRawUnsharedAliasing!S3);
    struct S4 { int a; shared double * b; }
    static assert(!hasRawUnsharedAliasing!S4);
}

@safe unittest
{
    // struct with a pointer member
    struct S3 { int a; double * b; }
    static assert( hasRawUnsharedAliasing!S3);
    struct S4 { int a; shared double * b; }
    static assert(!hasRawUnsharedAliasing!S4);
    // struct with an indirect pointer member
    struct S5 { S3 a; double b; }
    static assert( hasRawUnsharedAliasing!S5);
    struct S6 { S4 a; double b; }
    static assert(!hasRawUnsharedAliasing!S6);
    struct S7 { int a; Object z;      int c; }
    static assert( hasRawUnsharedAliasing!S5);
    static assert(!hasRawUnsharedAliasing!S6);
    static assert(!hasRawUnsharedAliasing!S7);

    union S8  { int a; int b; }
    union S9  { int a; int* b; }
    union S10 { int a; shared int* b; }
    static assert(!hasRawUnsharedAliasing!S8);
    static assert( hasRawUnsharedAliasing!S9);
    static assert(!hasRawUnsharedAliasing!S10);

    static assert(!hasRawUnsharedAliasing!(void delegate()));
    static assert(!hasRawUnsharedAliasing!(void delegate() const));
    static assert(!hasRawUnsharedAliasing!(void delegate() immutable));
    static assert(!hasRawUnsharedAliasing!(void delegate() shared));
    static assert(!hasRawUnsharedAliasing!(void delegate() shared const));
    static assert(!hasRawUnsharedAliasing!(const(void delegate())));
    static assert(!hasRawUnsharedAliasing!(const(void delegate() const)));
    static assert(!hasRawUnsharedAliasing!(const(void delegate() immutable)));
    static assert(!hasRawUnsharedAliasing!(const(void delegate() shared)));
    static assert(!hasRawUnsharedAliasing!(const(void delegate() shared const)));
    static assert(!hasRawUnsharedAliasing!(immutable(void delegate())));
    static assert(!hasRawUnsharedAliasing!(immutable(void delegate() const)));
    static assert(!hasRawUnsharedAliasing!(immutable(void delegate() immutable)));
    static assert(!hasRawUnsharedAliasing!(immutable(void delegate() shared)));
    static assert(!hasRawUnsharedAliasing!(immutable(void delegate() shared const)));
    static assert(!hasRawUnsharedAliasing!(shared(void delegate())));
    static assert(!hasRawUnsharedAliasing!(shared(void delegate() const)));
    static assert(!hasRawUnsharedAliasing!(shared(void delegate() immutable)));
    static assert(!hasRawUnsharedAliasing!(shared(void delegate() shared)));
    static assert(!hasRawUnsharedAliasing!(shared(void delegate() shared const)));
    static assert(!hasRawUnsharedAliasing!(shared(const(void delegate()))));
    static assert(!hasRawUnsharedAliasing!(shared(const(void delegate() const))));
    static assert(!hasRawUnsharedAliasing!(shared(const(void delegate() immutable))));
    static assert(!hasRawUnsharedAliasing!(shared(const(void delegate() shared))));
    static assert(!hasRawUnsharedAliasing!(shared(const(void delegate() shared const))));
    static assert(!hasRawUnsharedAliasing!(void function()));

    enum S13 { a }
    static assert(!hasRawUnsharedAliasing!S13);

    // indirect members
    struct S14 { S9  a; int b; }
    struct S15 { S10 a; int b; }
    struct S16 { S6  a; int b; }
    static assert( hasRawUnsharedAliasing!S14);
    static assert(!hasRawUnsharedAliasing!S15);
    static assert(!hasRawUnsharedAliasing!S16);

    static assert( hasRawUnsharedAliasing!(int[string]));
    static assert(!hasRawUnsharedAliasing!(shared(int[string])));
    static assert(!hasRawUnsharedAliasing!(immutable(int[string])));

    struct S17
    {
        void delegate() shared a;
        void delegate() immutable b;
        void delegate() shared const c;
        shared(void delegate()) d;
        shared(void delegate() shared) e;
        shared(void delegate() immutable) f;
        shared(void delegate() shared const) g;
        immutable(void delegate()) h;
        immutable(void delegate() shared) i;
        immutable(void delegate() immutable) j;
        immutable(void delegate() shared const) k;
        shared(const(void delegate())) l;
        shared(const(void delegate() shared)) m;
        shared(const(void delegate() immutable)) n;
        shared(const(void delegate() shared const)) o;
    }
    struct S18 { typeof(S17.tupleof) a; void delegate() p; }
    struct S19 { typeof(S17.tupleof) a; Object p; }
    struct S20 { typeof(S17.tupleof) a; int* p; }
    class S21 { typeof(S17.tupleof) a; }
    class S22 { typeof(S17.tupleof) a; void delegate() p; }
    class S23 { typeof(S17.tupleof) a; Object p; }
    class S24 { typeof(S17.tupleof) a; int* p; }
    static assert(!hasRawUnsharedAliasing!S17);
    static assert(!hasRawUnsharedAliasing!(immutable(S17)));
    static assert(!hasRawUnsharedAliasing!(shared(S17)));
    static assert(!hasRawUnsharedAliasing!S18);
    static assert(!hasRawUnsharedAliasing!(immutable(S18)));
    static assert(!hasRawUnsharedAliasing!(shared(S18)));
    static assert(!hasRawUnsharedAliasing!S19);
    static assert(!hasRawUnsharedAliasing!(immutable(S19)));
    static assert(!hasRawUnsharedAliasing!(shared(S19)));
    static assert( hasRawUnsharedAliasing!S20);
    static assert(!hasRawUnsharedAliasing!(immutable(S20)));
    static assert(!hasRawUnsharedAliasing!(shared(S20)));
    static assert(!hasRawUnsharedAliasing!S21);
    static assert(!hasRawUnsharedAliasing!(immutable(S21)));
    static assert(!hasRawUnsharedAliasing!(shared(S21)));
    static assert(!hasRawUnsharedAliasing!S22);
    static assert(!hasRawUnsharedAliasing!(immutable(S22)));
    static assert(!hasRawUnsharedAliasing!(shared(S22)));
    static assert(!hasRawUnsharedAliasing!S23);
    static assert(!hasRawUnsharedAliasing!(immutable(S23)));
    static assert(!hasRawUnsharedAliasing!(shared(S23)));
    static assert( hasRawUnsharedAliasing!S24);
    static assert(!hasRawUnsharedAliasing!(immutable(S24)));
    static assert(!hasRawUnsharedAliasing!(shared(S24)));
    struct S25 {}
    class S26 {}
    interface S27 {}
    union S28 {}
    static assert(!hasRawUnsharedAliasing!S25);
    static assert(!hasRawUnsharedAliasing!S26);
    static assert(!hasRawUnsharedAliasing!S27);
    static assert(!hasRawUnsharedAliasing!S28);
}

/*
Statically evaluates to `true` if and only if `T`'s
representation includes at least one non-immutable object reference.
*/
template hasObjects(T...)
{
    static if (T.length == 0)
    {
        enum hasObjects = false;
    }
    else static if (is(T[0] == struct))
    {
        enum hasObjects = hasObjects!(
            RepresentationTypeTuple!(T[0]), T[1 .. $]);
    }
    else
    {
        enum hasObjects = ((is(T[0] == class) || is(T[0] == interface))
            && !is(T[0] == immutable)) || hasObjects!(T[1 .. $]);
    }
}

/*
Statically evaluates to `true` if and only if `T`'s
representation includes at least one non-immutable non-shared object
reference.
*/
template hasUnsharedObjects(T...)
{
    static if (T.length == 0)
    {
        enum hasUnsharedObjects = false;
    }
    else static if (is(T[0] == struct))
    {
        enum hasUnsharedObjects = hasUnsharedObjects!(
            RepresentationTypeTuple!(T[0]), T[1 .. $]);
    }
    else
    {
        enum hasUnsharedObjects = ((is(T[0] == class) || is(T[0] == interface)) &&
                                !is(T[0] == immutable) && !is(T[0] == shared)) ||
            hasUnsharedObjects!(T[1 .. $]);
    }
}

// used by both Rebindable and UnqualRef
mixin template RebindableCommon(T, U, alias This)
if (is(T == class) || is(T == interface) || isAssociativeArray!T)
{
    private union
    {
        T original;
        U stripped;
    }

    void opAssign(T another) pure nothrow @nogc
    {
        // If `T` defines `opCast` we must infer the safety
        static if (hasMember!(T, "opCast"))
        {
            // This will allow the compiler to infer the safety of `T.opCast!U`
            // without generating any runtime cost
            if (false) { stripped = cast(U) another; }
        }
        () @trusted { stripped = cast(U) another; }();
    }

    void opAssign(typeof(this) another) @trusted pure nothrow @nogc
    {
        stripped = another.stripped;
    }

    static if (is(T == const U) && is(T == const shared U))
    {
        // safely assign immutable to const / const shared
        void opAssign(This!(immutable U) another) @trusted pure nothrow @nogc
        {
            stripped = another.stripped;
        }
    }

    this(T initializer) pure nothrow @nogc
    {
        // Infer safety from opAssign
        opAssign(initializer);
    }

    @property inout(T) get() @trusted pure nothrow @nogc inout
    {
        return original;
    }

    bool opEquals()(auto ref const(typeof(this)) rhs) const
    {
        // Must forward explicitly because 'stripped' is part of a union.
        // The necessary 'toHash' is forwarded to the class via alias this.
        return stripped == rhs.stripped;
    }

    bool opEquals(const(U) rhs) const
    {
        return stripped == rhs;
    }

    alias get this;
}

/*
`Rebindable!(T)` is a simple, efficient wrapper that behaves just
like an object of type `T`, except that you can reassign it to
refer to another object. For completeness, `Rebindable!(T)` aliases
itself away to `T` if `T` is a non-const object type.

You may want to use `Rebindable` when you want to have mutable
storage referring to `const` objects, for example an array of
references that must be sorted in place. `Rebindable` does not
break the soundness of D's type system and does not incur any of the
risks usually associated with `cast`.

Params:
    T = An object, interface, array slice type, or associative array type.
 */
template Rebindable(T)
if (is(T == class) || is(T == interface) || isDynamicArray!T || isAssociativeArray!T)
{
    static if (is(T == const U, U) || is(T == immutable U, U))
    {
        static if (isDynamicArray!T)
        {
            alias Rebindable = const(ElementEncodingType!T)[];
        }
        else
        {
            struct Rebindable
            {
                mixin RebindableCommon!(T, U, Rebindable);
            }
        }
    }
    else
    {
        alias Rebindable = T;
    }
}

///Regular `const` object references cannot be reassigned.
@safe unittest
{
    class Widget { int x; int y() @safe const { return x; } }
    const a = new Widget;
    // Fine
    a.y();
    // error! can't modify const a
    // a.x = 5;
    // error! can't modify const a
    // a = new Widget;
}

/**
    However, `Rebindable!(Widget)` does allow reassignment,
    while otherwise behaving exactly like a $(D const Widget).
 */
@safe unittest
{
    class Widget { int x; int y() const @safe { return x; } }
    auto a = Rebindable!(const Widget)(new Widget);
    // Fine
    a.y();
    // error! can't modify const a
    // a.x = 5;
    // Fine
    a = new Widget;
}

@safe unittest // issue 16054
{
    Rebindable!(immutable Object) r;
    static assert(__traits(compiles, r.get()));
    static assert(!__traits(compiles, &r.get()));
}

@safe unittest
{
    class CustomToHash
    {
        override size_t toHash() const nothrow @trusted { return 42; }
    }
    Rebindable!(immutable(CustomToHash)) a = new immutable CustomToHash();
    assert(a.toHash() == 42, "Rebindable!A should offer toHash()"
        ~ " by forwarding to A.toHash().");
}

@system unittest // issue 18615: Rebindable!A should use A.opEquals
{
    class CustomOpEq
    {
        int x;
        override bool opEquals(Object rhsObj)
        {
            if (auto rhs = cast(const(CustomOpEq)) rhsObj)
                return this.x == rhs.x;
            else
                return false;
        }
    }
    CustomOpEq a = new CustomOpEq();
    CustomOpEq b = new CustomOpEq();
    assert(a !is b);
    assert(a == b, "a.x == b.x should be true (0 == 0).");

    Rebindable!(const(CustomOpEq)) ra = a;
    Rebindable!(const(CustomOpEq)) rb = b;
    assert(ra !is rb);
    assert(ra == rb, "Rebindable should use CustomOpEq's opEquals, not 'is'.");
    assert(ra == b, "Rebindable!(someQualifier(A)) should be comparable"
        ~ " against const(A) via A.opEquals.");
    assert(a == rb, "Rebindable!(someQualifier(A)) should be comparable"
        ~ " against const(A) via A.opEquals.");

    b.x = 1;
    assert(a != b);
    assert(ra != b, "Rebindable!(someQualifier(A)) should be comparable"
        ~ " against const(A) via A.opEquals.");
    assert(a != rb, "Rebindable!(someQualifier(A)) should be comparable"
        ~ " against const(A) via A.opEquals.");

    Rebindable!(const(Object)) o1 = new Object();
    Rebindable!(const(Object)) o2 = new Object();
    assert(o1 !is o2);
    assert(o1 == o1, "When the class doesn't provide its own opEquals,"
        ~ " Rebindable treats 'a == b' as 'a is b' like Object.opEquals.");
    assert(o1 != o2, "When the class doesn't provide its own opEquals,"
        ~ " Rebindable treats 'a == b' as 'a is b' like Object.opEquals.");
    assert(o1 != new Object(), "Rebindable!(const(Object)) should be"
        ~ " comparable against Object itself and use Object.opEquals.");
}

@safe unittest // issue 18755
{
    static class Foo
    {
        auto opCast(T)() @system immutable pure nothrow
        {
            *(cast(uint*) 0xdeadbeef) = 0xcafebabe;
            return T.init;
        }
    }

    static assert(!__traits(compiles, () @safe {
        auto r = Rebindable!(immutable Foo)(new Foo);
    }));
    static assert(__traits(compiles, () @system {
        auto r = Rebindable!(immutable Foo)(new Foo);
    }));
}

/*
Get the primitive types of the fields of a struct or class, in
topological order.
*/
template RepresentationTypeTuple(T)
{
    template Impl(T...)
    {
        static if (T.length == 0)
        {
            alias Impl = AliasSeq!();
        }
        else
        {
            static if (is(T[0] R: Rebindable!R))
            {
                alias Impl = Impl!(Impl!R, T[1 .. $]);
            }
            else  static if (is(T[0] == struct) || is(T[0] == union))
            {
                // @@@BUG@@@ this should work
                //alias .RepresentationTypes!(T[0].tupleof)
                //    RepresentationTypes;
                alias Impl = Impl!(FieldTypeTuple!(T[0]), T[1 .. $]);
            }
            else
            {
                alias Impl = AliasSeq!(T[0], Impl!(T[1 .. $]));
            }
        }
    }

    static if (is(T == struct) || is(T == union) || is(T == class))
    {
        alias RepresentationTypeTuple = Impl!(FieldTypeTuple!T);
    }
    else
    {
        alias RepresentationTypeTuple = Impl!T;
    }
}

///
@safe unittest
{
    struct S1 { int a; float b; }
    struct S2 { char[] a; union { S1 b; S1 * c; } }
    alias R = RepresentationTypeTuple!S2;
    assert(R.length == 4
        && is(R[0] == char[]) && is(R[1] == int)
        && is(R[2] == float) && is(R[3] == S1*));
}

@safe unittest
{
    alias S1 = RepresentationTypeTuple!int;
    static assert(is(S1 == AliasSeq!int));

    struct S2 { int a; }
    struct S3 { int a; char b; }
    struct S4 { S1 a; int b; S3 c; }
    static assert(is(RepresentationTypeTuple!S2 == AliasSeq!int));
    static assert(is(RepresentationTypeTuple!S3 == AliasSeq!(int, char)));
    static assert(is(RepresentationTypeTuple!S4 == AliasSeq!(int, int, int, char)));

    struct S11 { int a; float b; }
    struct S21 { char[] a; union { S11 b; S11 * c; } }
    alias R = RepresentationTypeTuple!S21;
    assert(R.length == 4
           && is(R[0] == char[]) && is(R[1] == int)
           && is(R[2] == float) && is(R[3] == S11*));

    class C { int a; float b; }
    alias R1 = RepresentationTypeTuple!C;
    static assert(R1.length == 2 && is(R1[0] == int) && is(R1[1] == float));

    /* Issue 6642 */
    struct S5 { int a; Rebindable!(immutable Object) b; }
    alias R2 = RepresentationTypeTuple!S5;
    static assert(R2.length == 2 && is(R2[0] == int) && is(R2[1] == immutable(Object)));
}

/*
The element type of `R`. `R` does not have to be a range. The
element type is determined as the type yielded by `r.front` for an
object `r` of type `R`. For example, `ElementType!(T[])` is
`T` if `T[]` isn't a narrow string; if it is, the element type is
`dchar`. If `R` doesn't have `front`, `ElementType!R` is
`void`.
 */
template ElementType(R)
{
    static if (is(typeof(R.init.front.init) T))
        alias ElementType = T;
    else
        alias ElementType = void;
}

/*
Moved from std.range, but not enabled as it uses std.range.iota
@safe unittest
{
    import std.range : iota;

    // Standard arrays: returns the type of the elements of the array
    static assert(is(ElementType!(int[]) == int));

    // Accessing .front retrieves the decoded dchar
    static assert(is(ElementType!(char[])  == dchar)); // rvalue
    static assert(is(ElementType!(dchar[]) == dchar)); // lvalue

    // Ditto
    static assert(is(ElementType!(string) == dchar));
    static assert(is(ElementType!(dstring) == immutable(dchar)));

    // For ranges it gets the type of .front.
    auto range = iota(0, 10);
    static assert(is(ElementType!(typeof(range)) == int));
}
*/

@safe unittest
{
    static assert(is(ElementType!(byte[]) == byte));
    static assert(is(ElementType!(wchar[]) == dchar)); // rvalue
    static assert(is(ElementType!(wstring) == dchar));
}

@safe unittest
{
    enum XYZ : string { a = "foo" }
    auto x = XYZ.a.front;
    immutable char[3] a = "abc";
    int[] i;
    void[] buf;
    static assert(is(ElementType!(XYZ) == dchar));
    static assert(is(ElementType!(typeof(a)) == dchar));
    static assert(is(ElementType!(typeof(i)) == int));
    static assert(is(ElementType!(typeof(buf)) == void));
    static assert(is(ElementType!(inout(int)[]) == inout(int)));
    static assert(is(ElementType!(inout(int[])) == inout(int)));
}

@safe unittest
{
    static assert(is(ElementType!(int[5]) == int));
    static assert(is(ElementType!(int[0]) == int));
    static assert(is(ElementType!(char[5]) == dchar));
    static assert(is(ElementType!(char[0]) == dchar));
}

@safe unittest //11336
{
    static struct S
    {
        this(this) @disable;
    }
    static assert(is(ElementType!(S[]) == S));
}

@safe unittest // 11401
{
    // ElementType should also work for non-@propety 'front'
    struct E { ushort id; }
    struct R
    {
        E front() { return E.init; }
    }
    static assert(is(ElementType!R == E));
}

/**
The encoding element type of `R`. For narrow strings (`char[]`,
`wchar[]` and their qualified variants including `string` and
`wstring`), `ElementEncodingType` is the character type of the
string. For all other types, `ElementEncodingType` is the same as
`ElementType`.
 */
template ElementEncodingType(R)
{
    static if (is(StringTypeOf!R) && is(R : E[], E))
        alias ElementEncodingType = E;
    else
        alias ElementEncodingType = ElementType!R;
}

/*
Moved from std.range, but not enabled as it uses std.range.iota
@safe unittest
{
    import std.range : iota;
    // internally the range stores the encoded type
    static assert(is(ElementEncodingType!(char[])  == char));

    static assert(is(ElementEncodingType!(wstring) == immutable(wchar)));

    static assert(is(ElementEncodingType!(byte[]) == byte));

    auto range = iota(0, 10);
    static assert(is(ElementEncodingType!(typeof(range)) == int));
}
*/

@safe unittest
{
    static assert(is(ElementEncodingType!(wchar[]) == wchar));
    static assert(is(ElementEncodingType!(dchar[]) == dchar));
    static assert(is(ElementEncodingType!(string)  == immutable(char)));
    static assert(is(ElementEncodingType!(dstring) == immutable(dchar)));
    static assert(is(ElementEncodingType!(int[])  == int));
}

@safe unittest
{
    enum XYZ : string { a = "foo" }
    auto x = XYZ.a.front;
    immutable char[3] a = "abc";
    int[] i;
    void[] buf;
    static assert(is(ElementType!(XYZ) : dchar));
    static assert(is(ElementEncodingType!(char[]) == char));
    static assert(is(ElementEncodingType!(string) == immutable char));
    static assert(is(ElementType!(typeof(a)) : dchar));
    static assert(is(ElementType!(typeof(i)) == int));
    static assert(is(ElementEncodingType!(typeof(i)) == int));
    static assert(is(ElementType!(typeof(buf)) : void));

    static assert(is(ElementEncodingType!(inout char[]) : inout(char)));
}

@safe unittest
{
    static assert(is(ElementEncodingType!(int[5]) == int));
    static assert(is(ElementEncodingType!(int[0]) == int));
    static assert(is(ElementEncodingType!(char[5]) == char));
    static assert(is(ElementEncodingType!(char[0]) == char));
}

/*
Detect whether symbol or type `T` is a delegate.
*/
template isDelegate(T...)
if (T.length == 1)
{
    static if (is(typeof(& T[0]) U : U*) && is(typeof(& T[0]) U == delegate))
    {
        // T is a (nested) function symbol.
        enum bool isDelegate = true;
    }
    else static if (is(T[0] W) || is(typeof(T[0]) W))
    {
        // T is an expression or a type.  Take the type of it and examine.
        enum bool isDelegate = is(W == delegate);
    }
    else
        enum bool isDelegate = false;
}

//
@safe unittest
{
    static void sfunc() { }
    int x;
    void func() { x++; }

    int delegate() dg;
    assert(isDelegate!dg);
    assert(isDelegate!(int delegate()));
    assert(isDelegate!(typeof(&func)));

    int function() fp;
    assert(!isDelegate!fp);
    assert(!isDelegate!(int function()));
    assert(!isDelegate!(typeof(&sfunc)));
}

/*
 * Detect whether `T` is an associative array type
 */
enum bool isAssociativeArray(T) = __traits(isAssociativeArray, T);

@safe unittest
{
    struct Foo
    {
        @property uint[] keys()   { return null; }
        @property uint[] values() { return null; }
    }

    static foreach (T; AliasSeq!(int[int], int[string], immutable(char[5])[int]))
    {
        static foreach (Q; TypeQualifierList)
        {
            static assert( isAssociativeArray!(Q!T));
            static assert(!isAssociativeArray!(SubTypeOf!(Q!T)));
        }
    }

    static assert(!isAssociativeArray!Foo);
    static assert(!isAssociativeArray!int);
    static assert(!isAssociativeArray!(int[]));
    static assert(!isAssociativeArray!(typeof(null)));

    //enum EAA : int[int] { a = [1:1], b = [2:2] }
    //static assert( isAssociativeArray!EAA);
}

/*
Detect whether symbol or type `T` is a function pointer.
 */
template isFunctionPointer(T...)
if (T.length == 1)
{
    static if (is(T[0] U) || is(typeof(T[0]) U))
    {
        static if (is(U F : F*) && is(F == function))
            enum bool isFunctionPointer = true;
        else
            enum bool isFunctionPointer = false;
    }
    else
        enum bool isFunctionPointer = false;
}

//
@safe unittest
{
    static void foo() {}
    void bar() {}

    auto fpfoo = &foo;
    static assert( isFunctionPointer!fpfoo);
    static assert( isFunctionPointer!(void function()));

    auto dgbar = &bar;
    static assert(!isFunctionPointer!dgbar);
    static assert(!isFunctionPointer!(void delegate()));
    static assert(!isFunctionPointer!foo);
    static assert(!isFunctionPointer!bar);

    static assert( isFunctionPointer!((int a) {}));
}

/*
   Yields `true` if and only if `T` is an aggregate that defines
   a symbol called `name`.
 */
enum hasMember(T, string name) = __traits(hasMember, T, name);

//
@safe unittest
{
    static assert(!hasMember!(int, "blah"));
    struct S1 { int blah; }
    struct S2 { int blah(){ return 0; } }
    class C1 { int blah; }
    class C2 { int blah(){ return 0; } }
    static assert(hasMember!(S1, "blah"));
    static assert(hasMember!(S2, "blah"));
    static assert(hasMember!(C1, "blah"));
    static assert(hasMember!(C2, "blah"));
}

@safe unittest
{
    // 8321
    struct S {
        int x;
        void f(){}
        void t()(){}
        template T(){}
    }
    struct R1(T) {
        T t;
        alias t this;
    }
    struct R2(T) {
        T t;
        @property ref inout(T) payload() inout { return t; }
        alias t this;
    }
    static assert(hasMember!(S, "x"));
    static assert(hasMember!(S, "f"));
    static assert(hasMember!(S, "t"));
    static assert(hasMember!(S, "T"));
    static assert(hasMember!(R1!S, "x"));
    static assert(hasMember!(R1!S, "f"));
    static assert(hasMember!(R1!S, "t"));
    static assert(hasMember!(R1!S, "T"));
    static assert(hasMember!(R2!S, "x"));
    static assert(hasMember!(R2!S, "f"));
    static assert(hasMember!(R2!S, "t"));
    static assert(hasMember!(R2!S, "T"));
}

@safe unittest
{
    static struct S
    {
        void opDispatch(string n, A)(A dummy) {}
    }
    static assert(hasMember!(S, "foo"));
}

/*
Implements the range interface primitive `front` for built-in
arrays. Due to the fact that nonmember functions can be called with
the first argument using the dot notation, `array.front` is
equivalent to `front(array)`. For $(GLOSSARY narrow strings), $(D
front) automatically returns the first $(GLOSSARY code point) as _a $(D
dchar).
*/
private @property ref T front(T)(return scope T[] a) @safe pure nothrow @nogc
if (!isNarrowString!(T[]) && !is(T[] == void[]))
// We would have preferred to write the function template
// ---
//     @property ref inout(T) front(T)(return scope inout(T)[] a)
//        if (/* same constraint */)
// ---
// as that would cause fewer distinct functions to be generated with
// IFTI, but that caused a linker error in the test suite on Win32_64.
{
    assert(a.length, "Attempting to fetch the front of an empty array of " ~ T.stringof);
    return a[0];
}

//
@safe pure nothrow unittest
{
    int[] a = [ 1, 2, 3 ];
    assert(a.front == 1);
}

@safe pure nothrow unittest
{
    auto a = [ 1, 2 ];
    a.front = 4;
    assert(a.front == 4);
    assert(a == [ 4, 2 ]);

    immutable b = [ 1, 2 ];
    assert(b.front == 1);

    int[2] c = [ 1, 2 ];
    assert(c.front == 1);
}

// ditto
private @property dchar front(T)(scope const(T)[] a) @safe pure
if (isNarrowString!(T[]))
{
    import core.internal.utf : decode;
    assert(a.length, "Attempting to fetch the front of an empty array of " ~ T.stringof);
    size_t i = 0;
    return decode(a, i);
}

/*
 * Detect whether type `T` is a narrow string.
 *
 * All arrays that use char, wchar, and their qualified versions are narrow
 * strings. (Those include string and wstring).
 */
enum bool isNarrowString(T) = isSomeString!T && !is(T : const dchar[]);

//
@safe unittest
{
    static assert(isNarrowString!string);
    static assert(isNarrowString!wstring);
    static assert(isNarrowString!(char[]));
    static assert(isNarrowString!(wchar[]));

    static assert(!isNarrowString!dstring);
    static assert(!isNarrowString!(dchar[]));

    static assert(!isNarrowString!(typeof(null)));
    static assert(!isNarrowString!(char[4]));

    enum ES : string { a = "aaa", b = "bbb" }
    static assert(!isNarrowString!ES);

    static struct Stringish
    {
        string str;
        alias str this;
    }
    static assert(!isNarrowString!Stringish);
}

@safe unittest
{
    static foreach (T; AliasSeq!(char[], string, wstring))
    {
        static foreach (Q; AliasSeq!(MutableOf, ConstOf, ImmutableOf)/*TypeQualifierList*/)
        {
            static assert( isNarrowString!(            Q!T  ));
            static assert(!isNarrowString!( SubTypeOf!(Q!T) ));
        }
    }

    static foreach (T; AliasSeq!(int, int[], byte[], dchar[], dstring, char[4]))
    {
        static foreach (Q; TypeQualifierList)
        {
            static assert(!isNarrowString!(            Q!T  ));
            static assert(!isNarrowString!( SubTypeOf!(Q!T) ));
        }
    }
}

/*
Detect whether `T` is one of the built-in string types.

The built-in string types are `Char[]`, where `Char` is any of `char`,
`wchar` or `dchar`, with or without qualifiers.

Static arrays of characters (like `char[80]`) are not considered
built-in string types.
 */
enum bool isSomeString(T) = is(StringTypeOf!T) && !isAggregateType!T && !isStaticArray!T && !is(T == enum);

//
@safe unittest
{
    //String types
    static assert( isSomeString!string);
    static assert( isSomeString!(wchar[]));
    static assert( isSomeString!(dchar[]));
    static assert( isSomeString!(typeof("aaa")));
    static assert( isSomeString!(const(char)[]));

    //Non string types
    static assert(!isSomeString!int);
    static assert(!isSomeString!(int[]));
    static assert(!isSomeString!(byte[]));
    static assert(!isSomeString!(typeof(null)));
    static assert(!isSomeString!(char[4]));

    enum ES : string { a = "aaa", b = "bbb" }
    static assert(!isSomeString!ES);

    static struct Stringish
    {
        string str;
        alias str this;
    }
    static assert(!isSomeString!Stringish);
}

@safe unittest
{
    static foreach (T; AliasSeq!(char[], dchar[], string, wstring, dstring))
    {
        static assert( isSomeString!(           T ));
        static assert(!isSomeString!(SubTypeOf!(T)));
    }
}

/*
Always returns the Dynamic Array version.
 */
template StringTypeOf(T)
{
    static if (is(T == typeof(null)))
    {
        // It is impossible to determine exact string type from typeof(null) -
        // it means that StringTypeOf!(typeof(null)) is undefined.
        // Then this behavior is convenient for template constraint.
        static assert(0, T.stringof~" is not a string type");
    }
    else static if (is(T : const char[]) || is(T : const wchar[]) || is(T : const dchar[]))
    {
        static if (is(T : U[], U))
            alias StringTypeOf = U[];
        else
            static assert(0);
    }
    else
        static assert(0, T.stringof~" is not a string type");
}

@safe unittest
{
    static foreach (T; CharTypeList)
        static foreach (Q; AliasSeq!(MutableOf, ConstOf, ImmutableOf, InoutOf))
        {
            static assert(is(Q!T[] == StringTypeOf!( Q!T[] )));

            static if (!__traits(isSame, Q, InoutOf))
            {{
                static assert(is(Q!T[] == StringTypeOf!( SubTypeOf!(Q!T[]) )));

                alias Str = Q!T[];
                class C(S) { S val;  alias val this; }
                static assert(is(StringTypeOf!(C!Str) == Str));
            }}
        }

    static foreach (T; CharTypeList)
        static foreach (Q; AliasSeq!(SharedOf, SharedConstOf, SharedInoutOf))
        {
            static assert(!is(StringTypeOf!( Q!T[] )));
        }
}

@safe unittest
{
    static assert(is(StringTypeOf!(char[4]) == char[]));
}

version (unittest)
{
    alias TypeQualifierList = AliasSeq!(MutableOf, ConstOf, SharedOf, SharedConstOf, ImmutableOf);

    struct SubTypeOf(T)
    {
        T val;
        alias val this;
    }
}

private alias CharTypeList          = AliasSeq!(char, wchar, dchar);

package
{
    // Add the mutable qualifier to the given type T.
    template MutableOf(T)     { alias MutableOf     =              T  ; }
}

/**
 * Params:
 *     T = The type to qualify
 * Returns:
 *     `T` with the `inout` qualifier added.
 */
template InoutOf(T)
{
    alias InoutOf = inout(T);
}

///
@safe unittest
{
    static assert(is(InoutOf!(int) == inout int));
    static assert(is(InoutOf!(inout int) == inout int));
    static assert(is(InoutOf!(const int) == inout const int));
    static assert(is(InoutOf!(shared int) == inout shared int));
}

/**
 * Params:
 *     T = The type to qualify
 * Returns:
 *     `T` with the `const` qualifier added.
 */
template ConstOf(T)
{
    alias ConstOf = const(T);
}

///
@safe unittest
{
    static assert(is(ConstOf!(int) == const int));
    static assert(is(ConstOf!(const int) == const int));
    static assert(is(ConstOf!(inout int) == const inout int));
    static assert(is(ConstOf!(shared int) == const shared int));
}

/**
 * Params:
 *     T = The type to qualify
 * Returns:
 *     `T` with the `shared` qualifier added.
 */
template SharedOf(T)
{
    alias SharedOf = shared(T);
}

///
@safe unittest
{
    static assert(is(SharedOf!(int) == shared int));
    static assert(is(SharedOf!(shared int) == shared int));
    static assert(is(SharedOf!(inout int) == shared inout int));
    static assert(is(SharedOf!(immutable int) == shared immutable int));
}

/**
 * Params:
 *     T = The type to qualify
 * Returns:
 *     `T` with the `inout` and `shared` qualifiers added.
 */
template SharedInoutOf(T)
{
    alias SharedInoutOf = shared(inout(T));
}

///
@safe unittest
{
    static assert(is(SharedInoutOf!(int) == shared inout int));
    static assert(is(SharedInoutOf!(int) == inout shared int));

    static assert(is(SharedInoutOf!(const int) == shared inout const int));
    static assert(is(SharedInoutOf!(immutable int) == shared inout immutable int));
}

/**
 * Params:
 *     T = The type to qualify
 * Returns:
 *     `T` with the `const` and `shared` qualifiers added.
 */
template SharedConstOf(T)
{
    alias SharedConstOf = shared(const(T));
}

///
@safe unittest
{
    static assert(is(SharedConstOf!(int) == shared const int));
    static assert(is(SharedConstOf!(int) == const shared int));

    static assert(is(SharedConstOf!(inout int) == shared inout const int));
    // immutable variables are implicitly shared and const
    static assert(is(SharedConstOf!(immutable int) == immutable int));
}

/**
 * Params:
 *     T = The type to qualify
 * Returns:
 *     `T` with the `immutable` qualifier added.
 */
template ImmutableOf(T)
{
    alias ImmutableOf = immutable(T);
}

///
@safe unittest
{
    static assert(is(ImmutableOf!(int) == immutable int));
    static assert(is(ImmutableOf!(const int) == immutable int));
    static assert(is(ImmutableOf!(inout int) == immutable int));
    static assert(is(ImmutableOf!(shared int) == immutable int));
}

@safe unittest
{
    static assert(is(    MutableOf!int ==              int));
    static assert(is(      InoutOf!int ==        inout int));
    static assert(is(      ConstOf!int ==        const int));
    static assert(is(     SharedOf!int == shared       int));
    static assert(is(SharedInoutOf!int == shared inout int));
    static assert(is(SharedConstOf!int == shared const int));
    static assert(is(  ImmutableOf!int ==    immutable int));
}

/**
Get the function type from a callable object `func`.

Using builtin `typeof` on a property function yields the types of the
property value, not of the property function itself.  Still,
`FunctionTypeOf` is able to obtain function types of properties.

Note:
Do not confuse function types with function pointer types; function types are
usually used for compile-time reflection purposes.
 */
template FunctionTypeOf(func...)
if (func.length == 1 && isCallable!func)
{
    static if (is(typeof(& func[0]) Fsym : Fsym*) && is(Fsym == function) || is(typeof(& func[0]) Fsym == delegate))
    {
        alias FunctionTypeOf = Fsym; // HIT: (nested) function symbol
    }
    else static if (is(typeof(& func[0].opCall) Fobj == delegate))
    {
        alias FunctionTypeOf = Fobj; // HIT: callable object
    }
    else static if (is(typeof(& func[0].opCall) Ftyp : Ftyp*) && is(Ftyp == function))
    {
        alias FunctionTypeOf = Ftyp; // HIT: callable type
    }
    else static if (is(func[0] T) || is(typeof(func[0]) T))
    {
        static if (is(T == function))
            alias FunctionTypeOf = T;    // HIT: function
        else static if (is(T Fptr : Fptr*) && is(Fptr == function))
            alias FunctionTypeOf = Fptr; // HIT: function pointer
        else static if (is(T Fdlg == delegate))
            alias FunctionTypeOf = Fdlg; // HIT: delegate
        else
            static assert(0);
    }
    else
        static assert(0);
}

///
@safe unittest
{
    class C
    {
        int value() @property { return 0; }
    }
    static assert(is( typeof(C.value) == int ));
    static assert(is( FunctionTypeOf!(C.value) == function ));
}

@system unittest
{
    int test(int a);
    int propGet() @property;
    int propSet(int a) @property;
    int function(int) test_fp;
    int delegate(int) test_dg;
    static assert(is( typeof(test) == FunctionTypeOf!(typeof(test)) ));
    static assert(is( typeof(test) == FunctionTypeOf!test ));
    static assert(is( typeof(test) == FunctionTypeOf!test_fp ));
    static assert(is( typeof(test) == FunctionTypeOf!test_dg ));
    alias int GetterType() @property;
    alias int SetterType(int) @property;
    static assert(is( FunctionTypeOf!propGet == GetterType ));
    static assert(is( FunctionTypeOf!propSet == SetterType ));

    interface Prop { int prop() @property; }
    Prop prop;
    static assert(is( FunctionTypeOf!(Prop.prop) == GetterType ));
    static assert(is( FunctionTypeOf!(prop.prop) == GetterType ));

    class Callable { int opCall(int) { return 0; } }
    auto call = new Callable;
    static assert(is( FunctionTypeOf!call == typeof(test) ));

    struct StaticCallable { static int opCall(int) { return 0; } }
    StaticCallable stcall_val;
    StaticCallable* stcall_ptr;
    static assert(is( FunctionTypeOf!stcall_val == typeof(test) ));
    static assert(is( FunctionTypeOf!stcall_ptr == typeof(test) ));

    interface Overloads
    {
        void test(string);
        real test(real);
        int  test(int);
        int  test() @property;
    }
    alias ov = __traits(getVirtualFunctions, Overloads, "test");
    alias F_ov0 = FunctionTypeOf!(ov[0]);
    alias F_ov1 = FunctionTypeOf!(ov[1]);
    alias F_ov2 = FunctionTypeOf!(ov[2]);
    alias F_ov3 = FunctionTypeOf!(ov[3]);
    static assert(is(F_ov0* == void function(string)));
    static assert(is(F_ov1* == real function(real)));
    static assert(is(F_ov2* == int function(int)));
    static assert(is(F_ov3* == int function() @property));

    alias F_dglit = FunctionTypeOf!((int a){ return a; });
    static assert(is(F_dglit* : int function(int)));
}

/*
Detect whether symbol or type `T` is a function, a function pointer or a delegate.

Params:
    T = The type to check
Returns:
    A `bool`
 */
template isSomeFunction(T...)
if (T.length == 1)
{
    static if (is(typeof(& T[0]) U : U*) && is(U == function) || is(typeof(& T[0]) U == delegate))
    {
        // T is a (nested) function symbol.
        enum bool isSomeFunction = true;
    }
    else static if (is(T[0] W) || is(typeof(T[0]) W))
    {
        // T is an expression or a type.  Take the type of it and examine.
        static if (is(W F : F*) && is(F == function))
            enum bool isSomeFunction = true; // function pointer
        else
            enum bool isSomeFunction = is(W == function) || is(W == delegate);
    }
    else
        enum bool isSomeFunction = false;
}

///
@safe unittest
{
    static real func(ref int) { return 0; }
    static void prop() @property { }
    class C
    {
        real method(ref int) { return 0; }
        real prop() @property { return 0; }
    }
    auto c = new C;
    auto fp = &func;
    auto dg = &c.method;
    real val;

    static assert( isSomeFunction!func);
    static assert( isSomeFunction!prop);
    static assert( isSomeFunction!(C.method));
    static assert( isSomeFunction!(C.prop));
    static assert( isSomeFunction!(c.prop));
    static assert( isSomeFunction!(c.prop));
    static assert( isSomeFunction!fp);
    static assert( isSomeFunction!dg);

    static assert(!isSomeFunction!int);
    static assert(!isSomeFunction!val);
}

@safe unittest
{
    void nestedFunc() { }
    void nestedProp() @property { }
    static assert(isSomeFunction!nestedFunc);
    static assert(isSomeFunction!nestedProp);
    static assert(isSomeFunction!(real function(ref int)));
    static assert(isSomeFunction!(real delegate(ref int)));
    static assert(isSomeFunction!((int a) { return a; }));
    static assert(!isSomeFunction!isSomeFunction);
}

/*
Detect whether `T` is a callable object, which can be called with the
function call operator `$(LPAREN)...$(RPAREN)`.
 */
template isCallable(T...)
if (T.length == 1)
{
    static if (is(typeof(& T[0].opCall) == delegate))
        // T is a object which has a member function opCall().
        enum bool isCallable = true;
    else static if (is(typeof(& T[0].opCall) V : V*) && is(V == function))
        // T is a type which has a static member function opCall().
        enum bool isCallable = true;
    else
        enum bool isCallable = isSomeFunction!T;
}

///
@safe unittest
{
    interface I { real value() @property; }
    struct S { static int opCall(int) { return 0; } }
    class C { int opCall(int) { return 0; } }
    auto c = new C;

    static assert( isCallable!c);
    static assert( isCallable!S);
    static assert( isCallable!(c.opCall));
    static assert( isCallable!(I.value));
    static assert( isCallable!((int a) { return a; }));

    static assert(!isCallable!I);
}
