/**
 * D header file for C99.
 *
 * Copyright: Copyright Sean Kelly 2005 - 2009.
 * License: Distributed under the
 *      $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
 *    (See accompanying file LICENSE)
 * Authors:   Sean Kelly
 * Source:    $(DRUNTIMESRC core/stdc/_config.d)
 * Standards: ISO/IEC 9899:1999 (E)
 */

module core.stdc.config;

extern (C):
@trusted: // Types only.
nothrow:
@nogc:

version( Windows )
{
    struct __c_long
    {
      pure nothrow @nogc @safe:
        this(int x) { lng = x; }
        int lng;
        alias lng this;
    }

    struct __c_ulong
    {
      pure nothrow @nogc @safe:
        this(uint x) { lng = x; }
        uint lng;
        alias lng this;
    }

    /*
     * This is cpp_long instead of c_long because:
     * 1. Implicit casting of an int to __c_long doesn't happen, because D doesn't
     *    allow constructor calls in implicit conversions.
     * 2. long lng;
     *    cast(__c_long)lng;
     *    does not work because lng has to be implicitly cast to an int in the constructor,
     *    and since that truncates it is not done.
     * Both of these break existing code, so until we find a resolution the types are named
     * cpp_xxxx.
     */

    alias cpp_long = __c_long;
    alias cpp_ulong = __c_ulong;

    alias c_long = int;
    alias c_ulong = uint;
}
else
{
  static if( (void*).sizeof > int.sizeof )
  {
    alias c_long = long;
    alias c_ulong = ulong;
  }
  else
  {
    struct __c_long
    {
      pure nothrow @nogc @safe:
        this(int x) { lng = x; }
        int lng;
        alias lng this;
    }

    struct __c_ulong
    {
      pure nothrow @nogc @safe:
        this(uint x) { lng = x; }
        uint lng;
        alias lng this;
    }

    alias cpp_long = __c_long;
    alias cpp_ulong = __c_ulong;

    alias c_long = int;
    alias c_ulong = uint;
  }
}

version( DigitalMars )
{
    version( CRuntime_Microsoft )
    {
        /* long double is 64 bits, not 80 bits, but is mangled differently
         * than double. To distinguish double from long double, create a wrapper to represent
         * long double, then recognize that wrapper specially in the compiler
         * to generate the correct name mangling and correct function call/return
         * ABI conformance.
         */
        struct __c_long_double
        {
          pure nothrow @nogc @safe:
            this(double d) { ld = d; }
            double ld;
            alias ld this;
        }

        alias c_long_double = __c_long_double;
    }
    else version( X86 )
    {
        alias c_long_double = real;
    }
    else version( X86_64 )
    {
        version( linux )
            alias c_long_double = real;
        else version( FreeBSD )
            alias c_long_double = real;
        else version( OSX )
            alias c_long_double = real;
    }
}
else version( GNU )
    alias c_long_double = real;
else version( LDC )
{
    version( X86 )
        alias c_long_double = real;
    else version( X86_64 )
        alias c_long_double = real;
}
else version( SDC )
{
    version( X86 )
        alias c_long_double = real;
    else version( X86_64 )
        alias c_long_double = real;
}

static assert(is(c_long_double), "c_long_double needs to be declared for this platform/architecture.");
