/**
 * D header file for non-standard functions provided by Windows C runtimes.
 * All string arguments are expected to be UTF-16 encoded.
 *
 * Copyright: Copyright Denis Shelomovskij 2012.
 * License:   <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors:   Denis Shelomovskij
 * Source:    $(DRUNTIMESRC core/sys/windows/c/_stdio.d)
 */

module core.sys.windows.c.stdio;

version(Windows):

import core.stdc.stdio;

extern (C):
@system:
nothrow:


int _wremove(in wchar* filename);
int _wrename(in wchar* from, in wchar* to);
char* _wtmpnam(wchar* s);
FILE* _wfopen(in wchar* filename, in wchar* mode);
FILE* _wfreopen(in wchar* filename, in wchar* mode, FILE* stream);
