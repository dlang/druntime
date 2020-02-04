module rt.winargv;

version (Windows):

import core.stdc.wchar_ /+: wcslen+/;
import core.sys.windows.winbase /+: LocalAlloc+/;
import core.sys.windows.winnt /+: LPWSTR, LPCWSTR+/;

/++
 Splits a command line into argc/argv lists, using the VC7 parsing rules.
 This functions interface mimics the `CommandLineToArgvW` api.
 If function fails, returns NULL.
 If function suceeds, call LocalFree(HLOCAL)` on return pointer when done.
 NOTE Implementation-wise, once every few years it would be a good idea to
 compare this code with the .NET Runtime's `SegmentCommandLine` method,
 which is in `src/coreclr/src/utilcode/util.cpp`.
 Date: Feb 4, 2020
+/
LPWSTR *commandLineToArgv(LPCWSTR lpCmdLine, int *pNumArgs) nothrow @nogc
{
    /+
    The MIT License (MIT)

    Copyright (c) .NET Foundation and Contributors

    All rights reserved.

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
    +/

    *pNumArgs = 0;

    int nch = cast(int) wcslen(lpCmdLine);

    // Calculate the worstcase storage requirement. (One pointer for
    // each argument, plus storage for the arguments themselves.)
    int cbAlloc = (nch + 1) * (cast(int) LPWSTR.sizeof) + (nch + 1) * (cast(int) WCHAR.sizeof);
    LPWSTR pAlloc = cast(wchar*) LocalAlloc(LPTR, cbAlloc);
    if (!pAlloc)
        return NULL;

    LPWSTR* argv = cast(LPWSTR*) pAlloc;  // We store the argv pointers in the first halt
    LPWSTR  pdst = cast(LPWSTR)((cast(BYTE*) pAlloc) + (nch + 1) * (cast(int)LPWSTR.sizeof)); // A running pointer to second half to store arguments
    LPCWSTR psrc = lpCmdLine;
    WCHAR   c;
    BOOL    inquote;
    BOOL    copychar;
    int     numslash;

    // First, parse the program name (argv[0]). Argv[0] is parsed under
    // special rules. Anything up to the first whitespace outside a quoted
    // subtring is accepted. Backslashes are treated as normal characters.
    argv[(*pNumArgs)++] = pdst;
    inquote = FALSE;
    do 
    {
        if (*psrc == W!('"'))
        {
            inquote = !inquote;
            c = *psrc++;
            continue;
        }
        *pdst++ = *psrc;

        c = *psrc++;

    } while ((c != W!('\0') && (inquote || (c != W!(' ') && c != W!('\t')))));

    if (c == W!('\0'))
    {
        psrc--;
    }
    else
    {
        *(pdst-1) = W!('\0');
    }

    inquote = FALSE;

    /* loop on each argument */
    for (;;)
    {
        if (*psrc)
        {
            while (*psrc == W!(' ') || *psrc == W!('\t'))
            {
                ++psrc;
            }
        }

        if (*psrc == W!('\0'))
            break;              /* end of args */

        /* scan an argument */
        argv[(*pNumArgs)++] = pdst;

        /* loop through scanning one argument */
        for (;;)
        {
            copychar = 1;
            /* Rules: 2N backslashes + " ==> N backslashes and begin/end quote
            2N+1 backslashes + " ==> N backslashes + literal "
            N backslashes ==> N backslashes */
            numslash = 0;
            while (*psrc == W!('\\'))
            {
                /* count number of backslashes for use below */
                ++psrc;
                ++numslash;
            }
            if (*psrc == W!('"'))
            {
                /* if 2N backslashes before, start/end quote, otherwise
                copy literally */
                if (numslash % 2 == 0)
                {
                    if (inquote && psrc[1] == W!('"'))
                    {
                        psrc++;    /* Double quote inside quoted string */
                    }
                    else
                    {
                        /* skip first quote char and copy second */
                        copychar = 0;       /* don't copy quote */
                        inquote = !inquote;
                    }
                }
                numslash /= 2;          /* divide numslash by two */
            }

            /* copy slashes */
            while (numslash--)
            {
                *pdst++ = W!('\\');
            }

            /* if at end of arg, break loop */
            if (*psrc == W!('\0') || (!inquote && (*psrc == W!(' ') || *psrc == W!('\t'))))
                break;

            /* copy character into argument */
            if (copychar)
            {
                *pdst++ = *psrc;
            }
            ++psrc;
        }

        /* null-terminate the argument */
        *pdst++ = W!('\0');          /* terminate string */
    }

    /* We put one last argument in -- a null ptr */
    argv[(*pNumArgs)] = NULL;

    // If we hit this assert, we overwrote our destination buffer.
    // Since we're supposed to allocate for the worst
    // case, either the parsing rules have changed or our worse case
    // formula is wrong.
    assert(cast(BYTE*)pdst <= cast(BYTE*)pAlloc + cbAlloc);
    return argv;
}

// Ensure wchar literal
private template W(char c)
{
    enum wc = cast(wchar) c;
    alias W = wc;
}

unittest
{
    /// A variation of _d_run_main (Windows) which only changes `alloca` to `new`
    string[] parseArgv(wstring s)
    {
        import core.sys.windows.winnls /+: WideCharToMultiByte+/;

        const wCommandLine = s.ptr;
        immutable size_t wCommandLineLength = wcslen(wCommandLine);
        int wargc = 0;
        auto wargs = commandLineToArgv(wCommandLine, &wargc);

        char[][] args = new char[][wargc];

        // This is required because WideCharToMultiByte requires int as input.
        assert(wCommandLineLength <= cast(size_t) int.max, "Wide char command line length must not exceed int.max");

        immutable size_t totalArgsLength = 
            WideCharToMultiByte(CP_UTF8, 0, wCommandLine, cast(int)wCommandLineLength, null, 0, null, null);
        {
            char* totalArgsBuff = (new char[totalArgsLength]).ptr;
            size_t j = 0;
            foreach (i; 0 .. wargc)
            {
                immutable size_t wlen = wcslen(wargs[i]);
                assert(wlen <= cast(size_t) int.max, "wlen cannot exceed int.max");
                immutable int len = WideCharToMultiByte(CP_UTF8, 0, &wargs[i][0], cast(int) wlen, null, 0, null, null);
                args[i] = totalArgsBuff[j .. j + len];
                if (len == 0)
                    continue;
                j += len;
                assert(j <= totalArgsLength);
                WideCharToMultiByte(CP_UTF8, 0, &wargs[i][0], cast(int) wlen, &args[i][0], len, null, null);
            }
        }
        LocalFree(wargs);
        wargs = null;
        wargc = 0;

        return cast(string[])args;
    }

    // From https://docs.microsoft.com/en-us/cpp/c-language/parsing-c-command-line-arguments?view=vs-2019
    assert(parseArgv(`C:\test\demo.exe "abc" d e`w) == [`C:\test\demo.exe`, `abc`, `d`, `e`]);
    assert(parseArgv(`C:\test\demo.exe a\\\b d"e f"g h`w) == [`C:\test\demo.exe`, `a\\\b`, `de fg`, `h`]);
    assert(parseArgv(`C:\test\demo.exe a\\\"b c d`w) == [`C:\test\demo.exe`, `a\"b`, `c`, `d`]);
    assert(parseArgv(`C:\test\demo.exe "abc" d e`w) == [`C:\test\demo.exe`, `abc`, `d`, `e`]);
    assert(parseArgv(`C:\test\demo.exe a\\\\"b c" d e`w) == [`C:\test\demo.exe`, `a\\b c`, `d`, `e`]);
    // Issue 19502: windows command line arguments wrongly split
    assert(parseArgv(`"C:\test\"\blah.exe`w) == [`C:\test\\blah.exe`]);
}