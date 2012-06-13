/**
 * Contains all implicitly declared types and variables.
 *
 * Copyright: Copyright Digital Mars 2000 - 2011.
 * License:   <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors:   Walter Bright, Sean Kelly
 *
 *          Copyright Digital Mars 2000 - 2011.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */
module object;

private
{
    extern(C) void rt_finalize(void *ptr, bool det=true);
}

alias typeof(int.sizeof)                    size_t;
alias typeof(cast(void*)0 - cast(void*)0)   ptrdiff_t;
alias ptrdiff_t                             sizediff_t;

alias size_t hash_t;
alias bool equals_t;

alias immutable(char)[]  string;
alias immutable(wchar)[] wstring;
alias immutable(dchar)[] dstring;

class Object
{
    string   toString();
    hash_t   toHash() @trusted nothrow;
    int      opCmp(Object o);
    equals_t opEquals(Object o);
    equals_t opEquals(Object lhs, Object rhs);

    interface Monitor
    {
        void lock();
        void unlock();
    }

    static Object factory(string classname);
}

bool opEquals(const Object lhs, const Object rhs);
bool opEquals(Object lhs, Object rhs);
//bool opEquals(TypeInfo lhs, TypeInfo rhs);

void setSameMutex(shared Object ownee, shared Object owner);

struct Interface
{
    const TypeInfo_Class   classinfo;
    const void*[]     vtbl;
    const ptrdiff_t   offset;   // offset to Interface 'this' from Object 'this'
}

struct OffsetTypeInfo
{
    const size_t   offset;
    const TypeInfo ti;
}

class TypeInfo
{
    hash_t   getHash(in void* p) @trusted nothrow;
    equals_t equals(in void* p1, in void* p2);
    int      compare(in void* p1, in void* p2);
    @property size_t   tsize() nothrow pure const @trusted;
    void     swap(void* p1, void* p2);
    @property const(TypeInfo) next() nothrow pure const @trusted;
    const(void)[]   init() nothrow pure const @trusted; // TODO: make this a property, but may need to be renamed to diambiguate with T.init...
    @property uint     flags() nothrow pure const @trusted;
    // 1:    // has possible pointers into GC memory
    const(OffsetTypeInfo)[] offTi() nothrow pure const @trusted;
    void destroy(void* p);
    void postblit(void* p);
    @property size_t talign() nothrow pure const @trusted;
    version (X86_64) int argTypes(out TypeInfo arg1, out TypeInfo arg2) @trusted nothrow pure const;
    @property immutable(void)* rtInfo() nothrow pure const @trusted;
}

class TypeInfo_Typedef : TypeInfo
{
    private this() {}

    const TypeInfo base;
    const string   name;
    const void[]   m_init;
}

class TypeInfo_Enum : TypeInfo_Typedef
{
    private this() {}
}

class TypeInfo_Pointer : TypeInfo
{
    private this() {}

    const TypeInfo m_next;
}

class TypeInfo_Array : TypeInfo
{
    private this() {}

    const TypeInfo value;
}

class TypeInfo_Vector : TypeInfo
{
    private this() {}

    const TypeInfo base;
}

class TypeInfo_StaticArray : TypeInfo
{
    private this() {}

    const TypeInfo value;
    const size_t   len;
}

class TypeInfo_AssociativeArray : TypeInfo
{
    private this() {}

    const TypeInfo value;
    const TypeInfo key;
    const TypeInfo impl;
}

class TypeInfo_Function : TypeInfo
{
    private this() {}

    const TypeInfo next;
}

class TypeInfo_Delegate : TypeInfo
{
    private this() {}

    const TypeInfo next;
}

class TypeInfo_Class : TypeInfo
{
    private this() {}

    @property const(TypeInfo_Class) info() @trusted nothrow pure const { return this; }
    @property const(TypeInfo_Class) typeinfo() @trusted nothrow pure const { return this; }

    const byte[]      init;   // class static initializer
    const string      name;   // class name
    const void*[]     vtbl;   // virtual function pointer table
    const Interface[] interfaces;
    const TypeInfo_Class   base;
    const void*       destructor;
    const void function(Object) classInvariant;
    const uint        m_flags;
    //  1:      // is IUnknown or is derived from IUnknown
    //  2:      // has no possible pointers into GC memory
    //  4:      // has offTi[] member
    //  8:      // has constructors
    // 16:      // has xgetMembers member
    // 32:      // has typeinfo member
    const void*       deallocator;
    const OffsetTypeInfo[] m_offTi;
    const void*       defaultConstructor;
    immutable(void)*    m_rtInfo;     // data for precise GC

    @trusted static const(TypeInfo_Class) find(in char[] classname);
    @trusted Object create();
}

alias TypeInfo_Class ClassInfo;

class TypeInfo_Interface : TypeInfo
{
    private this() {}

    const ClassInfo info;
}

class TypeInfo_Struct : TypeInfo
{
    private this() {}

    const string name;
    const void[] m_init;

  @safe pure nothrow
  {
    const uint function(in void*)               xtoHash;
    const equals_t function(in void*, in void*) xopEquals;
    const int function(in void*, in void*)      xopCmp;
    const string function(in void*)             xtoString;

    const uint m_flags;
  }
    const void function(void*)                    xdtor;
    const void function(void*)                    xpostblit;

    const uint m_align;

    version (X86_64)
    {
        const TypeInfo m_arg1;
        const TypeInfo m_arg2;
    }
    immutable(void)* m_rtInfo;
}

class TypeInfo_Tuple : TypeInfo
{
    private this() {}

    const TypeInfo[]  elements;
}

class TypeInfo_Const : TypeInfo
{
    private this() {}

    const TypeInfo next;
}

class TypeInfo_Invariant : TypeInfo_Const
{
    private this() {}
}

class TypeInfo_Shared : TypeInfo_Const
{
    private this() {}
}

class TypeInfo_Inout : TypeInfo_Const
{
    private this() {}
}

abstract class MemberInfo
{
    private this() {}

    @property string name() nothrow pure const @trusted;
}

class MemberInfo_field : MemberInfo
{
    private this(string name, TypeInfo ti, size_t offset);

    @property override string name() nothrow pure const @trusted;
    @property const(TypeInfo) typeInfo() nothrow pure const @trusted;
    @property size_t offset() nothrow pure const @trusted;
}

class MemberInfo_function : MemberInfo
{
    enum
    {
        Virtual = 1,
        Member  = 2,
        Static  = 4,
    }

    private this(string name, TypeInfo ti, const(void)* fp, uint flags);

    @property override string name() nothrow pure const @trusted;
    @property const(TypeInfo) typeInfo() nothrow pure const @trusted;
    @property const(void)* fp() nothrow pure const @trusted;
    @property uint flags() nothrow pure const @trusted;
}

struct ModuleInfo
{
    @disable this();

    struct New
    {
        uint flags;
        uint index;
    }

    struct Old
    {
        const string           name;
        const ModuleInfo*[]    importedModules;
        const TypeInfo_Class[] localClasses;
        uint             flags;

        const void function() ctor;
        const void function() dtor;
        const void function() unitTest;
        const void* xgetMembers;
        const void function() ictor;
        const void function() tlsctor;
        const void function() tlsdtor;
        uint index;
        const void*[1] reserved;
    }

    union
    {
        New n;
        Old o;
    }

    @property bool isNew() nothrow pure const @trusted;
    @property uint index() nothrow pure const @trusted;
    @property void index(uint i) nothrow pure @trusted;
    @property uint flags() nothrow pure const @trusted;
    @property void flags(uint f) nothrow pure @trusted;
    @property void function() tlsctor() nothrow pure const @trusted;
    @property void function() tlsdtor() nothrow pure const @trusted;
    @property const(void)* xgetMembers() nothrow pure const @trusted;
    @property void function() ctor() nothrow pure const @trusted;
    @property void function() dtor() nothrow pure const @trusted;
    @property void function() ictor() nothrow pure const @trusted;
    @property void function() unitTest() nothrow pure const @trusted;
    @property const(ModuleInfo*)[] importedModules() nothrow pure const @trusted;
    @property const(TypeInfo_Class)[] localClasses() nothrow pure const @trusted;
    @property string name() nothrow pure const @trusted;

    @trusted static int opApply(scope int delegate(ref const ModuleInfo*) dg);
}

class Throwable : Object
{
    interface TraceInfo
    {
        @trusted int opApply(scope int delegate(ref char[]));
        @trusted int opApply(scope int delegate(ref size_t, ref char[]));
        string toString();
    }

    string      msg;
    string      file;
    size_t      line;
    TraceInfo   info;
    Throwable   next;

    this(string msg, Throwable next = null) pure nothrow @trusted;
    this(string msg, string file, size_t line, Throwable next = null) pure nothrow @trusted;
    override string toString();
}


class Exception : Throwable
{
    this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null) pure nothrow @trusted
    {
        super(msg, file, line, next);
    }

    this(string msg, Throwable next, string file = __FILE__, size_t line = __LINE__) pure nothrow @trusted
    {
        super(msg, file, line, next);
    }
}


class Error : Throwable
{
    this(string msg, Throwable next = null) pure nothrow @trusted
    {
        super(msg, next);
        bypassedException = null;
    }

    this(string msg, string file, size_t line, Throwable next = null) pure nothrow @trusted
    {
        super(msg, file, line, next);
        bypassedException = null;
    }
    Throwable   bypassedException;
}

extern (C)
{
    // from druntime/src/compiler/dmd/aaA.d

    @trusted size_t _aaLen(void* p) pure nothrow;
    @trusted void*  _aaGet(void** pp, TypeInfo keyti, size_t valuesize, ...) pure nothrow;
    @trusted void*  _aaGetRvalue(void* p, TypeInfo keyti, size_t valuesize, ...) pure nothrow;
    @trusted void*  _aaIn(void* p, TypeInfo keyti) pure nothrow;
    @trusted void   _aaDel(void* p, TypeInfo keyti, ...) pure nothrow;
    @trusted void[] _aaValues(void* p, size_t keysize, size_t valuesize) pure nothrow;
    @trusted void[] _aaKeys(void* p, size_t keysize) pure nothrow;
    @trusted void*  _aaRehash(void** pp, TypeInfo keyti) pure nothrow;

    extern (D) alias scope int delegate(void *) _dg_t;
    @trusted int _aaApply(void* aa, size_t keysize, _dg_t dg);

    extern (D) alias scope int delegate(void *, void *) _dg2_t;
    @trusted int _aaApply2(void* aa, size_t keysize, _dg2_t dg);

    @trusted void* _d_assocarrayliteralT(TypeInfo_AssociativeArray ti, size_t length, ...) pure nothrow;
}

struct AssociativeArray(Key, Value)
{
private:
    // Duplicates of the stuff found in druntime/src/rt/aaA.d
    struct Slot
    {
        Slot *next;
        hash_t hash;
        Key key;
        Value value;
    }

    struct Hashtable
    {
        Slot*[] b;
        size_t nodes;
        TypeInfo keyti;
        Slot*[4] binit;
    }

    void* p; // really Hashtable*

    struct Range
    {
        // State
        Slot*[] slots;
        Slot* current;

        @trusted this(void * aa) pure nothrow
        {
            if (!aa) return;
            auto pImpl = cast(Hashtable*) aa;
            slots = pImpl.b;
            nextSlot();
        }

        @trusted void nextSlot() pure nothrow
        {
            foreach (i, slot; slots)
            {
                if (!slot) continue;
                current = slot;
                slots = slots.ptr[i .. slots.length];
                break;
            }
        }

    public:
        @trusted @property bool empty() const pure nothrow
        {
            return current is null;
        }

        @trusted @property ref inout(Slot) front() inout pure nothrow
        {
            assert(current);
            return *current;
        }

        @trusted void popFront() pure nothrow
        {
            assert(current);
            current = current.next;
            if (!current)
            {
                slots = slots[1 .. $];
                nextSlot();
            }
        }
    }

public:

    @trusted @property size_t length() pure nothrow { return _aaLen(p); }

    @trusted Value[Key] rehash() @property pure nothrow
    {
        auto p = _aaRehash(&p, typeid(Value[Key]));
        return *cast(Value[Key]*)(&p);
    }

    @trusted Value[] values() @property pure nothrow
    {
        auto a = _aaValues(p, Key.sizeof, Value.sizeof);
        return *cast(Value[]*) &a;
    }

    @trusted Key[] keys() @property pure nothrow
    {
        auto a = _aaKeys(p, Key.sizeof);
        return *cast(Key[]*) &a;
    }

    @trusted int opApply(scope int delegate(ref Key, ref Value) dg)
    {
        return _aaApply2(p, Key.sizeof, cast(_dg2_t)dg);
    }

    @trusted int opApply(scope int delegate(ref Value) dg)
    {
        return _aaApply(p, Key.sizeof, cast(_dg_t)dg);
    }

    @trusted Value get(Key key, lazy Value defaultValue)
    {
        auto p = key in *cast(Value[Key]*)(&p);
        return p ? *p : defaultValue;
    }

    static if (is(typeof({ Value[Key] r; r[Key.init] = Value.init; }())))
        @trusted @property Value[Key] dup()
        {
            Value[Key] result;
            foreach (k, v; this)
            {
                result[k] = v;
            }
            return result;
        }

    @trusted @property auto byKey() pure nothrow
    {
        static struct Result
        {
            Range state;

            @trusted this(void* p) pure nothrow
            {
                state = Range(p);
            }

            @trusted @property ref Key front() pure nothrow
            {
                return state.front.key;
            }

            alias state this;
        }

        return Result(p);
    }

    @trusted @property auto byValue() pure nothrow
    {
        static struct Result
        {
            Range state;

            @trusted this(void* p) pure nothrow
            {
                state = Range(p);
            }

            @trusted @property ref Value front() pure nothrow
            {
                return state.front.value;
            }

            alias state this;
        }

        return Result(p);
    }
}

unittest
{
    auto a = [ 1:"one", 2:"two", 3:"three" ];
    auto b = a.dup;
    assert(b == [ 1:"one", 2:"two", 3:"three" ]);
}

// Scheduled for deprecation in December 2012.
// Please use destroy instead of clear.
alias destroy clear;

void destroy(T)(T obj) if (is(T == class))
{
    rt_finalize(cast(void*)obj);
}

void destroy(T)(ref T obj) if (is(T == struct))
{
    typeid(T).destroy(&obj);
    auto buf = (cast(ubyte*) &obj)[0 .. T.sizeof];
    auto init = cast(ubyte[])typeid(T).init();
    if(init.ptr is null) // null ptr means initialize to 0s
        buf[] = 0;
    else
        buf[] = init[];
}

void destroy(T : U[n], U, size_t n)(ref T obj)
{
    obj = T.init;
}

void destroy(T)(ref T obj)
if (!is(T == struct) && !is(T == class) && !_isStaticArray!T)
{
    obj = T.init;
}

template _isStaticArray(T : U[N], U, size_t N)
{
    enum bool _isStaticArray = true;
}

template _isStaticArray(T)
{
    enum bool _isStaticArray = false;
}

private
{
    extern (C) void _d_arrayshrinkfit(TypeInfo ti, void[] arr);
    extern (C) size_t _d_arraysetcapacity(TypeInfo ti, size_t newcapacity, void *arrptr);
}

@property size_t capacity(T)(T[] arr)
{
    return _d_arraysetcapacity(typeid(T[]), 0, cast(void *)&arr);
}

size_t reserve(T)(ref T[] arr, size_t newcapacity)
{
    return _d_arraysetcapacity(typeid(T[]), newcapacity, cast(void *)&arr);
}

void assumeSafeAppend(T)(T[] arr)
{
    _d_arrayshrinkfit(typeid(T[]), *(cast(void[]*)&arr));
}

bool _ArrayEq(T1, T2)(T1[] a1, T2[] a2)
{
    if (a1.length != a2.length)
        return false;
    foreach(i, a; a1)
    {   if (a != a2[i])
            return false;
    }
    return true;
}

bool _xopEquals(in void* ptr, in void* ptr);

void __ctfeWrite(T...)(auto ref T) {}
void __ctfeWriteln(T...)(auto ref T values) { __ctfeWrite(values, "\n"); }

template RTInfo(T)
{
    enum RTInfo = cast(void*)0x12345678;
}

