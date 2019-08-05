import core.stdc.stdio : fprintf, printf, stderr;

void test(string comp = "==", A, B)(A a, B b, string msg, size_t line = __LINE__)
{
    int ret = () {
        import core.exception : AssertError;
        try
        {
            assert(mixin("a " ~ comp ~ " b"));
        } catch(AssertError e)
        {
            // don't use assert here for better debugging
            if (e.msg != msg)
            {
                printf("Line %d: '%.*s' != '%.*s'\n", line, e.msg.length, e.msg.ptr, msg.length, msg.ptr);
                return 1;
            }
            return 0;
        }
        printf("Line %d: No assert triggered\n", line);
        return 1;
    }();
    // don't use assert here for better debugging
    if (ret != 0) {
        import core.stdc.stdlib : exit;
        exit(1);
    }
}

void testIntegers()()
{
    test(1, 2, "1 != 2");
    test(-10, 8, "-10 != 8");
    test(byte.min, byte.max, "-128 != 127");
    test(ubyte.min, ubyte.max, "0 != 255");
    test(short.min, short.max, "-32768 != 32767");
    test(ushort.min, ushort.max, "0 != 65535");
    test(int.min, int.max, "-2147483648 != 2147483647");
    test(uint.min, uint.max, "0 != 4294967295");
    test(long.min, long.max, "-9223372036854775808 != 9223372036854775807");
    test(ulong.min, ulong.max, "0 != 18446744073709551615");

    int testFun() { return 1; }
    test(testFun(), 2, "1 != 2");
}

void testIntegerComparisons()()
{
    test!"!="(2, 2, "2 == 2");
    test!"<"(2, 1, "2 >= 1");
    test!"<="(2, 1, "2 > 1");
    test!">"(1, 2, "1 <= 2");
    test!">="(1, 2, "1 < 2");
}

void testFloatingPoint()()
{
    test(1.5, 2.5, "1.5 != 2.5");
    test(float.max, -float.max, "3.40282e+38 != -3.40282e+38");
    test(double.max, -double.max, "1.79769e+308 != -1.79769e+308");
}

void testStrings()
{
    test("foo", "bar", `"foo" != "bar"`);
    test("", "bar", `"" != "bar"`);

    char[] dlang = "dlang".dup;
    const(char)[] rust = "rust";
    test(dlang, rust, `"dlang" != "rust"`);
}

void testToString()()
{
    class Foo
    {
        this(string payload) {
            this.payload = payload;
        }

        string payload;
        override string toString() {
            return "Foo(" ~ payload ~ ")";
        }
    }
    test(new Foo("a"), new Foo("b"), "Foo(a) != Foo(b)");
}


void testArray()()
{
    test([1], [0], "[1] != [0]");
    test([1, 2, 3], [0], "[1, 2, 3] != [0]");

    // test with long arrays
    int[] arr;
    foreach (i; 0 .. 100)
        arr ~= i;
    test(arr, [0], "[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, ...] != [0]");
}

void testStruct()()
{
    struct S { int s; }
    test(S(0), S(1), "S(0) !is S(1)");
}

void testAA()()
{
    test([1:"one"], [2: "two"], `[1: "one"] != [2: "two"]`);
    test!"in"(1, [2: 3], "1 !in [2: 3]");
    test!"in"("foo", ["bar": true], `"foo" !in ["bar": true]`);
}


void testAttributes() @safe pure @nogc nothrow
{
    int a;
    assert(a == 0);
}

// https://issues.dlang.org/show_bug.cgi?id=20066
void testVoidArray()()
{
    assert([] is null);
    assert(null is null);
    test([1], null, "[1] != []");
    test("s", null, `"s" != ""`);
    test(['c'], null, `"c" != ""`);
    test!"!="(null, null, "`null` == `null`");
}

void testStructEquals()()
{
    struct T {
    	bool b;
    	int i;
    	float f1 = 2.5;
    	float f2 = 0;
    	string s1 = "bar";
    	string s2;
    }

    T t1;
    test!"!="(t1, t1, `T(false, 0, 2.5, 0, "bar", "") == T(false, 0, 2.5, 0, "bar", "")`);
    T t2 = {s1: "bari"};
    test(t1, t2, `T(false, 0, 2.5, 0, "bar", "") != T(false, 0, 2.5, 0, "bari", "")`);
}

void testStructEquals2()()
{
    struct T {
    	bool b;
    	int i;
    	float f1 = 2.5;
    	float f2 = 0;
    }

    T t1;
    test!"!="(t1, t1, `T(false, 0, 2.5, 0) == T(false, 0, 2.5, 0)`);
    T t2 = {i: 2};
    test(t1, t2, `T(false, 0, 2.5, 0) != T(false, 2, 2.5, 0)`);
}

void testStructEquals3()()
{
    struct T {
    	bool b;
    	int i;
    	string s1 = "bar";
    	string s2;
    }

    T t1;
    test!"!="(t1, t1, `T(false, 0, "bar", "") == T(false, 0, "bar", "")`);
    T t2 = {s1: "bari"};
    test(t1, t2, `T(false, 0, "bar", "") != T(false, 0, "bari", "")`);
}

void testStructEquals4()()
{
    struct T {
    	float f1 = 2.5;
    	float f2 = 0;
    	string s1 = "bar";
    	string s2;
    }

    T t1;
    test!"!="(t1, t1, `T(2.5, 0, "bar", "") == T(2.5, 0, "bar", "")`);
    T t2 = {s1: "bari"};
    test(t1, t2, `T(2.5, 0, "bar", "") != T(2.5, 0, "bari", "")`);
}

void testStructEquals5()()
{
    struct T {
    	bool b;
    	int i;
    	float f2 = 0;
    	string s2;
    }

    T t1;
    test!"!="(t1, t1, `T(false, 0, 0, "") == T(false, 0, 0, "")`);
    T t2 = {b: true};
    test(t1, t2, `T(false, 0, 0, "") != T(true, 0, 0, "")`);
}

void testStructEquals6()()
{
    class C { override string toString() { return "C()"; }}
    struct T {
    	bool b;
    	int i;
    	float f2 = 0;
    	string s2;
    	int[] arr;
    	C c;
    }

    T t1;
    test!"!="(t1, t1, `T(false, 0, 0, "", [], C(null)) == T(false, 0, 0, "", [], C(null))`);
    T t2 = {arr: [1]};
    test(t1, t2, `T(false, 0, 0, "", [], C(null)) != T(false, 0, 0, "", [1], C(null))`);
    T t3 = {c: new C()};
    test(t1, t3, `T(false, 0, 0, "", [], C(null)) != T(false, 0, 0, "", [], C())`);
}



void main()
{
    testIntegers();
    testIntegerComparisons();
    testFloatingPoint();
    testStrings();
    testToString();
    testArray();
    testStruct();
    testAA();
    testAttributes();
    testVoidArray();
    testStructEquals();
    testStructEquals2();
    testStructEquals3();
    testStructEquals4();
    testStructEquals5();
    testStructEquals6();
    fprintf(stderr, "success.\n");
}
