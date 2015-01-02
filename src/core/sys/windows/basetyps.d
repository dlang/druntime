/***********************************************************************\
*                               basetyps.d                              *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*             Translated from MinGW API for MS-Windows 3.10             *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/
module core.sys.windows.basetyps;
nothrow @nogc:
version(Windows):

private import core.sys.windows.windef, core.sys.windows.basetsd;

align(1) struct GUID {  // size is 16
        DWORD   Data1;
        WORD    Data2;
        WORD    Data3;
        BYTE[8] Data4;
}
alias GUID UUID, IID, CLSID, FMTID, uuid_t;
alias GUID* LPGUID, LPCLSID, LPIID;
alias const(GUID)* REFGUID, REFIID, REFCLSID, REFFMTID;

alias uint error_status_t, PROPID;
