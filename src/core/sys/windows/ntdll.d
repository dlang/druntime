/***********************************************************************\
*                                ntdll.d                                *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*             Translated from MinGW API for MS-Windows 3.10             *
*                           by Stewart Gordon                           *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/
module core.sys.windows.ntdll;
nothrow @nogc:
version(Windows):

private import core.sys.windows.w32api;


enum SHUTDOWN_ACTION {
        ShutdownNoReboot,
        ShutdownReboot,
        ShutdownPowerOff
}

extern (Windows) uint NtShutdownSystem(SHUTDOWN_ACTION Action);
