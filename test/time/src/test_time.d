module core.test_time; // Belong to "core" package for access to package-visible members.
import core.exception;
import core.internal.string;
import core.time;
import core.stdc.stdio;

void main()
{
    // test of helper functions
    testDoubleToString();
    testAssertThrown();
    // ClockType
    ensureClockTypeValuesCrossPlatform();
    // Duration
    testDurationBounds();
    testDurationOpCmp();
    testDurationOpBinaryDuration();
    testDurationOpBinaryRightDuration();
    testDurationOpOpAssignDuration();
    testDurationTimesLong();
    testDurationDivideLong();
    testDurationTimesAssignLong();
    testDurationTimesDivideLong();
    testDurationDivideByDuration();
    testLongTimesDuration();
    testNegateDuration();
    testDurationCastToTickDuration();
    testDurationCastToBool();
    testDurationSplit();
    testDurationTotal();
    testDurationToString();
    testDurationIsNegative();
    // free functions 1
    testTo();
    testDur();
    // MonoTimeImpl
    foreach (typeStr; __traits(allMembers, ClockType))
    {
        mixin("alias type = ClockType." ~ typeStr ~ ";");
        static if (clockSupported(type))
        {
            testMonoTimeImplStorageConversion!(MonoTimeImpl!type)();
            testMonoTimeImplBounds!(MonoTimeImpl!type)();
            testMonoTimeImplOpCmp1!(MonoTimeImpl!type)();
            testMonoTimeImplOpCmp2!(MonoTimeImpl!type)();
            testMonoTimeImplOpCmp3!(MonoTimeImpl!type)();
            testMonoTimeImplMinusMonoTimeImpl1!(MonoTimeImpl!type)();
            testMonoTimeImplMinusMonoTimeImpl2!(MonoTimeImpl!type)();
            testMonoTimeImplPlusMinusDuration1!(MonoTimeImpl!type)();
            testMonoTimeImplPlusMinusDuration2!(MonoTimeImpl!type)();
            testMonoTimeImplPLusMinusAssign!(MonoTimeImpl!type)();
            testMonoTimeImplTicks!(MonoTimeImpl!type)();
            testMonoTimeImplToString!(MonoTimeImpl!type)();
        }
    }
    testMonoTimeImplCurTime();
    // free functions 2
    testConvClockFreq();
    testNsecsToTicks();
    // TickDuration
    testTickDurationBounds();
    testTickDurationSeconds();
    testTickDurationFrom();
    testTickDurationCastDuration();
    testTickDurationPlusMinusAssignTickDuration();
    testDurationPlusMinusTickDuration();
    testNegateTickDuration();
    testTickDurationOpCmp();
    testTickDurationTimesAssignIntFloat();
    testTickDurationDivideAssignIntFloat();
    testTickDurationTimesIntFloat();
    testTickDurationDivideIntFloat();
    testTickDurationCtor();
    // free functions 3
    testConvert();
    // TimeException
    testTimeException();
    // free functions 4
    testAbs();
    testAllAreAcceptedUnits();
    testUnitsAreInDescendingOrder();
    testNextLargerTimeUnits();
    // FracSec (deprecated)
    testFracSecZero();
    testFracSecFrom();
    testNegateFracSec();
    testFracSecMsecsGet();
    testFracSecMsecsSet();
    testFracSecUsecsGet();
    testFracSecUsecsSet();
    testFracSecHnsecsGet();
    testFracSecHnsecsSet();
    testFracSecNsecsGet();
    testFracSecNsecsSet();
    testFracSecToString1();
    testFracSecToString2();
}

//
// Helper functions & templates
//

// To verify that an lvalue isn't required.
private T copy(T)(T t)
{
    return t;
}

// Local version of abs, since std.math.abs is in Phobos, not druntime.
long _abs(long val) @safe pure nothrow @nogc
{
    return val >= 0 ? val : -val;
}

double _abs(double val) @safe pure nothrow @nogc
{
    return val >= 0.0 ? val : -val;
}

// A copy of std.typecons.TypeTuple.
template _TypeTuple(TList...)
{
    alias TList _TypeTuple;
}

void assertApprox(D, E)(D actual,
                          E lower,
                          E upper,
                          string msg = "unittest failure",
                          size_t line = __LINE__)
    if (is(D : const Duration) && is(E : const Duration))
{
    if (actual < lower)
        throw new AssertError(msg ~ ": lower: " ~ actual.toString(), __FILE__, line);
    if (actual > upper)
        throw new AssertError(msg ~ ": upper: " ~ actual.toString(), __FILE__, line);
}

void assertApprox(D, E)(D actual,
                        E lower,
                        E upper,
                        string msg = "unittest failure",
                        size_t line = __LINE__)
    if (is(D : const TickDuration) && is(E : const TickDuration))
{
    if (actual.length < lower.length || actual.length > upper.length)
    {
        throw new AssertError(msg ~ (": [" ~ signedToTempString(lower.length, 10) ~ "] [" ~
                              signedToTempString(actual.length, 10) ~ "] [" ~
                              signedToTempString(upper.length, 10) ~ "]").idup,
                              __FILE__, line);
    }
}

void assertApprox(MT)(MT actual,
                    MT lower,
                    MT upper,
                    string msg = "unittest failure",
                    size_t line = __LINE__)
    if (is(MT == MonoTimeImpl!type, ClockType type))
{
    assertApprox(actual._ticks, lower._ticks, upper._ticks, msg, line);
}

void assertApprox()(long actual,
                    long lower,
                    long upper,
                    string msg = "unittest failure",
                    size_t line = __LINE__)
{
    if (actual < lower)
        throw new AssertError(msg ~ ": lower: " ~ signedToTempString(actual, 10).idup, __FILE__, line);
    if (actual > upper)
        throw new AssertError(msg ~ ": upper: " ~ signedToTempString(actual, 10).idup, __FILE__, line);
}

string doubleToString(double value) @safe pure nothrow
{
    string result;
    if (value < 0 && cast(long)value == 0)
        result = "-0";
    else
        result = signedToTempString(cast(long)value, 10).idup;
    result ~= '.';
    result ~= unsignedToTempString(cast(ulong)(_abs((value - cast(long)value) * 1_000_000) + .5), 10);

    while (result[$-1] == '0')
        result = result[0 .. $-1];
    return result;
}

const(char)* numToStringz()(long value) @trusted pure nothrow
{
    return (signedToTempString(value, 10) ~ "\0").ptr;
}

/+ An adjusted copy of std.exception.assertThrown. +/
void _assertThrown(T : Throwable = Exception, E)
                                    (lazy E expression,
                                     string msg = null,
                                     string file = __FILE__,
                                     size_t line = __LINE__)
{
    bool thrown = false;

    try
        expression();
    catch (T t)
        thrown = true;

    if (!thrown)
    {
        immutable tail = msg.length == 0 ? "." : ": " ~ msg;

        throw new AssertError("assertThrown() failed: No " ~ T.stringof ~ " was thrown" ~ tail, file, line);
    }
}

void testAssertThrown()
{

    void throwEx(Throwable t)
    {
        throw t;
    }

    void nothrowEx()
    {}

    try
        _assertThrown!Exception(throwEx(new Exception("It's an Exception")));
    catch (AssertError)
        assert(0);

    try
        _assertThrown!Exception(throwEx(new Exception("It's an Exception")), "It's a message");
    catch (AssertError)
        assert(0);

    try
        _assertThrown!AssertError(throwEx(new AssertError("It's an AssertError", __FILE__, __LINE__)));
    catch (AssertError)
        assert(0);

    try
        _assertThrown!AssertError(throwEx(new AssertError("It's an AssertError", __FILE__, __LINE__)), "It's a message");
    catch (AssertError)
        assert(0);


    {
        bool thrown = false;
        try
            _assertThrown!Exception(nothrowEx());
        catch (AssertError)
            thrown = true;

        assert(thrown);
    }

    {
        bool thrown = false;
        try
            _assertThrown!Exception(nothrowEx(), "It's a message");
        catch (AssertError)
            thrown = true;

        assert(thrown);
    }

    {
        bool thrown = false;
        try
            _assertThrown!AssertError(nothrowEx());
        catch (AssertError)
            thrown = true;

        assert(thrown);
    }

    {
        bool thrown = false;
        try
            _assertThrown!AssertError(nothrowEx(), "It's a message");
        catch (AssertError)
            thrown = true;

        assert(thrown);
    }
}

bool clockSupported(ClockType c)
{
    version (Linux_Pre_2639) // skip CLOCK_BOOTTIME on older linux kernels
        return c != ClockType.second && c != ClockType.bootTime;
    else
        return c != ClockType.second; // second doesn't work with MonoTimeImpl
}

//
// Test of helper functions
//

void testDoubleToString()
{
    auto a = 1.337;
    auto aStr = doubleToString(a);
    assert(aStr == "1.337", aStr);

    a = 0.337;
    aStr = doubleToString(a);
    assert(aStr == "0.337", aStr);

    a = -0.337;
    aStr = doubleToString(a);
    assert(aStr == "-0.337", aStr);
}


//
// ClockType
//

// Make sure that ClockType values are the same across platforms.
void ensureClockTypeValuesCrossPlatform()
{
    static if (is(typeof(ClockType.normal)))         static assert(ClockType.normal == 0);
    static if (is(typeof(ClockType.bootTime)))       static assert(ClockType.bootTime == 1);
    static if (is(typeof(ClockType.coarse)))         static assert(ClockType.coarse == 2);
    static if (is(typeof(ClockType.precise)))        static assert(ClockType.precise == 3);
    static if (is(typeof(ClockType.processCPUTime))) static assert(ClockType.processCPUTime == 4);
    static if (is(typeof(ClockType.raw)))            static assert(ClockType.raw == 5);
    static if (is(typeof(ClockType.second)))         static assert(ClockType.second == 6);
    static if (is(typeof(ClockType.threadCPUTime)))  static assert(ClockType.threadCPUTime == 7);
    static if (is(typeof(ClockType.uptime)))         static assert(ClockType.uptime == 8);
    static if (is(typeof(ClockType.uptimeCoarse)))   static assert(ClockType.uptimeCoarse == 9);
    static if (is(typeof(ClockType.uptimePrecise)))  static assert(ClockType.uptimePrecise == 10);
}

//
// Duration
//

void testDurationBounds() pure @safe
{
    assert(Duration.zero == dur!"seconds"(0));
    assert(Duration.max == Duration(long.max));
    assert(Duration.min == Duration(long.min));
    assert(Duration.min < Duration.zero);
    assert(Duration.zero < Duration.max);
    assert(Duration.min < Duration.max);
    assert(Duration.min - dur!"hnsecs"(1) == Duration.max);
    assert(Duration.max + dur!"hnsecs"(1) == Duration.min);
}

void testDurationOpCmp() pure @safe
{
    foreach (T; _TypeTuple!(Duration, const Duration, immutable Duration))
    {
        foreach (U; _TypeTuple!(Duration, const Duration, immutable Duration))
        {
            T t = 42;
            // workaround https://issues.dlang.org/show_bug.cgi?id=18296
            version (D_Coverage)
                U u = T(t._hnsecs);
            else
                U u = t;
            assert(t == u);
            assert(copy(t) == u);
            assert(t == copy(u));
        }
    }

    foreach (D; _TypeTuple!(Duration, const Duration, immutable Duration))
    {
        foreach (E; _TypeTuple!(Duration, const Duration, immutable Duration))
        {
            assert((cast(D)Duration(12)).opCmp(cast(E)Duration(12)) == 0);
            assert((cast(D)Duration(-12)).opCmp(cast(E)Duration(-12)) == 0);

            assert((cast(D)Duration(10)).opCmp(cast(E)Duration(12)) < 0);
            assert((cast(D)Duration(-12)).opCmp(cast(E)Duration(12)) < 0);

            assert((cast(D)Duration(12)).opCmp(cast(E)Duration(10)) > 0);
            assert((cast(D)Duration(12)).opCmp(cast(E)Duration(-12)) > 0);

            assert(copy(cast(D)Duration(12)).opCmp(cast(E)Duration(12)) == 0);
            assert(copy(cast(D)Duration(-12)).opCmp(cast(E)Duration(-12)) == 0);

            assert(copy(cast(D)Duration(10)).opCmp(cast(E)Duration(12)) < 0);
            assert(copy(cast(D)Duration(-12)).opCmp(cast(E)Duration(12)) < 0);

            assert(copy(cast(D)Duration(12)).opCmp(cast(E)Duration(10)) > 0);
            assert(copy(cast(D)Duration(12)).opCmp(cast(E)Duration(-12)) > 0);

            assert((cast(D)Duration(12)).opCmp(copy(cast(E)Duration(12))) == 0);
            assert((cast(D)Duration(-12)).opCmp(copy(cast(E)Duration(-12))) == 0);

            assert((cast(D)Duration(10)).opCmp(copy(cast(E)Duration(12))) < 0);
            assert((cast(D)Duration(-12)).opCmp(copy(cast(E)Duration(12))) < 0);

            assert((cast(D)Duration(12)).opCmp(copy(cast(E)Duration(10))) > 0);
            assert((cast(D)Duration(12)).opCmp(copy(cast(E)Duration(-12))) > 0);
        }
    }
}

void testDurationOpBinaryDuration() pure @safe
{
    foreach (D; _TypeTuple!(Duration, const Duration, immutable Duration))
    {
        foreach (E; _TypeTuple!(Duration, const Duration, immutable Duration))
        {
            assert((cast(D)Duration(5)) + (cast(E)Duration(7)) == Duration(12));
            assert((cast(D)Duration(5)) - (cast(E)Duration(7)) == Duration(-2));
            assert((cast(D)Duration(5)) % (cast(E)Duration(7)) == Duration(5));
            assert((cast(D)Duration(7)) + (cast(E)Duration(5)) == Duration(12));
            assert((cast(D)Duration(7)) - (cast(E)Duration(5)) == Duration(2));
            assert((cast(D)Duration(7)) % (cast(E)Duration(5)) == Duration(2));

            assert((cast(D)Duration(5)) + (cast(E)Duration(-7)) == Duration(-2));
            assert((cast(D)Duration(5)) - (cast(E)Duration(-7)) == Duration(12));
            assert((cast(D)Duration(5)) % (cast(E)Duration(-7)) == Duration(5));
            assert((cast(D)Duration(7)) + (cast(E)Duration(-5)) == Duration(2));
            assert((cast(D)Duration(7)) - (cast(E)Duration(-5)) == Duration(12));
            assert((cast(D)Duration(7)) % (cast(E)Duration(-5)) == Duration(2));

            assert((cast(D)Duration(-5)) + (cast(E)Duration(7)) == Duration(2));
            assert((cast(D)Duration(-5)) - (cast(E)Duration(7)) == Duration(-12));
            assert((cast(D)Duration(-5)) % (cast(E)Duration(7)) == Duration(-5));
            assert((cast(D)Duration(-7)) + (cast(E)Duration(5)) == Duration(-2));
            assert((cast(D)Duration(-7)) - (cast(E)Duration(5)) == Duration(-12));
            assert((cast(D)Duration(-7)) % (cast(E)Duration(5)) == Duration(-2));

            assert((cast(D)Duration(-5)) + (cast(E)Duration(-7)) == Duration(-12));
            assert((cast(D)Duration(-5)) - (cast(E)Duration(-7)) == Duration(2));
            assert((cast(D)Duration(-5)) % (cast(E)Duration(7)) == Duration(-5));
            assert((cast(D)Duration(-7)) + (cast(E)Duration(-5)) == Duration(-12));
            assert((cast(D)Duration(-7)) - (cast(E)Duration(-5)) == Duration(-2));
            assert((cast(D)Duration(-7)) % (cast(E)Duration(5)) == Duration(-2));
        }

        foreach (T; _TypeTuple!(TickDuration, const TickDuration, immutable TickDuration))
        {
            assertApprox((cast(D)Duration(5)) + cast(T)TickDuration.from!"usecs"(7), Duration(70), Duration(80));
            assertApprox((cast(D)Duration(5)) - cast(T)TickDuration.from!"usecs"(7), Duration(-70), Duration(-60));
            assertApprox((cast(D)Duration(7)) + cast(T)TickDuration.from!"usecs"(5), Duration(52), Duration(62));
            assertApprox((cast(D)Duration(7)) - cast(T)TickDuration.from!"usecs"(5), Duration(-48), Duration(-38));

            assertApprox((cast(D)Duration(5)) + cast(T)TickDuration.from!"usecs"(-7), Duration(-70), Duration(-60));
            assertApprox((cast(D)Duration(5)) - cast(T)TickDuration.from!"usecs"(-7), Duration(70), Duration(80));
            assertApprox((cast(D)Duration(7)) + cast(T)TickDuration.from!"usecs"(-5), Duration(-48), Duration(-38));
            assertApprox((cast(D)Duration(7)) - cast(T)TickDuration.from!"usecs"(-5), Duration(52), Duration(62));

            assertApprox((cast(D)Duration(-5)) + cast(T)TickDuration.from!"usecs"(7), Duration(60), Duration(70));
            assertApprox((cast(D)Duration(-5)) - cast(T)TickDuration.from!"usecs"(7), Duration(-80), Duration(-70));
            assertApprox((cast(D)Duration(-7)) + cast(T)TickDuration.from!"usecs"(5), Duration(38), Duration(48));
            assertApprox((cast(D)Duration(-7)) - cast(T)TickDuration.from!"usecs"(5), Duration(-62), Duration(-52));

            assertApprox((cast(D)Duration(-5)) + cast(T)TickDuration.from!"usecs"(-7), Duration(-80), Duration(-70));
            assertApprox((cast(D)Duration(-5)) - cast(T)TickDuration.from!"usecs"(-7), Duration(60), Duration(70));
            assertApprox((cast(D)Duration(-7)) + cast(T)TickDuration.from!"usecs"(-5), Duration(-62), Duration(-52));
            assertApprox((cast(D)Duration(-7)) - cast(T)TickDuration.from!"usecs"(-5), Duration(38), Duration(48));
        }
    }
}

void testDurationOpBinaryRightDuration() pure @safe
{
    foreach (D; _TypeTuple!(Duration, const Duration, immutable Duration))
    {
        foreach (T; _TypeTuple!(TickDuration, const TickDuration, immutable TickDuration))
        {
            assertApprox((cast(T)TickDuration.from!"usecs"(7)) + cast(D)Duration(5), Duration(70), Duration(80));
            assertApprox((cast(T)TickDuration.from!"usecs"(7)) - cast(D)Duration(5), Duration(60), Duration(70));
            assertApprox((cast(T)TickDuration.from!"usecs"(5)) + cast(D)Duration(7), Duration(52), Duration(62));
            assertApprox((cast(T)TickDuration.from!"usecs"(5)) - cast(D)Duration(7), Duration(38), Duration(48));

            assertApprox((cast(T)TickDuration.from!"usecs"(-7)) + cast(D)Duration(5), Duration(-70), Duration(-60));
            assertApprox((cast(T)TickDuration.from!"usecs"(-7)) - cast(D)Duration(5), Duration(-80), Duration(-70));
            assertApprox((cast(T)TickDuration.from!"usecs"(-5)) + cast(D)Duration(7), Duration(-48), Duration(-38));
            assertApprox((cast(T)TickDuration.from!"usecs"(-5)) - cast(D)Duration(7), Duration(-62), Duration(-52));

            assertApprox((cast(T)TickDuration.from!"usecs"(7)) + (cast(D)Duration(-5)), Duration(60), Duration(70));
            assertApprox((cast(T)TickDuration.from!"usecs"(7)) - (cast(D)Duration(-5)), Duration(70), Duration(80));
            assertApprox((cast(T)TickDuration.from!"usecs"(5)) + (cast(D)Duration(-7)), Duration(38), Duration(48));
            assertApprox((cast(T)TickDuration.from!"usecs"(5)) - (cast(D)Duration(-7)), Duration(52), Duration(62));

            assertApprox((cast(T)TickDuration.from!"usecs"(-7)) + cast(D)Duration(-5), Duration(-80), Duration(-70));
            assertApprox((cast(T)TickDuration.from!"usecs"(-7)) - cast(D)Duration(-5), Duration(-70), Duration(-60));
            assertApprox((cast(T)TickDuration.from!"usecs"(-5)) + cast(D)Duration(-7), Duration(-62), Duration(-52));
            assertApprox((cast(T)TickDuration.from!"usecs"(-5)) - cast(D)Duration(-7), Duration(-48), Duration(-38));
        }
    }
}

void testDurationOpOpAssignDuration() pure @safe
{
    static void test1(string op, E)(Duration actual, in E rhs, Duration expected, size_t line = __LINE__)
    {
        if (mixin("actual " ~ op ~ " rhs") != expected)
            throw new AssertError("op failed", __FILE__, line);

        if (actual != expected)
            throw new AssertError("op assign failed", __FILE__, line);
    }

    static void test2(string op, E)
                     (Duration actual, in E rhs, Duration lower, Duration upper, size_t line = __LINE__)
    {
        assertApprox(mixin("actual " ~ op ~ " rhs"), lower, upper, "op failed", line);
        assertApprox(actual, lower, upper, "op assign failed", line);
    }

    foreach (E; _TypeTuple!(Duration, const Duration, immutable Duration))
    {
        test1!"+="(Duration(5), (cast(E)Duration(7)), Duration(12));
        test1!"-="(Duration(5), (cast(E)Duration(7)), Duration(-2));
        test1!"%="(Duration(5), (cast(E)Duration(7)), Duration(5));
        test1!"+="(Duration(7), (cast(E)Duration(5)), Duration(12));
        test1!"-="(Duration(7), (cast(E)Duration(5)), Duration(2));
        test1!"%="(Duration(7), (cast(E)Duration(5)), Duration(2));

        test1!"+="(Duration(5), (cast(E)Duration(-7)), Duration(-2));
        test1!"-="(Duration(5), (cast(E)Duration(-7)), Duration(12));
        test1!"%="(Duration(5), (cast(E)Duration(-7)), Duration(5));
        test1!"+="(Duration(7), (cast(E)Duration(-5)), Duration(2));
        test1!"-="(Duration(7), (cast(E)Duration(-5)), Duration(12));
        test1!"%="(Duration(7), (cast(E)Duration(-5)), Duration(2));

        test1!"+="(Duration(-5), (cast(E)Duration(7)), Duration(2));
        test1!"-="(Duration(-5), (cast(E)Duration(7)), Duration(-12));
        test1!"%="(Duration(-5), (cast(E)Duration(7)), Duration(-5));
        test1!"+="(Duration(-7), (cast(E)Duration(5)), Duration(-2));
        test1!"-="(Duration(-7), (cast(E)Duration(5)), Duration(-12));
        test1!"%="(Duration(-7), (cast(E)Duration(5)), Duration(-2));

        test1!"+="(Duration(-5), (cast(E)Duration(-7)), Duration(-12));
        test1!"-="(Duration(-5), (cast(E)Duration(-7)), Duration(2));
        test1!"%="(Duration(-5), (cast(E)Duration(-7)), Duration(-5));
        test1!"+="(Duration(-7), (cast(E)Duration(-5)), Duration(-12));
        test1!"-="(Duration(-7), (cast(E)Duration(-5)), Duration(-2));
        test1!"%="(Duration(-7), (cast(E)Duration(-5)), Duration(-2));
    }

    foreach (T; _TypeTuple!(TickDuration, const TickDuration, immutable TickDuration))
    {
        test2!"+="(Duration(5), cast(T)TickDuration.from!"usecs"(7), Duration(70), Duration(80));
        test2!"-="(Duration(5), cast(T)TickDuration.from!"usecs"(7), Duration(-70), Duration(-60));
        test2!"+="(Duration(7), cast(T)TickDuration.from!"usecs"(5), Duration(52), Duration(62));
        test2!"-="(Duration(7), cast(T)TickDuration.from!"usecs"(5), Duration(-48), Duration(-38));

        test2!"+="(Duration(5), cast(T)TickDuration.from!"usecs"(-7), Duration(-70), Duration(-60));
        test2!"-="(Duration(5), cast(T)TickDuration.from!"usecs"(-7), Duration(70), Duration(80));
        test2!"+="(Duration(7), cast(T)TickDuration.from!"usecs"(-5), Duration(-48), Duration(-38));
        test2!"-="(Duration(7), cast(T)TickDuration.from!"usecs"(-5), Duration(52), Duration(62));

        test2!"+="(Duration(-5), cast(T)TickDuration.from!"usecs"(7), Duration(60), Duration(70));
        test2!"-="(Duration(-5), cast(T)TickDuration.from!"usecs"(7), Duration(-80), Duration(-70));
        test2!"+="(Duration(-7), cast(T)TickDuration.from!"usecs"(5), Duration(38), Duration(48));
        test2!"-="(Duration(-7), cast(T)TickDuration.from!"usecs"(5), Duration(-62), Duration(-52));

        test2!"+="(Duration(-5), cast(T)TickDuration.from!"usecs"(-7), Duration(-80), Duration(-70));
        test2!"-="(Duration(-5), cast(T)TickDuration.from!"usecs"(-7), Duration(60), Duration(70));
        test2!"+="(Duration(-7), cast(T)TickDuration.from!"usecs"(-5), Duration(-62), Duration(-52));
        test2!"-="(Duration(-7), cast(T)TickDuration.from!"usecs"(-5), Duration(38), Duration(48));
    }

    foreach (D; _TypeTuple!(const Duration, immutable Duration))
    {
        foreach (E; _TypeTuple!(Duration, const Duration, immutable Duration,
                               TickDuration, const TickDuration, immutable TickDuration))
        {
            D lhs = D(120);
            E rhs = E(120);
            static assert(!__traits(compiles, lhs += rhs), D.stringof ~ " " ~ E.stringof);
        }
    }
}

void testDurationTimesLong() pure @safe
{
    foreach (D; _TypeTuple!(Duration, const Duration, immutable Duration))
    {
        assert((cast(D)Duration(5)) * 7 == Duration(35));
        assert((cast(D)Duration(7)) * 5 == Duration(35));

        assert((cast(D)Duration(5)) * -7 == Duration(-35));
        assert((cast(D)Duration(7)) * -5 == Duration(-35));

        assert((cast(D)Duration(-5)) * 7 == Duration(-35));
        assert((cast(D)Duration(-7)) * 5 == Duration(-35));

        assert((cast(D)Duration(-5)) * -7 == Duration(35));
        assert((cast(D)Duration(-7)) * -5 == Duration(35));

        assert((cast(D)Duration(5)) * 0 == Duration(0));
        assert((cast(D)Duration(-5)) * 0 == Duration(0));
    }
}

void testDurationDivideLong() pure @safe
{
    foreach (D; _TypeTuple!(Duration, const Duration, immutable Duration))
    {
        assert((cast(D)Duration(5)) / 7 == Duration(0));
        assert((cast(D)Duration(7)) / 5 == Duration(1));

        assert((cast(D)Duration(5)) / -7 == Duration(0));
        assert((cast(D)Duration(7)) / -5 == Duration(-1));

        assert((cast(D)Duration(-5)) / 7 == Duration(0));
        assert((cast(D)Duration(-7)) / 5 == Duration(-1));

        assert((cast(D)Duration(-5)) / -7 == Duration(0));
        assert((cast(D)Duration(-7)) / -5 == Duration(1));
    }
}

void testDurationTimesAssignLong() pure @safe
{
    static void test(D)(D actual, long value, Duration expected, size_t line = __LINE__)
    {
        if ((actual *= value) != expected)
            throw new AssertError("op failed", __FILE__, line);

        if (actual != expected)
            throw new AssertError("op assign failed", __FILE__, line);
    }

    test(Duration(5), 7, Duration(35));
    test(Duration(7), 5, Duration(35));

    test(Duration(5), -7, Duration(-35));
    test(Duration(7), -5, Duration(-35));

    test(Duration(-5), 7, Duration(-35));
    test(Duration(-7), 5, Duration(-35));

    test(Duration(-5), -7, Duration(35));
    test(Duration(-7), -5, Duration(35));

    test(Duration(5), 0, Duration(0));
    test(Duration(-5), 0, Duration(0));

    const cdur = Duration(12);
    immutable idur = Duration(12);
    static assert(!__traits(compiles, cdur *= 12));
    static assert(!__traits(compiles, idur *= 12));
}

void testDurationTimesDivideLong()
{
    static void test(Duration actual, long value, Duration expected, size_t line = __LINE__)
    {
        if ((actual /= value) != expected)
            throw new AssertError("op failed", __FILE__, line);

        if (actual != expected)
            throw new AssertError("op assign failed", __FILE__, line);
    }

    test(Duration(5), 7, Duration(0));
    test(Duration(7), 5, Duration(1));

    test(Duration(5), -7, Duration(0));
    test(Duration(7), -5, Duration(-1));

    test(Duration(-5), 7, Duration(0));
    test(Duration(-7), 5, Duration(-1));

    test(Duration(-5), -7, Duration(0));
    test(Duration(-7), -5, Duration(1));

    const cdur = Duration(12);
    immutable idur = Duration(12);
    static assert(!__traits(compiles, cdur /= 12));
    static assert(!__traits(compiles, idur /= 12));
}

void testDurationDivideByDuration() pure @safe
{
    assert(Duration(5) / Duration(7) == 0);
    assert(Duration(7) / Duration(5) == 1);
    assert(Duration(8) / Duration(4) == 2);

    assert(Duration(5) / Duration(-7) == 0);
    assert(Duration(7) / Duration(-5) == -1);
    assert(Duration(8) / Duration(-4) == -2);

    assert(Duration(-5) / Duration(7) == 0);
    assert(Duration(-7) / Duration(5) == -1);
    assert(Duration(-8) / Duration(4) == -2);

    assert(Duration(-5) / Duration(-7) == 0);
    assert(Duration(-7) / Duration(-5) == 1);
    assert(Duration(-8) / Duration(-4) == 2);
}

void testLongTimesDuration() pure @safe
{
    foreach (D; _TypeTuple!(Duration, const Duration, immutable Duration))
    {
        assert(5 * cast(D)Duration(7) == Duration(35));
        assert(7 * cast(D)Duration(5) == Duration(35));

        assert(5 * cast(D)Duration(-7) == Duration(-35));
        assert(7 * cast(D)Duration(-5) == Duration(-35));

        assert(-5 * cast(D)Duration(7) == Duration(-35));
        assert(-7 * cast(D)Duration(5) == Duration(-35));

        assert(-5 * cast(D)Duration(-7) == Duration(35));
        assert(-7 * cast(D)Duration(-5) == Duration(35));

        assert(0 * cast(D)Duration(-5) == Duration(0));
        assert(0 * cast(D)Duration(5) == Duration(0));
    }
}

void testNegateDuration() pure @safe
{
    foreach (D; _TypeTuple!(Duration, const Duration, immutable Duration))
    {
        assert(-(cast(D)Duration(7)) == Duration(-7));
        assert(-(cast(D)Duration(5)) == Duration(-5));
        assert(-(cast(D)Duration(-7)) == Duration(7));
        assert(-(cast(D)Duration(-5)) == Duration(5));
        assert(-(cast(D)Duration(0)) == Duration(0));
    }
}

void testDurationCastToTickDuration() pure @safe
{
    foreach (D; _TypeTuple!(Duration, const Duration, immutable Duration))
    {
        foreach (units; _TypeTuple!("seconds", "msecs", "usecs", "hnsecs"))
        {
            enum unitsPerSec = convert!("seconds", units)(1);

            if (TickDuration.ticksPerSec >= unitsPerSec)
            {
                foreach (T; _TypeTuple!(TickDuration, const TickDuration, immutable TickDuration))
                {
                    auto t = TickDuration.from!units(1);
                    assertApprox(cast(T)cast(D)dur!units(1), t - TickDuration(1), t + TickDuration(1), units);
                    t = TickDuration.from!units(2);
                    assertApprox(cast(T)cast(D)dur!units(2), t - TickDuration(1), t + TickDuration(1), units);
                }
            }
            else
            {
                auto t = TickDuration.from!units(1);
                assert(t.to!(units, long)() == 0, units);
                t = TickDuration.from!units(1_000_000);
                assert(t.to!(units, long)() >= 900_000, units);
                assert(t.to!(units, long)() <= 1_100_000, units);
            }
        }
    }
}

void testDurationCastToBool() pure @safe
{
    auto d = 10.minutes;
    assert(d);
    assert(!(d - d));
    assert(d + d);
}

void testDurationSplit() pure @safe nothrow
{
    foreach (D; _TypeTuple!(const Duration, immutable Duration))
    {
        D d = dur!"weeks"(3) + dur!"days"(5) + dur!"hours"(19) + dur!"minutes"(7) +
              dur!"seconds"(2) + dur!"hnsecs"(1234567);
        byte weeks;
        ubyte days;
        short hours;
        ushort minutes;
        int seconds;
        uint msecs;
        long usecs;
        ulong hnsecs;
        long nsecs;

        d.split!("weeks", "days", "hours", "minutes", "seconds", "msecs", "usecs", "hnsecs", "nsecs")
                (weeks, days, hours, minutes, seconds, msecs, usecs, hnsecs, nsecs);
        assert(weeks == 3);
        assert(days == 5);
        assert(hours == 19);
        assert(minutes == 7);
        assert(seconds == 2);
        assert(msecs == 123);
        assert(usecs == 456);
        assert(hnsecs == 7);
        assert(nsecs == 0);

        d.split!("weeks", "days", "hours", "seconds", "usecs")(weeks, days, hours, seconds, usecs);
        assert(weeks == 3);
        assert(days == 5);
        assert(hours == 19);
        assert(seconds == 422);
        assert(usecs == 123456);

        d.split!("days", "minutes", "seconds", "nsecs")(days, minutes, seconds, nsecs);
        assert(days == 26);
        assert(minutes == 1147);
        assert(seconds == 2);
        assert(nsecs == 123456700);

        d.split!("minutes", "msecs", "usecs", "hnsecs")(minutes, msecs, usecs, hnsecs);
        assert(minutes == 38587);
        assert(msecs == 2123);
        assert(usecs == 456);
        assert(hnsecs == 7);

        {
            auto result = d.split!("weeks", "days", "hours", "minutes", "seconds",
                                   "msecs", "usecs", "hnsecs", "nsecs");
            assert(result.weeks == 3);
            assert(result.days == 5);
            assert(result.hours == 19);
            assert(result.minutes == 7);
            assert(result.seconds == 2);
            assert(result.msecs == 123);
            assert(result.usecs == 456);
            assert(result.hnsecs == 7);
            assert(result.nsecs == 0);
        }

        {
            auto result = d.split!("weeks", "days", "hours", "seconds", "usecs");
            assert(result.weeks == 3);
            assert(result.days == 5);
            assert(result.hours == 19);
            assert(result.seconds == 422);
            assert(result.usecs == 123456);
        }

        {
            auto result = d.split!("days", "minutes", "seconds", "nsecs")();
            assert(result.days == 26);
            assert(result.minutes == 1147);
            assert(result.seconds == 2);
            assert(result.nsecs == 123456700);
        }

        {
            auto result = d.split!("minutes", "msecs", "usecs", "hnsecs")();
            assert(result.minutes == 38587);
            assert(result.msecs == 2123);
            assert(result.usecs == 456);
            assert(result.hnsecs == 7);
        }

        {
            auto result = d.split();
            assert(result.weeks == 3);
            assert(result.days == 5);
            assert(result.hours == 19);
            assert(result.minutes == 7);
            assert(result.seconds == 2);
            assert(result.msecs == 123);
            assert(result.usecs == 456);
            assert(result.hnsecs == 7);
            static assert(!is(typeof(result.nsecs)));
        }

        static assert(!is(typeof(d.split("seconds", "hnsecs")(seconds))));
        static assert(!is(typeof(d.split("hnsecs", "seconds", "minutes")(hnsecs, seconds, minutes))));
        static assert(!is(typeof(d.split("hnsecs", "seconds", "msecs")(hnsecs, seconds, msecs))));
        static assert(!is(typeof(d.split("seconds", "hnecs", "msecs")(seconds, hnsecs, msecs))));
        static assert(!is(typeof(d.split("seconds", "msecs", "msecs")(seconds, msecs, msecs))));
        static assert(!is(typeof(d.split("hnsecs", "seconds", "minutes")())));
        static assert(!is(typeof(d.split("hnsecs", "seconds", "msecs")())));
        static assert(!is(typeof(d.split("seconds", "hnecs", "msecs")())));
        static assert(!is(typeof(d.split("seconds", "msecs", "msecs")())));
        alias _TypeTuple!("nsecs", "hnsecs", "usecs", "msecs", "seconds",
                          "minutes", "hours", "days", "weeks") timeStrs;
        foreach (i, str; timeStrs[1 .. $])
            static assert(!is(typeof(d.split!(timeStrs[i - 1], str)())));

        D nd = -d;

        {
            auto result = nd.split();
            assert(result.weeks == -3);
            assert(result.days == -5);
            assert(result.hours == -19);
            assert(result.minutes == -7);
            assert(result.seconds == -2);
            assert(result.msecs == -123);
            assert(result.usecs == -456);
            assert(result.hnsecs == -7);
        }

        {
            auto result = nd.split!("weeks", "days", "hours", "minutes", "seconds", "nsecs")();
            assert(result.weeks == -3);
            assert(result.days == -5);
            assert(result.hours == -19);
            assert(result.minutes == -7);
            assert(result.seconds == -2);
            assert(result.nsecs == -123456700);
        }
    }
}

void testDurationTotal() pure @safe
{
    foreach (D; _TypeTuple!(const Duration, immutable Duration))
    {
        assert((cast(D)dur!"weeks"(12)).total!"weeks" == 12);
        assert((cast(D)dur!"weeks"(12)).total!"days" == 84);

        assert((cast(D)dur!"days"(13)).total!"weeks" == 1);
        assert((cast(D)dur!"days"(13)).total!"days" == 13);

        assert((cast(D)dur!"hours"(49)).total!"days" == 2);
        assert((cast(D)dur!"hours"(49)).total!"hours" == 49);

        assert((cast(D)dur!"nsecs"(2007)).total!"hnsecs" == 20);
        assert((cast(D)dur!"nsecs"(2007)).total!"nsecs" == 2000);
    }
}

void testDurationToString() pure @safe
{
    foreach (D; _TypeTuple!(Duration, const Duration, immutable Duration))
    {
        assert((cast(D)Duration(0)).toString() == "0 hnsecs");
        assert((cast(D)Duration(1)).toString() == "1 hnsec");
        assert((cast(D)Duration(7)).toString() == "7 hnsecs");
        assert((cast(D)Duration(10)).toString() == "1 μs");
        assert((cast(D)Duration(20)).toString() == "2 μs");
        assert((cast(D)Duration(10_000)).toString() == "1 ms");
        assert((cast(D)Duration(20_000)).toString() == "2 ms");
        assert((cast(D)Duration(10_000_000)).toString() == "1 sec");
        assert((cast(D)Duration(20_000_000)).toString() == "2 secs");
        assert((cast(D)Duration(600_000_000)).toString() == "1 minute");
        assert((cast(D)Duration(1_200_000_000)).toString() == "2 minutes");
        assert((cast(D)Duration(36_000_000_000)).toString() == "1 hour");
        assert((cast(D)Duration(72_000_000_000)).toString() == "2 hours");
        assert((cast(D)Duration(864_000_000_000)).toString() == "1 day");
        assert((cast(D)Duration(1_728_000_000_000)).toString() == "2 days");
        assert((cast(D)Duration(6_048_000_000_000)).toString() == "1 week");
        assert((cast(D)Duration(12_096_000_000_000)).toString() == "2 weeks");

        assert((cast(D)Duration(12)).toString() == "1 μs and 2 hnsecs");
        assert((cast(D)Duration(120_795)).toString() == "12 ms, 79 μs, and 5 hnsecs");
        assert((cast(D)Duration(12_096_020_900_003)).toString() == "2 weeks, 2 secs, 90 ms, and 3 hnsecs");

        assert((cast(D)Duration(-1)).toString() == "-1 hnsecs");
        assert((cast(D)Duration(-7)).toString() == "-7 hnsecs");
        assert((cast(D)Duration(-10)).toString() == "-1 μs");
        assert((cast(D)Duration(-20)).toString() == "-2 μs");
        assert((cast(D)Duration(-10_000)).toString() == "-1 ms");
        assert((cast(D)Duration(-20_000)).toString() == "-2 ms");
        assert((cast(D)Duration(-10_000_000)).toString() == "-1 secs");
        assert((cast(D)Duration(-20_000_000)).toString() == "-2 secs");
        assert((cast(D)Duration(-600_000_000)).toString() == "-1 minutes");
        assert((cast(D)Duration(-1_200_000_000)).toString() == "-2 minutes");
        assert((cast(D)Duration(-36_000_000_000)).toString() == "-1 hours");
        assert((cast(D)Duration(-72_000_000_000)).toString() == "-2 hours");
        assert((cast(D)Duration(-864_000_000_000)).toString() == "-1 days");
        assert((cast(D)Duration(-1_728_000_000_000)).toString() == "-2 days");
        assert((cast(D)Duration(-6_048_000_000_000)).toString() == "-1 weeks");
        assert((cast(D)Duration(-12_096_000_000_000)).toString() == "-2 weeks");

        assert((cast(D)Duration(-12)).toString() == "-1 μs and -2 hnsecs");
        assert((cast(D)Duration(-120_795)).toString() == "-12 ms, -79 μs, and -5 hnsecs");
        assert((cast(D)Duration(-12_096_020_900_003)).toString() == "-2 weeks, -2 secs, -90 ms, and -3 hnsecs");
    }
}

void testDurationIsNegative() pure @safe
{
    foreach (D; _TypeTuple!(Duration, const Duration, immutable Duration))
    {
        assert(!(cast(D)Duration(100)).isNegative);
        assert(!(cast(D)Duration(1)).isNegative);
        assert(!(cast(D)Duration(0)).isNegative);
        assert((cast(D)Duration(-1)).isNegative);
        assert((cast(D)Duration(-100)).isNegative);
    }
}

//
// free functions 1
//

void testTo()
{
    void testFun(string U)() {
        auto t1v = 1000;
        auto t2v = 333;

        auto t1 = TickDuration.from!U(t1v);
        auto t2 = TickDuration.from!U(t2v);

        auto _str(F)(F val)
        {
            static if (is(F == int) || is(F == long))
                return signedToTempString(val, 10);
            else
                return unsignedToTempString(val, 10);
        }

        foreach (F; _TypeTuple!(int,uint,long,ulong,float,double,real))
        {
            F t1f = to!(U,F)(t1);
            F t2f = to!(U,F)(t2);
            auto t12d = t1 / t2v;
            auto t12m = t1 - t2;
            F t3f = to!(U,F)(t12d);
            F t4f = to!(U,F)(t12m);


            static if (is(F == float) || is(F == double) || is(F == real))
            {
                assert((t1f - cast(F)t1v) <= 3.0,
                    F.stringof ~ " " ~ U ~ " " ~ doubleToString(t1f) ~ " " ~
                    doubleToString(cast(F)t1v)
                );
                assert((t2f - cast(F)t2v) <= 3.0,
                    F.stringof ~ " " ~ U ~ " " ~ doubleToString(t2f) ~ " " ~
                    doubleToString(cast(F)t2v)
                );
                assert(t3f - (cast(F)t1v) / (cast(F)t2v) <= 3.0,
                    F.stringof ~ " " ~ U ~ " " ~ doubleToString(t3f) ~ " " ~
                    doubleToString((cast(F)t1v)/(cast(F)t2v))
                );
                assert(t4f - (cast(F)(t1v - t2v)) <= 3.0,
                    F.stringof ~ " " ~ U ~ " " ~ doubleToString(t4f) ~ " " ~
                    doubleToString(cast(F)(t1v - t2v))
                );
            }
            else
            {
                // even though this should be exact math it is not as internal
                // in "to" floating point is used
                assert(_abs(t1f) - _abs(cast(F)t1v) <= 3,
                    F.stringof ~ " " ~ U ~ " " ~ _str(t1f) ~ " " ~
                    _str(cast(F)t1v)
                );
                assert(_abs(t2f) - _abs(cast(F)t2v) <= 3,
                    F.stringof ~ " " ~ U ~ " " ~ _str(t2f) ~ " " ~
                    _str(cast(F)t2v)
                );
                assert(_abs(t3f) - _abs((cast(F)t1v) / (cast(F)t2v)) <= 3,
                    F.stringof ~ " " ~ U ~ " " ~ _str(t3f) ~ " " ~
                    _str((cast(F)t1v) / (cast(F)t2v))
                );
                assert(_abs(t4f) - _abs((cast(F)t1v) - (cast(F)t2v)) <= 3,
                    F.stringof ~ " " ~ U ~ " " ~ _str(t4f) ~ " " ~
                    _str((cast(F)t1v) - (cast(F)t2v))
                );
            }
        }
    }

    testFun!"seconds"();
    testFun!"msecs"();
    testFun!"usecs"();
}

void testDur()
{
    foreach (D; _TypeTuple!(Duration, const Duration, immutable Duration))
    {
        assert(dur!"weeks"(7).total!"weeks" == 7);
        assert(dur!"days"(7).total!"days" == 7);
        assert(dur!"hours"(7).total!"hours" == 7);
        assert(dur!"minutes"(7).total!"minutes" == 7);
        assert(dur!"seconds"(7).total!"seconds" == 7);
        assert(dur!"msecs"(7).total!"msecs" == 7);
        assert(dur!"usecs"(7).total!"usecs" == 7);
        assert(dur!"hnsecs"(7).total!"hnsecs" == 7);
        assert(dur!"nsecs"(7).total!"nsecs" == 0);

        assert(dur!"weeks"(1007) == weeks(1007));
        assert(dur!"days"(1007) == days(1007));
        assert(dur!"hours"(1007) == hours(1007));
        assert(dur!"minutes"(1007) == minutes(1007));
        assert(dur!"seconds"(1007) == seconds(1007));
        assert(dur!"msecs"(1007) == msecs(1007));
        assert(dur!"usecs"(1007) == usecs(1007));
        assert(dur!"hnsecs"(1007) == hnsecs(1007));
        assert(dur!"nsecs"(10) == nsecs(10));
    }
}

//
// MonoTimeImpl
//

// POD value, test mutable/const/immutable conversion
void testMonoTimeImplStorageConversion(MonoTimeImpl)() @safe
{
    MonoTimeImpl m;
    const MonoTimeImpl cm = m;
    immutable MonoTimeImpl im = m;
    m = cm;
    m = im;
}

void testMonoTimeImplBounds(MonoTimeImpl)() @safe
{
    assert(MonoTimeImpl.zero == MonoTimeImpl(0));
    assert(MonoTimeImpl.max == MonoTimeImpl(long.max));
    assert(MonoTimeImpl.min == MonoTimeImpl(long.min));
    assert(MonoTimeImpl.min < MonoTimeImpl.zero);
    assert(MonoTimeImpl.zero < MonoTimeImpl.max);
    assert(MonoTimeImpl.min < MonoTimeImpl.max);
}

void testMonoTimeImplOpCmp1(MonoTimeImpl)() @safe
{
    const t = MonoTimeImpl.currTime;
    assert(t == copy(t));
}

void testMonoTimeImplOpCmp2(MonoTimeImpl)() @safe
{
    const before = MonoTimeImpl.currTime;
    auto after = MonoTimeImpl(before._ticks + 42);
    assert(before < after);
    assert(copy(before) <= before);
    assert(copy(after) > before);
    assert(after >= copy(after));
}

void testMonoTimeImplOpCmp3(MonoTimeImpl)() @safe
{
    const currTime = MonoTimeImpl.currTime;
    assert(MonoTimeImpl(long.max) > MonoTimeImpl(0));
    assert(MonoTimeImpl(0) > MonoTimeImpl(long.min));
    assert(MonoTimeImpl(long.max) > currTime);
    assert(currTime > MonoTimeImpl(0));
    assert(MonoTimeImpl(0) < currTime);
    assert(MonoTimeImpl(0) < MonoTimeImpl(long.max));
    assert(MonoTimeImpl(long.min) < MonoTimeImpl(0));
}

void testMonoTimeImplMinusMonoTimeImpl1(MonoTimeImpl)() @safe
{
    const t = MonoTimeImpl.currTime;
    assert(t - copy(t) == Duration.zero);
    static assert(!__traits(compiles, t + t));
}

void testMonoTimeImplMinusMonoTimeImpl2(MonoTimeImpl)() @safe
{
    static void test(in MonoTimeImpl before, in MonoTimeImpl after, in Duration min)
    {
        immutable diff = after - before;
        assert(diff >= min);
        auto calcAfter = before + diff;
        assertApprox(calcAfter, calcAfter - Duration(1), calcAfter + Duration(1));
        assert(before - after == -diff);
    }

    const before = MonoTimeImpl.currTime;
    test(before, MonoTimeImpl(before._ticks + 4202), Duration.zero);
    test(before, MonoTimeImpl.currTime, Duration.zero);

    const durLargerUnits = dur!"minutes"(7) + dur!"seconds"(22);
    test(before, before + durLargerUnits + dur!"msecs"(33) + dur!"hnsecs"(571), durLargerUnits);
}

void testMonoTimeImplPlusMinusDuration1(MonoTimeImpl)() @safe
{
    const t = MonoTimeImpl.currTime;
    assert(t + Duration(0) == t);
    assert(t - Duration(0) == t);
}

void testMonoTimeImplPlusMinusDuration2(MonoTimeImpl)() @safe
{
    const t = MonoTimeImpl.currTime;

    // We reassign ticks in order to get the same rounding errors
    // that we should be getting with Duration (e.g. MonoTimeImpl may be
    // at a higher precision than hnsecs, meaning that 7333 would be
    // truncated when converting to hnsecs).
    long ticks = 7333;
    auto hnsecs = convClockFreq(ticks, MonoTimeImpl.ticksPerSecond, hnsecsPer!"seconds");
    ticks = convClockFreq(hnsecs, hnsecsPer!"seconds", MonoTimeImpl.ticksPerSecond);

    assert(t - Duration(hnsecs) == MonoTimeImpl(t._ticks - ticks));
    assert(t + Duration(hnsecs) == MonoTimeImpl(t._ticks + ticks));
}

void testMonoTimeImplPLusMinusAssign(MonoTimeImpl)() @safe
{
    auto mt = MonoTimeImpl.currTime;
    const initial = mt;
    mt += Duration(0);
    assert(mt == initial);
    mt -= Duration(0);
    assert(mt == initial);

    // We reassign ticks in order to get the same rounding errors
    // that we should be getting with Duration (e.g. MonoTimeImpl may be
    // at a higher precision than hnsecs, meaning that 7333 would be
    // truncated when converting to hnsecs).
    long ticks = 7333;
    auto hnsecs = convClockFreq(ticks, MonoTimeImpl.ticksPerSecond, hnsecsPer!"seconds");
    ticks = convClockFreq(hnsecs, hnsecsPer!"seconds", MonoTimeImpl.ticksPerSecond);
    auto before = MonoTimeImpl(initial._ticks - ticks);

    assert((mt -= Duration(hnsecs)) == before);
    assert(mt  == before);
    assert((mt += Duration(hnsecs)) == initial);
    assert(mt  == initial);
}

void testMonoTimeImplTicks(MonoTimeImpl)() @safe
{
    const mt = MonoTimeImpl.currTime;
    assert(mt.ticks == mt._ticks);
}

void testMonoTimeImplToString(MonoTimeImpl)()
{
    static min(T)(T a, T b) { return a < b ? a : b; }

    static void eat(ref string s, const(char)[] exp)
    {
        assert(s[0 .. min($, exp.length)] == exp, s~" != "~exp);
        s = s[exp.length .. $];
    }

    immutable mt = MonoTimeImpl.currTime;
    auto str = mt.toString();
    static if (is(MonoTimeImpl == MonoTime))
        eat(str, "MonoTime(");
    else
        eat(str, "MonoTimeImpl!(ClockType."~MonoTimeImpl._clockName~")(");

    eat(str, signedToTempString(mt._ticks, 10));
    eat(str, " ticks, ");
    eat(str, signedToTempString(MonoTimeImpl.ticksPerSecond, 10));
    eat(str, " ticks per second)");
}


// Tests for MonoTimeImpl.currTime. It has to be outside, because MonoTimeImpl
// is a template. This unittest block also makes sure that MonoTimeImpl actually
// is instantiated with all of the various ClockTypes so that those types and
// their tests are compiled and run.
void testMonoTimeImplCurTime()
{
    // This test is separate so that it can be tested with MonoTime and not just
    // MonoTimeImpl.
    auto norm1 = MonoTime.currTime;
    auto norm2 = MonoTimeImpl!(ClockType.normal).currTime;
    assert(norm1 <= norm2);

    foreach (typeStr; __traits(allMembers, ClockType))
    {
        mixin("alias type = ClockType." ~ typeStr ~ ";");
        static if (clockSupported(type))
        {
            auto v1 = MonoTimeImpl!type.currTime;
            auto v2 = MonoTimeImpl!type.currTime;
            scope(failure)
            {
                printf("%s: v1 %s, v2 %s, tps %s\n",
                       (type.stringof ~ "\0").ptr,
                       numToStringz(v1._ticks),
                       numToStringz(v2._ticks),
                       numToStringz(typeof(v1).ticksPerSecond));
            }
            assert(v1 <= v2);

            foreach (otherStr; __traits(allMembers, ClockType))
            {
                mixin("alias other = ClockType." ~ otherStr ~ ";");
                static if (clockSupported(other))
                {
                    static assert(is(typeof({auto o1 = MonTimeImpl!other.currTime; auto b = v1 <= o1;})) ==
                                  is(type == other));
                }
            }
        }
    }
}

//
// Free functions 2
//

void testConvClockFreq()
{
    assert(convClockFreq(99, 43, 57) == 131);
    assert(convClockFreq(131, 57, 43) == 98);
    assert(convClockFreq(1234567890, 10_000_000, 1_000_000_000) == 123456789000);
    assert(convClockFreq(1234567890, 1_000_000_000, 10_000_000) == 12345678);
    assert(convClockFreq(123456789000, 1_000_000_000, 10_000_000) == 1234567890);
    assert(convClockFreq(12345678, 10_000_000, 1_000_000_000) == 1234567800);
    assert(convClockFreq(13131, 3_515_654, 10_000_000) == 37350);
    assert(convClockFreq(37350, 10_000_000, 3_515_654) == 13130);
    assert(convClockFreq(37350, 3_515_654, 10_000_000) == 106239);
    assert(convClockFreq(106239, 10_000_000, 3_515_654) == 37349);

    // It would be too expensive to cover a large range of possible values for
    // ticks, so we use pseudo-random values in an attempt to get reasonable coverage.
    uint rand()
    {
        static ulong x = 5418832822530675UL; // Consistent seed for deterministic test.
        x ^= x >> 12; x ^= x << 25; x ^= x >> 27;
        return cast(uint) ((x *= 2685821657736338717UL) >> 32);
    }
    enum freq1 = 5_527_551L;
    enum freq2 = 10_000_000L;
    enum freq3 = 1_000_000_000L;
    enum freq4 = 98_123_320L;
    immutable freq5 = MonoTime.ticksPerSecond;

    // This makes it so that freq6 is the first multiple of 10 which is greater
    // than or equal to freq5, which at one point was considered for MonoTime's
    // ticksPerSecond rather than using the system's actual clock frequency, so
    // it seemed like a good test case to have.
    import core.stdc.math;
    immutable numDigitsMinus1 = cast(int)floor(log10(freq5));
    auto freq6 = cast(long)pow(10, numDigitsMinus1);
    if (freq5 > freq6)
        freq6 *= 10;

    foreach (_; 0 .. 10_000)
    {
        long[2] values = [rand(), cast(long)rand() * (rand() % 16)];
        foreach (i; values)
        {
            scope(failure) printf("i %s\n", numToStringz(i));
            assertApprox(convClockFreq(convClockFreq(i, freq1, freq2), freq2, freq1), i - 10, i + 10);
            assertApprox(convClockFreq(convClockFreq(i, freq2, freq1), freq1, freq2), i - 10, i + 10);

            assertApprox(convClockFreq(convClockFreq(i, freq3, freq4), freq4, freq3), i - 100, i + 100);
            assertApprox(convClockFreq(convClockFreq(i, freq4, freq3), freq3, freq4), i - 100, i + 100);

            scope(failure) printf("sys %s mt %s\n", numToStringz(freq5), numToStringz(freq6));
            assertApprox(convClockFreq(convClockFreq(i, freq5, freq6), freq6, freq5), i - 10, i + 10);
            assertApprox(convClockFreq(convClockFreq(i, freq6, freq5), freq5, freq6), i - 10, i + 10);

            // This is here rather than in a unittest block immediately after
            // ticksToNSecs in order to avoid code duplication in the unit tests.
            assert(convClockFreq(i, MonoTime.ticksPerSecond, 1_000_000_000) == ticksToNSecs(i));
        }
    }
}

void testNsecsToTicks()
{
    long ticks = 123409832717333;
    auto nsecs = convClockFreq(ticks, MonoTime.ticksPerSecond, 1_000_000_000);
    ticks = convClockFreq(nsecs, 1_000_000_000, MonoTime.ticksPerSecond);
    assert(nsecsToTicks(nsecs) == ticks);
}

//
// TickDuration
//

void testTickDurationBounds()
{
    assert(TickDuration.zero == TickDuration(0));
    assert(TickDuration.max == TickDuration(long.max));
    assert(TickDuration.min == TickDuration(long.min));
    assert(TickDuration.min < TickDuration.zero);
    assert(TickDuration.zero < TickDuration.max);
    assert(TickDuration.min < TickDuration.max);
    assert(TickDuration.min - TickDuration(1) == TickDuration.max);
    assert(TickDuration.max + TickDuration(1) == TickDuration.min);
}

void testTickDurationSeconds()
{
    alias ticksPerSec = TickDuration.ticksPerSec;
    foreach (T; _TypeTuple!(TickDuration, const TickDuration, immutable TickDuration))
    {
        assert((cast(T)TickDuration(ticksPerSec)).seconds == 1);
        assert((cast(T)TickDuration(ticksPerSec - 1)).seconds == 0);
        assert((cast(T)TickDuration(ticksPerSec * 2)).seconds == 2);
        assert((cast(T)TickDuration(ticksPerSec * 2 - 1)).seconds == 1);
        assert((cast(T)TickDuration(-1)).seconds == 0);
        assert((cast(T)TickDuration(-ticksPerSec - 1)).seconds == -1);
        assert((cast(T)TickDuration(-ticksPerSec)).seconds == -1);
    }
}

void testTickDurationFrom()
{
    foreach (units; _TypeTuple!("seconds", "msecs", "usecs", "nsecs"))
    {
        foreach (T; _TypeTuple!(TickDuration, const TickDuration, immutable TickDuration))
        {
            assertApprox((cast(T)TickDuration.from!units(1000)).to!(units, long)(),
                         500, 1500, units);
            assertApprox((cast(T)TickDuration.from!units(1_000_000)).to!(units, long)(),
                         900_000, 1_100_000, units);
            assertApprox((cast(T)TickDuration.from!units(2_000_000)).to!(units, long)(),
                         1_900_000, 2_100_000, units);
        }
    }
}

void testTickDurationCastDuration()
{
    foreach (D; _TypeTuple!(Duration, const Duration, immutable Duration))
    {
        foreach (T; _TypeTuple!(TickDuration, const TickDuration, immutable TickDuration))
        {
            auto expected = dur!"seconds"(1);
            assert(cast(D)cast(T)TickDuration.from!"seconds"(1) == expected);

            foreach (units; _TypeTuple!("msecs", "usecs", "hnsecs"))
            {
                D actual = cast(D)cast(T)TickDuration.from!units(1_000_000);
                assertApprox(actual, dur!units(900_000), dur!units(1_100_000));
            }
        }
    }
}

void testTickDurationPlusMinusAssignTickDuration()
{
    foreach (T; _TypeTuple!(TickDuration, const TickDuration, immutable TickDuration))
    {
        auto a = TickDuration.currSystemTick;
        auto result = a += cast(T)TickDuration.currSystemTick;
        assert(a == result);
        assert(a.to!("seconds", real)() >= 0);

        auto b = TickDuration.currSystemTick;
        result = b -= cast(T)TickDuration.currSystemTick;
        assert(b == result);
        assert(b.to!("seconds", real)() <= 0);

        foreach (U; _TypeTuple!(const TickDuration, immutable TickDuration))
        {
            U u = TickDuration(12);
            static assert(!__traits(compiles, u += cast(T)TickDuration.currSystemTick));
            static assert(!__traits(compiles, u -= cast(T)TickDuration.currSystemTick));
        }
    }
}

void testDurationPlusMinusTickDuration()
{
    foreach (T; _TypeTuple!(TickDuration, const TickDuration, immutable TickDuration))
    {
        T a = TickDuration.currSystemTick;
        T b = TickDuration.currSystemTick;
        assert((a + b).seconds > 0);
        assert((a - b).seconds <= 0);
    }
}

void testNegateTickDuration()
{
    foreach (T; _TypeTuple!(TickDuration, const TickDuration, immutable TickDuration))
    {
        assert(-(cast(T)TickDuration(7)) == TickDuration(-7));
        assert(-(cast(T)TickDuration(5)) == TickDuration(-5));
        assert(-(cast(T)TickDuration(-7)) == TickDuration(7));
        assert(-(cast(T)TickDuration(-5)) == TickDuration(5));
        assert(-(cast(T)TickDuration(0)) == TickDuration(0));
    }
}

void testTickDurationOpCmp()
{
    foreach (T; _TypeTuple!(TickDuration, const TickDuration, immutable TickDuration))
    {
        foreach (U; _TypeTuple!(TickDuration, const TickDuration, immutable TickDuration))
        {
            T t = TickDuration.currSystemTick;
            U u = t;
            assert(t == u);
            assert(copy(t) == u);
            assert(t == copy(u));
        }
    }

    foreach (T; _TypeTuple!(TickDuration, const TickDuration, immutable TickDuration))
    {
        foreach (U; _TypeTuple!(TickDuration, const TickDuration, immutable TickDuration))
        {
            T t = TickDuration.currSystemTick;
            U u = t + t;
            assert(t < u);
            assert(t <= t);
            assert(u > t);
            assert(u >= u);

            assert(copy(t) < u);
            assert(copy(t) <= t);
            assert(copy(u) > t);
            assert(copy(u) >= u);

            assert(t < copy(u));
            assert(t <= copy(t));
            assert(u > copy(t));
            assert(u >= copy(u));
        }
    }
}

void testTickDurationTimesAssignIntFloat()
{
    immutable curr = TickDuration.currSystemTick;
    TickDuration t1 = curr;
    immutable t2 = curr + curr;
    t1 *= 2;
    assert(t1 == t2);

    t1 = curr;
    t1 *= 2.0;
    immutable tol = TickDuration(cast(long)(_abs(t1.length) * double.epsilon * 2.0));
    assertApprox(t1, t2 - tol, t2 + tol);

    t1 = curr;
    t1 *= 2.1;
    assert(t1 > t2);

    foreach (T; _TypeTuple!(const TickDuration, immutable TickDuration))
    {
        T t = TickDuration.currSystemTick;
        assert(!__traits(compiles, t *= 12));
        assert(!__traits(compiles, t *= 12.0));
    }
}

void testTickDurationDivideAssignIntFloat()
{
    immutable curr = TickDuration.currSystemTick;
    immutable t1 = curr;
    TickDuration t2 = curr + curr;
    t2 /= 2;
    assert(t1 == t2);

    t2 = curr + curr;
    t2 /= 2.0;
    immutable tol = TickDuration(cast(long)(_abs(t2.length) * double.epsilon / 2.0));
    assertApprox(t1, t2 - tol, t2 + tol);

    t2 = curr + curr;
    t2 /= 2.1;
    assert(t1 > t2);

    _assertThrown!TimeException(t2 /= 0);

    foreach (T; _TypeTuple!(const TickDuration, immutable TickDuration))
    {
        T t = TickDuration.currSystemTick;
        assert(!__traits(compiles, t /= 12));
        assert(!__traits(compiles, t /= 12.0));
    }
}

void testTickDurationTimesIntFloat()
{
    foreach (T; _TypeTuple!(TickDuration, const TickDuration, immutable TickDuration))
    {
        T t1 = TickDuration.currSystemTick;
        T t2 = t1 + t1;
        assert(t1 * 2 == t2);
        immutable tol = TickDuration(cast(long)(_abs(t1.length) * double.epsilon * 2.0));
        assertApprox(t1 * 2.0, t2 - tol, t2 + tol);
        assert(t1 * 2.1 > t2);
    }
}

void testTickDurationDivideIntFloat()
{
    foreach (T; _TypeTuple!(TickDuration, const TickDuration, immutable TickDuration))
    {
        T t1 = TickDuration.currSystemTick;
        T t2 = t1 + t1;
        assert(t2 / 2 == t1);
        immutable tol = TickDuration(cast(long)(_abs(t2.length) * double.epsilon / 2.0));
        assertApprox(t2 / 2.0, t1 - tol, t1 + tol);
        assert(t2 / 2.1 < t1);

        _assertThrown!TimeException(t2 / 0);
    }
}

void testTickDurationCtor()
{
    foreach (i; [-42, 0, 42])
        assert(TickDuration(i).length == i);
}

//
// free functions 3
//

void testConvert()
{
    foreach (units; _TypeTuple!("weeks", "days", "hours", "seconds", "msecs", "usecs", "hnsecs", "nsecs"))
    {
        static assert(!__traits(compiles, convert!("years", units)(12)), units);
        static assert(!__traits(compiles, convert!(units, "years")(12)), units);
    }

    foreach (units; _TypeTuple!("years", "months", "weeks", "days",
                               "hours", "seconds", "msecs", "usecs", "hnsecs", "nsecs"))
    {
        assert(convert!(units, units)(12) == 12);
    }

    assert(convert!("weeks", "hnsecs")(1) == 6_048_000_000_000L);
    assert(convert!("days", "hnsecs")(1) == 864_000_000_000L);
    assert(convert!("hours", "hnsecs")(1) == 36_000_000_000L);
    assert(convert!("minutes", "hnsecs")(1) == 600_000_000L);
    assert(convert!("seconds", "hnsecs")(1) == 10_000_000L);
    assert(convert!("msecs", "hnsecs")(1) == 10_000);
    assert(convert!("usecs", "hnsecs")(1) == 10);

    assert(convert!("hnsecs", "weeks")(6_048_000_000_000L) == 1);
    assert(convert!("hnsecs", "days")(864_000_000_000L) == 1);
    assert(convert!("hnsecs", "hours")(36_000_000_000L) == 1);
    assert(convert!("hnsecs", "minutes")(600_000_000L) == 1);
    assert(convert!("hnsecs", "seconds")(10_000_000L) == 1);
    assert(convert!("hnsecs", "msecs")(10_000) == 1);
    assert(convert!("hnsecs", "usecs")(10) == 1);

    assert(convert!("weeks", "days")(1) == 7);
    assert(convert!("days", "weeks")(7) == 1);

    assert(convert!("days", "hours")(1) == 24);
    assert(convert!("hours", "days")(24) == 1);

    assert(convert!("hours", "minutes")(1) == 60);
    assert(convert!("minutes", "hours")(60) == 1);

    assert(convert!("minutes", "seconds")(1) == 60);
    assert(convert!("seconds", "minutes")(60) == 1);

    assert(convert!("seconds", "msecs")(1) == 1000);
    assert(convert!("msecs", "seconds")(1000) == 1);

    assert(convert!("msecs", "usecs")(1) == 1000);
    assert(convert!("usecs", "msecs")(1000) == 1);

    assert(convert!("usecs", "hnsecs")(1) == 10);
    assert(convert!("hnsecs", "usecs")(10) == 1);

    assert(convert!("weeks", "nsecs")(1) == 604_800_000_000_000L);
    assert(convert!("days", "nsecs")(1) == 86_400_000_000_000L);
    assert(convert!("hours", "nsecs")(1) == 3_600_000_000_000L);
    assert(convert!("minutes", "nsecs")(1) == 60_000_000_000L);
    assert(convert!("seconds", "nsecs")(1) == 1_000_000_000L);
    assert(convert!("msecs", "nsecs")(1) == 1_000_000);
    assert(convert!("usecs", "nsecs")(1) == 1000);
    assert(convert!("hnsecs", "nsecs")(1) == 100);

    assert(convert!("nsecs", "weeks")(604_800_000_000_000L) == 1);
    assert(convert!("nsecs", "days")(86_400_000_000_000L) == 1);
    assert(convert!("nsecs", "hours")(3_600_000_000_000L) == 1);
    assert(convert!("nsecs", "minutes")(60_000_000_000L) == 1);
    assert(convert!("nsecs", "seconds")(1_000_000_000L) == 1);
    assert(convert!("nsecs", "msecs")(1_000_000) == 1);
    assert(convert!("nsecs", "usecs")(1000) == 1);
    assert(convert!("nsecs", "hnsecs")(100) == 1);
}

//
// TimeException
//

void testTimeException()
{
    {
        auto e = new TimeException("hello");
        assert(e.msg == "hello");
        assert(e.file == __FILE__);
        assert(e.line == __LINE__ - 3);
        assert(e.next is null);
    }

    {
        auto next = new Exception("foo");
        auto e = new TimeException("goodbye", next);
        assert(e.msg == "goodbye");
        assert(e.file == __FILE__);
        assert(e.line == __LINE__ - 3);
        assert(e.next is next);
    }
}

//
// free functions 4
//

void testAbs()
{
    assert(abs(dur!"msecs"(5)) == dur!"msecs"(5));
    assert(abs(dur!"msecs"(-5)) == dur!"msecs"(5));

    assert(abs(TickDuration(17)) == TickDuration(17));
    assert(abs(TickDuration(-17)) == TickDuration(17));
}

void testAllAreAcceptedUnits()
{
    assert(allAreAcceptedUnits!("hours", "seconds")("seconds", "hours"));
    assert(!allAreAcceptedUnits!("hours", "seconds")("minutes", "hours"));
    assert(!allAreAcceptedUnits!("hours", "seconds")("seconds", "minutes"));
    assert(allAreAcceptedUnits!("days", "hours", "minutes", "seconds", "msecs")("minutes"));
    assert(!allAreAcceptedUnits!("days", "hours", "minutes", "seconds", "msecs")("usecs"));
    assert(!allAreAcceptedUnits!("days", "hours", "minutes", "seconds", "msecs")("secs"));
}

void testUnitsAreInDescendingOrder()
{
    assert(unitsAreInDescendingOrder("years", "months", "weeks", "days", "hours", "minutes",
                                     "seconds", "msecs", "usecs", "hnsecs", "nsecs"));
    assert(unitsAreInDescendingOrder("weeks", "hours", "msecs"));
    assert(unitsAreInDescendingOrder("days", "hours", "minutes"));
    assert(unitsAreInDescendingOrder("hnsecs"));
    assert(!unitsAreInDescendingOrder("days", "hours", "hours"));
    assert(!unitsAreInDescendingOrder("days", "hours", "days"));
}

void testNextLargerTimeUnits()
{
    assert(nextLargerTimeUnits!"nsecs" == "hnsecs");
    assert(nextLargerTimeUnits!"hnsecs" == "usecs");
    assert(nextLargerTimeUnits!"usecs" == "msecs");
    assert(nextLargerTimeUnits!"msecs" == "seconds");
    assert(nextLargerTimeUnits!"seconds" == "minutes");
    assert(nextLargerTimeUnits!"minutes" == "hours");
    assert(nextLargerTimeUnits!"hours" == "days");
    assert(nextLargerTimeUnits!"days" == "weeks");

    static assert(!__traits(compiles, nextLargerTimeUnits!"weeks"));
    static assert(!__traits(compiles, nextLargerTimeUnits!"months"));
    static assert(!__traits(compiles, nextLargerTimeUnits!"years"));
}

//
// FracSec
//
/+ deprecated +/
pure @safe
{
    void testFracSecZero()
    {
        assert(FracSec.zero == FracSec.from!"msecs"(0));
    }

    void testFracSecFrom()
    {
        assert(FracSec.from!"msecs"(0) == FracSec(0));
        assert(FracSec.from!"usecs"(0) == FracSec(0));
        assert(FracSec.from!"hnsecs"(0) == FracSec(0));

        foreach (sign; [1, -1])
        {
            _assertThrown!TimeException(FracSec.from!"msecs"(1000 * sign));

            assert(FracSec.from!"msecs"(1 * sign) == FracSec(10_000 * sign));
            assert(FracSec.from!"msecs"(999 * sign) == FracSec(9_990_000 * sign));

            _assertThrown!TimeException(FracSec.from!"usecs"(1_000_000 * sign));

            assert(FracSec.from!"usecs"(1 * sign) == FracSec(10 * sign));
            assert(FracSec.from!"usecs"(999 * sign) == FracSec(9990 * sign));
            assert(FracSec.from!"usecs"(999_999 * sign) == FracSec(9999_990 * sign));

            _assertThrown!TimeException(FracSec.from!"hnsecs"(10_000_000 * sign));

            assert(FracSec.from!"hnsecs"(1 * sign) == FracSec(1 * sign));
            assert(FracSec.from!"hnsecs"(999 * sign) == FracSec(999 * sign));
            assert(FracSec.from!"hnsecs"(999_999 * sign) == FracSec(999_999 * sign));
            assert(FracSec.from!"hnsecs"(9_999_999 * sign) == FracSec(9_999_999 * sign));

            assert(FracSec.from!"nsecs"(1 * sign) == FracSec(0));
            assert(FracSec.from!"nsecs"(10 * sign) == FracSec(0));
            assert(FracSec.from!"nsecs"(99 * sign) == FracSec(0));
            assert(FracSec.from!"nsecs"(100 * sign) == FracSec(1 * sign));
            assert(FracSec.from!"nsecs"(99_999 * sign) == FracSec(999 * sign));
            assert(FracSec.from!"nsecs"(99_999_999 * sign) == FracSec(999_999 * sign));
            assert(FracSec.from!"nsecs"(999_999_999 * sign) == FracSec(9_999_999 * sign));
        }
    }

    void testNegateFracSec()
    {
        foreach (val; [-7, -5, 0, 5, 7])
        {
            foreach (F; _TypeTuple!(FracSec, const FracSec, immutable FracSec))
            {
                F fs = FracSec(val);
                assert(-fs == FracSec(-val));
            }
        }
    }

    void testFracSecMsecsGet()
    {
        foreach (F; _TypeTuple!(FracSec, const FracSec, immutable FracSec))
        {
            assert(FracSec(0).msecs == 0);

            foreach (sign; [1, -1])
            {
                assert((cast(F)FracSec(1 * sign)).msecs == 0);
                assert((cast(F)FracSec(999 * sign)).msecs == 0);
                assert((cast(F)FracSec(999_999 * sign)).msecs == 99 * sign);
                assert((cast(F)FracSec(9_999_999 * sign)).msecs == 999 * sign);
            }
        }
    }

    void testFracSecMsecsSet()
    {
        static void test(int msecs, FracSec expected = FracSec.init, size_t line = __LINE__)
        {
            FracSec fs;
            fs.msecs = msecs;

            if (fs != expected)
                throw new AssertError("unittest failure", __FILE__, line);
        }

        _assertThrown!TimeException(test(-1000));
        _assertThrown!TimeException(test(1000));

        test(0, FracSec(0));

        foreach (sign; [1, -1])
        {
            test(1 * sign, FracSec(10_000 * sign));
            test(999 * sign, FracSec(9_990_000 * sign));
        }

        foreach (F; _TypeTuple!(const FracSec, immutable FracSec))
        {
            F fs = FracSec(1234567);
            static assert(!__traits(compiles, fs.msecs = 12), F.stringof);
        }
    }

    void testFracSecUsecsGet()
    {
        foreach (F; _TypeTuple!(FracSec, const FracSec, immutable FracSec))
        {
            assert(FracSec(0).usecs == 0);

            foreach (sign; [1, -1])
            {
                assert((cast(F)FracSec(1 * sign)).usecs == 0);
                assert((cast(F)FracSec(999 * sign)).usecs == 99 * sign);
                assert((cast(F)FracSec(999_999 * sign)).usecs == 99_999 * sign);
                assert((cast(F)FracSec(9_999_999 * sign)).usecs == 999_999 * sign);
            }
        }
    }

    void testFracSecUsecsSet()
    {
        static void test(int usecs, FracSec expected = FracSec.init, size_t line = __LINE__)
        {
            FracSec fs;
            fs.usecs = usecs;

            if (fs != expected)
                throw new AssertError("unittest failure", __FILE__, line);
        }

        _assertThrown!TimeException(test(-1_000_000));
        _assertThrown!TimeException(test(1_000_000));

        test(0, FracSec(0));

        foreach (sign; [1, -1])
        {
            test(1 * sign, FracSec(10 * sign));
            test(999 * sign, FracSec(9990 * sign));
            test(999_999 * sign, FracSec(9_999_990 * sign));
        }

        foreach (F; _TypeTuple!(const FracSec, immutable FracSec))
        {
            F fs = FracSec(1234567);
            static assert(!__traits(compiles, fs.usecs = 12), F.stringof);
        }
    }

    void testFracSecHnsecsGet()
    {
        foreach (F; _TypeTuple!(FracSec, const FracSec, immutable FracSec))
        {
            assert(FracSec(0).hnsecs == 0);

            foreach (sign; [1, -1])
            {
                assert((cast(F)FracSec(1 * sign)).hnsecs == 1 * sign);
                assert((cast(F)FracSec(999 * sign)).hnsecs == 999 * sign);
                assert((cast(F)FracSec(999_999 * sign)).hnsecs == 999_999 * sign);
                assert((cast(F)FracSec(9_999_999 * sign)).hnsecs == 9_999_999 * sign);
            }
        }
    }

    void testFracSecHnsecsSet()
    {
        static void test(int hnsecs, FracSec expected = FracSec.init, size_t line = __LINE__)
        {
            FracSec fs;
            fs.hnsecs = hnsecs;

            if (fs != expected)
                throw new AssertError("unittest failure", __FILE__, line);
        }

        _assertThrown!TimeException(test(-10_000_000));
        _assertThrown!TimeException(test(10_000_000));

        test(0, FracSec(0));

        foreach (sign; [1, -1])
        {
            test(1 * sign, FracSec(1 * sign));
            test(999 * sign, FracSec(999 * sign));
            test(999_999 * sign, FracSec(999_999 * sign));
            test(9_999_999 * sign, FracSec(9_999_999 * sign));
        }

        foreach (F; _TypeTuple!(const FracSec, immutable FracSec))
        {
            F fs = FracSec(1234567);
            static assert(!__traits(compiles, fs.hnsecs = 12), F.stringof);
        }
    }

    void testFracSecNsecsGet()
    {
        foreach (F; _TypeTuple!(FracSec, const FracSec, immutable FracSec))
        {
            assert(FracSec(0).nsecs == 0);

            foreach (sign; [1, -1])
            {
                assert((cast(F)FracSec(1 * sign)).nsecs == 100 * sign);
                assert((cast(F)FracSec(999 * sign)).nsecs == 99_900 * sign);
                assert((cast(F)FracSec(999_999 * sign)).nsecs == 99_999_900 * sign);
                assert((cast(F)FracSec(9_999_999 * sign)).nsecs == 999_999_900 * sign);
            }
        }
    }

    void testFracSecNsecsSet()
    {
        static void test(int nsecs, FracSec expected = FracSec.init, size_t line = __LINE__)
        {
            FracSec fs;
            fs.nsecs = nsecs;

            if (fs != expected)
                throw new AssertError("unittest failure", __FILE__, line);
        }

        _assertThrown!TimeException(test(-1_000_000_000));
        _assertThrown!TimeException(test(1_000_000_000));

        test(0, FracSec(0));

        foreach (sign; [1, -1])
        {
            test(1 * sign, FracSec(0));
            test(10 * sign, FracSec(0));
            test(100 * sign, FracSec(1 * sign));
            test(999 * sign, FracSec(9 * sign));
            test(999_999 * sign, FracSec(9999 * sign));
            test(9_999_999 * sign, FracSec(99_999 * sign));
        }

        foreach (F; _TypeTuple!(const FracSec, immutable FracSec))
        {
            F fs = FracSec(1234567);
            static assert(!__traits(compiles, fs.nsecs = 12), F.stringof);
        }
    }

    void testFracSecToString1()
    {
        auto fs = FracSec(12);
        const cfs = FracSec(12);
        immutable ifs = FracSec(12);
        assert(fs.toString() == "12 hnsecs");
        assert(cfs.toString() == "12 hnsecs");
        assert(ifs.toString() == "12 hnsecs");
    }

    void testFracSecToString2()
    {
        foreach (sign; [1 , -1])
        {
            immutable signStr = sign == 1 ? "" : "-";

            assert(FracSec.from!"msecs"(0 * sign).toString() == "0 hnsecs");
            assert(FracSec.from!"msecs"(1 * sign).toString() == signStr ~ "1 ms");
            assert(FracSec.from!"msecs"(2 * sign).toString() == signStr ~ "2 ms");
            assert(FracSec.from!"msecs"(100 * sign).toString() == signStr ~ "100 ms");
            assert(FracSec.from!"msecs"(999 * sign).toString() == signStr ~ "999 ms");

            assert(FracSec.from!"usecs"(0* sign).toString() == "0 hnsecs");
            assert(FracSec.from!"usecs"(1* sign).toString() == signStr ~ "1 μs");
            assert(FracSec.from!"usecs"(2* sign).toString() == signStr ~ "2 μs");
            assert(FracSec.from!"usecs"(100* sign).toString() == signStr ~ "100 μs");
            assert(FracSec.from!"usecs"(999* sign).toString() == signStr ~ "999 μs");
            assert(FracSec.from!"usecs"(1000* sign).toString() == signStr ~ "1 ms");
            assert(FracSec.from!"usecs"(2000* sign).toString() == signStr ~ "2 ms");
            assert(FracSec.from!"usecs"(9999* sign).toString() == signStr ~ "9999 μs");
            assert(FracSec.from!"usecs"(10_000* sign).toString() == signStr ~ "10 ms");
            assert(FracSec.from!"usecs"(20_000* sign).toString() == signStr ~ "20 ms");
            assert(FracSec.from!"usecs"(100_000* sign).toString() == signStr ~ "100 ms");
            assert(FracSec.from!"usecs"(100_001* sign).toString() == signStr ~ "100001 μs");
            assert(FracSec.from!"usecs"(999_999* sign).toString() == signStr ~ "999999 μs");

            assert(FracSec.from!"hnsecs"(0* sign).toString() == "0 hnsecs");
            assert(FracSec.from!"hnsecs"(1* sign).toString() == (sign == 1 ? "1 hnsec" : "-1 hnsecs"));
            assert(FracSec.from!"hnsecs"(2* sign).toString() == signStr ~ "2 hnsecs");
            assert(FracSec.from!"hnsecs"(100* sign).toString() == signStr ~ "10 μs");
            assert(FracSec.from!"hnsecs"(999* sign).toString() == signStr ~ "999 hnsecs");
            assert(FracSec.from!"hnsecs"(1000* sign).toString() == signStr ~ "100 μs");
            assert(FracSec.from!"hnsecs"(2000* sign).toString() == signStr ~ "200 μs");
            assert(FracSec.from!"hnsecs"(9999* sign).toString() == signStr ~ "9999 hnsecs");
            assert(FracSec.from!"hnsecs"(10_000* sign).toString() == signStr ~ "1 ms");
            assert(FracSec.from!"hnsecs"(20_000* sign).toString() == signStr ~ "2 ms");
            assert(FracSec.from!"hnsecs"(100_000* sign).toString() == signStr ~ "10 ms");
            assert(FracSec.from!"hnsecs"(100_001* sign).toString() == signStr ~ "100001 hnsecs");
            assert(FracSec.from!"hnsecs"(200_000* sign).toString() == signStr ~ "20 ms");
            assert(FracSec.from!"hnsecs"(999_999* sign).toString() == signStr ~ "999999 hnsecs");
            assert(FracSec.from!"hnsecs"(1_000_001* sign).toString() == signStr ~ "1000001 hnsecs");
            assert(FracSec.from!"hnsecs"(9_999_999* sign).toString() == signStr ~ "9999999 hnsecs");
        }
    }
}
