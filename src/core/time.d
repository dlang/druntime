//Written in the D programming language

/++
    Module containing core time functionality, such as $(LREF Duration) (which
    represents a duration of time) or $(LREF MonoTime) (which represents a
    timestamp of the system's monotonic clock).

    Various functions take a string (or strings) to represent a unit of time
    (e.g. $(D convert!("days", "hours")(numDays))). The valid strings to use
    with such functions are "years", "months", "weeks", "days", "hours",
    "minutes", "seconds", "msecs" (milliseconds), "usecs" (microseconds),
    "hnsecs" (hecto-nanoseconds - i.e. 100 ns) or some subset thereof. There
    are a few functions that also allow "nsecs", but very little actually
    has precision greater than hnsecs.

    $(BOOKTABLE Cheat Sheet,
    $(TR $(TH Symbol) $(TH Description))
    $(LEADINGROW Types)
    $(TR $(TDNW $(LREF Duration)) $(TD Represents a duration of time of weeks
    or less (kept internally as hnsecs). (e.g. 22 days or 700 seconds).))
    $(TR $(TDNW $(LREF TickDuration)) $(TD Represents a duration of time in
    system clock ticks, using the highest precision that the system provides.))
    $(TR $(TDNW $(LREF MonoTime)) $(TD Represents a monotonic timestamp in
    system clock ticks, using the highest precision that the system provides.))
    $(TR $(TDNW $(LREF FracSec)) $(TD Represents fractional seconds
    (portions of time smaller than a second).))
    $(LEADINGROW Functions)
    $(TR $(TDNW $(LREF convert)) $(TD Generic way of converting between two time
    units.))
    $(TR $(TDNW $(LREF dur)) $(TD Allows constructing a $(LREF Duration) from
    the given time units with the given length.))
    $(TR $(TDNW $(LREF weeks)$(NBSP)$(LREF days)$(NBSP)$(LREF hours)$(BR)
    $(LREF minutes)$(NBSP)$(LREF seconds)$(NBSP)$(LREF msecs)$(BR)
    $(LREF usecs)$(NBSP)$(LREF hnsecs)$(NBSP)$(LREF nsecs))
    $(TD Convenience aliases for $(LREF dur).))
    $(TR $(TDNW $(LREF abs)) $(TD Returns the absolute value of a duration.))
    )

    $(BOOKTABLE Conversions,
    $(TR $(TH )
     $(TH From $(LREF Duration))
     $(TH From $(LREF TickDuration))
     $(TH From $(LREF FracSec))
     $(TH From units)
    )
    $(TR $(TD $(B To $(LREF Duration)))
     $(TD -)
     $(TD $(D tickDuration.)$(REF_SHORT to, std,conv)$(D !Duration()))
     $(TD -)
     $(TD $(D dur!"msecs"(5)) or $(D 5.msecs()))
    )
    $(TR $(TD $(B To $(LREF TickDuration)))
     $(TD $(D duration.)$(REF_SHORT to, std,conv)$(D !TickDuration()))
     $(TD -)
     $(TD -)
     $(TD $(D TickDuration.from!"msecs"(msecs)))
    )
    $(TR $(TD $(B To $(LREF FracSec)))
     $(TD $(D duration.fracSec))
     $(TD -)
     $(TD -)
     $(TD $(D FracSec.from!"msecs"(msecs)))
    )
    $(TR $(TD $(B To units))
     $(TD $(D duration.total!"days"))
     $(TD $(D tickDuration.msecs))
     $(TD $(D fracSec.msecs))
     $(TD $(D convert!("days", "msecs")(msecs)))
    ))

    Copyright: Copyright 2010 - 2012
    License:   $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
    Authors:   $(HTTP jmdavisprog.com, Jonathan M Davis) and Kato Shoichi
    Source:    $(DRUNTIMESRC core/_time.d)
    Macros:
    NBSP=&nbsp;
 +/
module core.time;

import core.exception;
import core.stdc.time;
import core.stdc.stdio;
import core.internal.traits : _Unqual = Unqual;
import core.internal.string;

version (Windows)
{
import core.sys.windows.windows;
}
else version (Posix)
{
import core.sys.posix.time;
import core.sys.posix.sys.time;
}

version (OSX)
    version = Darwin;
else version (iOS)
    version = Darwin;
else version (TVOS)
    version = Darwin;
else version (WatchOS)
    version = Darwin;

//This probably should be moved somewhere else in druntime which
//is Darwin-specific.
version (Darwin)
{

public import core.sys.darwin.mach.kern_return;

extern(C) nothrow @nogc
{

struct mach_timebase_info_data_t
{
    uint numer;
    uint denom;
}

alias mach_timebase_info_data_t* mach_timebase_info_t;

kern_return_t mach_timebase_info(mach_timebase_info_t);

ulong mach_absolute_time();

}

}

/++
    What type of clock to use with $(LREF MonoTime) / $(LREF MonoTimeImpl) or
    $(D std.datetime.Clock.currTime). They default to $(D ClockType.normal),
    and most programs do not need to ever deal with the others.

    The other $(D ClockType)s are provided so that other clocks provided by the
    underlying C, system calls can be used with $(LREF MonoTimeImpl) or
    $(D std.datetime.Clock.currTime) without having to use the C API directly.

    In the case of the monotonic time, $(LREF MonoTimeImpl) is templatized on
    $(D ClockType), whereas with $(D std.datetime.Clock.currTime), its a runtime
    argument, since in the case of the monotonic time, the type of the clock
    affects the resolution of a $(LREF MonoTimeImpl) object, whereas with
    $(REF SysTime, std,datetime), its resolution is always hecto-nanoseconds
    regardless of the source of the time.

    $(D ClockType.normal), $(D ClockType.coarse), and $(D ClockType.precise)
    work with both $(D Clock.currTime) and $(LREF MonoTimeImpl).
    $(D ClockType.second) only works with $(D Clock.currTime). The others only
    work with $(LREF MonoTimeImpl).
  +/
version (CoreDdoc) enum ClockType
{
    /++
        Use the normal clock.
      +/
    normal = 0,

    /++
        $(BLUE Linux-Only)

        Uses $(D CLOCK_BOOTTIME).
      +/
    bootTime = 1,

    /++
        Use the coarse clock, not the normal one (e.g. on Linux, that would be
        $(D CLOCK_REALTIME_COARSE) instead of $(D CLOCK_REALTIME) for
        $(D clock_gettime) if a function is using the realtime clock). It's
        generally faster to get the time with the coarse clock than the normal
        clock, but it's less precise (e.g. 1 msec instead of 1 usec or 1 nsec).
        Howeover, it $(I is) guaranteed to still have sub-second precision
        (just not as high as with $(D ClockType.normal)).

        On systems which do not support a coarser clock,
        $(D MonoTimeImpl!(ClockType.coarse)) will internally use the same clock
        as $(D Monotime) does, and $(D Clock.currTime!(ClockType.coarse)) will
        use the same clock as $(D Clock.currTime). This is because the coarse
        clock is doing the same thing as the normal clock (just at lower
        precision), whereas some of the other clock types
        (e.g. $(D ClockType.processCPUTime)) mean something fundamentally
        different. So, treating those as $(D ClockType.normal) on systems where
        they weren't natively supported would give misleading results.

        Most programs should not use the coarse clock, exactly because it's
        less precise, and most programs don't need to get the time often
        enough to care, but for those rare programs that need to get the time
        extremely frequently (e.g. hundreds of thousands of times a second) but
        don't care about high precision, the coarse clock might be appropriate.

        Currently, only Linux and FreeBSD/DragonFlyBSD support a coarser clock, and on other
        platforms, it's treated as $(D ClockType.normal).
      +/
    coarse = 2,

    /++
        Uses a more precise clock than the normal one (which is already very
        precise), but it takes longer to get the time. Similarly to
        $(D ClockType.coarse), if it's used on a system that does not support a
        more precise clock than the normal one, it's treated as equivalent to
        $(D ClockType.normal).

        Currently, only FreeBSD/DragonFlyBSD supports a more precise clock, where it uses
        $(D CLOCK_MONOTONIC_PRECISE) for the monotonic time and
        $(D CLOCK_REALTIME_PRECISE) for the wall clock time.
      +/
    precise = 3,

    /++
        $(BLUE Linux,Solaris-Only)

        Uses $(D CLOCK_PROCESS_CPUTIME_ID).
      +/
    processCPUTime = 4,

    /++
        $(BLUE Linux-Only)

        Uses $(D CLOCK_MONOTONIC_RAW).
      +/
    raw = 5,

    /++
        Uses a clock that has a precision of one second (contrast to the coarse
        clock, which has sub-second precision like the normal clock does).

        FreeBSD/DragonFlyBSD are the only systems which specifically have a clock set up for
        this (it has $(D CLOCK_SECOND) to use with $(D clock_gettime) which
        takes advantage of an in-kernel cached value), but on other systems, the
        fastest function available will be used, and the resulting $(D SysTime)
        will be rounded down to the second if the clock that was used gave the
        time at a more precise resolution. So, it's guaranteed that the time
        will be given at a precision of one second and it's likely the case that
        will be faster than $(D ClockType.normal), since there tend to be
        several options on a system to get the time at low resolutions, and they
        tend to be faster than getting the time at high resolutions.

        So, the primary difference between $(D ClockType.coarse) and
        $(D ClockType.second) is that $(D ClockType.coarse) sacrifices some
        precision in order to get speed but is still fairly precise, whereas
        $(D ClockType.second) tries to be as fast as possible at the expense of
        all sub-second precision.
      +/
    second = 6,

    /++
        $(BLUE Linux,Solaris-Only)

        Uses $(D CLOCK_THREAD_CPUTIME_ID).
      +/
    threadCPUTime = 7,

    /++
        $(BLUE FreeBSD-Only)

        Uses $(D CLOCK_UPTIME).
      +/
    uptime = 8,

    /++
        $(BLUE FreeBSD-Only)

        Uses $(D CLOCK_UPTIME_FAST).
      +/
    uptimeCoarse = 9,

    /++
        $(BLUE FreeBSD-Only)

        Uses $(D CLOCK_UPTIME_PRECISE).
      +/
    uptimePrecise = 10,
}
else version (Windows) enum ClockType
{
    normal = 0,
    coarse = 2,
    precise = 3,
    second = 6,
}
else version (Darwin) enum ClockType
{
    normal = 0,
    coarse = 2,
    precise = 3,
    second = 6,
}
else version (linux) enum ClockType
{
    normal = 0,
    bootTime = 1,
    coarse = 2,
    precise = 3,
    processCPUTime = 4,
    raw = 5,
    second = 6,
    threadCPUTime = 7,
}
else version (FreeBSD) enum ClockType
{
    normal = 0,
    coarse = 2,
    precise = 3,
    second = 6,
    uptime = 8,
    uptimeCoarse = 9,
    uptimePrecise = 10,
}
else version (NetBSD) enum ClockType
{
    normal = 0,
    coarse = 2,
    precise = 3,
    second = 6,
}
else version (DragonFlyBSD) enum ClockType
{
    normal = 0,
    coarse = 2,
    precise = 3,
    second = 6,
    uptime = 8,
    uptimeCoarse = 9,
    uptimePrecise = 10,
}
else version (Solaris) enum ClockType
{
    normal = 0,
    coarse = 2,
    precise = 3,
    processCPUTime = 4,
    second = 6,
    threadCPUTime = 7,
}
else
{
    // It needs to be decided (and implemented in an appropriate version branch
    // here) which clock types new platforms are going to support. At minimum,
    // the ones _not_ marked with $(D Blue Foo-Only) should be supported.
    static assert(0, "What are the clock types supported by this system?");
}

// private, used to translate clock type to proper argument to clock_xxx
// functions on posix systems
version (CoreDdoc)
    private int _posixClock(ClockType clockType) { return 0; }
else
version (Posix)
{
    private auto _posixClock(ClockType clockType)
    {
        version (linux)
        {
            import core.sys.linux.time;
            with(ClockType) final switch (clockType)
            {
            case bootTime: return CLOCK_BOOTTIME;
            case coarse: return CLOCK_MONOTONIC_COARSE;
            case normal: return CLOCK_MONOTONIC;
            case precise: return CLOCK_MONOTONIC;
            case processCPUTime: return CLOCK_PROCESS_CPUTIME_ID;
            case raw: return CLOCK_MONOTONIC_RAW;
            case threadCPUTime: return CLOCK_THREAD_CPUTIME_ID;
            case second: assert(0);
            }
        }
        else version (FreeBSD)
        {
            import core.sys.freebsd.time;
            with(ClockType) final switch (clockType)
            {
            case coarse: return CLOCK_MONOTONIC_FAST;
            case normal: return CLOCK_MONOTONIC;
            case precise: return CLOCK_MONOTONIC_PRECISE;
            case uptime: return CLOCK_UPTIME;
            case uptimeCoarse: return CLOCK_UPTIME_FAST;
            case uptimePrecise: return CLOCK_UPTIME_PRECISE;
            case second: assert(0);
            }
        }
        else version (NetBSD)
        {
            import core.sys.netbsd.time;
            with(ClockType) final switch (clockType)
            {
            case coarse: return CLOCK_MONOTONIC;
            case normal: return CLOCK_MONOTONIC;
            case precise: return CLOCK_MONOTONIC;
            case second: assert(0);
            }
        }
        else version (DragonFlyBSD)
        {
            import core.sys.dragonflybsd.time;
            with(ClockType) final switch (clockType)
            {
            case coarse: return CLOCK_MONOTONIC_FAST;
            case normal: return CLOCK_MONOTONIC;
            case precise: return CLOCK_MONOTONIC_PRECISE;
            case uptime: return CLOCK_UPTIME;
            case uptimeCoarse: return CLOCK_UPTIME_FAST;
            case uptimePrecise: return CLOCK_UPTIME_PRECISE;
            case second: assert(0);
            }
        }
        else version (Solaris)
        {
            import core.sys.solaris.time;
            with(ClockType) final switch (clockType)
            {
            case coarse: return CLOCK_MONOTONIC;
            case normal: return CLOCK_MONOTONIC;
            case precise: return CLOCK_MONOTONIC;
            case processCPUTime: return CLOCK_PROCESS_CPUTIME_ID;
            case threadCPUTime: return CLOCK_THREAD_CPUTIME_ID;
            case second: assert(0);
            }
        }
        else
            // It needs to be decided (and implemented in an appropriate
            // version branch here) which clock types new platforms are going
            // to support. Also, ClockType's documentation should be updated to
            // mention it if a new platform uses anything that's not supported
            // on all platforms..
            assert(0, "What are the monotonic clock types supported by this system?");
    }
}

/++
    Represents a duration of time of weeks or less (kept internally as hnsecs).
    (e.g. 22 days or 700 seconds).

    It is used when representing a duration of time - such as how long to
    sleep with $(REF Thread.sleep, core,thread).

    In std.datetime, it is also used as the result of various arithmetic
    operations on time points.

    Use the $(LREF dur) function or one of its non-generic aliases to create
    $(D Duration)s.

    It's not possible to create a Duration of months or years, because the
    variable number of days in a month or year makes it impossible to convert
    between months or years and smaller units without a specific date. So,
    nothing uses $(D Duration)s when dealing with months or years. Rather,
    functions specific to months and years are defined. For instance,
    $(REF Date, std,datetime) has $(D add!"years") and $(D add!"months") for adding
    years and months rather than creating a Duration of years or months and
    adding that to a $(REF Date, std,datetime). But Duration is used when dealing
    with weeks or smaller.

    Examples:
--------------------
import std.datetime;

assert(dur!"days"(12) == dur!"hnsecs"(10_368_000_000_000L));
assert(dur!"hnsecs"(27) == dur!"hnsecs"(27));
assert(std.datetime.Date(2010, 9, 7) + dur!"days"(5) ==
       std.datetime.Date(2010, 9, 12));

assert(days(-12) == dur!"hnsecs"(-10_368_000_000_000L));
assert(hnsecs(-27) == dur!"hnsecs"(-27));
assert(std.datetime.Date(2010, 9, 7) - std.datetime.Date(2010, 10, 3) ==
       days(-26));
--------------------
 +/
struct Duration
{
@safe pure:

public:

    /++
        A $(D Duration) of $(D 0). It's shorter than doing something like
        $(D dur!"seconds"(0)) and more explicit than $(D Duration.init).
      +/
    static @property nothrow @nogc Duration zero() { return Duration(0); }

    /++
        Largest $(D Duration) possible.
      +/
    static @property nothrow @nogc Duration max() { return Duration(long.max); }

    /++
        Most negative $(D Duration) possible.
      +/
    static @property nothrow @nogc Duration min() { return Duration(long.min); }

    /++
        Compares this $(D Duration) with the given $(D Duration).

        Returns:
            $(TABLE
            $(TR $(TD this &lt; rhs) $(TD &lt; 0))
            $(TR $(TD this == rhs) $(TD 0))
            $(TR $(TD this &gt; rhs) $(TD &gt; 0))
            )
     +/
    int opCmp(Duration rhs) const nothrow @nogc
    {
        if (_hnsecs < rhs._hnsecs)
            return -1;
        if (_hnsecs > rhs._hnsecs)
            return 1;
        return 0;
    }

    /++
        Adds, subtracts or calculates the modulo of two durations.

        The legal types of arithmetic for $(D Duration) using this operator are

        $(TABLE
        $(TR $(TD Duration) $(TD +) $(TD Duration) $(TD -->) $(TD Duration))
        $(TR $(TD Duration) $(TD -) $(TD Duration) $(TD -->) $(TD Duration))
        $(TR $(TD Duration) $(TD %) $(TD Duration) $(TD -->) $(TD Duration))
        $(TR $(TD Duration) $(TD +) $(TD TickDuration) $(TD -->) $(TD Duration))
        $(TR $(TD Duration) $(TD -) $(TD TickDuration) $(TD -->) $(TD Duration))
        )

        Params:
            rhs = The duration to add to or subtract from this $(D Duration).
      +/
    Duration opBinary(string op, D)(D rhs) const nothrow @nogc
        if (((op == "+" || op == "-" || op == "%") && is(_Unqual!D == Duration)) ||
           ((op == "+" || op == "-") && is(_Unqual!D == TickDuration)))
    {
        static if (is(_Unqual!D == Duration))
            return Duration(mixin("_hnsecs " ~ op ~ " rhs._hnsecs"));
        else if (is(_Unqual!D == TickDuration))
            return Duration(mixin("_hnsecs " ~ op ~ " rhs.hnsecs"));
    }

    /++
        Adds or subtracts two durations.

        The legal types of arithmetic for $(D Duration) using this operator are

        $(TABLE
        $(TR $(TD TickDuration) $(TD +) $(TD Duration) $(TD -->) $(TD Duration))
        $(TR $(TD TickDuration) $(TD -) $(TD Duration) $(TD -->) $(TD Duration))
        )

        Params:
            lhs = The $(D TickDuration) to add to this $(D Duration) or to
                  subtract this $(D Duration) from.
      +/
    Duration opBinaryRight(string op, D)(D lhs) const nothrow @nogc
        if ((op == "+" || op == "-") &&
            is(_Unqual!D == TickDuration))
    {
        return Duration(mixin("lhs.hnsecs " ~ op ~ " _hnsecs"));
    }

    /++
        Adds, subtracts or calculates the modulo of two durations as well as
        assigning the result to this $(D Duration).

        The legal types of arithmetic for $(D Duration) using this operator are

        $(TABLE
        $(TR $(TD Duration) $(TD +) $(TD Duration) $(TD -->) $(TD Duration))
        $(TR $(TD Duration) $(TD -) $(TD Duration) $(TD -->) $(TD Duration))
        $(TR $(TD Duration) $(TD %) $(TD Duration) $(TD -->) $(TD Duration))
        $(TR $(TD Duration) $(TD +) $(TD TickDuration) $(TD -->) $(TD Duration))
        $(TR $(TD Duration) $(TD -) $(TD TickDuration) $(TD -->) $(TD Duration))
        )

        Params:
            rhs = The duration to add to or subtract from this $(D Duration).
      +/
    ref Duration opOpAssign(string op, D)(in D rhs) nothrow @nogc
        if (((op == "+" || op == "-" || op == "%") && is(_Unqual!D == Duration)) ||
           ((op == "+" || op == "-") && is(_Unqual!D == TickDuration)))
    {
        static if (is(_Unqual!D == Duration))
            mixin("_hnsecs " ~ op ~ "= rhs._hnsecs;");
        else if (is(_Unqual!D == TickDuration))
            mixin("_hnsecs " ~ op ~ "= rhs.hnsecs;");
        return this;
    }

    /++
        Multiplies or divides the duration by an integer value.

        The legal types of arithmetic for $(D Duration) using this operator
        overload are

        $(TABLE
        $(TR $(TD Duration) $(TD *) $(TD long) $(TD -->) $(TD Duration))
        $(TR $(TD Duration) $(TD /) $(TD long) $(TD -->) $(TD Duration))
        )

        Params:
            value = The value to multiply this $(D Duration) by.
      +/
    Duration opBinary(string op)(long value) const nothrow @nogc
        if (op == "*" || op == "/")
    {
        mixin("return Duration(_hnsecs " ~ op ~ " value);");
    }

    /++
        Multiplies/Divides the duration by an integer value as well as
        assigning the result to this $(D Duration).

        The legal types of arithmetic for $(D Duration) using this operator
        overload are

        $(TABLE
        $(TR $(TD Duration) $(TD *) $(TD long) $(TD -->) $(TD Duration))
        $(TR $(TD Duration) $(TD /) $(TD long) $(TD -->) $(TD Duration))
        )

        Params:
            value = The value to multiply/divide this $(D Duration) by.
      +/
    ref Duration opOpAssign(string op)(long value) nothrow @nogc
        if (op == "*" || op == "/")
    {
        mixin("_hnsecs " ~ op ~ "= value;");
        return this;
    }

    /++
        Divides two durations.

        The legal types of arithmetic for $(D Duration) using this operator are

        $(TABLE
        $(TR $(TD Duration) $(TD /) $(TD Duration) $(TD -->) $(TD long))
        )

        Params:
            rhs = The duration to divide this $(D Duration) by.
      +/
    long opBinary(string op)(Duration rhs) const nothrow @nogc
        if (op == "/")
    {
        return _hnsecs / rhs._hnsecs;
    }

    /++
        Multiplies an integral value and a $(D Duration).

        The legal types of arithmetic for $(D Duration) using this operator
        overload are

        $(TABLE
        $(TR $(TD long) $(TD *) $(TD Duration) $(TD -->) $(TD Duration))
        )

        Params:
            value = The number of units to multiply this $(D Duration) by.
      +/
    Duration opBinaryRight(string op)(long value) const nothrow @nogc
        if (op == "*")
    {
        return opBinary!op(value);
    }

    /++
        Returns the negation of this $(D Duration).
      +/
    Duration opUnary(string op)() const nothrow @nogc
        if (op == "-")
    {
        return Duration(-_hnsecs);
    }

    /++
        Returns a $(LREF TickDuration) with the same number of hnsecs as this
        $(D Duration).
        Note that the conventional way to convert between $(D Duration) and
        $(D TickDuration) is using $(REF to, std,conv), e.g.:
        $(D duration.to!TickDuration())
      +/
    TickDuration opCast(T)() const nothrow @nogc
        if (is(_Unqual!T == TickDuration))
    {
        return TickDuration.from!"hnsecs"(_hnsecs);
    }

    /++
        Allow Duration to be used as a boolean.
        Returns: `true` if this duration is non-zero.
      +/
    bool opCast(T : bool)() const nothrow @nogc
    {
        return _hnsecs != 0;
    }

    //Temporary hack until bug http://d.puremagic.com/issues/show_bug.cgi?id=5747 is fixed.
    Duration opCast(T)() const nothrow @nogc
        if (is(_Unqual!T == Duration))
    {
        return this;
    }


    /++
        Splits out the Duration into the given units.

        split takes the list of time units to split out as template arguments.
        The time unit strings must be given in decreasing order. How it returns
        the values for those units depends on the overload used.

        The overload which accepts function arguments takes integral types in
        the order that the time unit strings were given, and those integers are
        passed by $(D ref). split assigns the values for the units to each
        corresponding integer. Any integral type may be used, but no attempt is
        made to prevent integer overflow, so don't use small integral types in
        circumstances where the values for those units aren't likely to fit in
        an integral type that small.

        The overload with no arguments returns the values for the units in a
        struct with members whose names are the same as the given time unit
        strings. The members are all $(D long)s. This overload will also work
        with no time strings being given, in which case $(I all) of the time
        units from weeks through hnsecs will be provided (but no nsecs, since it
        would always be $(D 0)).

        For both overloads, the entire value of the Duration is split among the
        units (rather than splitting the Duration across all units and then only
        providing the values for the requested units), so if only one unit is
        given, the result is equivalent to $(LREF total).

        $(D "nsecs") is accepted by split, but $(D "years") and $(D "months")
        are not.

        For negative durations, all of the split values will be negative.
      +/
    template split(units...)
        if (allAreAcceptedUnits!("weeks", "days", "hours", "minutes", "seconds",
                                "msecs", "usecs", "hnsecs", "nsecs")(units) &&
           unitsAreInDescendingOrder(units))
    {
        /++ Ditto +/
        void split(Args...)(out Args args) const nothrow @nogc
            if (units.length != 0 && args.length == units.length && allAreMutableIntegralTypes!Args)
        {
            long hnsecs = _hnsecs;
            foreach (i, unit; units)
            {
                static if (unit == "nsecs")
                    args[i] = cast(Args[i])convert!("hnsecs", "nsecs")(hnsecs);
                else
                    args[i] = cast(Args[i])splitUnitsFromHNSecs!unit(hnsecs);
            }
        }

        /++ Ditto +/
        auto split() const nothrow @nogc
        {
            static if (units.length == 0)
                return split!("weeks", "days", "hours", "minutes", "seconds", "msecs", "usecs", "hnsecs")();
            else
            {
                static string genMemberDecls()
                {
                    string retval;
                    foreach (unit; units)
                    {
                        retval ~= "long ";
                        retval ~= unit;
                        retval ~= "; ";
                    }
                    return retval;
                }

                static struct SplitUnits
                {
                    mixin(genMemberDecls());
                }

                static string genSplitCall()
                {
                    auto retval = "split(";
                    foreach (i, unit; units)
                    {
                        retval ~= "su.";
                        retval ~= unit;
                        if (i < units.length - 1)
                            retval ~= ", ";
                        else
                            retval ~= ");";
                    }
                    return retval;
                }

                SplitUnits su = void;
                mixin(genSplitCall());
                return su;
            }
        }

        /+
            Whether all of the given arguments are integral types.
          +/
        private template allAreMutableIntegralTypes(Args...)
        {
            static if (Args.length == 0)
                enum allAreMutableIntegralTypes = true;
            else static if (!is(Args[0] == long) &&
                           !is(Args[0] == int) &&
                           !is(Args[0] == short) &&
                           !is(Args[0] == byte) &&
                           !is(Args[0] == ulong) &&
                           !is(Args[0] == uint) &&
                           !is(Args[0] == ushort) &&
                           !is(Args[0] == ubyte))
            {
                enum allAreMutableIntegralTypes = false;
            }
            else
                enum allAreMutableIntegralTypes = allAreMutableIntegralTypes!(Args[1 .. $]);
        }

        unittest
        {
            foreach (T; _TypeTuple!(long, int, short, byte, ulong, uint, ushort, ubyte))
                static assert(allAreMutableIntegralTypes!T);
            foreach (T; _TypeTuple!(long, int, short, byte, ulong, uint, ushort, ubyte))
                static assert(!allAreMutableIntegralTypes!(const T));
            foreach (T; _TypeTuple!(char, wchar, dchar, float, double, real, string))
                static assert(!allAreMutableIntegralTypes!T);
            static assert(allAreMutableIntegralTypes!(long, int, short, byte));
            static assert(!allAreMutableIntegralTypes!(long, int, short, char, byte));
            static assert(!allAreMutableIntegralTypes!(long, int*, short));
        }
    }

    ///
    unittest
    {
        {
            auto d = dur!"days"(12) + dur!"minutes"(7) + dur!"usecs"(501223);
            long days;
            int seconds;
            short msecs;
            d.split!("days", "seconds", "msecs")(days, seconds, msecs);
            assert(days == 12);
            assert(seconds == 7 * 60);
            assert(msecs == 501);

            auto splitStruct = d.split!("days", "seconds", "msecs")();
            assert(splitStruct.days == 12);
            assert(splitStruct.seconds == 7 * 60);
            assert(splitStruct.msecs == 501);

            auto fullSplitStruct = d.split();
            assert(fullSplitStruct.weeks == 1);
            assert(fullSplitStruct.days == 5);
            assert(fullSplitStruct.hours == 0);
            assert(fullSplitStruct.minutes == 7);
            assert(fullSplitStruct.seconds == 0);
            assert(fullSplitStruct.msecs == 501);
            assert(fullSplitStruct.usecs == 223);
            assert(fullSplitStruct.hnsecs == 0);

            assert(d.split!"minutes"().minutes == d.total!"minutes");
        }

        {
            auto d = dur!"days"(12);
            assert(d.split!"weeks"().weeks == 1);
            assert(d.split!"days"().days == 12);

            assert(d.split().weeks == 1);
            assert(d.split().days == 5);
        }

        {
            auto d = dur!"days"(7) + dur!"hnsecs"(42);
            assert(d.split!("seconds", "nsecs")().nsecs == 4200);
        }

        {
            auto d = dur!"days"(-7) + dur!"hours"(-9);
            auto result = d.split!("days", "hours")();
            assert(result.days == -7);
            assert(result.hours == -9);
        }
    }

    /++
        Returns the total number of the given units in this $(D Duration).
        So, unlike $(D split), it does not strip out the larger units.
      +/
    @property long total(string units)() const nothrow @nogc
        if (units == "weeks" ||
           units == "days" ||
           units == "hours" ||
           units == "minutes" ||
           units == "seconds" ||
           units == "msecs" ||
           units == "usecs" ||
           units == "hnsecs" ||
           units == "nsecs")
    {
        static if (units == "nsecs")
            return convert!("hnsecs", "nsecs")(_hnsecs);
        else
            return getUnitsFromHNSecs!units(_hnsecs);
    }

    ///
    unittest
    {
        assert(dur!"weeks"(12).total!"weeks" == 12);
        assert(dur!"weeks"(12).total!"days" == 84);

        assert(dur!"days"(13).total!"weeks" == 1);
        assert(dur!"days"(13).total!"days" == 13);

        assert(dur!"hours"(49).total!"days" == 2);
        assert(dur!"hours"(49).total!"hours" == 49);

        assert(dur!"nsecs"(2007).total!"hnsecs" == 20);
        assert(dur!"nsecs"(2007).total!"nsecs" == 2000);
    }

    /++
        Converts this `Duration` to a `string`.

        The string is meant to be human readable, not machine parseable (e.g.
        whether there is an `'s'` on the end of the unit name usually depends on
        whether it's plural or not, and empty units are not included unless the
        Duration is `zero`). Any code needing a specific string format should
        use `total` or `split` to get the units needed to create the desired
        string format and create the string itself.

        The format returned by toString may or may not change in the future.
      +/
    string toString() const nothrow pure @safe
    {
        static void appListSep(ref string res, uint pos, bool last)
        {
            if (pos == 0)
                return;
            if (!last)
                res ~= ", ";
            else
                res ~= pos == 1 ? " and " : ", and ";
        }

        static void appUnitVal(string units)(ref string res, long val)
        {
            immutable plural = val != 1;
            string unit;
            static if (units == "seconds")
                unit = plural ? "secs" : "sec";
            else static if (units == "msecs")
                unit = "ms";
            else static if (units == "usecs")
                unit = "μs";
            else
                unit = plural ? units : units[0 .. $-1];
            res ~= signedToTempString(val, 10);
            res ~= " ";
            res ~= unit;
        }

        if (_hnsecs == 0)
            return "0 hnsecs";

        template TT(T...) { alias T TT; }
        alias units = TT!("weeks", "days", "hours", "minutes", "seconds", "msecs", "usecs");

        long hnsecs = _hnsecs; string res; uint pos;
        foreach (unit; units)
        {
            if (auto val = splitUnitsFromHNSecs!unit(hnsecs))
            {
                appListSep(res, pos++, hnsecs == 0);
                appUnitVal!unit(res, val);
            }
            if (hnsecs == 0)
                break;
        }
        if (hnsecs != 0)
        {
            appListSep(res, pos++, true);
            appUnitVal!"hnsecs"(res, hnsecs);
        }
        return res;
    }

    ///
    unittest
    {
        assert(Duration.zero.toString() == "0 hnsecs");
        assert(weeks(5).toString() == "5 weeks");
        assert(days(2).toString() == "2 days");
        assert(hours(1).toString() == "1 hour");
        assert(minutes(19).toString() == "19 minutes");
        assert(seconds(42).toString() == "42 secs");
        assert(msecs(42).toString() == "42 ms");
        assert(usecs(27).toString() == "27 μs");
        assert(hnsecs(5).toString() == "5 hnsecs");

        assert(seconds(121).toString() == "2 minutes and 1 sec");
        assert((minutes(5) + seconds(3) + usecs(4)).toString() ==
               "5 minutes, 3 secs, and 4 μs");

        assert(seconds(-42).toString() == "-42 secs");
        assert(usecs(-5239492).toString() == "-5 secs, -239 ms, and -492 μs");
    }

    /++
        Returns whether this $(D Duration) is negative.
      +/
    @property bool isNegative() const nothrow @nogc
    {
        return _hnsecs < 0;
    }


package (core) // Non-private for tests.
{
    /+
        Params:
            hnsecs = The total number of hecto-nanoseconds in this $(D Duration).
      +/
    this(long hnsecs) nothrow @nogc
    {
        _hnsecs = hnsecs;
    }
}

    private long _hnsecs;
}

///
unittest
{
    import core.time;

    // using the dur template
    auto numDays = dur!"days"(12);

    // using the days function
    numDays = days(12);

    // alternatively using UFCS syntax
    numDays = 12.days;

    auto myTime = 100.msecs + 20_000.usecs + 30_000.hnsecs;
    assert(myTime == 123.msecs);
}

/++
    Converts a $(D TickDuration) to the given units as either an integral
    value or a floating point value.

    Params:
        units = The units to convert to. Accepts $(D "seconds") and smaller
                only.
        T     = The type to convert to (either an integral type or a
                floating point type).

        td    = The TickDuration to convert
  +/
T to(string units, T, D)(D td) @safe pure nothrow @nogc
    if (is(_Unqual!D == TickDuration) &&
       (units == "seconds" ||
        units == "msecs" ||
        units == "usecs" ||
        units == "hnsecs" ||
        units == "nsecs"))
{
    static if (__traits(isIntegral, T) && T.sizeof >= 4)
    {
        enum unitsPerSec = convert!("seconds", units)(1);

        return cast(T) (td.length / (TickDuration.ticksPerSec / cast(real) unitsPerSec));
    }
    else static if (__traits(isFloating, T))
    {
        static if (units == "seconds")
            return td.length / cast(T)TickDuration.ticksPerSec;
        else
        {
            enum unitsPerSec = convert!("seconds", units)(1);

            return cast(T) (td.length /
                (TickDuration.ticksPerSec / cast(real) unitsPerSec));
        }
    }
    else
        static assert(0, "Incorrect template constraint.");
}

///
unittest
{
    auto t = TickDuration.from!"seconds"(1000);

    long tl = to!("seconds",long)(t);
    assert(tl == 1000);

    double td = to!("seconds",double)(t);
    assert(_abs(td - 1000) < 0.001);
}

/++
    These allow you to construct a $(D Duration) from the given time units
    with the given length.

    You can either use the generic function $(D dur) and give it the units as
    a $(D string) or use the named aliases.

    The possible values for units are $(D "weeks"), $(D "days"), $(D "hours"),
    $(D "minutes"), $(D "seconds"), $(D "msecs") (milliseconds), $(D "usecs"),
    (microseconds), $(D "hnsecs") (hecto-nanoseconds, i.e. 100 ns), and
    $(D "nsecs").

    Params:
        units  = The time units of the $(D Duration) (e.g. $(D "days")).
        length = The number of units in the $(D Duration).
  +/
Duration dur(string units)(long length) @safe pure nothrow @nogc
    if (units == "weeks" ||
       units == "days" ||
       units == "hours" ||
       units == "minutes" ||
       units == "seconds" ||
       units == "msecs" ||
       units == "usecs" ||
       units == "hnsecs" ||
       units == "nsecs")
{
    return Duration(convert!(units, "hnsecs")(length));
}

alias weeks   = dur!"weeks";   /// Ditto
alias days    = dur!"days";    /// Ditto
alias hours   = dur!"hours";   /// Ditto
alias minutes = dur!"minutes"; /// Ditto
alias seconds = dur!"seconds"; /// Ditto
alias msecs   = dur!"msecs";   /// Ditto
alias usecs   = dur!"usecs";   /// Ditto
alias hnsecs  = dur!"hnsecs";  /// Ditto
alias nsecs   = dur!"nsecs";   /// Ditto

///
unittest
{
    // Generic
    assert(dur!"weeks"(142).total!"weeks" == 142);
    assert(dur!"days"(142).total!"days" == 142);
    assert(dur!"hours"(142).total!"hours" == 142);
    assert(dur!"minutes"(142).total!"minutes" == 142);
    assert(dur!"seconds"(142).total!"seconds" == 142);
    assert(dur!"msecs"(142).total!"msecs" == 142);
    assert(dur!"usecs"(142).total!"usecs" == 142);
    assert(dur!"hnsecs"(142).total!"hnsecs" == 142);
    assert(dur!"nsecs"(142).total!"nsecs" == 100);

    // Non-generic
    assert(weeks(142).total!"weeks" == 142);
    assert(days(142).total!"days" == 142);
    assert(hours(142).total!"hours" == 142);
    assert(minutes(142).total!"minutes" == 142);
    assert(seconds(142).total!"seconds" == 142);
    assert(msecs(142).total!"msecs" == 142);
    assert(usecs(142).total!"usecs" == 142);
    assert(hnsecs(142).total!"hnsecs" == 142);
    assert(nsecs(142).total!"nsecs" == 100);
}

// used in MonoTimeImpl
private string _clockTypeName(ClockType clockType)
{
    final switch (clockType)
    {
        foreach (name; __traits(allMembers, ClockType))
        {
        case __traits(getMember, ClockType, name):
            return name;
        }
    }
    assert(0);
}

// used in MonoTimeImpl
private size_t _clockTypeIdx(ClockType clockType)
{
    final switch (clockType)
    {
        foreach (i, name; __traits(allMembers, ClockType))
        {
        case __traits(getMember, ClockType, name):
            return i;
        }
    }
    assert(0);
}


/++
    alias for $(D MonoTimeImpl) instantiated with $(D ClockType.normal). This is
    what most programs should use. It's also what much of $(D MonoTimeImpl) uses
    in its documentation (particularly in the examples), because that's what's
    going to be used in most code.
  +/
alias MonoTime = MonoTimeImpl!(ClockType.normal);

/++
    Represents a timestamp of the system's monotonic clock.

    A monotonic clock is one which always goes forward and never moves
    backwards, unlike the system's wall clock time (as represented by
    $(REF SysTime, std,datetime)). The system's wall clock time can be adjusted
    by the user or by the system itself via services such as NTP, so it is
    unreliable to use the wall clock time for timing. Timers which use the wall
    clock time could easily end up never going off due to changes made to the
    wall clock time or otherwise waiting for a different period of time than
    that specified by the programmer. However, because the monotonic clock
    always increases at a fixed rate and is not affected by adjustments to the
    wall clock time, it is ideal for use with timers or anything which requires
    high precision timing.

    So, MonoTime should be used for anything involving timers and timing,
    whereas $(REF SysTime, std,datetime) should be used when the wall clock time
    is required.

    The monotonic clock has no relation to wall clock time. Rather, it holds
    its time as the number of ticks of the clock which have occurred since the
    clock started (typically when the system booted up). So, to determine how
    much time has passed between two points in time, one monotonic time is
    subtracted from the other to determine the number of ticks which occurred
    between the two points of time, and those ticks are divided by the number of
    ticks that occur every second (as represented by MonoTime.ticksPerSecond)
    to get a meaningful duration of time. Normally, MonoTime does these
    calculations for the programmer, but the $(D ticks) and $(D ticksPerSecond)
    properties are provided for those who require direct access to the system
    ticks. The normal way that MonoTime would be used is

--------------------
    MonoTime before = MonoTime.currTime;
    // do stuff...
    MonoTime after = MonoTime.currTime;
    Duration timeElapsed = after - before;
--------------------

    $(LREF MonoTime) is an alias to $(D MonoTimeImpl!(ClockType.normal)) and is
    what most programs should use for the monotonic clock, so that's what is
    used in most of $(D MonoTimeImpl)'s documentation. But $(D MonoTimeImpl)
    can be instantiated with other clock types for those rare programs that need
    it.

    See_Also:
        $(LREF ClockType)
  +/
struct MonoTimeImpl(ClockType clockType)
{
    private enum _clockIdx = _clockTypeIdx(clockType);
    package (core) enum _clockName = _clockTypeName(clockType); // Package visibility for tests.

@safe:

    version (Windows)
    {
        static if (clockType != ClockType.coarse &&
                  clockType != ClockType.normal &&
                  clockType != ClockType.precise)
        {
            static assert(0, "ClockType." ~ _clockName ~
                             " is not supported by MonoTimeImpl on this system.");
        }
    }
    else version (Darwin)
    {
        static if (clockType != ClockType.coarse &&
                  clockType != ClockType.normal &&
                  clockType != ClockType.precise)
        {
            static assert(0, "ClockType." ~ _clockName ~
                             " is not supported by MonoTimeImpl on this system.");
        }
    }
    else version (Posix)
    {
        enum clockArg = _posixClock(clockType);
    }
    else
        static assert(0, "Unsupported platform");

    /++
        The current time of the system's monotonic clock. This has no relation
        to the wall clock time, as the wall clock time can be adjusted (e.g.
        by NTP), whereas the monotonic clock always moves forward. The source
        of the monotonic time is system-specific.

        On Windows, $(D QueryPerformanceCounter) is used. On Mac OS X,
        $(D mach_absolute_time) is used, while on other POSIX systems,
        $(D clock_gettime) is used.

        $(RED Warning): On some systems, the monotonic clock may stop counting
                        when the computer goes to sleep or hibernates. So, the
                        monotonic clock may indicate less time than has actually
                        passed if that occurs. This is known to happen on
                        Mac OS X. It has not been tested whether it occurs on
                        either Windows or Linux.
      +/
    static @property MonoTimeImpl currTime() @trusted nothrow @nogc
    {
        if (ticksPerSecond == 0)
        {
            import core.internal.abort : abort;
            abort("MonoTimeImpl!(ClockType." ~ _clockName ~
                      ") failed to get the frequency of the system's monotonic clock.");
        }

        version (Windows)
        {
            long ticks;
            if (QueryPerformanceCounter(&ticks) == 0)
            {
                // This probably cannot happen on Windows 95 or later
                import core.internal.abort : abort;
                abort("Call to QueryPerformanceCounter failed.");
            }
            return MonoTimeImpl(ticks);
        }
        else version (Darwin)
            return MonoTimeImpl(mach_absolute_time());
        else version (Posix)
        {
            timespec ts;
            if (clock_gettime(clockArg, &ts) != 0)
            {
                import core.internal.abort : abort;
                abort("Call to clock_gettime failed.");
            }

            return MonoTimeImpl(convClockFreq(ts.tv_sec * 1_000_000_000L + ts.tv_nsec,
                                              1_000_000_000L,
                                              ticksPerSecond));
        }
    }


    static @property pure nothrow @nogc
    {
    /++
        A $(D MonoTime) of $(D 0) ticks. It's provided to be consistent with
        $(D Duration.zero), and it's more explicit than $(D MonoTime.init).
      +/
    MonoTimeImpl zero() { return MonoTimeImpl(0); }

    /++
        Largest $(D MonoTime) possible.
      +/
    MonoTimeImpl max() { return MonoTimeImpl(long.max); }

    /++
        Most negative $(D MonoTime) possible.
      +/
    MonoTimeImpl min() { return MonoTimeImpl(long.min); }
    }

    /++
        Compares this MonoTime with the given MonoTime.

        Returns:
            $(BOOKTABLE,
                $(TR $(TD this &lt; rhs) $(TD &lt; 0))
                $(TR $(TD this == rhs) $(TD 0))
                $(TR $(TD this &gt; rhs) $(TD &gt; 0))
            )
     +/
    int opCmp(MonoTimeImpl rhs) const pure nothrow @nogc
    {
        if (_ticks < rhs._ticks)
            return -1;
        return _ticks > rhs._ticks ? 1 : 0;
    }


    /++
        Subtracting two MonoTimes results in a $(LREF Duration) representing
        the amount of time which elapsed between them.

        The primary way that programs should time how long something takes is to
        do
--------------------
MonoTime before = MonoTime.currTime;
// do stuff
MonoTime after = MonoTime.currTime;

// How long it took.
Duration timeElapsed = after - before;
--------------------
        or to use a wrapper (such as a stop watch type) which does that.

        $(RED Warning):
            Because $(LREF Duration) is in hnsecs, whereas MonoTime is in system
            ticks, it's usually the case that this assertion will fail
--------------------
auto before = MonoTime.currTime;
// do stuff
auto after = MonoTime.currTime;
auto timeElapsed = after - before;
assert(before + timeElapsed == after);
--------------------

            This is generally fine, and by its very nature, converting from
            system ticks to any type of seconds (hnsecs, nsecs, etc.) will
            introduce rounding errors, but if code needs to avoid any of the
            small rounding errors introduced by conversion, then it needs to use
            MonoTime's $(D ticks) property and keep all calculations in ticks
            rather than using $(LREF Duration).
      +/
    Duration opBinary(string op)(MonoTimeImpl rhs) const pure nothrow @nogc
        if (op == "-")
    {
        immutable diff = _ticks - rhs._ticks;
        return Duration(convClockFreq(diff , ticksPerSecond, hnsecsPer!"seconds"));
    }


    /++
        Adding or subtracting a $(LREF Duration) to/from a MonoTime results in
        a MonoTime which is adjusted by that amount.
      +/
    MonoTimeImpl opBinary(string op)(Duration rhs) const pure nothrow @nogc
        if (op == "+" || op == "-")
    {
        immutable rhsConverted = convClockFreq(rhs._hnsecs, hnsecsPer!"seconds", ticksPerSecond);
        mixin("return MonoTimeImpl(_ticks " ~ op ~ " rhsConverted);");
    }


    /++ Ditto +/
    ref MonoTimeImpl opOpAssign(string op)(Duration rhs) pure nothrow @nogc
        if (op == "+" || op == "-")
    {
        immutable rhsConverted = convClockFreq(rhs._hnsecs, hnsecsPer!"seconds", ticksPerSecond);
        mixin("_ticks " ~ op ~ "= rhsConverted;");
        return this;
    }

    /++
        The number of ticks in the monotonic time.

        Most programs should not use this directly, but it's exposed for those
        few programs that need it.

        The main reasons that a program might need to use ticks directly is if
        the system clock has higher precision than hnsecs, and the program needs
        that higher precision, or if the program needs to avoid the rounding
        errors caused by converting to hnsecs.
      +/
    @property long ticks() const pure nothrow @nogc
    {
        return _ticks;
    }


    /++
        The number of ticks that MonoTime has per second - i.e. the resolution
        or frequency of the system's monotonic clock.

        e.g. if the system clock had a resolution of microseconds, then
        ticksPerSecond would be $(D 1_000_000).
      +/
    static @property long ticksPerSecond() pure nothrow @nogc
    {
        return _ticksPerSecond[_clockIdx];
    }

    unittest
    {
        assert(MonoTimeImpl.ticksPerSecond == _ticksPerSecond[_clockIdx]);
    }


    ///
    string toString() const pure nothrow
    {
        static if (clockType == ClockType.normal)
            return "MonoTime(" ~ signedToTempString(_ticks, 10) ~ " ticks, " ~ signedToTempString(ticksPerSecond, 10) ~ " ticks per second)";
        else
            return "MonoTimeImpl!(ClockType." ~ _clockName ~ ")(" ~ signedToTempString(_ticks, 10) ~ " ticks, " ~
                   signedToTempString(ticksPerSecond, 10) ~ " ticks per second)";
    }

private:

    // static immutable long _ticksPerSecond;

    unittest
    {
        assert(_ticksPerSecond[_clockIdx]);
    }


    package(core) long _ticks; // Package visibility for tests.
}

// This is supposed to be a static variable in MonoTimeImpl with the static
// constructor being in there, but https://issues.dlang.org/show_bug.cgi?id=14517
// prevents that from working. However, moving it back to a static ctor will
// reraise issues with other systems using MonoTime, so we should leave this
// here even when that bug is fixed.
private immutable long[__traits(allMembers, ClockType).length] _ticksPerSecond;

// This is called directly from the runtime initilization function (rt_init),
// instead of using a static constructor. Other subsystems inside the runtime
// (namely, the GC) may need time functionality, but cannot wait until the
// static ctors have run. Therefore, we initialize these specially. Because
// it's a normal function, we need to do some dangerous casting PLEASE take
// care when modifying this function, and it should NOT be called except from
// the runtime init.
//
// NOTE: the code below SPECIFICALLY does not assert when it cannot initialize
// the ticks per second array. This allows cases where a clock is never used on
// a system that doesn't support it. See bugzilla issue
// https://issues.dlang.org/show_bug.cgi?id=14863
// The assert will occur when someone attempts to use _ticksPerSecond for that
// value.
extern(C) void _d_initMonoTime()
{
    // We need a mutable pointer to the ticksPerSecond array. Although this
    // would appear to break immutability, it is logically the same as a static
    // ctor. So we should ONLY write these values once (we will check for 0
    // values when setting to ensure this is truly only called once).
    auto tps = cast(long[])_ticksPerSecond[];

    // If we try to do anything with ClockType in the documentation build, it'll
    // trigger the static assertions related to ClockType, since the
    // documentation build defines all of the possible ClockTypes, which won't
    // work when they're used in the static ifs, because no system supports them
    // all.
    version (CoreDdoc)
    {}
    else version (Windows)
    {
        long ticksPerSecond;
        if (QueryPerformanceFrequency(&ticksPerSecond) != 0)
        {
            foreach (i, typeStr; __traits(allMembers, ClockType))
            {
                // ensure we are only writing immutable data once
                if (tps[i] != 0)
                    // should only be called once
                    assert(0);
                tps[i] = ticksPerSecond;
            }
        }
    }
    else version (Darwin)
    {
        immutable long ticksPerSecond = machTicksPerSecond();
        foreach (i, typeStr; __traits(allMembers, ClockType))
        {
            // ensure we are only writing immutable data once
            if (tps[i] != 0)
                // should only be called once
                assert(0);
            tps[i] = ticksPerSecond;
        }
    }
    else version (Posix)
    {
        timespec ts;
        foreach (i, typeStr; __traits(allMembers, ClockType))
        {
            static if (typeStr != "second")
            {
                enum clockArg = _posixClock(__traits(getMember, ClockType, typeStr));
                if (clock_getres(clockArg, &ts) == 0)
                {
                    // ensure we are only writing immutable data once
                    if (tps[i] != 0)
                        // should only be called once
                        assert(0);

                    // For some reason, on some systems, clock_getres returns
                    // a resolution which is clearly wrong:
                    //  - it's a millisecond or worse, but the time is updated
                    //    much more frequently than that.
                    //  - it's negative
                    //  - it's zero
                    // In such cases, we'll just use nanosecond resolution.
                    tps[i] = ts.tv_sec != 0 || ts.tv_nsec <= 0 || ts.tv_nsec >= 1000
                        ? 1_000_000_000L : 1_000_000_000L / ts.tv_nsec;
                }
            }
        }
    }
}


/++
    Converts the given time from one clock frequency/resolution to another.

    See_Also:
        $(LREF ticksToNSecs)
  +/
long convClockFreq(long ticks, long srcTicksPerSecond, long dstTicksPerSecond) @safe pure nothrow @nogc
{
    // This would be more straightforward with floating point arithmetic,
    // but we avoid it here in order to avoid the rounding errors that that
    // introduces. Also, by splitting out the units in this way, we're able
    // to deal with much larger values before running into problems with
    // integer overflow.
    return ticks / srcTicksPerSecond * dstTicksPerSecond +
           ticks % srcTicksPerSecond * dstTicksPerSecond / srcTicksPerSecond;
}

///
unittest
{
    // one tick is one second -> one tick is a hecto-nanosecond
    assert(convClockFreq(45, 1, 10_000_000) == 450_000_000);

    // one tick is one microsecond -> one tick is a millisecond
    assert(convClockFreq(9029, 1_000_000, 1_000) == 9);

    // one tick is 1/3_515_654 of a second -> 1/1_001_010 of a second
    assert(convClockFreq(912_319, 3_515_654, 1_001_010) == 259_764);

    // one tick is 1/MonoTime.ticksPerSecond -> one tick is a nanosecond
    // Equivalent to ticksToNSecs
    auto nsecs = convClockFreq(1982, MonoTime.ticksPerSecond, 1_000_000_000);
}


/++
    Convenience wrapper around $(LREF convClockFreq) which converts ticks at
    a clock frequency of $(D MonoTime.ticksPerSecond) to nanoseconds.

    It's primarily of use when $(D MonoTime.ticksPerSecond) is greater than
    hecto-nanosecond resolution, and an application needs a higher precision
    than hecto-nanoceconds.

    See_Also:
        $(LREF convClockFreq)
  +/
long ticksToNSecs(long ticks) @safe pure nothrow @nogc
{
    return convClockFreq(ticks, MonoTime.ticksPerSecond, 1_000_000_000);
}

///
unittest
{
    auto before = MonoTime.currTime;
    // do stuff
    auto after = MonoTime.currTime;
    auto diffInTicks = after.ticks - before.ticks;
    auto diffInNSecs = ticksToNSecs(diffInTicks);
    assert(diffInNSecs == convClockFreq(diffInTicks, MonoTime.ticksPerSecond, 1_000_000_000));
}


/++
    The reverse of $(LREF ticksToNSecs).
  +/
long nsecsToTicks(long ticks) @safe pure nothrow @nogc
{
    return convClockFreq(ticks, 1_000_000_000, MonoTime.ticksPerSecond);
}


/++
    $(RED Warning: TickDuration will be deprecated in the near future (once all
          uses of it in Phobos have been deprecated). Please use
          $(LREF MonoTime) for the cases where a monotonic timestamp is needed
          and $(LREF Duration) when a duration is needed, rather than using
          TickDuration. It has been decided that TickDuration is too confusing
          (e.g. it conflates a monotonic timestamp and a duration in monotonic
           clock ticks) and that having multiple duration types is too awkward
          and confusing.)

   Represents a duration of time in system clock ticks.

   The system clock ticks are the ticks of the system clock at the highest
   precision that the system provides.
  +/
struct TickDuration
{
    /++
       The number of ticks that the system clock has in one second.

       If $(D ticksPerSec) is $(D 0), then then $(D TickDuration) failed to
       get the value of $(D ticksPerSec) on the current system, and
       $(D TickDuration) is not going to work. That would be highly abnormal
       though.
      +/
    static immutable long ticksPerSec;


    /++
        The tick of the system clock (as a $(D TickDuration)) when the
        application started.
      +/
    static immutable TickDuration appOrigin;


    static @property @safe pure nothrow @nogc
    {
    /++
        It's the same as $(D TickDuration(0)), but it's provided to be
        consistent with $(D Duration) and $(D FracSec), which provide $(D zero)
        properties.
      +/
    TickDuration zero() { return TickDuration(0); }

    /++
        Largest $(D TickDuration) possible.
      +/
    TickDuration max() { return TickDuration(long.max); }

    /++
        Most negative $(D TickDuration) possible.
      +/
    TickDuration min() { return TickDuration(long.min); }
    }


    @trusted shared static this()
    {
        version (Windows)
        {
            if (QueryPerformanceFrequency(cast(long*)&ticksPerSec) == 0)
                ticksPerSec = 0;
        }
        else version (Darwin)
        {
            ticksPerSec = machTicksPerSecond();
        }
        else version (Posix)
        {
            static if (is(typeof(clock_gettime)))
            {
                timespec ts;

                if (clock_getres(CLOCK_MONOTONIC, &ts) != 0)
                    ticksPerSec = 0;
                else
                {
                    //For some reason, on some systems, clock_getres returns
                    //a resolution which is clearly wrong (it's a millisecond
                    //or worse, but the time is updated much more frequently
                    //than that). In such cases, we'll just use nanosecond
                    //resolution.
                    ticksPerSec = ts.tv_nsec >= 1000 ? 1_000_000_000
                                                     : 1_000_000_000 / ts.tv_nsec;
                }
            }
            else
                ticksPerSec = 1_000_000;
        }

        if (ticksPerSec != 0)
            appOrigin = TickDuration.currSystemTick;
    }

    unittest
    {
        assert(ticksPerSec);
    }


    /++
       The number of system ticks in this $(D TickDuration).

       You can convert this $(D length) into the number of seconds by dividing
       it by $(D ticksPerSec) (or using one the appropriate property function
       to do it).
      +/
    long length;

    /++
        Returns the total number of seconds in this $(D TickDuration).
      +/
    @property long seconds() @safe const pure nothrow @nogc
    {
        return this.to!("seconds", long)();
    }


    /++
        Returns the total number of milliseconds in this $(D TickDuration).
      +/
    @property long msecs() @safe const pure nothrow @nogc
    {
        return this.to!("msecs", long)();
    }


    /++
        Returns the total number of microseconds in this $(D TickDuration).
      +/
    @property long usecs() @safe const pure nothrow @nogc
    {
        return this.to!("usecs", long)();
    }


    /++
        Returns the total number of hecto-nanoseconds in this $(D TickDuration).
      +/
    @property long hnsecs() @safe const pure nothrow @nogc
    {
        return this.to!("hnsecs", long)();
    }


    /++
        Returns the total number of nanoseconds in this $(D TickDuration).
      +/
    @property long nsecs() @safe const pure nothrow @nogc
    {
        return this.to!("nsecs", long)();
    }


    /++
        This allows you to construct a $(D TickDuration) from the given time
        units with the given length.

        Params:
            units  = The time units of the $(D TickDuration) (e.g. $(D "msecs")).
            length = The number of units in the $(D TickDuration).
      +/
    static TickDuration from(string units)(long length) @safe pure nothrow @nogc
        if (units == "seconds" ||
           units == "msecs" ||
           units == "usecs" ||
           units == "hnsecs" ||
           units == "nsecs")
    {
        enum unitsPerSec = convert!("seconds", units)(1);

        return TickDuration(cast(long)(length * (ticksPerSec / cast(real)unitsPerSec)));
    }


    /++
        Returns a $(LREF Duration) with the same number of hnsecs as this
        $(D TickDuration).
        Note that the conventional way to convert between $(D TickDuration)
        and $(D Duration) is using $(REF to, std,conv), e.g.:
        $(D tickDuration.to!Duration())
      +/
    Duration opCast(T)() @safe const pure nothrow @nogc
        if (is(_Unqual!T == Duration))
    {
        return Duration(hnsecs);
    }


    //Temporary hack until bug http://d.puremagic.com/issues/show_bug.cgi?id=5747 is fixed.
    TickDuration opCast(T)() @safe const pure nothrow @nogc
        if (is(_Unqual!T == TickDuration))
    {
        return this;
    }


    /++
        Adds or subtracts two $(D TickDuration)s as well as assigning the result
        to this $(D TickDuration).

        The legal types of arithmetic for $(D TickDuration) using this operator
        are

        $(TABLE
        $(TR $(TD TickDuration) $(TD +=) $(TD TickDuration) $(TD -->) $(TD TickDuration))
        $(TR $(TD TickDuration) $(TD -=) $(TD TickDuration) $(TD -->) $(TD TickDuration))
        )

        Params:
            rhs = The $(D TickDuration) to add to or subtract from this
                  $(D $(D TickDuration)).
      +/
    ref TickDuration opOpAssign(string op)(TickDuration rhs) @safe pure nothrow @nogc
        if (op == "+" || op == "-")
    {
        mixin("length " ~ op ~ "= rhs.length;");
        return this;
    }


    /++
        Adds or subtracts two $(D TickDuration)s.

        The legal types of arithmetic for $(D TickDuration) using this operator
        are

        $(TABLE
        $(TR $(TD TickDuration) $(TD +) $(TD TickDuration) $(TD -->) $(TD TickDuration))
        $(TR $(TD TickDuration) $(TD -) $(TD TickDuration) $(TD -->) $(TD TickDuration))
        )

        Params:
            rhs = The $(D TickDuration) to add to or subtract from this
                  $(D TickDuration).
      +/
    TickDuration opBinary(string op)(TickDuration rhs) @safe const pure nothrow @nogc
        if (op == "+" || op == "-")
    {
        return TickDuration(mixin("length " ~ op ~ " rhs.length"));
    }


    /++
        Returns the negation of this $(D TickDuration).
      +/
    TickDuration opUnary(string op)() @safe const pure nothrow @nogc
        if (op == "-")
    {
        return TickDuration(-length);
    }


    /++
       operator overloading "<, >, <=, >="
      +/
    int opCmp(TickDuration rhs) @safe const pure nothrow @nogc
    {
        return length < rhs.length ? -1 : (length == rhs.length ? 0 : 1);
    }


    /++
        The legal types of arithmetic for $(D TickDuration) using this operator
        overload are

        $(TABLE
        $(TR $(TD TickDuration) $(TD *) $(TD long) $(TD -->) $(TD TickDuration))
        $(TR $(TD TickDuration) $(TD *) $(TD floating point) $(TD -->) $(TD TickDuration))
        )

        Params:
            value = The value to divide from this duration.
      +/
    void opOpAssign(string op, T)(T value) @safe pure nothrow @nogc
        if (op == "*" &&
           (__traits(isIntegral, T) || __traits(isFloating, T)))
    {
        length = cast(long)(length * value);
    }


    /++
        The legal types of arithmetic for $(D TickDuration) using this operator
        overload are

        $(TABLE
        $(TR $(TD TickDuration) $(TD /) $(TD long) $(TD -->) $(TD TickDuration))
        $(TR $(TD TickDuration) $(TD /) $(TD floating point) $(TD -->) $(TD TickDuration))
        )

        Params:
            value = The value to divide from this $(D TickDuration).

        Throws:
            $(D TimeException) if an attempt to divide by $(D 0) is made.
      +/
    void opOpAssign(string op, T)(T value) @safe pure
        if (op == "/" &&
           (__traits(isIntegral, T) || __traits(isFloating, T)))
    {
        if (value == 0)
            throw new TimeException("Attempted division by 0.");

        length = cast(long)(length / value);
    }


    /++
        The legal types of arithmetic for $(D TickDuration) using this operator
        overload are

        $(TABLE
        $(TR $(TD TickDuration) $(TD *) $(TD long) $(TD -->) $(TD TickDuration))
        $(TR $(TD TickDuration) $(TD *) $(TD floating point) $(TD -->) $(TD TickDuration))
        )

        Params:
            value = The value to divide from this $(D TickDuration).
      +/
    TickDuration opBinary(string op, T)(T value) @safe const pure nothrow @nogc
        if (op == "*" &&
           (__traits(isIntegral, T) || __traits(isFloating, T)))
    {
        return TickDuration(cast(long)(length * value));
    }


    /++
        The legal types of arithmetic for $(D TickDuration) using this operator
        overload are

        $(TABLE
        $(TR $(TD TickDuration) $(TD /) $(TD long) $(TD -->) $(TD TickDuration))
        $(TR $(TD TickDuration) $(TD /) $(TD floating point) $(TD -->) $(TD TickDuration))
        )

        Params:
            value = The value to divide from this $(D TickDuration).

        Throws:
            $(D TimeException) if an attempt to divide by $(D 0) is made.
      +/
    TickDuration opBinary(string op, T)(T value) @safe const pure
        if (op == "/" &&
           (__traits(isIntegral, T) || __traits(isFloating, T)))
    {
        if (value == 0)
            throw new TimeException("Attempted division by 0.");

        return TickDuration(cast(long)(length / value));
    }


    /++
        Params:
            ticks = The number of ticks in the TickDuration.
      +/
    @safe pure nothrow @nogc this(long ticks)
    {
        this.length = ticks;
    }


    /++
        The current system tick. The number of ticks per second varies from
        system to system. $(D currSystemTick) uses a monotonic clock, so it's
        intended for precision timing by comparing relative time values, not for
        getting the current system time.

        On Windows, $(D QueryPerformanceCounter) is used. On Mac OS X,
        $(D mach_absolute_time) is used, while on other Posix systems,
        $(D clock_gettime) is used. If $(D mach_absolute_time) or
        $(D clock_gettime) is unavailable, then Posix systems use
        $(D gettimeofday) (the decision is made when $(D TickDuration) is
        compiled), which unfortunately, is not monotonic, but if
        $(D mach_absolute_time) and $(D clock_gettime) aren't available, then
        $(D gettimeofday) is the the best that there is.

        $(RED Warning):
            On some systems, the monotonic clock may stop counting when
            the computer goes to sleep or hibernates. So, the monotonic
            clock could be off if that occurs. This is known to happen
            on Mac OS X. It has not been tested whether it occurs on
            either Windows or on Linux.

        Throws:
            $(D TimeException) if it fails to get the time.
      +/
    static @property TickDuration currSystemTick() @trusted nothrow @nogc
    {
        import core.internal.abort : abort;
        version (Windows)
        {
            ulong ticks = void;
            QueryPerformanceCounter(cast(long*)&ticks);
            return TickDuration(ticks);
        }
        else version (Darwin)
        {
            static if (is(typeof(mach_absolute_time)))
                return TickDuration(cast(long)mach_absolute_time());
            else
            {
                timeval tv = void;
                gettimeofday(&tv, null);
                return TickDuration(tv.tv_sec * TickDuration.ticksPerSec +
                                    tv.tv_usec * TickDuration.ticksPerSec / 1000 / 1000);
            }
        }
        else version (Posix)
        {
            static if (is(typeof(clock_gettime)))
            {
                timespec ts;
                if (clock_gettime(CLOCK_MONOTONIC, &ts) != 0)
                    abort("Failed in clock_gettime().");

                return TickDuration(ts.tv_sec * TickDuration.ticksPerSec +
                                    ts.tv_nsec * TickDuration.ticksPerSec / 1000 / 1000 / 1000);
            }
            else
            {
                timeval tv = void;
                gettimeofday(&tv, null);
                return TickDuration(tv.tv_sec * TickDuration.ticksPerSec +
                                    tv.tv_usec * TickDuration.ticksPerSec / 1000 / 1000);
            }
        }
    }

    @safe nothrow unittest
    {
        assert(TickDuration.currSystemTick.length > 0);
    }
}


/++
    Generic way of converting between two time units. Conversions to smaller
    units use truncating division. Years and months can be converted to each
    other, small units can be converted to each other, but years and months
    cannot be converted to or from smaller units (due to the varying number
    of days in a month or year).

    Params:
        from  = The units of time to convert from.
        to    = The units of time to convert to.
        value = The value to convert.
  +/
long convert(string from, string to)(long value) @safe pure nothrow @nogc
    if (((from == "weeks" ||
         from == "days" ||
         from == "hours" ||
         from == "minutes" ||
         from == "seconds" ||
         from == "msecs" ||
         from == "usecs" ||
         from == "hnsecs" ||
         from == "nsecs") &&
        (to == "weeks" ||
         to == "days" ||
         to == "hours" ||
         to == "minutes" ||
         to == "seconds" ||
         to == "msecs" ||
         to == "usecs" ||
         to == "hnsecs" ||
         to == "nsecs")) ||
       ((from == "years" || from == "months") && (to == "years" || to == "months")))
{
    static if (from == "years")
    {
        static if (to == "years")
            return value;
        else static if (to == "months")
            return value * 12;
        else
            static assert(0, "A generic month or year cannot be converted to or from smaller units.");
    }
    else static if (from == "months")
    {
        static if (to == "years")
            return value / 12;
        else static if (to == "months")
            return value;
        else
            static assert(0, "A generic month or year cannot be converted to or from smaller units.");
    }
    else static if (from == "nsecs" && to == "nsecs")
        return value;
    else static if (from == "nsecs")
        return convert!("hnsecs", to)(value / 100);
    else static if (to == "nsecs")
        return convert!(from, "hnsecs")(value) * 100;
    else
        return (hnsecsPer!from * value) / hnsecsPer!to;
}

///
unittest
{
    assert(convert!("years", "months")(1) == 12);
    assert(convert!("months", "years")(12) == 1);

    assert(convert!("weeks", "days")(1) == 7);
    assert(convert!("hours", "seconds")(1) == 3600);
    assert(convert!("seconds", "days")(1) == 0);
    assert(convert!("seconds", "days")(86_400) == 1);

    assert(convert!("nsecs", "nsecs")(1) == 1);
    assert(convert!("nsecs", "hnsecs")(1) == 0);
    assert(convert!("hnsecs", "nsecs")(1) == 100);
    assert(convert!("nsecs", "seconds")(1) == 0);
    assert(convert!("seconds", "nsecs")(1) == 1_000_000_000);
}


// @@@DEPRECATED_2018-10@@@
/++
    $(RED Everything in druntime and Phobos that was using FracSec now uses
          Duration for greater simplicity. So, FracSec has been deprecated.
          It will be removed from the docs in October 2018, and removed
          completely from druntime in October 2019.)

    Represents fractional seconds.

    This is the portion of the time which is smaller than a second and it cannot
    hold values which would be greater than or equal to a second (or less than
    or equal to a negative second).

    It holds hnsecs internally, but you can create it using either milliseconds,
    microseconds, or hnsecs. What it does is allow for a simple way to set or
    adjust the fractional seconds portion of a $(D Duration) or a
    $(REF SysTime, std,datetime) without having to worry about whether you're
    dealing with milliseconds, microseconds, or hnsecs.

    $(D FracSec)'s functions which take time unit strings do accept
    $(D "nsecs"), but because the resolution of $(D Duration) and
    $(REF SysTime, std,datetime) is hnsecs, you don't actually get precision higher
    than hnsecs. $(D "nsecs") is accepted merely for convenience. Any values
    given as nsecs will be converted to hnsecs using $(D convert) (which uses
    truncating division when converting to smaller units).
  +/
deprecated("FracSec has been deprecated in favor of just using Duration for the sake of simplicity")
struct FracSec
{
@safe pure:

public:

    /++
        A $(D FracSec) of $(D 0). It's shorter than doing something like
        $(D FracSec.from!"msecs"(0)) and more explicit than $(D FracSec.init).
      +/
    static @property nothrow @nogc FracSec zero() { return FracSec(0); }


    /++
        Create a $(D FracSec) from the given units ($(D "msecs"), $(D "usecs"),
        or $(D "hnsecs")).

        Params:
            units = The units to create a FracSec from.
            value = The number of the given units passed the second.

        Throws:
            $(D TimeException) if the given value would result in a $(D FracSec)
            greater than or equal to $(D 1) second or less than or equal to
            $(D -1) seconds.
      +/
    static FracSec from(string units)(long value)
        if (units == "msecs" ||
           units == "usecs" ||
           units == "hnsecs" ||
           units == "nsecs")
    {
        immutable hnsecs = cast(int)convert!(units, "hnsecs")(value);
        _enforceValid(hnsecs);
        return FracSec(hnsecs);
    }


    /++
        Returns the negation of this $(D FracSec).
      +/
    FracSec opUnary(string op)() const nothrow @nogc
        if (op == "-")
    {
        return FracSec(-_hnsecs);
    }


    /++
        The value of this $(D FracSec) as milliseconds.
      +/
    @property int msecs() const nothrow @nogc
    {
        return cast(int)convert!("hnsecs", "msecs")(_hnsecs);
    }


    /++
        The value of this $(D FracSec) as milliseconds.

        Params:
            milliseconds = The number of milliseconds passed the second.

        Throws:
            $(D TimeException) if the given value is not less than $(D 1) second
            and greater than a $(D -1) seconds.
      +/
    @property void msecs(int milliseconds)
    {
        immutable hnsecs = cast(int)convert!("msecs", "hnsecs")(milliseconds);
        _enforceValid(hnsecs);
        _hnsecs = hnsecs;
    }


    /++
        The value of this $(D FracSec) as microseconds.
      +/
    @property int usecs() const nothrow @nogc
    {
        return cast(int)convert!("hnsecs", "usecs")(_hnsecs);
    }


    /++
        The value of this $(D FracSec) as microseconds.

        Params:
            microseconds = The number of microseconds passed the second.

        Throws:
            $(D TimeException) if the given value is not less than $(D 1) second
            and greater than a $(D -1) seconds.
      +/
    @property void usecs(int microseconds)
    {
        immutable hnsecs = cast(int)convert!("usecs", "hnsecs")(microseconds);
        _enforceValid(hnsecs);
        _hnsecs = hnsecs;
    }


    /++
        The value of this $(D FracSec) as hnsecs.
      +/
    @property int hnsecs() const nothrow @nogc
    {
        return _hnsecs;
    }


    /++
        The value of this $(D FracSec) as hnsecs.

        Params:
            hnsecs = The number of hnsecs passed the second.

        Throws:
            $(D TimeException) if the given value is not less than $(D 1) second
            and greater than a $(D -1) seconds.
      +/
    @property void hnsecs(int hnsecs)
    {
        _enforceValid(hnsecs);
        _hnsecs = hnsecs;
    }


    /++
        The value of this $(D FracSec) as nsecs.

        Note that this does not give you any greater precision
        than getting the value of this $(D FracSec) as hnsecs.
      +/
    @property int nsecs() const nothrow @nogc
    {
        return cast(int)convert!("hnsecs", "nsecs")(_hnsecs);
    }


    /++
        The value of this $(D FracSec) as nsecs.

        Note that this does not give you any greater precision
        than setting the value of this $(D FracSec) as hnsecs.

        Params:
            nsecs = The number of nsecs passed the second.

        Throws:
            $(D TimeException) if the given value is not less than $(D 1) second
            and greater than a $(D -1) seconds.
      +/
    @property void nsecs(long nsecs)
    {
        immutable hnsecs = cast(int)convert!("nsecs", "hnsecs")(nsecs);
        _enforceValid(hnsecs);
        _hnsecs = hnsecs;
    }


    /+
        Converts this $(D TickDuration) to a string.
      +/
    //Due to bug http://d.puremagic.com/issues/show_bug.cgi?id=3715 , we can't
    //have versions of toString() with extra modifiers, so we define one version
    //with modifiers and one without.
    string toString()
    {
        return _toStringImpl();
    }


    /++
        Converts this $(D TickDuration) to a string.
      +/
    //Due to bug http://d.puremagic.com/issues/show_bug.cgi?id=3715 , we can't
    //have versions of toString() with extra modifiers, so we define one version
    //with modifiers and one without.
    string toString() const nothrow
    {
        return _toStringImpl();
    }


private:

    /+
        Since we have two versions of $(D toString), we have $(D _toStringImpl)
        so that they can share implementations.
      +/
    string _toStringImpl() const nothrow
    {
        long hnsecs = _hnsecs;

        immutable milliseconds = splitUnitsFromHNSecs!"msecs"(hnsecs);
        immutable microseconds = splitUnitsFromHNSecs!"usecs"(hnsecs);

        if (hnsecs == 0)
        {
            if (microseconds == 0)
            {
                if (milliseconds == 0)
                    return "0 hnsecs";
                else
                {
                    if (milliseconds == 1)
                        return "1 ms";
                    else
                    {
                        auto r = signedToTempString(milliseconds, 10).idup;
                        r ~= " ms";
                        return r;
                    }
                }
            }
            else
            {
                immutable fullMicroseconds = getUnitsFromHNSecs!"usecs"(_hnsecs);

                if (fullMicroseconds == 1)
                    return "1 μs";
                else
                {
                    auto r = signedToTempString(fullMicroseconds, 10).idup;
                    r ~= " μs";
                    return r;
                }
            }
        }
        else
        {
            if (_hnsecs == 1)
                return "1 hnsec";
            else
            {
                auto r = signedToTempString(_hnsecs, 10).idup;
                r ~= " hnsecs";
                return r;
            }
        }
    }


    /+
        Returns whether the given number of hnsecs fits within the range of
        $(D FracSec).

        Params:
            hnsecs = The number of hnsecs.
      +/
    static bool _valid(int hnsecs) nothrow @nogc
    {
        immutable second = convert!("seconds", "hnsecs")(1);
        return hnsecs > -second && hnsecs < second;
    }


    /+
        Throws:
            $(D TimeException) if $(D valid(hnsecs)) is $(D false).
      +/
    static void _enforceValid(int hnsecs)
    {
        if (!_valid(hnsecs))
            throw new TimeException("FracSec must be greater than equal to 0 and less than 1 second.");
    }


    /+
        Params:
            hnsecs = The number of hnsecs passed the second.
      +/
    package (core) this(int hnsecs) nothrow @nogc // Package visibility for tests.
    {
        _hnsecs = hnsecs;
    }


    invariant()
    {
        if (!_valid(_hnsecs))
            throw new AssertError("Invariant Failure: hnsecs [" ~ signedToTempString(_hnsecs, 10).idup ~ "]", __FILE__, __LINE__);
    }


    int _hnsecs;
}


/++
    Exception type used by core.time.
  +/
class TimeException : Exception
{
    /++
        Params:
            msg  = The message for the exception.
            file = The file where the exception occurred.
            line = The line number where the exception occurred.
            next = The previous exception in the chain of exceptions, if any.
      +/
    this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null) @safe pure nothrow
    {
        super(msg, file, line, next);
    }

    /++
        Params:
            msg  = The message for the exception.
            next = The previous exception in the chain of exceptions.
            file = The file where the exception occurred.
            line = The line number where the exception occurred.
      +/
    this(string msg, Throwable next, string file = __FILE__, size_t line = __LINE__) @safe pure nothrow
    {
        super(msg, file, line, next);
    }
}


/++
    Returns the absolute value of a duration.
  +/
Duration abs(Duration duration) @safe pure nothrow @nogc
{
    return Duration(_abs(duration._hnsecs));
}

/++ Ditto +/
TickDuration abs(TickDuration duration) @safe pure nothrow @nogc
{
    return TickDuration(_abs(duration.length));
}


//==============================================================================
// Private Section.
//
// Much of this is a copy or simplified copy of what's in std.datetime.
//==============================================================================
private:


/+
    Template to help with converting between time units.
 +/
package (core) template hnsecsPer(string units) // Package visibility for tests.
    if (units == "weeks" ||
       units == "days" ||
       units == "hours" ||
       units == "minutes" ||
       units == "seconds" ||
       units == "msecs" ||
       units == "usecs" ||
       units == "hnsecs")
{
    static if (units == "hnsecs")
        enum hnsecsPer = 1L;
    else static if (units == "usecs")
        enum hnsecsPer = 10L;
    else static if (units == "msecs")
        enum hnsecsPer = 1000 * hnsecsPer!"usecs";
    else static if (units == "seconds")
        enum hnsecsPer = 1000 * hnsecsPer!"msecs";
    else static if (units == "minutes")
        enum hnsecsPer = 60 * hnsecsPer!"seconds";
    else static if (units == "hours")
        enum hnsecsPer = 60 * hnsecsPer!"minutes";
    else static if (units == "days")
        enum hnsecsPer = 24 * hnsecsPer!"hours";
    else static if (units == "weeks")
        enum hnsecsPer = 7 * hnsecsPer!"days";
}

/+
    Splits out a particular unit from hnsecs and gives you the value for that
    unit and the remaining hnsecs. It really shouldn't be used unless all units
    larger than the given units have already been split out.

    Params:
        units  = The units to split out.
        hnsecs = The current total hnsecs. Upon returning, it is the hnsecs left
                 after splitting out the given units.

    Returns:
        The number of the given units from converting hnsecs to those units.
  +/
long splitUnitsFromHNSecs(string units)(ref long hnsecs) @safe pure nothrow @nogc
    if (units == "weeks" ||
       units == "days" ||
       units == "hours" ||
       units == "minutes" ||
       units == "seconds" ||
       units == "msecs" ||
       units == "usecs" ||
       units == "hnsecs")
{
    immutable value = convert!("hnsecs", units)(hnsecs);
    hnsecs -= convert!(units, "hnsecs")(value);

    return value;
}

///
unittest
{
    auto hnsecs = 2595000000007L;
    immutable days = splitUnitsFromHNSecs!"days"(hnsecs);
    assert(days == 3);
    assert(hnsecs == 3000000007);

    immutable minutes = splitUnitsFromHNSecs!"minutes"(hnsecs);
    assert(minutes == 5);
    assert(hnsecs == 7);
}


/+
    This function is used to split out the units without getting the remaining
    hnsecs.

    See_Also:
        $(LREF splitUnitsFromHNSecs)

    Params:
        units  = The units to split out.
        hnsecs = The current total hnsecs.

    Returns:
        The split out value.
  +/
long getUnitsFromHNSecs(string units)(long hnsecs) @safe pure nothrow @nogc
    if (units == "weeks" ||
       units == "days" ||
       units == "hours" ||
       units == "minutes" ||
       units == "seconds" ||
       units == "msecs" ||
       units == "usecs" ||
       units == "hnsecs")
{
    return convert!("hnsecs", units)(hnsecs);
}

///
unittest
{
    auto hnsecs = 2595000000007L;
    immutable days = getUnitsFromHNSecs!"days"(hnsecs);
    assert(days == 3);
    assert(hnsecs == 2595000000007L);
}


/+
    This function is used to split out the units without getting the units but
    just the remaining hnsecs.

    See_Also:
        $(LREF splitUnitsFromHNSecs)

    Params:
        units  = The units to split out.
        hnsecs = The current total hnsecs.

    Returns:
        The remaining hnsecs.
  +/
long removeUnitsFromHNSecs(string units)(long hnsecs) @safe pure nothrow @nogc
    if (units == "weeks" ||
       units == "days" ||
       units == "hours" ||
       units == "minutes" ||
       units == "seconds" ||
       units == "msecs" ||
       units == "usecs" ||
       units == "hnsecs")
{
    immutable value = convert!("hnsecs", units)(hnsecs);

    return hnsecs - convert!(units, "hnsecs")(value);
}

///
unittest
{
    auto hnsecs = 2595000000007L;
    auto returned = removeUnitsFromHNSecs!"days"(hnsecs);
    assert(returned == 3000000007);
    assert(hnsecs == 2595000000007L);
}


/+
    Whether all of the given strings are among the accepted strings.
  +/
package (core) bool allAreAcceptedUnits(acceptedUnits...)(string[] units...) // Package visibility for tests.
{
    foreach (unit; units)
    {
        bool found = false;
        foreach (acceptedUnit; acceptedUnits)
        {
            if (unit == acceptedUnit)
            {
                found = true;
                break;
            }
        }
        if (!found)
            return false;
    }
    return true;
}


/+
    Whether the given time unit strings are arranged in order from largest to
    smallest.
  +/
package(core) bool unitsAreInDescendingOrder(string[] units...) // Package visibility for tests.
{
    if (units.length <= 1)
        return true;

    immutable string[] timeStrings = ["nsecs", "hnsecs", "usecs", "msecs", "seconds",
                                      "minutes", "hours", "days", "weeks", "months", "years"];
    size_t currIndex = 42;
    foreach (i, timeStr; timeStrings)
    {
        if (units[0] == timeStr)
        {
            currIndex = i;
            break;
        }
    }
    assert(currIndex != 42);

    foreach (unit; units[1 .. $])
    {
        size_t nextIndex = 42;
        foreach (i, timeStr; timeStrings)
        {
            if (unit == timeStr)
            {
                nextIndex = i;
                break;
            }
        }
        assert(nextIndex != 42);

        if (currIndex <= nextIndex)
            return false;
        currIndex = nextIndex;
    }
    return true;
}


/+
    The time units which are one step larger than the given units.
  +/
package (core) template nextLargerTimeUnits(string units) // Package visibility for tests.
    if (units == "days" ||
       units == "hours" ||
       units == "minutes" ||
       units == "seconds" ||
       units == "msecs" ||
       units == "usecs" ||
       units == "hnsecs" ||
       units == "nsecs")
{
    static if (units == "days")
        enum nextLargerTimeUnits = "weeks";
    else static if (units == "hours")
        enum nextLargerTimeUnits = "days";
    else static if (units == "minutes")
        enum nextLargerTimeUnits = "hours";
    else static if (units == "seconds")
        enum nextLargerTimeUnits = "minutes";
    else static if (units == "msecs")
        enum nextLargerTimeUnits = "seconds";
    else static if (units == "usecs")
        enum nextLargerTimeUnits = "msecs";
    else static if (units == "hnsecs")
        enum nextLargerTimeUnits = "usecs";
    else static if (units == "nsecs")
        enum nextLargerTimeUnits = "hnsecs";
    else
        static assert(0, "Broken template constraint");
}

///
unittest
{
    assert(nextLargerTimeUnits!"minutes" == "hours");
    assert(nextLargerTimeUnits!"hnsecs" == "usecs");
}

version (Darwin)
long machTicksPerSecond()
{
    // Be optimistic that ticksPerSecond (1e9*denom/numer) is integral. So far
    // so good on Darwin based platforms OS X, iOS.
    import core.internal.abort : abort;
    mach_timebase_info_data_t info;
    if (mach_timebase_info(&info) != 0)
        abort("Failed in mach_timebase_info().");

    long scaledDenom = 1_000_000_000L * info.denom;
    if (scaledDenom % info.numer != 0)
        abort("Non integral ticksPerSecond from mach_timebase_info.");
    return scaledDenom / info.numer;
}

/+
    Local version of abs, since std.math.abs is in Phobos, not druntime.
  +/
long _abs(long val) @safe pure nothrow @nogc
{
    return val >= 0 ? val : -val;
}

double _abs(double val) @safe pure nothrow @nogc
{
    return val >= 0.0 ? val : -val;
}

/+ A copy of std.typecons.TypeTuple. +/
template _TypeTuple(TList...)
{
    alias TList _TypeTuple;
}
