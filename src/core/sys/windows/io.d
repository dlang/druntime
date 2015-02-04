/**
 *  Windows is a registered trademark of Microsoft Corporation in the United
 *  States and other countries.
 *
 * Copyright: Copyright Digital Mars 2014 -.
 * License: Distributed under the
 *      $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
 *    (See accompanying file LICENSE)
 * Authors:   Jonathan M. Davis
 * Source:    $(DRUNTIMESRC core/sys/windows/_io.d)
 */
module core.sys.windows.io;

version (Windows):
extern (C):
nothrow:
@nogc:

enum
{
    _S_IREAD  = 0x0100, // read permission, owner
    _S_IWRITE = 0x0080, // write permission, owner
}

enum
{
    _SH_DENYRW = 0x10, // deny read/write mode
    _SH_DENYWR = 0x20, // deny write mode
    _SH_DENYRD = 0x30, // deny read mode
    _SH_DENYNO = 0x40, // deny none mode
}

int _wsopen(const wchar* filename, int oflag, int shflag, ...);
