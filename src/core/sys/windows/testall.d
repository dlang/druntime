// Used only for testing -- imports all windows headers.
module core.sys.windows.testall;
nothrow @nogc:
version(Windows):

import core.sys.windows.core;
import core.sys.windows.windows;
import core.sys.windows.commctrl;
import core.sys.windows.setupapi;

import core.sys.windows.directx.dinput8;
import core.sys.windows.directx.dsound8;

import core.sys.windows.directx.d3d9;
import core.sys.windows.directx.d3dx9;
import core.sys.windows.directx.dxerr;
import core.sys.windows.directx.dxerr8;
import core.sys.windows.directx.dxerr9;

import core.sys.windows.directx.d3d10;
import core.sys.windows.directx.d3d10effect;
import core.sys.windows.directx.d3d10shader;
import core.sys.windows.directx.d3dx10;
import core.sys.windows.directx.dxgi;

import core.sys.windows.oleacc;
import core.sys.windows.comcat;
import core.sys.windows.cpl;
import core.sys.windows.cplext;
import core.sys.windows.custcntl;
import core.sys.windows.ocidl;
import core.sys.windows.olectl;
import core.sys.windows.oledlg;
import core.sys.windows.objsafe;
import core.sys.windows.ole;

import core.sys.windows.shldisp;
import core.sys.windows.shlobj;
import core.sys.windows.shlwapi;
import core.sys.windows.regstr;
import core.sys.windows.richole;
import core.sys.windows.tmschema;
import core.sys.windows.servprov;
import core.sys.windows.exdisp;
import core.sys.windows.exdispid;
import core.sys.windows.idispids;
import core.sys.windows.mshtml;

import core.sys.windows.lm;
import core.sys.windows.lmbrowsr;

import core.sys.windows.sql;
import core.sys.windows.sqlext;
import core.sys.windows.sqlucode;
import core.sys.windows.odbcinst;

import core.sys.windows.imagehlp;
import core.sys.windows.intshcut;
import core.sys.windows.iphlpapi;
import core.sys.windows.isguids;

import core.sys.windows.subauth;
import core.sys.windows.rasdlg;
import core.sys.windows.rassapi;

import core.sys.windows.mapi;
import core.sys.windows.mciavi;
import core.sys.windows.mcx;
import core.sys.windows.mgmtapi;

import core.sys.windows.nddeapi;
import core.sys.windows.msacm;
import core.sys.windows.nspapi;

import core.sys.windows.ntdef;
import core.sys.windows.ntldap;
import core.sys.windows.ntsecapi;

import core.sys.windows.pbt;
import core.sys.windows.powrprof;
import core.sys.windows.rapi;

import core.sys.windows.wininet;
import core.sys.windows.winioctl;
import core.sys.windows.winldap;

import core.sys.windows.dbt;

import core.sys.windows.rpcdce2;

import core.sys.windows.tlhelp32;

import core.sys.windows.httpext;
import core.sys.windows.lmwksta;
import core.sys.windows.mswsock;
import core.sys.windows.objidl;
import core.sys.windows.ole2ver;
import core.sys.windows.psapi;
import core.sys.windows.raserror;
import core.sys.windows.usp10;
import core.sys.windows.vfw;

version (WindowsVista) {
        version = WINDOWS_XP_UP;
} else version (Windows2003) {
        version = WINDOWS_XP_UP;
} else version (WindowsXP) {
        version = WINDOWS_XP_UP;
}

version (WINDOWS_XP_UP) {
        import core.sys.windows.errorrep;
        import core.sys.windows.lmmsg;
        import core.sys.windows.reason;
        import core.sys.windows.secext;
}
import core.sys.windows.aclapi;
import core.sys.windows.aclui;
import core.sys.windows.dhcpcsdk;
import core.sys.windows.lmserver;
import core.sys.windows.ntdll;

version (Win32_Winsock1) {
        import core.sys.windows.winsock;
}
