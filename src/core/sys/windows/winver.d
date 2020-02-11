/**
 * Windows API header module
 *
 * Translated from MinGW Windows headers
 *
 * Authors: Stewart Gordon
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 * Source: $(DRUNTIMESRC src/core/sys/windows/_winver.d)
 */
module core.sys.windows.winver;
version (Windows):

version (ANSI) {} else version = Unicode;
pragma(lib, "version");

private import core.sys.windows.windef;

//
// _WIN32_WINNT version enumants
//
enum _WIN32_WINNT_NT4                    = 0x0400;
enum _WIN32_WINNT_WIN2K                  = 0x0500;
enum _WIN32_WINNT_WINXP                  = 0x0501;
enum _WIN32_WINNT_WS03                   = 0x0502;
enum _WIN32_WINNT_WIN6                   = 0x0600;
enum _WIN32_WINNT_VISTA                  = 0x0600;
enum _WIN32_WINNT_WS08                   = 0x0600;
enum _WIN32_WINNT_LONGHORN               = 0x0600;
enum _WIN32_WINNT_WIN7                   = 0x0601;
enum _WIN32_WINNT_WIN8                   = 0x0602;
enum _WIN32_WINNT_WINBLUE                = 0x0603;
enum _WIN32_WINNT_WIN10					 = 0x0A00;

//
// _WIN32_IE_ version enumants
//
enum _WIN32_IE_IE20                      = 0x0200;
enum _WIN32_IE_IE30                      = 0x0300;
enum _WIN32_IE_IE302                     = 0x0302;
enum _WIN32_IE_IE40                      = 0x0400;
enum _WIN32_IE_IE401                     = 0x0401;
enum _WIN32_IE_IE50                      = 0x0500;
enum _WIN32_IE_IE501                     = 0x0501;
enum _WIN32_IE_IE55                      = 0x0550;
enum _WIN32_IE_IE60                      = 0x0600;
enum _WIN32_IE_IE60SP1                   = 0x0601;
enum _WIN32_IE_IE60SP2                   = 0x0603;
enum _WIN32_IE_IE70                      = 0x0700;
enum _WIN32_IE_IE80                      = 0x0800;
enum _WIN32_IE_IE90                      = 0x0900;
enum _WIN32_IE_IE100                     = 0x0A00;

//
// IE <-> OS version mapping
//
// NT4 supports IE versions 2.0 -> 6.0 SP1
enum _WIN32_IE_NT4                    =  _WIN32_IE_IE20;
enum _WIN32_IE_NT4SP1                 =  _WIN32_IE_IE20;
enum _WIN32_IE_NT4SP2                 =  _WIN32_IE_IE20;
enum _WIN32_IE_NT4SP3                 =  _WIN32_IE_IE302;
enum _WIN32_IE_NT4SP4                 =  _WIN32_IE_IE401;
enum _WIN32_IE_NT4SP5                 =  _WIN32_IE_IE401;
enum _WIN32_IE_NT4SP6                 =  _WIN32_IE_IE50;
// Win98 supports IE versions 4.01 -> 6.0 SP1
enum _WIN32_IE_WIN98                  =  _WIN32_IE_IE401;
// Win98SE supports IE versions 5.0 -> 6.0 SP1
enum _WIN32_IE_WIN98SE                =  _WIN32_IE_IE50;
// WinME supports IE versions 5.5 -> 6.0 SP1
enum _WIN32_IE_WINME                  =  _WIN32_IE_IE55;
// Win2k supports IE versions 5.01 -> 6.0 SP1
enum _WIN32_IE_WIN2K                  =  _WIN32_IE_IE501;
enum _WIN32_IE_WIN2KSP1               =  _WIN32_IE_IE501;
enum _WIN32_IE_WIN2KSP2               =  _WIN32_IE_IE501;
enum _WIN32_IE_WIN2KSP3               =  _WIN32_IE_IE501;
enum _WIN32_IE_WIN2KSP4               =  _WIN32_IE_IE501;
enum _WIN32_IE_XP                     =  _WIN32_IE_IE60;
enum _WIN32_IE_XPSP1                  =  _WIN32_IE_IE60SP1;
enum _WIN32_IE_XPSP2                  =  _WIN32_IE_IE60SP2;
enum _WIN32_IE_WS03                      = 0x0602;
enum _WIN32_IE_WS03SP1                =  _WIN32_IE_IE60SP2;
enum _WIN32_IE_WIN6                   =  _WIN32_IE_IE70;
enum _WIN32_IE_LONGHORN               =  _WIN32_IE_IE70;
enum _WIN32_IE_WIN7                   =  _WIN32_IE_IE80;
enum _WIN32_IE_WIN8                   =  _WIN32_IE_IE100;
enum _WIN32_IE_WINBLUE                =  _WIN32_IE_IE100;


//
// NTDDI version enumants
//
enum NTDDI_WIN2K                         = 0x05000000;
enum NTDDI_WIN2KSP1                      = 0x05000100;
enum NTDDI_WIN2KSP2                      = 0x05000200;
enum NTDDI_WIN2KSP3                      = 0x05000300;
enum NTDDI_WIN2KSP4                      = 0x05000400;

enum NTDDI_WINXP                         = 0x05010000;
enum NTDDI_WINXPSP1                      = 0x05010100;
enum NTDDI_WINXPSP2                      = 0x05010200;
enum NTDDI_WINXPSP3                      = 0x05010300;
enum NTDDI_WINXPSP4                      = 0x05010400;

enum NTDDI_WS03                          = 0x05020000;
enum NTDDI_WS03SP1                       = 0x05020100;
enum NTDDI_WS03SP2                       = 0x05020200;
enum NTDDI_WS03SP3                       = 0x05020300;
enum NTDDI_WS03SP4                       = 0x05020400;

enum NTDDI_WIN6                          = 0x06000000;
enum NTDDI_WIN6SP1                       = 0x06000100;
enum NTDDI_WIN6SP2                       = 0x06000200;
enum NTDDI_WIN6SP3                       = 0x06000300;
enum NTDDI_WIN6SP4                       = 0x06000400;

enum NTDDI_VISTA                       = NTDDI_WIN6;
enum NTDDI_VISTASP1                    = NTDDI_WIN6SP1;
enum NTDDI_VISTASP2                    = NTDDI_WIN6SP2;
enum NTDDI_VISTASP3                    = NTDDI_WIN6SP3;
enum NTDDI_VISTASP4                    = NTDDI_WIN6SP4;

enum NTDDI_LONGHORN= NTDDI_VISTA;

enum NTDDI_WS08                        = NTDDI_WIN6SP1;
enum NTDDI_WS08SP2                     = NTDDI_WIN6SP2;
enum NTDDI_WS08SP3                     = NTDDI_WIN6SP3;
enum NTDDI_WS08SP4                     = NTDDI_WIN6SP4;

enum NTDDI_WIN7                          = 0x06010000;
enum NTDDI_WIN8                          = 0x06020000;
enum NTDDI_WINBLUE                       = 0x06030000;


//
// masks for version macros
//
enum OSVERSION_MASK      = 0xFFFF0000;
enum SPVERSION_MASK      = 0x0000FF00;
enum SUBVERSION_MASK     = 0x000000FF;

enum  _WIN32_WINNT   = 0x0603;

enum NTDDI_VERSION   = 0x06030000;
enum WINVER       =  _WIN32_WINNT;

// set _WIN32_IE based on _WIN32_WINNT
static if (_WIN32_WINNT <= _WIN32_WINNT_NT4)
	enum _WIN32_IE    =  _WIN32_IE_IE50;
else static if (_WIN32_WINNT <= _WIN32_WINNT_WIN2K)
	enum _WIN32_IE    =  _WIN32_IE_IE501;
else static if (_WIN32_WINNT <= _WIN32_WINNT_WINXP)
	enum _WIN32_IE    =  _WIN32_IE_IE60;
else static if (_WIN32_WINNT <= _WIN32_WINNT_WS03)
	enum _WIN32_IE    =  _WIN32_IE_WS03;
else static if (_WIN32_WINNT <= _WIN32_WINNT_VISTA)
	enum _WIN32_IE    =  _WIN32_IE_LONGHORN;
else static if (_WIN32_WINNT <= _WIN32_WINNT_WIN7)
	enum _WIN32_IE    =  _WIN32_IE_WIN7;
else static if (_WIN32_WINNT <= _WIN32_WINNT_WIN8)
	enum _WIN32_IE    =  _WIN32_IE_WIN8;
else
	enum _WIN32_IE       = 0x0A00;

// FIXME: type weirdness
enum {
    VS_FILE_INFO    =  16,
    VS_VERSION_INFO =   1,
    VS_USER_DEFINED = 100
}

enum {
    VS_FFI_SIGNATURE     = 0xFEEF04BD,
    VS_FFI_STRUCVERSION  =    0x10000,
    VS_FFI_FILEFLAGSMASK =       0x3F
}

enum {
    VS_FF_DEBUG        =  1,
    VS_FF_PRERELEASE   =  2,
    VS_FF_PATCHED      =  4,
    VS_FF_PRIVATEBUILD =  8,
    VS_FF_INFOINFERRED = 16,
    VS_FF_SPECIALBUILD = 32
}

enum {
    VOS_UNKNOWN       =       0,
    VOS_DOS           = 0x10000,
    VOS_OS216         = 0x20000,
    VOS_OS232         = 0x30000,
    VOS_NT            = 0x40000,
    VOS__BASE         =       0,
    VOS__WINDOWS16    =       1,
    VOS__PM16         =       2,
    VOS__PM32         =       3,
    VOS__WINDOWS32    =       4,
    VOS_DOS_WINDOWS16 = 0x10001,
    VOS_DOS_WINDOWS32 = 0x10004,
    VOS_OS216_PM16    = 0x20002,
    VOS_OS232_PM32    = 0x30003,
    VOS_NT_WINDOWS32  = 0x40004
}

enum {
    VFT_UNKNOWN    = 0,
    VFT_APP        = 1,
    VFT_DLL        = 2,
    VFT_DRV        = 3,
    VFT_FONT       = 4,
    VFT_VXD        = 5,
    VFT_STATIC_LIB = 7
}

enum {
    VFT2_UNKNOWN         =  0,
    VFT2_DRV_PRINTER     =  1,
    VFT2_DRV_KEYBOARD    =  2,
    VFT2_DRV_LANGUAGE    =  3,
    VFT2_DRV_DISPLAY     =  4,
    VFT2_DRV_MOUSE       =  5,
    VFT2_DRV_NETWORK     =  6,
    VFT2_DRV_SYSTEM      =  7,
    VFT2_DRV_INSTALLABLE =  8,
    VFT2_DRV_SOUND       =  9,
    VFT2_DRV_COMM        = 10,
    VFT2_DRV_INPUTMETHOD = 11,
    VFT2_FONT_RASTER     =  1,
    VFT2_FONT_VECTOR     =  2,
    VFT2_FONT_TRUETYPE   =  3
}

enum : DWORD {
    VFFF_ISSHAREDFILE = 1
}

enum : DWORD {
    VFF_CURNEDEST    = 1,
    VFF_FILEINUSE    = 2,
    VFF_BUFFTOOSMALL = 4
}

enum : DWORD {
    VIFF_FORCEINSTALL  = 1,
    VIFF_DONTDELETEOLD
}

enum {
    VIF_TEMPFILE         = 0x00001,
    VIF_MISMATCH         = 0x00002,
    VIF_SRCOLD           = 0x00004,
    VIF_DIFFLANG         = 0x00008,
    VIF_DIFFCODEPG       = 0x00010,
    VIF_DIFFTYPE         = 0x00020,
    VIF_WRITEPROT        = 0x00040,
    VIF_FILEINUSE        = 0x00080,
    VIF_OUTOFSPACE       = 0x00100,
    VIF_ACCESSVIOLATION  = 0x00200,
    VIF_SHARINGVIOLATION = 0x00400,
    VIF_CANNOTCREATE     = 0x00800,
    VIF_CANNOTDELETE     = 0x01000,
    VIF_CANNOTRENAME     = 0x02000,
    VIF_CANNOTDELETECUR  = 0x04000,
    VIF_OUTOFMEMORY      = 0x08000,
    VIF_CANNOTREADSRC    = 0x10000,
    VIF_CANNOTREADDST    = 0x20000,
    VIF_BUFFTOOSMALL     = 0x40000
}

struct VS_FIXEDFILEINFO {
    DWORD dwSignature;
    DWORD dwStrucVersion;
    DWORD dwFileVersionMS;
    DWORD dwFileVersionLS;
    DWORD dwProductVersionMS;
    DWORD dwProductVersionLS;
    DWORD dwFileFlagsMask;
    DWORD dwFileFlags;
    DWORD dwFileOS;
    DWORD dwFileType;
    DWORD dwFileSubtype;
    DWORD dwFileDateMS;
    DWORD dwFileDateLS;
}

extern (Windows) {
    DWORD VerFindFileA(DWORD, LPCSTR, LPCSTR, LPCSTR, LPSTR, PUINT, LPSTR,
      PUINT);
    DWORD VerFindFileW(DWORD, LPCWSTR, LPCWSTR, LPCWSTR, LPWSTR, PUINT, LPWSTR,
      PUINT);
    DWORD VerInstallFileA(DWORD, LPCSTR, LPCSTR, LPCSTR, LPCSTR, LPCSTR, LPSTR,
      PUINT);
    DWORD VerInstallFileW(DWORD, LPCWSTR, LPCWSTR, LPCWSTR, LPCWSTR, LPCWSTR,
      LPWSTR, PUINT);
    DWORD GetFileVersionInfoSizeA(LPCSTR, PDWORD);
    DWORD GetFileVersionInfoSizeW(LPCWSTR, PDWORD);
    BOOL GetFileVersionInfoA(LPCSTR, DWORD, DWORD, PVOID);
    BOOL GetFileVersionInfoW(LPCWSTR, DWORD, DWORD, PVOID);
    DWORD VerLanguageNameA(DWORD, LPSTR, DWORD);
    DWORD VerLanguageNameW(DWORD, LPWSTR, DWORD);
    BOOL VerQueryValueA(LPCVOID, LPCSTR, LPVOID*, PUINT);
    BOOL VerQueryValueW(LPCVOID, LPCWSTR, LPVOID*, PUINT);
}

version (Unicode) {
    alias VerFindFileW VerFindFile;
    alias VerQueryValueW VerQueryValue;
    alias VerInstallFileW VerInstallFile;
    alias GetFileVersionInfoSizeW GetFileVersionInfoSize;
    alias GetFileVersionInfoW GetFileVersionInfo;
    alias VerLanguageNameW VerLanguageName;
    alias VerQueryValueW VerQueryValue;
} else {
    alias VerQueryValueA VerQueryValue;
    alias VerFindFileA VerFindFile;
    alias VerInstallFileA VerInstallFile;
    alias GetFileVersionInfoSizeA GetFileVersionInfoSize;
    alias GetFileVersionInfoA GetFileVersionInfo;
    alias VerLanguageNameA VerLanguageName;
    alias VerQueryValueA VerQueryValue;
}

alias VERSIONHELPERAPI = BOOL;
VERSIONHELPERAPI IsWindowsVersionOrGreater(WORD wMajorVersion, WORD wMinorVersion, WORD wServicePackMajor)
{
	OSVERSIONINFOEXW osvi;
	const DWORDLONG dwlConditionMask = VerSetConditionMask(
		VerSetConditionMask(
			VerSetConditionMask(
				0, VER_MAJORVERSION, VER_GREATER_EQUAL),
			VER_MINORVERSION, VER_GREATER_EQUAL),
		VER_SERVICEPACKMAJOR, VER_GREATER_EQUAL);
	osvi.dwMajorVersion = wMajorVersion;
	osvi.dwMinorVersion = wMinorVersion;
	osvi.wServicePackMajor = wServicePackMajor;
	
	return VerifyVersionInfoW(&osvi, VER_MAJORVERSION | VER_MINORVERSION | VER_SERVICEPACKMAJOR, dwlConditionMask) != FALSE;
}

VERSIONHELPERAPI
	IsWindowsXPOrGreater()
{
	return IsWindowsVersionOrGreater(HIBYTE(_WIN32_WINNT_WINXP), LOBYTE(_WIN32_WINNT_WINXP), 0);
}

VERSIONHELPERAPI
	IsWindowsXPSP1OrGreater()
{
	return IsWindowsVersionOrGreater(HIBYTE(_WIN32_WINNT_WINXP), LOBYTE(_WIN32_WINNT_WINXP), 1);
}

VERSIONHELPERAPI
	IsWindowsXPSP2OrGreater()
{
	return IsWindowsVersionOrGreater(HIBYTE(_WIN32_WINNT_WINXP), LOBYTE(_WIN32_WINNT_WINXP), 2);
}

VERSIONHELPERAPI
	IsWindowsXPSP3OrGreater()
{
	return IsWindowsVersionOrGreater(HIBYTE(_WIN32_WINNT_WINXP), LOBYTE(_WIN32_WINNT_WINXP), 3);
}

VERSIONHELPERAPI
	IsWindowsVistaOrGreater()
{
	return IsWindowsVersionOrGreater(HIBYTE(_WIN32_WINNT_VISTA), LOBYTE(_WIN32_WINNT_VISTA), 0);
}

VERSIONHELPERAPI
	IsWindowsVistaSP1OrGreater()
{
	return IsWindowsVersionOrGreater(HIBYTE(_WIN32_WINNT_VISTA), LOBYTE(_WIN32_WINNT_VISTA), 1);
}

VERSIONHELPERAPI
	IsWindowsVistaSP2OrGreater()
{
	return IsWindowsVersionOrGreater(HIBYTE(_WIN32_WINNT_VISTA), LOBYTE(_WIN32_WINNT_VISTA), 2);
}

VERSIONHELPERAPI
	IsWindows7OrGreater()
{
	return IsWindowsVersionOrGreater(HIBYTE(_WIN32_WINNT_WIN7), LOBYTE(_WIN32_WINNT_WIN7), 0);
}

VERSIONHELPERAPI
	IsWindows7SP1OrGreater()
{
	return IsWindowsVersionOrGreater(HIBYTE(_WIN32_WINNT_WIN7), LOBYTE(_WIN32_WINNT_WIN7), 1);
}

VERSIONHELPERAPI
	IsWindows8OrGreater()
{
	return IsWindowsVersionOrGreater(HIBYTE(_WIN32_WINNT_WIN8), LOBYTE(_WIN32_WINNT_WIN8), 0);
}

VERSIONHELPERAPI
	IsWindows8Point1OrGreater()
{
	return IsWindowsVersionOrGreater(HIBYTE(_WIN32_WINNT_WINBLUE), LOBYTE(_WIN32_WINNT_WINBLUE), 0);
}

VERSIONHELPERAPI
	IsWindows10OrGreater()
{
	return IsWindowsVersionOrGreater(HIBYTE(_WIN32_WINNT_WIN10), LOBYTE(_WIN32_WINNT_WIN10), 0);
}


VERSIONHELPERAPI
	IsWindowsServer()
{
	OSVERSIONINFOEXW osvi = { OSVERSIONINFOEXW.sizeof, 0, 0, 0, 0, [0], 0, 0, 0, VER_NT_WORKSTATION };
	const DWORDLONG        dwlConditionMask = VerSetConditionMask( 0, VER_PRODUCT_TYPE, VER_EQUAL );

	return !VerifyVersionInfoW(&osvi, VER_PRODUCT_TYPE, dwlConditionMask);
}
