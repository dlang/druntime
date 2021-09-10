/**
 * Windows API header module
 *
 * Translated from MinGW Windows headers
 *
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 * Source: $(DRUNTIMESRC core/sys/windows/_imm.d)
 */
module core.sys.windows.imm;
version (Windows):
@system:

version (ANSI) {} else version = Unicode;
pragma(lib, "imm32");

import core.sys.windows.windef, core.sys.windows.wingdi;
import core.sys.windows.winuser; // for the MFS_xxx enums.
import core.sys.windows.w32api;

enum WM_CONVERTREQUESTEX     = 0x108;
enum WM_IME_STARTCOMPOSITION = 0x10D;
enum WM_IME_ENDCOMPOSITION   = 0x10E;
enum WM_IME_COMPOSITION      = 0x10F;
enum WM_IME_KEYLAST          = 0x10F;
enum WM_IME_SETCONTEXT       = 0x281;
enum WM_IME_NOTIFY           = 0x282;
enum WM_IME_CONTROL          = 0x283;
enum WM_IME_COMPOSITIONFULL  = 0x284;
enum WM_IME_SELECT           = 0x285;
enum WM_IME_CHAR             = 0x286;
//static if (_WIN32_WINNT >= 0x500) {
enum WM_IME_REQUEST      = 0x288;
//}
enum WM_IME_KEYDOWN          = 0x290;
enum WM_IME_KEYUP            = 0x291;


enum IMC_GETCANDIDATEPOS=7;
enum IMC_SETCANDIDATEPOS=8;
enum IMC_GETCOMPOSITIONFONT=9;
enum IMC_SETCOMPOSITIONFONT=10;
enum IMC_GETCOMPOSITIONWINDOW=11;
enum IMC_SETCOMPOSITIONWINDOW=12;
enum IMC_GETSTATUSWINDOWPOS=15;
enum IMC_SETSTATUSWINDOWPOS=16;
enum IMC_CLOSESTATUSWINDOW=0x21;
enum IMC_OPENSTATUSWINDOW=0x22;
enum IMN_CLOSESTATUSWINDOW=1;
enum IMN_OPENSTATUSWINDOW=2;
enum IMN_CHANGECANDIDATE=3;
enum IMN_CLOSECANDIDATE=4;
enum IMN_OPENCANDIDATE=5;
enum IMN_SETCONVERSIONMODE=6;
enum IMN_SETSENTENCEMODE=7;
enum IMN_SETOPENSTATUS=8;
enum IMN_SETCANDIDATEPOS=9;
enum IMN_SETCOMPOSITIONFONT=10;
enum IMN_SETCOMPOSITIONWINDOW=11;
enum IMN_SETSTATUSWINDOWPOS=12;
enum IMN_GUIDELINE=13;
enum IMN_PRIVATE=14;

enum NI_OPENCANDIDATE=16;
enum NI_CLOSECANDIDATE=17;
enum NI_SELECTCANDIDATESTR=18;
enum NI_CHANGECANDIDATELIST=19;
enum NI_FINALIZECONVERSIONRESULT=20;
enum NI_COMPOSITIONSTR=21;
enum NI_SETCANDIDATE_PAGESTART=22;
enum NI_SETCANDIDATE_PAGESIZE=23;
enum NI_IMEMENUSELECTED=24;

enum ISC_SHOWUICANDIDATEWINDOW=1;
enum ISC_SHOWUICOMPOSITIONWINDOW=0x80000000;
enum ISC_SHOWUIGUIDELINE=0x40000000;
enum ISC_SHOWUIALLCANDIDATEWINDOW=15;
enum ISC_SHOWUIALL=0xC000000F;

enum CPS_COMPLETE=1;
enum CPS_CONVERT=2;
enum CPS_REVERT=3;
enum CPS_CANCEL=4;

enum IME_CHOTKEY_IME_NONIME_TOGGLE=16;
enum IME_CHOTKEY_SHAPE_TOGGLE=17;
enum IME_CHOTKEY_SYMBOL_TOGGLE=18;
enum IME_JHOTKEY_CLOSE_OPEN=0x30;
enum IME_KHOTKEY_SHAPE_TOGGLE=0x50;
enum IME_KHOTKEY_HANJACONVERT=0x51;
enum IME_KHOTKEY_ENGLISH=0x52;
enum IME_THOTKEY_IME_NONIME_TOGGLE=0x70;
enum IME_THOTKEY_SHAPE_TOGGLE=0x71;
enum IME_THOTKEY_SYMBOL_TOGGLE=0x72;
enum IME_HOTKEY_DSWITCH_FIRST=256;
enum IME_HOTKEY_DSWITCH_LAST=0x11F;
enum IME_ITHOTKEY_RESEND_RESULTSTR=512;
enum IME_ITHOTKEY_PREVIOUS_COMPOSITION=513;
enum IME_ITHOTKEY_UISTYLE_TOGGLE=514;

enum GCS_COMPREADSTR=1;
enum GCS_COMPREADATTR=2;
enum GCS_COMPREADCLAUSE=4;
enum GCS_COMPSTR=8;
enum GCS_COMPATTR=16;
enum GCS_COMPCLAUSE=32;
enum GCS_CURSORPOS=128;
enum GCS_DELTASTART=256;
enum GCS_RESULTREADSTR=512;
enum GCS_RESULTREADCLAUSE=1024;
enum GCS_RESULTSTR=2048;
enum GCS_RESULTCLAUSE=4096;

enum CS_INSERTCHAR=0x2000;
enum CS_NOMOVECARET=0x4000;

enum IMEVER_0310=0x3000A;
enum IMEVER_0400=0x40000;

enum IME_PROP_AT_CARET=0x10000;
enum IME_PROP_SPECIAL_UI=0x20000;
enum IME_PROP_CANDLIST_START_FROM_1=0x40000;
enum IME_PROP_UNICODE=0x80000;

enum UI_CAP_2700=1;
enum UI_CAP_ROT90=2;
enum UI_CAP_ROTANY=4;

enum SCS_CAP_COMPSTR=1;
enum SCS_CAP_MAKEREAD=2;
enum SELECT_CAP_CONVERSION=1;
enum SELECT_CAP_SENTENCE=2;
enum GGL_LEVEL=1;
enum GGL_INDEX=2;
enum GGL_STRING=3;
enum GGL_PRIVATE=4;
enum GL_LEVEL_NOGUIDELINE=0;
enum GL_LEVEL_FATAL=1;
enum GL_LEVEL_ERROR=2;
enum GL_LEVEL_WARNING=3;
enum GL_LEVEL_INFORMATION=4;
enum GL_ID_UNKNOWN=0;
enum GL_ID_NOMODULE=1;
enum GL_ID_NODICTIONARY=16;
enum GL_ID_CANNOTSAVE=17;
enum GL_ID_NOCONVERT=32;
enum GL_ID_TYPINGERROR=33;
enum GL_ID_TOOMANYSTROKE=34;
enum GL_ID_READINGCONFLICT=35;
enum GL_ID_INPUTREADING=36;
enum GL_ID_INPUTRADICAL=37;
enum GL_ID_INPUTCODE=38;
enum GL_ID_INPUTSYMBOL=39;
enum GL_ID_CHOOSECANDIDATE=40;
enum GL_ID_REVERSECONVERSION=41;
enum GL_ID_PRIVATE_FIRST=0x8000;
enum GL_ID_PRIVATE_LAST=0xFFFF;

enum DWORD IGP_GETIMEVERSION = -4;
enum IGP_PROPERTY=4;
enum IGP_CONVERSION=8;
enum IGP_SENTENCE=12;
enum IGP_UI=16;
enum IGP_SETCOMPSTR=0x14;
enum IGP_SELECT=0x18;

enum SCS_SETSTR       = GCS_COMPREADSTR|GCS_COMPSTR;
enum SCS_CHANGEATTR   = GCS_COMPREADATTR|GCS_COMPATTR;
enum SCS_CHANGECLAUSE = GCS_COMPREADCLAUSE|GCS_COMPCLAUSE;

enum ATTR_INPUT=0;
enum ATTR_TARGET_CONVERTED=1;
enum ATTR_CONVERTED=2;
enum ATTR_TARGET_NOTCONVERTED=3;
enum ATTR_INPUT_ERROR=4;
enum ATTR_FIXEDCONVERTED=5;
enum CFS_DEFAULT=0;
enum CFS_RECT=1;
enum CFS_POINT=2;
enum CFS_SCREEN=4;
enum CFS_FORCE_POSITION=32;
enum CFS_CANDIDATEPOS=64;
enum CFS_EXCLUDE=128;
enum GCL_CONVERSION=1;
enum GCL_REVERSECONVERSION=2;
enum GCL_REVERSE_LENGTH=3;

enum IME_CMODE_ALPHANUMERIC=0;
enum IME_CMODE_NATIVE=1;
enum IME_CMODE_CHINESE=IME_CMODE_NATIVE;
enum IME_CMODE_HANGEUL=IME_CMODE_NATIVE;
enum IME_CMODE_HANGUL=IME_CMODE_NATIVE;
enum IME_CMODE_JAPANESE=IME_CMODE_NATIVE;
enum IME_CMODE_KATAKANA=2;
enum IME_CMODE_LANGUAGE=3;
enum IME_CMODE_FULLSHAPE=8;
enum IME_CMODE_ROMAN=16;
enum IME_CMODE_CHARCODE=32;
enum IME_CMODE_HANJACONVERT=64;
enum IME_CMODE_SOFTKBD=128;
enum IME_CMODE_NOCONVERSION=256;
enum IME_CMODE_EUDC=512;
enum IME_CMODE_SYMBOL=1024;
enum IME_CMODE_FIXED=2048;
enum IME_SMODE_NONE=0;
enum IME_SMODE_PLAURALCLAUSE=1;
enum IME_SMODE_SINGLECONVERT=2;
enum IME_SMODE_AUTOMATIC=4;
enum IME_SMODE_PHRASEPREDICT=8;
enum IME_CAND_UNKNOWN=0;
enum IME_CAND_READ=1;
enum IME_CAND_CODE=2;
enum IME_CAND_MEANING=3;
enum IME_CAND_RADICAL=4;
enum IME_CAND_STROKE=5;
enum IMM_ERROR_NODATA=(-1);
enum IMM_ERROR_GENERAL=(-2);
enum IME_CONFIG_GENERAL=1;
enum IME_CONFIG_REGISTERWORD=2;
enum IME_CONFIG_SELECTDICTIONARY=3;
enum IME_ESC_QUERY_SUPPORT=3;
enum IME_ESC_RESERVED_FIRST=4;
enum IME_ESC_RESERVED_LAST=0x7FF;
enum IME_ESC_PRIVATE_FIRST=0x800;
enum IME_ESC_PRIVATE_LAST=0xFFF;
enum IME_ESC_SEQUENCE_TO_INTERNAL=0x1001;
enum IME_ESC_GET_EUDC_DICTIONARY=0x1003;
enum IME_ESC_SET_EUDC_DICTIONARY=0x1004;
enum IME_ESC_MAX_KEY=0x1005;
enum IME_ESC_IME_NAME=0x1006;
enum IME_ESC_SYNC_HOTKEY=0x1007;
enum IME_ESC_HANJA_MODE=0x1008;
enum IME_ESC_AUTOMATA=0x1009;
enum IME_REGWORD_STYLE_EUDC=1;
enum IME_REGWORD_STYLE_USER_FIRST=0x80000000;
enum IME_REGWORD_STYLE_USER_LAST=0xFFFFFFFF;

enum SOFTKEYBOARD_TYPE_T1=1;
enum SOFTKEYBOARD_TYPE_C1=2;

enum IMEMENUITEM_STRING_SIZE=80;

enum MOD_ALT=1;
enum MOD_CONTROL=2;
enum MOD_SHIFT=4;
enum MOD_WIN=8;
enum MOD_IGNORE_ALL_MODIFIER=1024;
enum MOD_ON_KEYUP=2048;
enum MOD_RIGHT=16384;
enum MOD_LEFT=32768;

enum IACE_CHILDREN=1;
enum IACE_DEFAULT=16;
enum IACE_IGNORENOCONTEXT=32;

enum IGIMIF_RIGHTMENU=1;

enum IGIMII_CMODE=1;
enum IGIMII_SMODE=2;
enum IGIMII_CONFIGURE=4;
enum IGIMII_TOOLS=8;
enum IGIMII_HELP=16;
enum IGIMII_OTHER=32;
enum IGIMII_INPUTTOOLS=64;

enum IMFT_RADIOCHECK=1;
enum IMFT_SEPARATOR=2;
enum IMFT_SUBMENU=4;

enum IMFS_GRAYED=MFS_GRAYED;
enum IMFS_DISABLED=MFS_DISABLED;
enum IMFS_CHECKED=MFS_CHECKED;
enum IMFS_HILITE=MFS_HILITE;
enum IMFS_ENABLED=MFS_ENABLED;
enum IMFS_UNCHECKED=MFS_UNCHECKED;
enum IMFS_UNHILITE=MFS_UNHILITE;
enum IMFS_DEFAULT=MFS_DEFAULT;

enum STYLE_DESCRIPTION_SIZE=32;

alias DWORD HIMC;
alias DWORD HIMCC;
alias HKL* LPHKL;

struct COMPOSITIONFORM{
    DWORD dwStyle;
    POINT ptCurrentPos;
    RECT rcArea;
}
alias COMPOSITIONFORM* PCOMPOSITIONFORM, LPCOMPOSITIONFORM;

struct CANDIDATEFORM{
    DWORD dwIndex;
    DWORD dwStyle;
    POINT ptCurrentPos;
    RECT rcArea;
}
alias CANDIDATEFORM* PCANDIDATEFORM, LPCANDIDATEFORM;

struct CANDIDATELIST{
    DWORD dwSize;
    DWORD dwStyle;
    DWORD dwCount;
    DWORD dwSelection;
    DWORD dwPageStart;
    DWORD dwPageSize;
    DWORD[1] dwOffset;
}
alias CANDIDATELIST* PCANDIDATELIST, LPCANDIDATELIST;

struct REGISTERWORDA{
    LPSTR lpReading;
    LPSTR lpWord;
}
alias REGISTERWORDA* PREGISTERWORDA, LPREGISTERWORDA;

struct REGISTERWORDW{
    LPWSTR lpReading;
    LPWSTR lpWord;
}
alias REGISTERWORDW* PREGISTERWORDW, LPREGISTERWORDW;

struct STYLEBUFA{
    DWORD dwStyle;
    CHAR[STYLE_DESCRIPTION_SIZE] szDescription = 0;
}
alias STYLEBUFA* PSTYLEBUFA, LPSTYLEBUFA;

struct STYLEBUFW{
    DWORD dwStyle;
    WCHAR[STYLE_DESCRIPTION_SIZE] szDescription = 0;
}
alias STYLEBUFW* PSTYLEBUFW, LPSTYLEBUFW;

struct IMEMENUITEMINFOA{
    UINT cbSize = this.sizeof;
    UINT fType;
    UINT fState;
    UINT wID;
    HBITMAP hbmpChecked;
    HBITMAP hbmpUnchecked;
    DWORD dwItemData;
    CHAR[IMEMENUITEM_STRING_SIZE] szString = 0;
    HBITMAP hbmpItem;
}
alias IMEMENUITEMINFOA* PIMEMENUITEMINFOA, LPIMEMENUITEMINFOA;

struct IMEMENUITEMINFOW{
    UINT cbSize = this.sizeof;
    UINT fType;
    UINT fState;
    UINT wID;
    HBITMAP hbmpChecked;
    HBITMAP hbmpUnchecked;
    DWORD dwItemData;
    WCHAR[IMEMENUITEM_STRING_SIZE] szString = 0;
    HBITMAP hbmpItem;
}
alias IMEMENUITEMINFOW* PIMEMENUITEMINFOW, LPIMEMENUITEMINFOW;

extern (Windows) {
alias int function (LPCSTR, DWORD, LPCSTR, LPVOID)  REGISTERWORDENUMPROCA;
alias int function (LPCWSTR, DWORD, LPCWSTR, LPVOID) REGISTERWORDENUMPROCW;
}

version (Unicode) {
    alias REGISTERWORDENUMPROCW REGISTERWORDENUMPROC;
    alias REGISTERWORDW REGISTERWORD;
    alias IMEMENUITEMINFOW IMEMENUITEMINFO;
    alias STYLEBUFW STYLEBUF;
} else {
    alias REGISTERWORDENUMPROCA REGISTERWORDENUMPROC;
    alias REGISTERWORDA REGISTERWORD;
    alias IMEMENUITEMINFOA IMEMENUITEMINFO;
    alias STYLEBUFA STYLEBUF;
}

alias STYLEBUF* PSTYLEBUF, LPSTYLEBUF;
alias REGISTERWORD* PREGISTERWORD, LPREGISTERWORD;
alias IMEMENUITEMINFO* PIMEMENUITEMINFO, LPIMEMENUITEMINFO;


extern (Windows):
HKL ImmInstallIMEA(LPCSTR, LPCSTR);
HKL ImmInstallIMEW(LPCWSTR, LPCWSTR);
HWND ImmGetDefaultIMEWnd(HWND);
UINT ImmGetDescriptionA(HKL, LPSTR, UINT);
UINT ImmGetDescriptionW(HKL, LPWSTR, UINT);
UINT ImmGetIMEFileNameA(HKL, LPSTR, UINT);
UINT ImmGetIMEFileNameW(HKL, LPWSTR, UINT);
DWORD ImmGetProperty(HKL, DWORD);
BOOL ImmIsIME(HKL);
BOOL ImmSimulateHotKey(HWND, DWORD);
HIMC ImmCreateContext();
BOOL ImmDestroyContext(HIMC);
HIMC ImmGetContext(HWND);
BOOL ImmReleaseContext(HWND, HIMC);
HIMC ImmAssociateContext(HWND, HIMC);
LONG ImmGetCompositionStringA(HIMC, DWORD, PVOID, DWORD);
LONG ImmGetCompositionStringW(HIMC, DWORD, PVOID, DWORD);
BOOL ImmSetCompositionStringA(HIMC, DWORD, PCVOID, DWORD, PCVOID, DWORD);
BOOL ImmSetCompositionStringW(HIMC, DWORD, PCVOID, DWORD, PCVOID, DWORD);
DWORD ImmGetCandidateListCountA(HIMC, PDWORD);
DWORD ImmGetCandidateListCountW(HIMC, PDWORD);
DWORD ImmGetCandidateListA(HIMC, DWORD, PCANDIDATELIST, DWORD);
DWORD ImmGetCandidateListW(HIMC, DWORD, PCANDIDATELIST, DWORD);
DWORD ImmGetGuideLineA(HIMC, DWORD, LPSTR, DWORD);
DWORD ImmGetGuideLineW(HIMC, DWORD, LPWSTR, DWORD);
BOOL ImmGetConversionStatus(HIMC, LPDWORD, PDWORD);
BOOL ImmSetConversionStatus(HIMC, DWORD, DWORD);
BOOL ImmGetOpenStatus(HIMC);
BOOL ImmSetOpenStatus(HIMC, BOOL);

BOOL ImmGetCompositionFontA(HIMC, LPLOGFONTA);
BOOL ImmGetCompositionFontW(HIMC, LPLOGFONTW);
BOOL ImmSetCompositionFontA(HIMC, LPLOGFONTA);
BOOL ImmSetCompositionFontW(HIMC, LPLOGFONTW);

BOOL ImmConfigureIMEA(HKL, HWND, DWORD, PVOID);
BOOL ImmConfigureIMEW(HKL, HWND, DWORD, PVOID);
LRESULT ImmEscapeA(HKL, HIMC, UINT, PVOID);
LRESULT ImmEscapeW(HKL, HIMC, UINT, PVOID);
DWORD ImmGetConversionListA(HKL, HIMC, LPCSTR, PCANDIDATELIST, DWORD, UINT);
DWORD ImmGetConversionListW(HKL, HIMC, LPCWSTR, PCANDIDATELIST, DWORD, UINT);
BOOL ImmNotifyIME(HIMC, DWORD, DWORD, DWORD);
BOOL ImmGetStatusWindowPos(HIMC, LPPOINT);
BOOL ImmSetStatusWindowPos(HIMC, LPPOINT);
BOOL ImmGetCompositionWindow(HIMC, PCOMPOSITIONFORM);
BOOL ImmSetCompositionWindow(HIMC, PCOMPOSITIONFORM);
BOOL ImmGetCandidateWindow(HIMC, DWORD, PCANDIDATEFORM);
BOOL ImmSetCandidateWindow(HIMC, PCANDIDATEFORM);
BOOL ImmIsUIMessageA(HWND, UINT, WPARAM, LPARAM);
BOOL ImmIsUIMessageW(HWND, UINT, WPARAM, LPARAM);
UINT ImmGetVirtualKey(HWND);
BOOL ImmRegisterWordA(HKL, LPCSTR, DWORD, LPCSTR);
BOOL ImmRegisterWordW(HKL, LPCWSTR, DWORD, LPCWSTR);
BOOL ImmUnregisterWordA(HKL, LPCSTR, DWORD, LPCSTR);
BOOL ImmUnregisterWordW(HKL, LPCWSTR, DWORD, LPCWSTR);
UINT ImmGetRegisterWordStyleA(HKL, UINT, PSTYLEBUFA);
UINT ImmGetRegisterWordStyleW(HKL, UINT, PSTYLEBUFW);
UINT ImmEnumRegisterWordA(HKL, REGISTERWORDENUMPROCA, LPCSTR, DWORD, LPCSTR, PVOID);
UINT ImmEnumRegisterWordW(HKL, REGISTERWORDENUMPROCW, LPCWSTR, DWORD, LPCWSTR, PVOID);
BOOL EnableEUDC(BOOL);
BOOL ImmDisableIME(DWORD);
DWORD ImmGetImeMenuItemsA(HIMC, DWORD, DWORD, LPIMEMENUITEMINFOA, LPIMEMENUITEMINFOA, DWORD);
DWORD ImmGetImeMenuItemsW(HIMC, DWORD, DWORD, LPIMEMENUITEMINFOW, LPIMEMENUITEMINFOW, DWORD);

version (Unicode) {
    alias ImmEnumRegisterWordW ImmEnumRegisterWord;
    alias ImmGetRegisterWordStyleW ImmGetRegisterWordStyle;
    alias ImmUnregisterWordW ImmUnregisterWord;
    alias ImmRegisterWordW ImmRegisterWord;
    alias ImmInstallIMEW ImmInstallIME;
    alias ImmIsUIMessageW ImmIsUIMessage;
    alias ImmGetConversionListW ImmGetConversionList;
    alias ImmEscapeW ImmEscape;
    alias ImmConfigureIMEW ImmConfigureIME;
    alias ImmSetCompositionFontW ImmSetCompositionFont;
    alias ImmGetCompositionFontW ImmGetCompositionFont;
    alias ImmGetGuideLineW ImmGetGuideLine;
    alias ImmGetCandidateListW ImmGetCandidateList;
    alias ImmGetCandidateListCountW ImmGetCandidateListCount;
    alias ImmSetCompositionStringW ImmSetCompositionString;
    alias ImmGetCompositionStringW ImmGetCompositionString;
    alias ImmGetDescriptionW ImmGetDescription;
    alias ImmGetIMEFileNameW ImmGetIMEFileName;
    alias ImmGetImeMenuItemsW ImmGetImeMenuItems;
} else {
    alias ImmEnumRegisterWordA ImmEnumRegisterWord;
    alias ImmGetRegisterWordStyleA ImmGetRegisterWordStyle;
    alias ImmUnregisterWordA ImmUnregisterWord;
    alias ImmRegisterWordA ImmRegisterWord;
    alias ImmInstallIMEA ImmInstallIME;
    alias ImmIsUIMessageA ImmIsUIMessage;
    alias ImmGetConversionListA ImmGetConversionList;
    alias ImmEscapeA ImmEscape;
    alias ImmConfigureIMEA ImmConfigureIME;
    alias ImmSetCompositionFontA ImmSetCompositionFont;
    alias ImmGetCompositionFontA ImmGetCompositionFont;
    alias ImmGetGuideLineA ImmGetGuideLine;
    alias ImmGetCandidateListA ImmGetCandidateList;
    alias ImmGetCandidateListCountA ImmGetCandidateListCount;
    alias ImmSetCompositionStringA ImmSetCompositionString;
    alias ImmGetCompositionStringA ImmGetCompositionString;
    alias ImmGetDescriptionA ImmGetDescription;
    alias ImmGetIMEFileNameA ImmGetIMEFileName;
    alias ImmGetImeMenuItemsW ImmGetImeMenuItems;
}
