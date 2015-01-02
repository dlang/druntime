/***********************************************************************\
*                                wingdi.d                               *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*                 Translated from MinGW Windows headers                 *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/
module core.sys.windows.wingdi;
nothrow @nogc:
version(Windows):
pragma(lib, "gdi32");

// FIXME: clean up Windows version support

private import core.sys.windows.w32api, core.sys.windows.windef, core.sys.windows.winver;

// BITMAPINFOHEADER.biCompression
enum : DWORD {
        BI_RGB = 0,
        BI_RLE8,
        BI_RLE4,
        BI_BITFIELDS,
        BI_JPEG,
        BI_PNG
}

// ---
// COLORADJUSTMENT -- only for NT 3.1+, Win2000+
const WORD
        CA_NEGATIVE   = 1,
        CA_LOG_FILTER = 2;

// COLORADJUSTMENT
enum : WORD  {
        ILLUMINANT_DEVICE_DEFAULT = 0,
        ILLUMINANT_A,
        ILLUMINANT_B,
        ILLUMINANT_C,
        ILLUMINANT_D50,
        ILLUMINANT_D55,
        ILLUMINANT_D65,
        ILLUMINANT_D75,
        ILLUMINANT_F2,
        ILLUMINANT_MAX_INDEX   = ILLUMINANT_F2,
        ILLUMINANT_TUNGSTEN    = ILLUMINANT_A,
        ILLUMINANT_DAYLIGHT    = ILLUMINANT_C,
        ILLUMINANT_FLUORESCENT = ILLUMINANT_F2,
        ILLUMINANT_NTSC        = ILLUMINANT_C
}

enum {
        RGB_GAMMA_MIN       = 2500,
        RGB_GAMMA_MAX       = 65000,
        REFERENCE_WHITE_MIN = 6000,
        REFERENCE_WHITE_MAX = 10000,
        REFERENCE_BLACK_MIN = 0,
        REFERENCE_BLACK_MAX = 4000,
        COLOR_ADJ_MIN       = -100,
        COLOR_ADJ_MAX       = 100,
}
//---

/* FIXME: move to core.sys.windows.winuser ? */
// DrawIconEx()
enum : UINT {
        DI_MASK        = 1,
        DI_IMAGE       = 2,
        DI_NORMAL      = 3,
        DI_COMPAT      = 4,
        DI_DEFAULTSIZE = 8
}

// DOCINFO
enum : DWORD {
        DI_APPBANDING = 1,
        DI_ROPS_READ_DESTINATION = 2,
}

// ENHMETAHEADER
enum : DWORD {
        EMR_HEADER = 1,
        EMR_POLYBEZIER,
        EMR_POLYGON,
        EMR_POLYLINE,
        EMR_POLYBEZIERTO,
        EMR_POLYLINETO,
        EMR_POLYPOLYLINE,
        EMR_POLYPOLYGON,
        EMR_SETWINDOWEXTEX,
        EMR_SETWINDOWORGEX,
        EMR_SETVIEWPORTEXTEX,
        EMR_SETVIEWPORTORGEX,
        EMR_SETBRUSHORGEX,
        EMR_EOF,
        EMR_SETPIXELV,
        EMR_SETMAPPERFLAGS,
        EMR_SETMAPMODE,
        EMR_SETBKMODE,
        EMR_SETPOLYFILLMODE,
        EMR_SETROP2,
        EMR_SETSTRETCHBLTMODE,
        EMR_SETTEXTALIGN,
        EMR_SETCOLORADJUSTMENT,
        EMR_SETTEXTCOLOR,
        EMR_SETBKCOLOR,
        EMR_OFFSETCLIPRGN,
        EMR_MOVETOEX,
        EMR_SETMETARGN,
        EMR_EXCLUDECLIPRECT,
        EMR_INTERSECTCLIPRECT,
        EMR_SCALEVIEWPORTEXTEX,
        EMR_SCALEWINDOWEXTEX,
        EMR_SAVEDC,
        EMR_RESTOREDC,
        EMR_SETWORLDTRANSFORM,
        EMR_MODIFYWORLDTRANSFORM,
        EMR_SELECTOBJECT,
        EMR_CREATEPEN,
        EMR_CREATEBRUSHINDIRECT,
        EMR_DELETEOBJECT,
        EMR_ANGLEARC,
        EMR_ELLIPSE,
        EMR_RECTANGLE,
        EMR_ROUNDRECT,
        EMR_ARC,
        EMR_CHORD,
        EMR_PIE,
        EMR_SELECTPALETTE,
        EMR_CREATEPALETTE,
        EMR_SETPALETTEENTRIES,
        EMR_RESIZEPALETTE,
        EMR_REALIZEPALETTE,
        EMR_EXTFLOODFILL,
        EMR_LINETO,
        EMR_ARCTO,
        EMR_POLYDRAW,
        EMR_SETARCDIRECTION,
        EMR_SETMITERLIMIT,
        EMR_BEGINPATH,
        EMR_ENDPATH,
        EMR_CLOSEFIGURE,
        EMR_FILLPATH,
        EMR_STROKEANDFILLPATH,
        EMR_STROKEPATH,
        EMR_FLATTENPATH,
        EMR_WIDENPATH,
        EMR_SELECTCLIPPATH,
        EMR_ABORTPATH, // 68
        // reserved 69
        EMR_GDICOMMENT = 70,
        EMR_FILLRGN,
        EMR_FRAMERGN,
        EMR_INVERTRGN,
        EMR_PAINTRGN,
        EMR_EXTSELECTCLIPRGN,
        EMR_BITBLT,
        EMR_STRETCHBLT,
        EMR_MASKBLT,
        EMR_PLGBLT,
        EMR_SETDIBITSTODEVICE,
        EMR_STRETCHDIBITS,
        EMR_EXTCREATEFONTINDIRECTW,
        EMR_EXTTEXTOUTA,
        EMR_EXTTEXTOUTW,
        EMR_POLYBEZIER16,
        EMR_POLYGON16,
        EMR_POLYLINE16,
        EMR_POLYBEZIERTO16,
        EMR_POLYLINETO16,
        EMR_POLYPOLYLINE16,
        EMR_POLYPOLYGON16,
        EMR_POLYDRAW16,
        EMR_CREATEMONOBRUSH,
        EMR_CREATEDIBPATTERNBRUSHPT,
        EMR_EXTCREATEPEN,
        EMR_POLYTEXTOUTA,
        EMR_POLYTEXTOUTW, // 97
        EMR_SETICMMODE,
        EMR_CREATECOLORSPACE,
        EMR_SETCOLORSPACE,
        EMR_DELETECOLORSPACE,
        EMR_GLSRECORD,
        EMR_GLSBOUNDEDRECORD,
        EMR_PIXELFORMAT, // = 104
        // reserved 105 - 110
        EMR_COLORCORRECTPALETTE = 111,
        EMR_SETICMPROFILEA,
        EMR_SETICMPROFILEW,
        EMR_ALPHABLEND,
        EMR_SETLAYOUT,
        EMR_TRANSPARENTBLT, // 116
        // reserved 117
        EMR_GRADIENTFILL = 118,
        // reserved 119, 120
        EMR_COLORMATCHTOTARGETW = 121,
        EMR_CREATECOLORSPACEW // 122
}

const EMR_MIN = EMR_HEADER;

static if (_WIN32_WINNT >= 0x500) {
        const EMR_MAX = EMR_CREATECOLORSPACEW;
} else {
        const EMR_MAX = EMR_PIXELFORMAT;
}

// ENHMETAHEADER.dSignature, ENHMETAHEADER3.dSignature,
// EMRFORMAT.dSignature
enum : DWORD {
        ENHMETA_SIGNATURE = 1179469088,
        EPS_SIGNATURE     = 0x46535045
}

static if (_WIN32_WINNT >= 0x500) {
        // AddFontResourceEx()
        enum : DWORD {
                FR_PRIVATE  = 0x10,
                FR_NOT_ENUM = 0x20
        }
}

enum {
        META_SAVEDC                = 0x1E,
        META_REALIZEPALETTE        = 0x35,
        META_SETPALENTRIES         = 0x37,
        META_CREATEPALETTE         = 0xf7,
        META_SETBKMODE             = 0x102,
        META_SETMAPMODE            = 0x103,
        META_SETROP2               = 0x104,
        META_SETRELABS             = 0x105,
        META_SETPOLYFILLMODE       = 0x106,
        META_SETSTRETCHBLTMODE     = 0x107,
        META_SETTEXTCHAREXTRA      = 0x108,
        META_RESTOREDC             = 0x127,
        META_INVERTREGION          = 0x12A,
        META_PAINTREGION           = 0x12B,
        META_SELECTCLIPREGION      = 0x12C,
        META_SELECTOBJECT          = 0x12D,
        META_SETTEXTALIGN          = 0x12E,
        META_RESIZEPALETTE         = 0x139,
        META_DIBCREATEPATTERNBRUSH = 0x142,
        META_SETLAYOUT             = 0x149,
        META_DELETEOBJECT          = 0x1F0,
        META_CREATEPATTERNBRUSH    = 0x1F9,
        META_SETBKCOLOR            = 0x201,
        META_SETTEXTCOLOR          = 0x209,
        META_SETTEXTJUSTIFICATION  = 0x20A,
        META_SETWINDOWORG          = 0x20B,
        META_SETWINDOWEXT          = 0x20C,
        META_SETVIEWPORTORG        = 0x20D,
        META_SETVIEWPORTEXT        = 0x20E,
        META_OFFSETWINDOWORG       = 0x20F,
        META_OFFSETVIEWPORTORG     = 0x211,
        META_LINETO                = 0x213,
        META_MOVETO                = 0x214,
        META_OFFSETCLIPRGN         = 0x220,
        META_FILLREGION            = 0x228,
        META_SETMAPPERFLAGS        = 0x231,
        META_SELECTPALETTE         = 0x234,
        META_CREATEPENINDIRECT     = 0x2FA,
        META_CREATEFONTINDIRECT    = 0x2FB,
        META_CREATEBRUSHINDIRECT   = 0x2FC,
        META_POLYGON               = 0x324,
        META_POLYLINE              = 0x325,
        META_SCALEWINDOWEXT        = 0x410,
        META_SCALEVIEWPORTEXT      = 0x412,
        META_EXCLUDECLIPRECT       = 0x415,
        META_INTERSECTCLIPRECT     = 0x416,
        META_ELLIPSE               = 0x418,
        META_FLOODFILL             = 0x419,
        META_RECTANGLE             = 0x41B,
        META_SETPIXEL              = 0x41F,
        META_FRAMEREGION           = 0x429,
        META_ANIMATEPALETTE        = 0x436,
        META_TEXTOUT               = 0x521,
        META_POLYPOLYGON           = 0x538,
        META_EXTFLOODFILL          = 0x548,
        META_ROUNDRECT             = 0x61C,
        META_PATBLT                = 0x61D,
        META_ESCAPE                = 0x626,
        META_CREATEREGION          = 0x6FF,
        META_ARC                   = 0x817,
        META_PIE                   = 0x81A,
        META_CHORD                 = 0x830,
        META_BITBLT                = 0x922,
        META_DIBBITBLT             = 0x940,
        META_EXTTEXTOUT            = 0xA32,
        META_STRETCHBLT            = 0xB23,
        META_DIBSTRETCHBLT         = 0xB41,
        META_SETDIBTODEV           = 0xD33,
        META_STRETCHDIB            = 0xF43
}

// EMRPOLYDRAW
enum : BYTE {
        PT_CLOSEFIGURE = 1,
        PT_LINETO      = 2,
        PT_BEZIERTO    = 4,
        PT_MOVETO      = 6
}

// ----
// PIXELFORMATDESCRIPTOR.iPixelType
enum : BYTE {
        PFD_TYPE_RGBA       = 0,
        PFD_TYPE_COLORINDEX = 1
}

deprecated {
// PIXELFORMATDESCRIPTOR.
const byte
        PFD_MAIN_PLANE     = 0,
        PFD_OVERLAY_PLANE  = 1,
        PFD_UNDERLAY_PLANE = -1;
}
// PIXELFORMATDESCRIPTOR.dwFlags
const DWORD
        PFD_DOUBLEBUFFER          = 0x00000001,
        PFD_STEREO                = 0x00000002,
        PFD_DRAW_TO_WINDOW        = 0x00000004,
        PFD_DRAW_TO_BITMAP        = 0x00000008,
        PFD_SUPPORT_GDI           = 0x00000010,
        PFD_SUPPORT_OPENGL        = 0x00000020,
        PFD_GENERIC_FORMAT        = 0x00000040,
        PFD_NEED_PALETTE          = 0x00000080,
        PFD_NEED_SYSTEM_PALETTE   = 0x00000100,
        PFD_SWAP_EXCHANGE         = 0x00000200,
        PFD_SWAP_COPY             = 0x00000400,
        PFD_SWAP_LAYER_BUFFERS    = 0x00000800,
        PFD_GENERIC_ACCELERATED   = 0x00001000,
        PFD_SUPPORT_DIRECTDRAW    = 0x00002000,
        /* PIXELFORMATDESCRIPTOR flags for use in ChoosePixelFormat only */
        PFD_DEPTH_DONTCARE        = 0x20000000,
        PFD_DOUBLEBUFFER_DONTCARE = 0x40000000,
        PFD_STEREO_DONTCARE       = 0x80000000;

// ----

const DWORD
        BLACKNESS   = 0x000042,
        NOTSRCERASE = 0x1100A6,
        NOTSRCCOPY  = 0x330008,
        SRCERASE    = 0x440328,
        DSTINVERT   = 0x550009,
        PATINVERT   = 0x5A0049,
        SRCINVERT   = 0x660046,
        SRCAND      = 0x8800C6,
        MERGEPAINT  = 0xBB0226,
        MERGECOPY   = 0xC000CA,
        SRCCOPY     = 0xCC0020,
        SRCPAINT    = 0xEE0086,
        PATCOPY     = 0xF00021,
        PATPAINT    = 0xFB0A09,
        WHITENESS   = 0xFF0062;
static if (_WIN32_WINNT >= 0x500) {
        const DWORD
                NOMIRRORBITMAP = 0x80000000,
                CAPTUREBLT     = 0x40000000;
}

// GetROP2(), SetROP2()
enum : int {
        R2_BLACK       = 1,
        R2_NOTMERGEPEN = 2,
        R2_MASKNOTPEN  = 3,
        R2_NOTCOPYPEN  = 4,
        R2_MASKPENNOT  = 5,
        R2_NOT         = 6,
        R2_XORPEN      = 7,
        R2_NOTMASKPEN  = 8,
        R2_MASKPEN     = 9,
        R2_NOTXORPEN   = 10,
        R2_NOP         = 11,
        R2_MERGENOTPEN = 12,
        R2_COPYPEN     = 13,
        R2_MERGEPENNOT = 14,
        R2_MERGEPEN    = 15,
        R2_WHITE       = 16
}

const R2_LAST = R2_WHITE;

// CheckColorsInGamut()
const ubyte
        CM_IN_GAMUT     = 0,
        CM_OUT_OF_GAMUT = 255;

/* UpdateICMRegKey Constants               */
const int
        ICM_ADDPROFILE = 1,
        ICM_DELETEPROFILE = 2,
        ICM_QUERYPROFILE = 3,
        ICM_SETDEFAULTPROFILE = 4,
        ICM_REGISTERICMATCHER = 5,
        ICM_UNREGISTERICMATCHER = 6,
        ICM_QUERYMATCH = 7;

enum : int {
        RGN_AND  = 1,
        RGN_OR   = 2,
        RGN_XOR  = 3,
        RGN_DIFF = 4,
        RGN_COPY = 5
}

const RGN_MIN = RGN_AND;
const RGN_MAX = RGN_COPY;

// Return values for CombineRgn()
enum {
        NULLREGION    = 1,
        SIMPLEREGION  = 2,
        COMPLEXREGION = 3
}

const ERROR = 0;
alias ERROR RGN_ERROR;

// CreateDIBitmap()
const DWORD CBM_INIT = 4;

// CreateDIBitmap()
enum : UINT {
        DIB_RGB_COLORS = 0,
        DIB_PAL_COLORS = 1
}

// ---
//  Values for LOGFONT and CreateFont()

// FIXME: For D, replace with lfFaceName.length()
const LF_FACESIZE     = 32;
const LF_FULLFACESIZE = 64;

// FIXME: Not needed for D, only EXTLOGFONT
const ELF_VENDOR_SIZE = 4;

// ???
const ELF_VERSION = 0;
const ELF_CULTURE_LATIN = 0;

// LOGFONT.lfWeight
const LONG
        FW_DONTCARE   = 0,
        FW_THIN       = 100,
        FW_EXTRALIGHT = 200,
        FW_ULTRALIGHT = FW_EXTRALIGHT,
        FW_LIGHT      = 300,
        FW_NORMAL     = 400,
        FW_REGULAR    = FW_NORMAL,
        FW_MEDIUM     = 500,
        FW_SEMIBOLD   = 600,
        FW_DEMIBOLD   = FW_SEMIBOLD,
        FW_BOLD       = 700,
        FW_EXTRABOLD  = 800,
        FW_ULTRABOLD  = FW_EXTRABOLD,
        FW_HEAVY      = 900,
        FW_BLACK      = FW_HEAVY;

// LOGFONT.lfCharSet
enum : DWORD {
        ANSI_CHARSET        = 0,
        DEFAULT_CHARSET     = 1,
        SYMBOL_CHARSET      = 2,
        MAC_CHARSET         = 77,
        SHIFTJIS_CHARSET    = 128,
        HANGEUL_CHARSET     = 129,
        HANGUL_CHARSET      = 129,
        JOHAB_CHARSET       = 130,
        GB2312_CHARSET      = 134,
        CHINESEBIG5_CHARSET = 136,
        GREEK_CHARSET       = 161,
        TURKISH_CHARSET     = 162,
        VIETNAMESE_CHARSET  = 163,
        HEBREW_CHARSET      = 177,
        ARABIC_CHARSET      = 178,
        BALTIC_CHARSET      = 186,
        RUSSIAN_CHARSET     = 204,
        THAI_CHARSET        = 222,
        EASTEUROPE_CHARSET  = 238,
        OEM_CHARSET         = 255
}

// LOGFONT.lfOutPrecision
enum : BYTE {
        OUT_DEFAULT_PRECIS = 0,
        OUT_STRING_PRECIS,
        OUT_CHARACTER_PRECIS,
        OUT_STROKE_PRECIS,
        OUT_TT_PRECIS,
        OUT_DEVICE_PRECIS,
        OUT_RASTER_PRECIS,
        OUT_TT_ONLY_PRECIS,
        OUT_OUTLINE_PRECIS,
        OUT_SCREEN_OUTLINE_PRECIS,
        OUT_PS_ONLY_PRECIS, // 10
}

// LOGFONT.lfClipPrecision
enum : BYTE  {
        CLIP_DEFAULT_PRECIS   = 0,
        CLIP_CHARACTER_PRECIS = 1,
        CLIP_STROKE_PRECIS    = 2,
        CLIP_MASK             = 15,
        CLIP_LH_ANGLES        = 16,
        CLIP_TT_ALWAYS        = 32,
        CLIP_DFA_DISABLE      = 64,
        CLIP_EMBEDDED         = 128
}

// LOGFONT.lfQuality
enum : BYTE {
        DEFAULT_QUALITY = 0,
        DRAFT_QUALITY,
        PROOF_QUALITY,
        NONANTIALIASED_QUALITY,
        ANTIALIASED_QUALITY
}

// LOGFONT.lfPitchAndFamily

const BYTE
        DEFAULT_PITCH  = 0,
        FIXED_PITCH    = 1,
        VARIABLE_PITCH = 2,
        MONO_FONT      = 8,
        FF_DONTCARE    = 0,
        FF_ROMAN       = 16,
        FF_SWISS       = 32,
        FF_SCRIPT      = 64,
        FF_MODERN      = 48,
        FF_DECORATIVE  = 80;

// ----
// Enums for the PANOSE struct

const PANOSE_COUNT=10;

enum {
        PAN_FAMILYTYPE_INDEX = 0,
        PAN_SERIFSTYLE_INDEX,
        PAN_WEIGHT_INDEX,
        PAN_PROPORTION_INDEX,
        PAN_CONTRAST_INDEX,
        PAN_STROKEVARIATION_INDEX,
        PAN_ARMSTYLE_INDEX,
        PAN_LETTERFORM_INDEX,
        PAN_MIDLINE_INDEX,
        PAN_XHEIGHT_INDEX
}

const PAN_CULTURE_LATIN=0;

// NOTE: the first two values (PAN_ANY and PAN_NO_FIT) apply to all these enums!
enum : BYTE {
        PAN_ANY    = 0,
        PAN_NO_FIT = 1,
}

enum : BYTE {
        PAN_FAMILY_TEXT_DISPLAY = 2,
        PAN_FAMILY_SCRIPT,
        PAN_FAMILY_DECORATIVE,
        PAN_FAMILY_PICTORIAL
}
enum : BYTE {
        PAN_SERIF_COVE = 2,
        PAN_SERIF_OBTUSE_COVE,
        PAN_SERIF_SQUARE_COVE,
        PAN_SERIF_OBTUSE_SQUARE_COVE,
        PAN_SERIF_SQUARE,
        PAN_SERIF_THIN,
        PAN_SERIF_BONE,
        PAN_SERIF_EXAGGERATED,
        PAN_SERIF_TRIANGLE,
        PAN_SERIF_NORMAL_SANS,
        PAN_SERIF_OBTUSE_SANS,
        PAN_SERIF_PERP_SANS,
        PAN_SERIF_FLARED,
        PAN_SERIF_ROUNDED
}

enum : BYTE {
        PAN_WEIGHT_VERY_LIGHT = 2,
        PAN_WEIGHT_LIGHT,
        PAN_WEIGHT_THIN,
        PAN_WEIGHT_BOOK,
        PAN_WEIGHT_MEDIUM,
        PAN_WEIGHT_DEMI,
        PAN_WEIGHT_BOLD,
        PAN_WEIGHT_HEAVY,
        PAN_WEIGHT_BLACK,
        PAN_WEIGHT_NORD
}

enum : BYTE {
        PAN_PROP_OLD_STYLE = 2,
        PAN_PROP_MODERN,
        PAN_PROP_EVEN_WIDTH,
        PAN_PROP_EXPANDED,
        PAN_PROP_CONDENSED,
        PAN_PROP_VERY_EXPANDED,
        PAN_PROP_VERY_CONDENSED,
        PAN_PROP_MONOSPACED
}

enum : BYTE {
        PAN_CONTRAST_NONE = 2,
        PAN_CONTRAST_VERY_LOW,
        PAN_CONTRAST_LOW,
        PAN_CONTRAST_MEDIUM_LOW,
        PAN_CONTRAST_MEDIUM,
        PAN_CONTRAST_MEDIUM_HIGH,
        PAN_CONTRAST_HIGH,
        PAN_CONTRAST_VERY_HIGH
}

// PANOSE.bStrokeVariation
enum : BYTE {
        PAN_STROKE_GRADUAL_DIAG = 2,
        PAN_STROKE_GRADUAL_TRAN,
        PAN_STROKE_GRADUAL_VERT,
        PAN_STROKE_GRADUAL_HORZ,
        PAN_STROKE_RAPID_VERT,
        PAN_STROKE_RAPID_HORZ,
        PAN_STROKE_INSTANT_VERT
}

// PANOSE.bArmStyle
enum : BYTE {
        PAN_STRAIGHT_ARMS_HORZ = 2,
        PAN_STRAIGHT_ARMS_WEDGE,
        PAN_STRAIGHT_ARMS_VERT,
        PAN_STRAIGHT_ARMS_SINGLE_SERIF,
        PAN_STRAIGHT_ARMS_DOUBLE_SERIF,
        PAN_BENT_ARMS_HORZ,
        PAN_BENT_ARMS_WEDGE,
        PAN_BENT_ARMS_VERT,
        PAN_BENT_ARMS_SINGLE_SERIF,
        PAN_BENT_ARMS_DOUBLE_SERIF
}

// PANOSE.bLetterForm
enum : BYTE {
        PAN_LETT_NORMAL_CONTACT = 2,
        PAN_LETT_NORMAL_WEIGHTED,
        PAN_LETT_NORMAL_BOXED,
        PAN_LETT_NORMAL_FLATTENED,
        PAN_LETT_NORMAL_ROUNDED,
        PAN_LETT_NORMAL_OFF_CENTER,
        PAN_LETT_NORMAL_SQUARE,
        PAN_LETT_OBLIQUE_CONTACT,
        PAN_LETT_OBLIQUE_WEIGHTED,
        PAN_LETT_OBLIQUE_BOXED,
        PAN_LETT_OBLIQUE_FLATTENED,
        PAN_LETT_OBLIQUE_ROUNDED,
        PAN_LETT_OBLIQUE_OFF_CENTER,
        PAN_LETT_OBLIQUE_SQUARE
}

// PANOSE.bMidLine
enum : BYTE {
        PAN_MIDLINE_STANDARD_TRIMMED = 2,
        PAN_MIDLINE_STANDARD_POINTED,
        PAN_MIDLINE_STANDARD_SERIFED,
        PAN_MIDLINE_HIGH_TRIMMED,
        PAN_MIDLINE_HIGH_POINTED,
        PAN_MIDLINE_HIGH_SERIFED,
        PAN_MIDLINE_CONSTANT_TRIMMED,
        PAN_MIDLINE_CONSTANT_POINTED,
        PAN_MIDLINE_CONSTANT_SERIFED,
        PAN_MIDLINE_LOW_TRIMMED,
        PAN_MIDLINE_LOW_POINTED,
        PAN_MIDLINE_LOW_SERIFED
}

// PANOSE.bXHeight
enum : BYTE {
        PAN_XHEIGHT_CONSTANT_SMALL = 2,
        PAN_XHEIGHT_CONSTANT_STD,
        PAN_XHEIGHT_CONSTANT_LARGE,
        PAN_XHEIGHT_DUCKING_SMALL,
        PAN_XHEIGHT_DUCKING_STD,
        PAN_XHEIGHT_DUCKING_LARGE
}

// ----
// ???
const FS_LATIN1      = 0x00000001;
const FS_LATIN2      = 0x00000002;
const FS_CYRILLIC    = 0x00000004;
const FS_GREEK       = 0x00000008;
const FS_TURKISH     = 0x00000010;
const FS_HEBREW      = 0x00000020;
const FS_ARABIC      = 0x00000040;
const FS_BALTIC      = 0x00000080;
const FS_VIETNAMESE  = 0x00000100;
const FS_THAI        = 0x00010000;
const FS_JISJAPAN    = 0x00020000;
const FS_CHINESESIMP = 0x00040000;
const FS_WANSUNG     = 0x00080000;
const FS_CHINESETRAD = 0x00100000;
const FS_JOHAB       = 0x00200000;
const FS_SYMBOL      = 0x80000000;

// ----
// Poly Fill Mode
enum : int {
        ALTERNATE = 1,
        WINDING = 2
}
const int POLYFILL_LAST = WINDING;

//---
// LOGBRUSH
enum : LONG {
        HS_HORIZONTAL = 0,
        HS_VERTICAL,
        HS_FDIAGONAL,
        HS_BDIAGONAL,
        HS_CROSS,
        HS_DIAGCROSS
}

//LOGBRUSH.lbStyle
enum : UINT {
        BS_SOLID = 0,
        BS_NULL  = 1,
        BS_HOLLOW = BS_NULL,
        BS_HATCHED,
        BS_PATTERN,
        BS_INDEXED,
        BS_DIBPATTERN,
        BS_DIBPATTERNPT,
        BS_PATTERN8X8,
        BS_DIBPATTERN8X8,
        BS_MONOPATTERN,
}
//-----
// EXTLOGPEN, ExtCreatePen()

// EXTLOGPEN.elpPenStyle
enum : DWORD {
        PS_SOLID       = 0,
        PS_DASH        = 1,
        PS_DOT         = 2,
        PS_DASHDOT     = 3,
        PS_DASHDOTDOT  = 4,
        PS_NULL        = 5,
        PS_INSIDEFRAME = 6,
        PS_USERSTYLE   = 7,
        PS_ALTERNATE   = 8,
        PS_STYLE_MASK  = 15,
}

enum : DWORD {
        PS_COSMETIC      = 0x00000000,
        PS_GEOMETRIC     = 0x00010000,
        PS_TYPE_MASK     = 0x000F0000,
}
enum : DWORD {
        PS_ENDCAP_ROUND  = 0x00000000,
        PS_ENDCAP_SQUARE = 0x00000100,
        PS_ENDCAP_FLAT   = 0x00000200,
        PS_ENDCAP_MASK   = 0x00000F00,
}
enum : DWORD {
        PS_JOIN_ROUND    = 0x00000000,
        PS_JOIN_BEVEL    = 0x00001000,
        PS_JOIN_MITER    = 0x00002000,
        PS_JOIN_MASK     = 0x0000F000,
}

// ---
// DeviceCapabilities()

enum : WORD {
        DC_FIELDS = 1,
        DC_PAPERS,
        DC_PAPERSIZE,
        DC_MINEXTENT,
        DC_MAXEXTENT,
        DC_BINS,
        DC_DUPLEX,
        DC_SIZE,
        DC_EXTRA,
        DC_VERSION,
        DC_DRIVER,
        DC_BINNAMES,
        DC_ENUMRESOLUTIONS,
        DC_FILEDEPENDENCIES,
        DC_TRUETYPE,
        DC_PAPERNAMES,
        DC_ORIENTATION,
        DC_COPIES,
        DC_BINADJUST,
        DC_EMF_COMPLIANT,
        DC_DATATYPE_PRODUCED,
        DC_COLLATE,
        DC_MANUFACTURER,
        DC_MODEL,
}

static if (_WIN32_WINNT >= 0x500) {
        enum {
                DC_PERSONALITY = 25,
                DC_PRINTRATE = 26,
                DC_PRINTRATEUNIT = 27,
                DC_PRINTERMEM = 28,
                DC_MEDIAREADY = 29,
                DC_STAPLE = 30,
                DC_PRINTRATEPPM = 31,
                DC_COLORDEVICE = 32,
                DC_NUP = 33,
                DC_MEDIATYPENAMES = 34,
                DC_MEDIATYPES = 35,
        }
        enum {
                PRINTRATEUNIT_PPM = 1,
                PRINTRATEUNIT_CPS = 2,
                PRINTRATEUNIT_LPM = 3,
                PRINTRATEUNIT_IPM = 4,
        }
}


// return from DC_TRUETYPE
const DWORD
        DCTT_BITMAP           = 1,
        DCTT_DOWNLOAD         = 2,
        DCTT_SUBDEV           = 4,
        DCTT_DOWNLOAD_OUTLINE = 8;

// return from DC_BINADJUST
enum : DWORD {
        DCBA_FACEUPNONE     = 0x0000,
        DCBA_FACEUPCENTER   = 0x0001,
        DCBA_FACEUPLEFT     = 0x0002,
        DCBA_FACEUPRIGHT    = 0x0003,
        DCBA_FACEDOWNNONE   = 0x0100,
        DCBA_FACEDOWNCENTER = 0x0101,
        DCBA_FACEDOWNLEFT   = 0x0102,
        DCBA_FACEDOWNRIGHT  = 0x0103,
}
//---

const FLOODFILLBORDER  = 0;
const FLOODFILLSURFACE = 1;

// ExtTextOut()
const UINT
        ETO_OPAQUE         = 0x0002,
        ETO_CLIPPED        = 0x0004,
        ETO_GLYPH_INDEX    = 0x0010,
        ETO_RTLREADING     = 0x0080,
        ETO_NUMERICSLOCAL  = 0x0400,
        ETO_NUMERICSLATIN  = 0x0800,
        ETO_IGNORELANGUAGE = 0x1000;
static if (_WIN32_WINNT >= 0x500) {
        const UINT
                ETO_PDY = 0x2000;
}

// GdiComment()
enum {
        GDICOMMENT_BEGINGROUP       = 0x00000002,
        GDICOMMENT_ENDGROUP         = 0x00000003,
        GDICOMMENT_UNICODE_STRING   = 0x00000040,
        GDICOMMENT_UNICODE_END      = 0x00000080,
        GDICOMMENT_MULTIFORMATS     = 0x40000004,
        GDICOMMENT_IDENTIFIER       = 0x43494447,
        GDICOMMENT_WINDOWS_METAFILE = 0x80000001,
}

// Get/SetArcDirection()
enum : int {
        AD_COUNTERCLOCKWISE = 1,
        AD_CLOCKWISE        = 2
}

const RDH_RECTANGLES = 1;

// GCPRESULTS.lpClass
enum {
        GCPCLASS_LATIN  = 1,
        GCPCLASS_HEBREW = 2,
        GCPCLASS_ARABIC = 2,
        GCPCLASS_NEUTRAL,
        GCPCLASS_LOCALNUMBER,
        GCPCLASS_LATINNUMBER,
        GCPCLASS_LATINNUMERICTERMINATOR,
        GCPCLASS_LATINNUMERICSEPARATOR,
        GCPCLASS_NUMERICSEPARATOR, // = 8,
        GCPCLASS_POSTBOUNDRTL = 16,
        GCPCLASS_POSTBOUNDLTR = 32,
        GCPCLASS_PREBOUNDRTL  = 64,
        GCPCLASS_PREBOUNDLTR  = 128,
        GCPGLYPH_LINKAFTER    = 0x4000,
        GCPGLYPH_LINKBEFORE   = 0x8000
}

// GetBoundsRect(), SetBoundsRect()
const UINT
        DCB_RESET      = 1,
        DCB_ACCUMULATE = 2,
        DCB_SET        = DCB_RESET | DCB_ACCUMULATE,
        DCB_ENABLE     = 4,
        DCB_DISABLE    = 8,
        DCB_DIRTY      = DCB_ACCUMULATE;

//---
// GetObjectType()
enum : DWORD {
        OBJ_PEN = 1,
        OBJ_BRUSH,
        OBJ_DC,
        OBJ_METADC,
        OBJ_PAL,
        OBJ_FONT,
        OBJ_BITMAP,
        OBJ_REGION,
        OBJ_METAFILE,
        OBJ_MEMDC,
        OBJ_EXTPEN,
        OBJ_ENHMETADC,
        OBJ_ENHMETAFILE,
        OBJ_COLORSPACE,
}

//---------------------
// Capabilities for GetDeviceCaps(dc, xxx)

enum : int {
        DRIVERVERSION   = 0,
        TECHNOLOGY      = 2,
        HORZSIZE        = 4,
        VERTSIZE        = 6,
        HORZRES         = 8,
        VERTRES         = 10,
        BITSPIXEL       = 12,
        PLANES          = 14,
        NUMBRUSHES      = 16,
        NUMPENS         = 18,
        NUMMARKERS      = 20,
        NUMFONTS        = 22,
        NUMCOLORS       = 24,
        PDEVICESIZE     = 26,
        CURVECAPS       = 28,
        LINECAPS        = 30,
        POLYGONALCAPS   = 32,
        TEXTCAPS        = 34,
        CLIPCAPS        = 36,
        RASTERCAPS      = 38,
        ASPECTX         = 40,
        ASPECTY         = 42,
        ASPECTXY        = 44,
        LOGPIXELSX      = 88,
        LOGPIXELSY      = 90,
        SIZEPALETTE     = 104,
        NUMRESERVED     = 106,
        COLORRES        = 108,
        PHYSICALWIDTH   = 110,
        PHYSICALHEIGHT  = 111,
        PHYSICALOFFSETX = 112,
        PHYSICALOFFSETY = 113,
        SCALINGFACTORX  = 114,
        SCALINGFACTORY  = 115,
        VREFRESH        = 116,
        DESKTOPVERTRES  = 117,
        DESKTOPHORZRES  = 118,
        BLTALIGNMENT    = 119
}
static if (_WIN32_WINNT >= 0x500) {
enum : int {
        SHADEBLENDCAPS  = 120,
        COLORMGMTCAPS   = 121,
}
}

// Return values for GetDeviceCaps(dc, TECHNOLOGY)
enum : int {
        DT_PLOTTER = 0,
        DT_RASDISPLAY,
        DT_RASPRINTER,
        DT_RASCAMERA,
        DT_CHARSTREAM,
        DT_METAFILE,
        DT_DISPFILE // = 6
}

// Return values for GetDeviceCaps(dc, RASTERCAPS)
const int
        RC_NONE         = 0,
        RC_BITBLT       = 1,
        RC_BANDING      = 2,
        RC_SCALING      = 4,
        RC_BITMAP64     = 8,
        RC_GDI20_OUTPUT = 16,
        RC_GDI20_STATE  = 32,
        RC_SAVEBITMAP   = 64,
        RC_DI_BITMAP    = 128,
        RC_PALETTE      = 256,
        RC_DIBTODEV     = 512,
        RC_BIGFONT      = 1024,
        RC_STRETCHBLT   = 2048,
        RC_FLOODFILL    = 4096,
        RC_STRETCHDIB   = 8192,
        RC_OP_DX_OUTPUT = 0x4000,
        RC_DEVBITS      = 0x8000;

static if (_WIN32_WINNT >= 0x500) {
        /* Shading and blending caps */
        const SB_NONE = 0x00000000;
        const SB_CONST_ALPHA = 0x00000001;
        const SB_PIXEL_ALPHA = 0x00000002;
        const SB_PREMULT_ALPHA = 0x00000004;
        const SB_GRAD_RECT = 0x00000010;
        const SB_GRAD_TRI = 0x00000020;
        /* Color Management caps */
        const CM_NONE = 0x00000000;
        const CM_DEVICE_ICM = 0x00000001;
        const CM_GAMMA_RAMP = 0x00000002;
        const CM_CMYK_COLOR = 0x00000004;
}

// Return values for GetDeviceCaps(dc, CURVECAPS)
const int
        CC_NONE       = 0,
        CC_CIRCLES    = 1,
        CC_PIE        = 2,
        CC_CHORD      = 4,
        CC_ELLIPSES   = 8,
        CC_WIDE       = 16,
        CC_STYLED     = 32,
        CC_WIDESTYLED = 64,
        CC_INTERIORS  = 128,
        CC_ROUNDRECT  = 256;

// Return values for GetDeviceCaps(dc, LINECAPS)

const int
        LC_NONE       = 0,
        LC_POLYLINE   = 2,
        LC_MARKER     = 4,
        LC_POLYMARKER = 8,
        LC_WIDE       = 16,
        LC_STYLED     = 32,
        LC_WIDESTYLED = 64,
        LC_INTERIORS  = 128;

// Return values for GetDeviceCaps(dc, POLYGONALCAPS)

const int
        PC_NONE        = 0,
        PC_POLYGON     = 1,
        PC_RECTANGLE   = 2,
        PC_WINDPOLYGON = 4,
        PC_TRAPEZOID   = 4,
        PC_SCANLINE    = 8,
        PC_WIDE        = 16,
        PC_STYLED      = 32,
        PC_WIDESTYLED  = 64,
        PC_INTERIORS   = 128,
        PC_POLYPOLYGON = 256,
        PC_PATHS       = 512;

/* Clipping Capabilities */
const int CP_NONE = 0,
        CP_RECTANGLE = 1,
        CP_REGION = 2;

// Return values for GetDeviceCaps(dc, TEXTCAPS)

const int
        TC_OP_CHARACTER = 1,
        TC_OP_STROKE    = 2,
        TC_CP_STROKE    = 4,
        TC_CR_90        = 8,
        TC_CR_ANY       = 16,
        TC_SF_X_YINDEP  = 32,
        TC_SA_DOUBLE    = 64,
        TC_SA_INTEGER   = 128,
        TC_SA_CONTIN    = 256,
        TC_EA_DOUBLE    = 512,
        TC_IA_ABLE      = 1024,
        TC_UA_ABLE      = 2048,
        TC_SO_ABLE      = 4096,
        TC_RA_ABLE      = 8192,
        TC_VA_ABLE      = 16384,
        TC_RESERVED     = 32768,
        TC_SCROLLBLT    = 65536;

// End GetDeviceCaps
//---------------------
// GetCharacterPlacement(), and GetFontLanguageInfo()
const DWORD
        GCP_DBCS            = 1,
        GCP_REORDER         = 2,
        GCP_USEKERNING      = 8,
        GCP_GLYPHSHAPE      = 16,
        GCP_LIGATE          = 32,
        GCP_DIACRITIC       = 256,
        GCP_KASHIDA         = 1024,
        GCP_ERROR           = 0x8000,
        GCP_JUSTIFY         = 0x10000,
        GCP_CLASSIN         = 0x80000,
        GCP_MAXEXTENT       = 0x100000,
        GCP_JUSTIFYIN       = 0x200000,
        GCP_DISPLAYZWG      = 0x400000,
        GCP_SYMSWAPOFF      = 0x800000,
        GCP_NUMERICOVERRIDE = 0x1000000,
        GCP_NEUTRALOVERRIDE = 0x2000000,
        GCP_NUMERICSLATIN   = 0x4000000,
        GCP_NUMERICSLOCAL   = 0x8000000,
        // Only for GetFontLanguageInfo()
        FLI_GLYPHS          = 0x40000,
        FLI_MASK            = 0x103b;

// GetGlyphOutline()
enum : UINT {
        GGO_METRICS      = 0,
        GGO_BITMAP       = 1,
        GGO_NATIVE       = 2,
        GGO_BEZIER       = 3,
        GGO_GRAY2_BITMAP = 4,
        GGO_GRAY4_BITMAP = 5,
        GGO_GRAY8_BITMAP = 6,
        GGO_GLYPH_INDEX  = 128,
        GGO_UNHINTED     = 256
}

enum : int {
        GM_COMPATIBLE = 1,
        GM_ADVANCED
}
const GM_LAST = GM_ADVANCED;

enum : int {
        MM_TEXT = 1,
        MM_LOMETRIC,
        MM_HIMETRIC,
        MM_LOENGLISH,
        MM_HIENGLISH,
        MM_TWIPS,
        MM_ISOTROPIC,
        MM_ANISOTROPIC,
}

const int
        MM_MIN = MM_TEXT,
        MM_MAX = MM_ANISOTROPIC,
        MM_MAX_FIXEDSCALE = MM_TWIPS;

const ABSOLUTE = 1;
const RELATIVE = 2;

enum : BYTE {
        PC_RESERVED   = 1,
        PC_EXPLICIT   = 2,
        PC_NOCOLLAPSE = 4
}

/* FIXME: move to core.sys.windows.commctrl ? */
// ImageList
const COLORREF
        CLR_NONE    = 0xffffffff,
        CLR_INVALID = CLR_NONE,
        CLR_DEFAULT = 0xff000000;

// RASTERIZER_STATUS.wFlags
const short
        TT_AVAILABLE = 1,
        TT_ENABLED   = 2;

// GetStockObject()
enum : int {
        WHITE_BRUSH = 0,
        LTGRAY_BRUSH,
        GRAY_BRUSH,
        DKGRAY_BRUSH,
        BLACK_BRUSH,
        HOLLOW_BRUSH, // = 5
        NULL_BRUSH = HOLLOW_BRUSH,
        WHITE_PEN = 6,
        BLACK_PEN,
        NULL_PEN, // = 8
        OEM_FIXED_FONT = 10,
        ANSI_FIXED_FONT,
        ANSI_VAR_FONT,
        SYSTEM_FONT,
        DEVICE_DEFAULT_FONT,
        DEFAULT_PALETTE,
        SYSTEM_FIXED_FONT,
        DEFAULT_GUI_FONT = SYSTEM_FIXED_FONT + 1,
}
static if (_WIN32_WINNT >= 0x500) {
        enum : int {
                DC_BRUSH = DEFAULT_GUI_FONT + 1,
                DC_PEN,
        }
}

static if (_WIN32_WINNT >= 0x500) {
        const STOCK_LAST = DC_PEN;
} else {
        const STOCK_LAST = DEFAULT_GUI_FONT;
}

// Get/SetSystemPaletteUse()
enum : UINT {
        SYSPAL_ERROR    = 0,
        SYSPAL_STATIC   = 1,
        SYSPAL_NOSTATIC = 2,
        SYSPAL_NOSTATIC256 = 3,
}

// SetTextAlign()
const UINT
        TA_TOP        = 0,
        TA_CENTER     = 6,
        TA_BOTTOM     = 8,
        TA_BASELINE   = 24,
        TA_LEFT       = 0,
        TA_RIGHT      = 2,
        TA_RTLREADING = 256,
        TA_NOUPDATECP = 0,
        TA_UPDATECP   = 1,
        TA_MASK       = TA_BASELINE+TA_CENTER+TA_UPDATECP+TA_RTLREADING,
        VTA_BASELINE  = TA_BASELINE,
        VTA_CENTER    = TA_CENTER,
        VTA_LEFT      = TA_BOTTOM,
        VTA_RIGHT     = TA_TOP,
        VTA_BOTTOM    = TA_RIGHT,
        VTA_TOP       = TA_LEFT;

// EMRMODIFYWORLDTRANSFORM.iMode
enum : DWORD {
        MWT_IDENTITY = 1,
        MWT_LEFTMULTIPLY,
        MWT_RIGHTMULTIPLY
}

const DWORD
        MWT_MIN = MWT_IDENTITY,
        MWT_MAX = MWT_RIGHTMULTIPLY;

enum {
        TRANSPARENT = 1,
        OPAQUE      = 2
}

// Get/SetStretchMode()
enum : int {
        BLACKONWHITE = 1,
        WHITEONBLACK = 2,
        COLORONCOLOR = 3,
        HALFTONE     = 4,

        STRETCH_ANDSCANS    = 1,
        STRETCH_ORSCANS     = 2,
        STRETCH_DELETESCANS = 3,
        STRETCH_HALFTONE    = 4,

        MAXSTRETCHBLTMODE   = 4
}

// TranslateCharsetInfo()
enum : DWORD {
        TCI_SRCCHARSET  = 1,
        TCI_SRCCODEPAGE = 2,
        TCI_SRCFONTSIG  = 3,
        TCI_SRCLOCALE   = 0x1000,
}

// SetICMMode()
enum : int {
        ICM_OFF   = 1,
        ICM_ON    = 2,
        ICM_QUERY = 3,
        ICM_DONE_OUTSIDEDC = 4,
}

// ----
// Escape() Spooler Error Codes
enum : int {
        SP_NOTREPORTED = 0x4000,
        SP_ERROR       = -1,
        SP_APPABORT    = -2,
        SP_USERABORT   = -3,
        SP_OUTOFDISK   = -4,
        SP_OUTOFMEMORY = -5
}

// Escape(), ExtEscape()
// Most of the following are deprecated (Win16 only)
enum : int {
        NEWFRAME      = 1,
        ABORTDOC      = 2,
        NEXTBAND      = 3,
        SETCOLORTABLE = 4,
        GETCOLORTABLE = 5,
        FLUSHOUTPUT   = 6,
        DRAFTMODE     = 7,
        QUERYESCSUPPORT = 8,
        SETABORTPROC  = 9,
        STARTDOC      = 10,
        ENDDOC        = 11,
        GETPHYSPAGESIZE   = 12,
        GETPRINTINGOFFSET = 13,
        GETSCALINGFACTOR  = 14,
        MFCOMMENT         = 15,
        GETPENWIDTH       = 16,
        SETCOPYCOUNT      = 17,
        SELECTPAPERSOURCE = 18,
        DEVICEDATA        = 19,
        PASSTHROUGH       = 19,
        GETTECHNOLOGY     = 20,
        SETLINECAP = 21,
        SETLINEJOIN = 22,
        SETMITERLIMIT = 23,
        BANDINFO = 24,
        DRAWPATTERNRECT = 25,
        GETVECTORPENSIZE = 26,
        GETVECTORBRUSHSIZE = 27,
        ENABLEDUPLEX = 28,
        GETSETPAPERBINS = 29,
        GETSETPRINTORIENT = 30,
        ENUMPAPERBINS = 31,
        SETDIBSCALING = 32,
        EPSPRINTING = 33,
        ENUMPAPERMETRICS = 34,
        GETSETPAPERMETRICS = 35,
        POSTSCRIPT_DATA = 37,
        POSTSCRIPT_IGNORE = 38,
        MOUSETRAILS = 39,
        GETDEVICEUNITS = 42,
        GETEXTENDEDTEXTMETRICS = 256,
        GETEXTENTTABLE = 257,
        GETPAIRKERNTABLE = 258,
        GETTRACKKERNTABLE = 259,
        EXTTEXTOUT = 512,
        GETFACENAME = 513,
        DOWNLOADFACE = 514,
        ENABLERELATIVEWIDTHS = 768,
        ENABLEPAIRKERNING = 769,
        SETKERNTRACK = 770,
        SETALLJUSTVALUES = 771,
        SETCHARSET = 772,
        STRETCHBLT = 2048,
        METAFILE_DRIVER = 2049,
        GETSETSCREENPARAMS = 3072,
        QUERYDIBSUPPORT = 3073,
        BEGIN_PATH = 4096,
        CLIP_TO_PATH = 4097,
        END_PATH = 4098,
        EXT_DEVICE_CAPS = 4099,
        RESTORE_CTM = 4100,
        SAVE_CTM = 4101,
        SET_ARC_DIRECTION = 4102,
        SET_BACKGROUND_COLOR = 4103,
        SET_POLY_MODE = 4104,
        SET_SCREEN_ANGLE = 4105,
        SET_SPREAD = 4106,
        TRANSFORM_CTM = 4107,
        SET_CLIP_BOX = 4108,
        SET_BOUNDS = 4109,
        SET_MIRROR_MODE = 4110,
        OPENCHANNEL = 4110,
        DOWNLOADHEADER = 4111,
        CLOSECHANNEL = 4112,
        POSTSCRIPT_PASSTHROUGH  = 4115,
        ENCAPSULATED_POSTSCRIPT = 4116,
        POSTSCRIPT_IDENTIFY = 4117,
        POSTSCRIPT_INJECTION = 4118,
        CHECKJPEGFORMAT = 4119,
        CHECKPNGFORMAT = 4120,
        GET_PS_FEATURESETTING = 4121,
        SPCLPASSTHROUGH2 = 4568,
}

enum : int {
        PSIDENT_GDICENTRIC = 0,
        PSIDENT_PSCENTRIC = 1,
}

/*
 * Header structure for the input buffer to POSTSCRIPT_INJECTION escape
 */
struct PSINJECTDATA {
        DWORD DataBytes;
        WORD  InjectionPoint;
        WORD  PageNumber;
}
alias PSINJECTDATA* PPSINJECTDATA;

/* Constants for PSINJECTDATA.InjectionPoint field */
enum {
        PSINJECT_BEGINSTREAM = 1,
        PSINJECT_PSADOBE = 2,
        PSINJECT_PAGESATEND = 3,
        PSINJECT_PAGES = 4,
        PSINJECT_DOCNEEDEDRES = 5,
        PSINJECT_DOCSUPPLIEDRES = 6,
        PSINJECT_PAGEORDER = 7,
        PSINJECT_ORIENTATION = 8,
        PSINJECT_BOUNDINGBOX = 9,
        PSINJECT_DOCUMENTPROCESSCOLORS = 10,
        PSINJECT_COMMENTS = 11,
        PSINJECT_BEGINDEFAULTS = 12,
        PSINJECT_ENDDEFAULTS = 13,
        PSINJECT_BEGINPROLOG = 14,
        PSINJECT_ENDPROLOG = 15,
        PSINJECT_BEGINSETUP = 16,
        PSINJECT_ENDSETUP = 17,
        PSINJECT_TRAILER = 18,
        PSINJECT_EOF = 19,
        PSINJECT_ENDSTREAM = 20,
        PSINJECT_DOCUMENTPROCESSCOLORSATEND = 21,

        PSINJECT_PAGENUMBER = 100,
        PSINJECT_BEGINPAGESETUP = 101,
        PSINJECT_ENDPAGESETUP = 102,
        PSINJECT_PAGETRAILER = 103,
        PSINJECT_PLATECOLOR = 104,
        PSINJECT_SHOWPAGE = 105,
        PSINJECT_PAGEBBOX = 106,
        PSINJECT_ENDPAGECOMMENTS = 107,

        PSINJECT_VMSAVE = 200,
        PSINJECT_VMRESTORE = 201,
}

/* Parameter for GET_PS_FEATURESETTING escape */
enum {
        FEATURESETTING_NUP = 0,
        FEATURESETTING_OUTPUT = 1,
        FEATURESETTING_PSLEVEL = 2,
        FEATURESETTING_CUSTPAPER = 3,
        FEATURESETTING_MIRROR = 4,
        FEATURESETTING_NEGATIVE = 5,
        FEATURESETTING_PROTOCOL = 6,
}

enum {
        FEATURESETTING_PRIVATE_BEGIN = 0x1000,
        FEATURESETTING_PRIVATE_END = 0x1FFF,
}

/* Value returned for FEATURESETTING_PROTOCOL */
const PSPROTOCOL_ASCII = 0;
const PSPROTOCOL_BCP = 1;
const PSPROTOCOL_TBCP = 2;
const PSPROTOCOL_BINARY = 3;

// ----

const WPARAM PR_JOBSTATUS = 0;

// ???
const QDI_SETDIBITS   = 1;
const QDI_GETDIBITS   = 2;
const QDI_DIBTOSCREEN = 4;
const QDI_STRETCHDIB  = 8;

const ASPECT_FILTERING = 1;

// LOGCOLORSPACE.lcsCSType
enum : LCSCSTYPE {
        LCS_CALIBRATED_RGB = 0,
        LCS_DEVICE_RGB,
        LCS_DEVICE_CMYK
} /* What this for? */

// LOGCOLORSPACE.lcsIntent
enum : LCSGAMUTMATCH {
        LCS_GM_BUSINESS         = 1,
        LCS_GM_GRAPHICS         = 2,
        LCS_GM_IMAGES           = 4,
        LCS_GM_ABS_COLORIMETRIC = 8,
}

const DWORD
        RASTER_FONTTYPE   = 1,
        DEVICE_FONTTYPE   = 2,
        TRUETYPE_FONTTYPE = 4;

// ---
// DEVMODE struct

// FIXME: Not needed for D (use .length instead)
const CCHDEVICENAME = 32;
const CCHFORMNAME   = 32;

// DEVMODE.dmSpecVersion
// current version of specification
const WORD DM_SPECVERSION = 0x0401;

// DEVMODE.dmOrientation
enum : short {
        DMORIENT_PORTRAIT  = 1,
        DMORIENT_LANDSCAPE = 2
}

// DEVMODE.dmPaperSize
enum : short {
        DMPAPER_LETTER = 1,
        DMPAPER_LETTERSMALL,
        DMPAPER_TABLOID,
        DMPAPER_LEDGER,
        DMPAPER_LEGAL,
        DMPAPER_STATEMENT,
        DMPAPER_EXECUTIVE,
        DMPAPER_A3,
        DMPAPER_A4,
        DMPAPER_A4SMALL,
        DMPAPER_A5,
        DMPAPER_B4,
        DMPAPER_B5,
        DMPAPER_FOLIO,
        DMPAPER_QUARTO,
        DMPAPER_10X14,
        DMPAPER_11X17,
        DMPAPER_NOTE,
        DMPAPER_ENV_9,
        DMPAPER_ENV_10,
        DMPAPER_ENV_11,
        DMPAPER_ENV_12,
        DMPAPER_ENV_14,
        DMPAPER_CSHEET,
        DMPAPER_DSHEET,
        DMPAPER_ESHEET,
        DMPAPER_ENV_DL,
        DMPAPER_ENV_C5,
        DMPAPER_ENV_C3,
        DMPAPER_ENV_C4,
        DMPAPER_ENV_C6,
        DMPAPER_ENV_C65,
        DMPAPER_ENV_B4,
        DMPAPER_ENV_B5,
        DMPAPER_ENV_B6,
        DMPAPER_ENV_ITALY,
        DMPAPER_ENV_MONARCH,
        DMPAPER_ENV_PERSONAL,
        DMPAPER_FANFOLD_US,
        DMPAPER_FANFOLD_STD_GERMAN,
        DMPAPER_FANFOLD_LGL_GERMAN,
        DMPAPER_ISO_B4,
        DMPAPER_JAPANESE_POSTCARD,
        DMPAPER_9X11,
        DMPAPER_10X11,
        DMPAPER_15X11,
        DMPAPER_ENV_INVITE,
        DMPAPER_RESERVED_48,
        DMPAPER_RESERVED_49,
        DMPAPER_LETTER_EXTRA,
        DMPAPER_LEGAL_EXTRA,
        DMPAPER_TABLOID_EXTRA,
        DMPAPER_A4_EXTRA,
        DMPAPER_LETTER_TRANSVERSE,
        DMPAPER_A4_TRANSVERSE,
        DMPAPER_LETTER_EXTRA_TRANSVERSE,
        DMPAPER_A_PLUS,
        DMPAPER_B_PLUS,
        DMPAPER_LETTER_PLUS,
        DMPAPER_A4_PLUS,
        DMPAPER_A5_TRANSVERSE,
        DMPAPER_B5_TRANSVERSE,
        DMPAPER_A3_EXTRA,
        DMPAPER_A5_EXTRA,
        DMPAPER_B5_EXTRA,
        DMPAPER_A2,
        DMPAPER_A3_TRANSVERSE,
        DMPAPER_A3_EXTRA_TRANSVERSE // = 68
}
static if (_WIN32_WINNT >= 0x500) {
        enum : short {
                DMPAPER_DBL_JAPANESE_POSTCARD = 69,
                DMPAPER_A6,
                DMPAPER_JENV_KAKU2,
                DMPAPER_JENV_KAKU3,
                DMPAPER_JENV_CHOU3,
                DMPAPER_JENV_CHOU4,
                DMPAPER_LETTER_ROTATED,
                DMPAPER_A3_ROTATED,
                DMPAPER_A4_ROTATED,
                DMPAPER_A5_ROTATED,
                DMPAPER_B4_JIS_ROTATED,
                DMPAPER_B5_JIS_ROTATED,
                DMPAPER_JAPANESE_POSTCARD_ROTATED,
                DMPAPER_DBL_JAPANESE_POSTCARD_ROTATED,
                DMPAPER_A6_ROTATED,
                DMPAPER_JENV_KAKU2_ROTATED,
                DMPAPER_JENV_KAKU3_ROTATED,
                DMPAPER_JENV_CHOU3_ROTATED,
                DMPAPER_JENV_CHOU4_ROTATED,
                DMPAPER_B6_JIS,
                DMPAPER_B6_JIS_ROTATED,
                DMPAPER_12X11,
                DMPAPER_JENV_YOU4,
                DMPAPER_JENV_YOU4_ROTATED,
                DMPAPER_P16K,
                DMPAPER_P32K,
                DMPAPER_P32KBIG,
                DMPAPER_PENV_1,
                DMPAPER_PENV_2,
                DMPAPER_PENV_3,
                DMPAPER_PENV_4,
                DMPAPER_PENV_5,
                DMPAPER_PENV_6,
                DMPAPER_PENV_7,
                DMPAPER_PENV_8,
                DMPAPER_PENV_9,
                DMPAPER_PENV_10,
                DMPAPER_P16K_ROTATED,
                DMPAPER_P32K_ROTATED,
                DMPAPER_P32KBIG_ROTATED,
                DMPAPER_PENV_1_ROTATED,
                DMPAPER_PENV_2_ROTATED,
                DMPAPER_PENV_3_ROTATED,
                DMPAPER_PENV_4_ROTATED,
                DMPAPER_PENV_5_ROTATED,
                DMPAPER_PENV_6_ROTATED,
                DMPAPER_PENV_7_ROTATED,
                DMPAPER_PENV_8_ROTATED,
                DMPAPER_PENV_9_ROTATED,
                DMPAPER_PENV_10_ROTATED // 118
        }
}

const short DMPAPER_FIRST = DMPAPER_LETTER;

static if (_WIN32_WINNT >= 0x500) {
        const short DMPAPER_LAST = DMPAPER_PENV_10_ROTATED;
} else {
        const short DMPAPER_LAST = DMPAPER_A3_EXTRA_TRANSVERSE;
}

const short DMPAPER_USER = 256;


// DEVMODE.dmDefaultSource
enum : short {
        DMBIN_ONLYONE = 1,
        DMBIN_UPPER   = 1,
        DMBIN_LOWER,
        DMBIN_MIDDLE,
        DMBIN_MANUAL,
        DMBIN_ENVELOPE,
        DMBIN_ENVMANUAL,
        DMBIN_AUTO,
        DMBIN_TRACTOR,
        DMBIN_SMALLFMT,
        DMBIN_LARGEFMT,
        DMBIN_LARGECAPACITY, // = 11
        DMBIN_CASSETTE   = 14,
        DMBIN_FORMSOURCE,
}
enum : short {
        DMBIN_FIRST = DMBIN_UPPER,
        DMBIN_LAST = DMBIN_FORMSOURCE,
        DMBIN_USER = 256,
}

// DEVMODE.dmPrintQuality
enum : short {
        DMRES_DRAFT  = -1,
        DMRES_LOW    = -2,
        DMRES_MEDIUM = -3,
        DMRES_HIGH   = -4
}

// DEVMODE.dmColor
enum : short {
        DMCOLOR_MONOCHROME = 1,
        DMCOLOR_COLOR      = 2
}

// DEVMODE.dmDuplex
enum : short {
        DMDUP_SIMPLEX    = 1,
        DMDUP_VERTICAL   = 2,
        DMDUP_HORIZONTAL = 3
}

// DEVMODE.dmTTOption
enum : short {
        DMTT_BITMAP = 1,
        DMTT_DOWNLOAD,
        DMTT_SUBDEV,
        DMTT_DOWNLOAD_OUTLINE
}

// DEVMODE.dmCollate
enum : short {
        DMCOLLATE_FALSE = 0,
        DMCOLLATE_TRUE
}

static if (_WIN32_WINNT >= 0x501) {
        /* DEVMODE dmDisplayOrientation specifiations */
        enum : short {
                DMDO_DEFAULT = 0,
                DMDO_90 = 1,
                DMDO_180 = 2,
                DMDO_270 = 3,
        }

        /* DEVMODE dmDisplayFixedOutput specifiations */
        enum : short {
                DMDFO_DEFAULT = 0,
                DMDFO_STRETCH = 1,
                DMDFO_CENTER = 2,
        }
}


/* FIXME: this flags are deprecated ? */
// DEVMODE.dmDisplayFlags
const DWORD
        DM_GRAYSCALE  = 1,
        DM_INTERLACED = 2;

const DWORD
        DMDISPLAYFLAGS_TEXTMODE = 0x00000004;

/* dmNup , multiple logical page per physical page options */
const DWORD
        DMNUP_SYSTEM = 1,
        DMNUP_ONEUP = 2;

// DEVMODE.dmFields
const DWORD
        DM_ORIENTATION        = 0x00000001,
        DM_PAPERSIZE          = 0x00000002,
        DM_PAPERLENGTH        = 0x00000004,
        DM_PAPERWIDTH         = 0x00000008,
        DM_SCALE              = 0x00000010;
static if (_WIN32_WINNT >= 0x500) {
        const DWORD
                DM_POSITION       = 0x00000020,
                DM_NUP            = 0x00000040;
}
static if (_WIN32_WINNT >= 0x501) {
        const DWORD
                DM_DISPLAYORIENTATION = 0x00000080;
}
const DWORD
        DM_COPIES             = 0x00000100,
        DM_DEFAULTSOURCE      = 0x00000200,
        DM_PRINTQUALITY       = 0x00000400,
        DM_COLOR              = 0x00000800,
        DM_DUPLEX             = 0x00001000,
        DM_YRESOLUTION        = 0x00002000,
        DM_TTOPTION           = 0x00004000,
        DM_COLLATE            = 0x00008000,
        DM_FORMNAME           = 0x00010000,
        DM_LOGPIXELS          = 0x00020000,
        DM_BITSPERPEL         = 0x00040000,
        DM_PELSWIDTH          = 0x00080000,
        DM_PELSHEIGHT         = 0x00100000,
        DM_DISPLAYFLAGS       = 0x00200000,
        DM_DISPLAYFREQUENCY   = 0x00400000,
        DM_ICMMETHOD          = 0x00800000,
        DM_ICMINTENT          = 0x01000000,
        DM_MEDIATYPE          = 0x02000000,
        DM_DITHERTYPE         = 0x04000000,
        DM_PANNINGWIDTH       = 0x08000000,
        DM_PANNINGHEIGHT      = 0x10000000;
static if (_WIN32_WINNT >= 0x501) {
        const DWORD
                DM_DISPLAYFIXEDOUTPUT = 0x20000000;
}

// DEVMODE.dmICMMethod
enum : DWORD {
        DMICMMETHOD_NONE   = 1,
        DMICMMETHOD_SYSTEM = 2,
        DMICMMETHOD_DRIVER = 3,
        DMICMMETHOD_DEVICE = 4,
        DMICMMETHOD_USER   = 256
}

// DEVMODE.dmICMIntent
enum : DWORD {
        DMICM_SATURATE    = 1,
        DMICM_CONTRAST    = 2,
        DMICM_COLORIMETRIC = 3,
        DMICM_ABS_COLORIMETRIC = 4,
        DMICM_USER        = 256
}

// DEVMODE.dmMediaType
enum : DWORD {
        DMMEDIA_STANDARD     = 1,
        DMMEDIA_TRANSPARENCY = 2,
        DMMEDIA_GLOSSY       = 3,
        DMMEDIA_USER         = 256
}

// DEVMODE.dmDitherType
enum : DWORD {
        DMDITHER_NONE = 1,
        DMDITHER_COARSE,
        DMDITHER_FINE,
        DMDITHER_LINEART,
        DMDITHER_ERRORDIFFUSION,
        DMDITHER_RESERVED6,
        DMDITHER_RESERVED7,
        DMDITHER_RESERVED8,
        DMDITHER_RESERVED9,
        DMDITHER_GRAYSCALE,
        DMDITHER_USER = 256
}

// ----
// DocumentProperties()
const DWORD
        DM_UPDATE      = 1,
        DM_COPY        = 2,
        DM_PROMPT      = 4,
        DM_MODIFY      = 8,
        DM_IN_BUFFER   = DM_MODIFY,
        DM_IN_PROMPT   = DM_PROMPT,
        DM_OUT_BUFFER  = DM_COPY,
        DM_OUT_DEFAULT = DM_UPDATE;
// ---

const GDI_ERROR = 0xFFFFFFFF;
const HGDI_ERROR= cast(HANDLE)GDI_ERROR;

// TEXTMETRIC.tmPitchAndFamily
const BYTE
        TMPF_FIXED_PITCH = 1,
        TMPF_VECTOR      = 2,
        TMPF_TRUETYPE    = 4,
        TMPF_DEVICE      = 8;

// NEWTEXTMETRIC.ntmFlags
const DWORD
        NTM_ITALIC         = 0x00000001,
        NTM_BOLD           = 0x00000020,
        NTM_REGULAR        = 0x00000040,
        NTM_NONNEGATIVE_AC = 0x00010000,
        NTM_PS_OPENTYPE    = 0x00020000,
        NTM_TT_OPENTYPE    = 0x00040000,
        NTM_MULTIPLEMASTER = 0x00080000,
        NTM_TYPE1          = 0x00100000,
        NTM_DSIG           = 0x00200000;

// ---
const DWORD TT_POLYGON_TYPE = 24;

// TTPOLYCURVE
enum : WORD {
        TT_PRIM_LINE    = 1,
        TT_PRIM_QSPLINE = 2,
        TT_PRIM_CSPLINE = 3,
}
// ---
const FONTMAPPER_MAX = 10;
const ENHMETA_STOCK_OBJECT = 0x80000000;
const WGL_FONT_LINES = 0;
const WGL_FONT_POLYGONS = 1;

// ---
// LAYERPLANEDESCRIPTOR.dwFlags
const DWORD
        LPD_DOUBLEBUFFER   = 1,
        LPD_STEREO         = 2,
        LPD_SUPPORT_GDI    = 16,
        LPD_SUPPORT_OPENGL = 32,
        LPD_SHARE_DEPTH    = 64,
        LPD_SHARE_STENCIL  = 128,
        LPD_SHARE_ACCUM    = 256,
        LPD_SWAP_EXCHANGE  = 512,
        LPD_SWAP_COPY      = 1024,
        LPD_TRANSPARENT    = 4096;

// LAYERPLANEDESCRIPTOR.iPixelType
enum : BYTE {
        LPD_TYPE_RGBA       = 0,
        LPD_TYPE_COLORINDEX = 1
}

// ---

// wglSwapLayerBuffers()
const UINT
        WGL_SWAP_MAIN_PLANE = 1,
        WGL_SWAP_OVERLAY1   = 2,
        WGL_SWAP_OVERLAY2   = 4,
        WGL_SWAP_OVERLAY3   = 8,
        WGL_SWAP_OVERLAY4   = 16,
        WGL_SWAP_OVERLAY5   = 32,
        WGL_SWAP_OVERLAY6   = 64,
        WGL_SWAP_OVERLAY7   = 128,
        WGL_SWAP_OVERLAY8   = 256,
        WGL_SWAP_OVERLAY9   = 512,
        WGL_SWAP_OVERLAY10  = 1024,
        WGL_SWAP_OVERLAY11  = 2048,
        WGL_SWAP_OVERLAY12  = 4096,
        WGL_SWAP_OVERLAY13  = 8192,
        WGL_SWAP_OVERLAY14  = 16384,
        WGL_SWAP_OVERLAY15  = 32768,
        WGL_SWAP_UNDERLAY1  = 65536,
        WGL_SWAP_UNDERLAY2  = 0x20000,
        WGL_SWAP_UNDERLAY3  = 0x40000,
        WGL_SWAP_UNDERLAY4  = 0x80000,
        WGL_SWAP_UNDERLAY5  = 0x100000,
        WGL_SWAP_UNDERLAY6  = 0x200000,
        WGL_SWAP_UNDERLAY7  = 0x400000,
        WGL_SWAP_UNDERLAY8  = 0x800000,
        WGL_SWAP_UNDERLAY9  = 0x1000000,
        WGL_SWAP_UNDERLAY10 = 0x2000000,
        WGL_SWAP_UNDERLAY11 = 0x4000000,
        WGL_SWAP_UNDERLAY12 = 0x8000000,
        WGL_SWAP_UNDERLAY13 = 0x10000000,
        WGL_SWAP_UNDERLAY14 = 0x20000000,
        WGL_SWAP_UNDERLAY15 = 0x40000000;

const AC_SRC_OVER  = 0x00;
const AC_SRC_ALPHA = 0x01;

// ???
const AC_SRC_NO_PREMULT_ALPHA = 0x01;
const AC_SRC_NO_ALPHA         = 0x02;
const AC_DST_NO_PREMULT_ALPHA = 0x10;
const AC_DST_NO_ALPHA         = 0x20;

const LAYOUT_RTL = 1;
const LAYOUT_BTT = 2;
const LAYOUT_VBH = 4;
const LAYOUT_BITMAPORIENTATIONPRESERVED = 8;

const CS_ENABLE = 0x00000001;
const CS_DISABLE = 0x00000002;
const CS_DELETE_TRANSFORM = 0x00000003;

static if (_WIN32_WINNT > 0x500) {
        const GRADIENT_FILL_RECT_H=0x00;
        const GRADIENT_FILL_RECT_V=0x01;
        const GRADIENT_FILL_TRIANGLE=0x02;
        const GRADIENT_FILL_OP_FLAG=0xff;
        const COLORMATCHTOTARGET_EMBEDED=0x00000001;
        const CREATECOLORSPACE_EMBEDED=0x00000001;
        const SETICMPROFILE_EMBEDED=0x00000001;
}

// DISPLAY_DEVICE.StateFlags
const DWORD
        DISPLAY_DEVICE_ATTACHED_TO_DESKTOP = 0x00000001,
        DISPLAY_DEVICE_MULTI_DRIVER        = 0x00000002,
        DISPLAY_DEVICE_PRIMARY_DEVICE      = 0x00000004,
        DISPLAY_DEVICE_MIRRORING_DRIVER    = 0x00000008,
        DISPLAY_DEVICE_VGA_COMPATIBLE      = 0x00000010,
        DISPLAY_DEVICE_REMOVABLE           = 0x00000020,
        DISPLAY_DEVICE_DISCONNECT          = 0x02000000,
        DISPLAY_DEVICE_REMOTE              = 0x04000000,
        DISPLAY_DEVICE_MODESPRUNED         = 0x08000000;

/* Child device state */
const DWORD
        DISPLAY_DEVICE_ACTIVE = 0x00000001,
        DISPLAY_DEVICE_ATTACHED = 0x00000002;

static if (_WIN32_WINNT >= 0x500) {
        const GGI_MARK_NONEXISTING_GLYPHS = 1;
}

// ----------
//   STRUCTS
// ----------

struct ABC {
        int  abcA;
        UINT abcB;
        int  abcC;
}
alias ABC* PABC, NPABC, LPABC;

struct ABCFLOAT {
        FLOAT abcfA;
        FLOAT abcfB;
        FLOAT abcfC;
}
alias ABCFLOAT* PABCFLOAT, NPABCFLOAT, LPABCFLOAT;

struct BITMAP {
        LONG   bmType;
        LONG   bmWidth;
        LONG   bmHeight;
        LONG   bmWidthBytes;
        WORD   bmPlanes;
        WORD   bmBitsPixel;
        LPVOID bmBits;
}
alias BITMAP* PBITMAP, NPBITMAP, LPBITMAP;

struct BITMAPCOREHEADER {
        DWORD bcSize;
        WORD  bcWidth;
        WORD  bcHeight;
        WORD  bcPlanes;
        WORD  bcBitCount;
}
alias BITMAPCOREHEADER* PBITMAPCOREHEADER, LPBITMAPCOREHEADER;

align(1):
struct RGBTRIPLE {
        BYTE rgbtBlue;
        BYTE rgbtGreen;
        BYTE rgbtRed;
}
alias RGBTRIPLE* LPRGBTRIPLE;

align(2):
struct BITMAPFILEHEADER {
        WORD  bfType;
        DWORD bfSize;
        WORD  bfReserved1;
        WORD  bfReserved2;
        DWORD bfOffBits;
}
alias BITMAPFILEHEADER* LPBITMAPFILEHEADER, PBITMAPFILEHEADER;

align:

struct BITMAPCOREINFO {
        BITMAPCOREHEADER bmciHeader;
        RGBTRIPLE[1]     bmciColors;
}
alias BITMAPCOREINFO* LPBITMAPCOREINFO, PBITMAPCOREINFO;

struct BITMAPINFOHEADER {
        DWORD biSize;
        LONG  biWidth;
        LONG  biHeight;
        WORD  biPlanes;
        WORD  biBitCount;
        DWORD biCompression;
        DWORD biSizeImage;
        LONG  biXPelsPerMeter;
        LONG  biYPelsPerMeter;
        DWORD biClrUsed;
        DWORD biClrImportant;
}

alias BITMAPINFOHEADER* LPBITMAPINFOHEADER, PBITMAPINFOHEADER;

struct RGBQUAD {
        BYTE rgbBlue;
        BYTE rgbGreen;
        BYTE rgbRed;
        BYTE rgbReserved;
};
alias RGBQUAD* LPRGBQUAD;

struct BITMAPINFO {
        BITMAPINFOHEADER bmiHeader;
        RGBQUAD[1]       bmiColors;
};
alias BITMAPINFO* PBITMAPINFO, LPBITMAPINFO;

alias int FXPT16DOT16;
alias int* LPFXPT16DOT16;
alias int FXPT2DOT30;
alias int* LPFXPT2DOT30;

struct CIEXYZ {
        FXPT2DOT30 ciexyzX;
        FXPT2DOT30 ciexyzY;
        FXPT2DOT30 ciexyzZ;
}
alias CIEXYZ* LPCIEXYZ;

struct CIEXYZTRIPLE {
        CIEXYZ ciexyzRed;
        CIEXYZ ciexyzGreen;
        CIEXYZ ciexyzBlue;
}
alias CIEXYZTRIPLE* LPCIEXYZTRIPLE;

struct BITMAPV4HEADER {
        DWORD        bV4Size;
        LONG         bV4Width;
        LONG         bV4Height;
        WORD         bV4Planes;
        WORD         bV4BitCount;
        DWORD        bV4V4Compression;
        DWORD        bV4SizeImage;
        LONG         bV4XPelsPerMeter;
        LONG         bV4YPelsPerMeter;
        DWORD        bV4ClrUsed;
        DWORD        bV4ClrImportant;
        DWORD        bV4RedMask;
        DWORD        bV4GreenMask;
        DWORD        bV4BlueMask;
        DWORD        bV4AlphaMask;
        DWORD        bV4CSType;
        CIEXYZTRIPLE bV4Endpoints;
        DWORD        bV4GammaRed;
        DWORD        bV4GammaGreen;
        DWORD        bV4GammaBlue;
}
alias BITMAPV4HEADER* LPBITMAPV4HEADER, PBITMAPV4HEADER;

struct BITMAPV5HEADER {
        DWORD bV5Size;
        LONG bV5Width;
        LONG bV5Height;
        WORD bV5Planes;
        WORD bV5BitCount;
        DWORD bV5Compression;
        DWORD bV5SizeImage;
        LONG bV5XPelsPerMeter;
        LONG bV5YPelsPerMeter;
        DWORD bV5ClrUsed;
        DWORD bV5ClrImportant;
        DWORD bV5RedMask;
        DWORD bV5GreenMask;
        DWORD bV5BlueMask;
        DWORD bV5AlphaMask;
        DWORD bV5CSType;
        CIEXYZTRIPLE bV5Endpoints;
        DWORD bV5GammaRed;
        DWORD bV5GammaGreen;
        DWORD bV5GammaBlue;
        DWORD bV5Intent;
        DWORD bV5ProfileData;
        DWORD bV5ProfileSize;
        DWORD bV5Reserved;
}
alias BITMAPV5HEADER* LPBITMAPV5HEADER, PBITMAPV5HEADER;

struct FONTSIGNATURE {
        DWORD[4] fsUsb;
        DWORD[2] fsCsb;
}
alias FONTSIGNATURE* PFONTSIGNATURE, LPFONTSIGNATURE;

struct CHARSETINFO {
        UINT ciCharset;
        UINT ciACP;
        FONTSIGNATURE fs;
}
alias CHARSETINFO* PCHARSETINFO, NPCHARSETINFO, LPCHARSETINFO;

struct COLORADJUSTMENT {
        WORD  caSize;
        WORD  caFlags;
        WORD  caIlluminantIndex;
        WORD  caRedGamma;
        WORD  caGreenGamma;
        WORD  caBlueGamma;
        WORD  caReferenceBlack;
        WORD  caReferenceWhite;
        SHORT caContrast;
        SHORT caBrightness;
        SHORT caColorfulness;
        SHORT caRedGreenTint;
}
alias COLORADJUSTMENT* PCOLORADJUSTMENT, LPCOLORADJUSTMENT;

struct DEVMODEA {
        BYTE[CCHDEVICENAME] dmDeviceName;
        WORD   dmSpecVersion;
        WORD   dmDriverVersion;
        WORD   dmSize;
        WORD   dmDriverExtra;
        DWORD  dmFields;
        union {
                struct {
                        short dmOrientation;
                        short dmPaperSize;
                        short dmPaperLength;
                        short dmPaperWidth;
                        short dmScale;
                        short dmCopies;
                        short dmDefaultSource;
                        short dmPrintQuality;
                }
                POINTL dmPosition;
                DWORD  dmDisplayOrientation;
                DWORD  dmDisplayFixedOutput;
        }
        short  dmColor;
        short  dmDuplex;
        short  dmYResolution;
        short  dmTTOption;
        short  dmCollate;
        BYTE[CCHFORMNAME]   dmFormName;
        WORD   dmLogPixels;
        DWORD  dmBitsPerPel;
        DWORD  dmPelsWidth;
        DWORD  dmPelsHeight;
        union {
                DWORD  dmDisplayFlags;
                DWORD  dmNup;
        }
        DWORD  dmDisplayFrequency;
        DWORD  dmICMMethod;
        DWORD  dmICMIntent;
        DWORD  dmMediaType;
        DWORD  dmDitherType;
        DWORD  dmReserved1;
        DWORD  dmReserved2;
        DWORD  dmPanningWidth;
        DWORD  dmPanningHeight;
}
alias DEVMODEA* PDEVMODEA, NPDEVMODEA, LPDEVMODEA;

struct DEVMODEW {
        WCHAR[CCHDEVICENAME]   dmDeviceName;
        WORD   dmSpecVersion;
        WORD   dmDriverVersion;
        WORD   dmSize;
        WORD   dmDriverExtra;
        DWORD  dmFields;
        union {
                struct {
                        short dmOrientation;
                        short dmPaperSize;
                        short dmPaperLength;
                        short dmPaperWidth;
                        short dmScale;
                        short dmCopies;
                        short dmDefaultSource;
                        short dmPrintQuality;
                }
                POINTL dmPosition;
                DWORD  dmDisplayOrientation;
                DWORD  dmDisplayFixedOutput;
        }

        short  dmColor;
        short  dmDuplex;
        short  dmYResolution;
        short  dmTTOption;
        short  dmCollate;
        WCHAR[CCHFORMNAME]  dmFormName;
        WORD   dmLogPixels;
        DWORD  dmBitsPerPel;
        DWORD  dmPelsWidth;
        DWORD  dmPelsHeight;
        union {
                DWORD  dmDisplayFlags;
                DWORD  dmNup;
        }
        DWORD  dmDisplayFrequency;
        DWORD  dmICMMethod;
        DWORD  dmICMIntent;
        DWORD  dmMediaType;
        DWORD  dmDitherType;
        DWORD  dmReserved1;
        DWORD  dmReserved2;
        DWORD  dmPanningWidth;
        DWORD  dmPanningHeight;
}
alias DEVMODEW* PDEVMODEW, NPDEVMODEW, LPDEVMODEW;

/*
 * Information about output options
 */
struct PSFEATURE_OUTPUT {
        BOOL bPageIndependent;
        BOOL bSetPageDevice;
}
alias PSFEATURE_OUTPUT* PPSFEATURE_OUTPUT;

/*
 * Information about custom paper size
 */
struct PSFEATURE_CUSTPAPER {
        LONG lOrientation;
        LONG lWidth;
        LONG lHeight;
        LONG lWidthOffset;
        LONG lHeightOffset;
}
alias PSFEATURE_CUSTPAPER* PPSFEATURE_CUSTPAPER;

struct DIBSECTION {
        BITMAP           dsBm;
        BITMAPINFOHEADER dsBmih;
        DWORD[3]         dsBitfields;
        HANDLE           dshSection;
        DWORD            dsOffset;
}
alias DIBSECTION* PDIBSECTION;

struct DOCINFOA {
        int    cbSize = DOCINFOA.sizeof;
        LPCSTR lpszDocName;
        LPCSTR lpszOutput;
        LPCSTR lpszDatatype;
        DWORD  fwType;
}
alias DOCINFOA* LPDOCINFOA;

struct DOCINFOW {
        int     cbSize = DOCINFOW.sizeof;
        LPCWSTR lpszDocName;
        LPCWSTR lpszOutput;
        LPCWSTR lpszDatatype;
        DWORD   fwType;
}
alias DOCINFOW* LPDOCINFOW;


struct PANOSE {
        BYTE bFamilyType;
        BYTE bSerifStyle;
        BYTE bWeight;
        BYTE bProportion;
        BYTE bContrast;
        BYTE bStrokeVariation;
        BYTE bArmStyle;
        BYTE bLetterform;
        BYTE bMidline;
        BYTE bXHeight;
}
alias PANOSE* LPPANOSE;

struct LOGFONTA {
        LONG lfHeight;
        LONG lfWidth;
        LONG lfEscapement;
        LONG lfOrientation;
        LONG lfWeight;
        BYTE lfItalic;
        BYTE lfUnderline;
        BYTE lfStrikeOut;
        BYTE lfCharSet;
        BYTE lfOutPrecision;
        BYTE lfClipPrecision;
        BYTE lfQuality;
        BYTE lfPitchAndFamily;
        CHAR[LF_FACESIZE] lfFaceName;
}
alias LOGFONTA* PLOGFONTA, NPLOGFONTA, LPLOGFONTA;

struct LOGFONTW {
        LONG lfHeight;
        LONG lfWidth;
        LONG lfEscapement;
        LONG lfOrientation;
        LONG lfWeight;
        BYTE lfItalic;
        BYTE lfUnderline;
        BYTE lfStrikeOut;
        BYTE lfCharSet;
        BYTE lfOutPrecision;
        BYTE lfClipPrecision;
        BYTE lfQuality;
        BYTE lfPitchAndFamily;
        WCHAR[LF_FACESIZE] lfFaceName;
}
alias LOGFONTW* PLOGFONTW, NPLOGFONTW, LPLOGFONTW;

struct EXTLOGFONTA {
        LOGFONTA              elfLogFont;
        BYTE[LF_FULLFACESIZE] elfFullName;
        BYTE[LF_FACESIZE]     elfStyle;
        DWORD                 elfVersion;
        DWORD                 elfStyleSize;
        DWORD                 elfMatch;
        DWORD                 elfReserved;
        BYTE[ELF_VENDOR_SIZE] elfVendorId;
        DWORD                 elfCulture;
        PANOSE                elfPanose;
}
alias EXTLOGFONTA* PEXTLOGFONTA, NPEXTLOGFONTA, LPEXTLOGFONTA;

struct EXTLOGFONTW {
        LOGFONTW               elfLogFont;
        WCHAR[LF_FULLFACESIZE] elfFullName;
        WCHAR[LF_FACESIZE]     elfStyle;
        DWORD                  elfVersion;
        DWORD                  elfStyleSize;
        DWORD                  elfMatch;
        DWORD                  elfReserved;
        BYTE[ELF_VENDOR_SIZE]  elfVendorId;
        DWORD                  elfCulture;
        PANOSE                 elfPanose;
}
alias EXTLOGFONTW* PEXTLOGFONTW, NPEXTLOGFONTW, LPEXTLOGFONTW;

struct LOGPEN {
        UINT     lopnStyle;
        POINT    lopnWidth;
        COLORREF lopnColor;
}
alias LOGPEN* PLOGPEN, NPLOGPEN, LPLOGPEN;

// ---------------------- EMR ------------

struct EMR {
        DWORD iType;
        DWORD nSize;
}
alias EMR* PEMR;

struct EMRANGLEARC {
        EMR    emr;
        POINTL ptlCenter;
        DWORD  nRadius;
        FLOAT  eStartAngle;
        FLOAT  eSweepAngle;
}
alias EMRANGLEARC* PEMRANGLEARC;

struct EMRARC {
        EMR    emr;
        RECTL  rclBox;
        POINTL ptlStart;
        POINTL ptlEnd;
}
alias EMRARC* PEMRARC;
alias TypeDef!(EMRARC) EMRARCTO;
alias EMRARCTO* PEMRARCTO;
alias TypeDef!(EMRARC) EMRCHORD;
alias EMRCHORD* PEMRCHORD;
alias TypeDef!(EMRARC) EMRPIE;
alias EMRPIE* PEMRPIE;

struct XFORM {
        FLOAT eM11;
        FLOAT eM12;
        FLOAT eM21;
        FLOAT eM22;
        FLOAT eDx;
        FLOAT eDy;
}
alias XFORM* PXFORM, LPXFORM;

struct EMRBITBLT {
        EMR      emr;
        RECTL    rclBounds;
        LONG     xDest;
        LONG     yDest;
        LONG     cxDest;
        LONG     cyDest;
        DWORD    dwRop;
        LONG     xSrc;
        LONG     ySrc;
        XFORM    xformSrc;
        COLORREF crBkColorSrc;
        DWORD    iUsageSrc;
        DWORD    offBmiSrc;
        DWORD    cbBmiSrc;
        DWORD    offBitsSrc;
        DWORD    cbBitsSrc;
}
alias EMRBITBLT* PEMRBITBLT;

struct LOGBRUSH {
        UINT     lbStyle;
        COLORREF lbColor;
        LONG     lbHatch;
}
alias TypeDef!(LOGBRUSH) PATTERN;
alias LOGBRUSH* PLOGBRUSH, NPLOGBRUSH, LPLOGBRUSH;
alias PATTERN* PPATTERN, NPPATTERN, LPPATTERN;

struct LOGBRUSH32 {
        UINT lbStyle;
        COLORREF lbColor;
        ULONG lbHatch;
}
alias LOGBRUSH32* PLOGBRUSH32, NPLOGBRUSH32, LPLOGBRUSH32;

struct EMRCREATEBRUSHINDIRECT {
        EMR      emr;
        DWORD    ihBrush;
        LOGBRUSH32 lb;
}
alias EMRCREATEBRUSHINDIRECT* PEMRCREATEBRUSHINDIRECT;

alias LONG LCSCSTYPE, LCSGAMUTMATCH;

struct LOGCOLORSPACEA {
        DWORD lcsSignature;
        DWORD lcsVersion;
        DWORD lcsSize;
        LCSCSTYPE lcsCSType;
        LCSGAMUTMATCH lcsIntent;
        CIEXYZTRIPLE lcsEndpoints;
        DWORD lcsGammaRed;
        DWORD lcsGammaGreen;
        DWORD lcsGammaBlue;
        CHAR[MAX_PATH] lcsFilename;
}
alias LOGCOLORSPACEA* LPLOGCOLORSPACEA;

struct LOGCOLORSPACEW {
        DWORD lcsSignature;
        DWORD lcsVersion;
        DWORD lcsSize;
        LCSCSTYPE lcsCSType;
        LCSGAMUTMATCH lcsIntent;
        CIEXYZTRIPLE lcsEndpoints;
        DWORD lcsGammaRed;
        DWORD lcsGammaGreen;
        DWORD lcsGammaBlue;
        WCHAR[MAX_PATH] lcsFilename;
}
alias LOGCOLORSPACEW* LPLOGCOLORSPACEW;

alias USHORT COLOR16;
struct TRIVERTEX {
        LONG x;
        LONG y;
        COLOR16 Red;
        COLOR16 Green;
        COLOR16 Blue;
        COLOR16 Alpha;
}
alias TRIVERTEX* PTRIVERTEX, LPTRIVERTEX;

struct EMRGLSRECORD {
        EMR emr;
        DWORD cbData;
        BYTE[1] Data;
}
alias EMRGLSRECORD* PEMRGLSRECORD;

struct EMRGLSBOUNDEDRECORD {
        EMR emr;
        RECTL rclBounds;
        DWORD cbData;
        BYTE[1] Data;
}
alias EMRGLSBOUNDEDRECORD* PEMRGLSBOUNDEDRECORD;

struct EMRPIXELFORMAT {
        EMR emr;
        PIXELFORMATDESCRIPTOR pfd;
}
alias EMRPIXELFORMAT* PEMRPIXELFORMAT;

struct EMRCREATECOLORSPACE {
        EMR emr;
        DWORD ihCS;
        LOGCOLORSPACE lcs;
}
alias EMRCREATECOLORSPACE* PEMRCREATECOLORSPACE;

struct EMRSETCOLORSPACE {
        EMR emr;
        DWORD ihCS;
}
alias EMRSETCOLORSPACE* PEMRSETCOLORSPACE;
alias TypeDef!(EMRSETCOLORSPACE) EMRSELECTCOLORSPACE;
alias EMRSELECTCOLORSPACE* PEMRSELECTCOLORSPACE;
alias TypeDef!(EMRSETCOLORSPACE) EMRDELETECOLORSPACE;
alias EMRDELETECOLORSPACE* PEMRDELETECOLORSPACE;

static if (_WIN32_WINNT >= 0x500) {

        struct EMREXTESCAPE {
                EMR emr;
                INT iEscape;
                INT cbEscData;
                BYTE[1] EscData;
        }
        alias EMREXTESCAPE* PEMREXTESCAPE;
        alias TypeDef!(EMREXTESCAPE) EMRDRAWESCAPE;
        alias EMRDRAWESCAPE* PEMRDRAWESCAPE;

        struct EMRNAMEDESCAPE {
                EMR emr;
                INT iEscape;
                INT cbDriver;
                INT cbEscData;
                BYTE[1] EscData;
        }
        alias EMRNAMEDESCAPE* PEMRNAMEDESCAPE;

        struct EMRSETICMPROFILE {
                EMR emr;
                DWORD dwFlags;
                DWORD cbName;
                DWORD cbData;
                BYTE[1] Data;
        }
        alias EMRSETICMPROFILE* PEMRSETICMPROFILE;
        alias TypeDef!(EMRSETICMPROFILE) EMRSETICMPROFILEA;
        alias EMRSETICMPROFILEA* PEMRSETICMPROFILEA;
        alias TypeDef!(EMRSETICMPROFILE) EMRSETICMPROFILEW;
        alias EMRSETICMPROFILEW* PEMRSETICMPROFILEW;

        struct EMRCREATECOLORSPACEW {
                EMR emr;
                DWORD ihCS;
                LOGCOLORSPACEW lcs;
                DWORD dwFlags;
                DWORD cbData;
                BYTE[1] Data;
        }
        alias EMRCREATECOLORSPACEW* PEMRCREATECOLORSPACEW;

        struct EMRCOLORMATCHTOTARGET {
                EMR emr;
                DWORD dwAction;
                DWORD dwFlags;
                DWORD cbName;
                DWORD cbData;
                BYTE[1] Data;
        }
        alias EMRCOLORMATCHTOTARGET* PEMRCOLORMATCHTOTARGET;

        struct EMRCOLORCORRECTPALETTE {
                EMR emr;
                DWORD ihPalette;
                DWORD nFirstEntry;
                DWORD nPalEntries;
                DWORD nReserved;
        }
        alias EMRCOLORCORRECTPALETTE* PEMRCOLORCORRECTPALETTE;

        struct EMRALPHABLEND {
                EMR emr;
                RECTL rclBounds;
                LONG xDest;
                LONG yDest;
                LONG cxDest;
                LONG cyDest;
                DWORD dwRop;
                LONG xSrc;
                LONG ySrc;
                XFORM xformSrc;
                COLORREF crBkColorSrc;
                DWORD iUsageSrc;
                DWORD offBmiSrc;
                DWORD cbBmiSrc;
                DWORD offBitsSrc;
                DWORD cbBitsSrc;
                LONG cxSrc;
                LONG cySrc;
        }
        alias EMRALPHABLEND* PEMRALPHABLEND;

        struct EMRGRADIENTFILL {
                EMR emr;
                RECTL rclBounds;
                DWORD nVer;
                DWORD nTri;
                ULONG ulMode;
                TRIVERTEX[1] Ver;
        }
        alias EMRGRADIENTFILL* PEMRGRADIENTFILL;

        struct EMRTRANSPARENTBLT {
                EMR emr;
                RECTL rclBounds;
                LONG xDest;
                LONG yDest;
                LONG cxDest;
                LONG cyDest;
                DWORD dwRop;
                LONG xSrc;
                LONG ySrc;
                XFORM xformSrc;
                COLORREF crBkColorSrc;
                DWORD iUsageSrc;
                DWORD offBmiSrc;
                DWORD cbBmiSrc;
                DWORD offBitsSrc;
                DWORD cbBitsSrc;
                LONG cxSrc;
                LONG cySrc;
        }
        alias EMRTRANSPARENTBLT* PEMRTRANSPARENTBLT;
}

struct EMRCREATEDIBPATTERNBRUSHPT {
        EMR emr;
        DWORD ihBrush;
        DWORD iUsage;
        DWORD offBmi;
        DWORD cbBmi;
        DWORD offBits;
        DWORD cbBits;
}
alias EMRCREATEDIBPATTERNBRUSHPT* PEMRCREATEDIBPATTERNBRUSHPT;

struct EMRCREATEMONOBRUSH {
        EMR emr;
        DWORD ihBrush;
        DWORD iUsage;
        DWORD offBmi;
        DWORD cbBmi;
        DWORD offBits;
        DWORD cbBits;
}
alias EMRCREATEMONOBRUSH* PEMRCREATEMONOBRUSH;

struct PALETTEENTRY {
        BYTE peRed;
        BYTE peGreen;
        BYTE peBlue;
        BYTE peFlags;
}
alias PALETTEENTRY* PPALETTEENTRY, LPPALETTEENTRY;

struct LOGPALETTE {
        WORD palVersion;
        WORD palNumEntries;
        PALETTEENTRY[1] palPalEntry;
}
alias LOGPALETTE* PLOGPALETTE, NPLOGPALETTE, LPLOGPALETTE;

struct EMRCREATEPALETTE {
        EMR emr;
        DWORD ihPal;
        LOGPALETTE lgpl;
}
alias EMRCREATEPALETTE* PEMRCREATEPALETTE;

struct EMRCREATEPEN {
        EMR emr;
        DWORD ihPen;
        LOGPEN lopn;
}
alias EMRCREATEPEN* PEMRCREATEPEN;

struct EMRELLIPSE {
        EMR emr;
        RECTL rclBox;
}
alias EMRELLIPSE* PEMRELLIPSE;

alias TypeDef!(EMRELLIPSE) EMRRECTANGLE;
alias EMRRECTANGLE* PEMRRECTANGLE;

struct EMREOF {
        EMR emr;
        DWORD nPalEntries;
        DWORD offPalEntries;
        DWORD nSizeLast;
}
alias EMREOF* PEMREOF;

struct EMREXCLUDECLIPRECT {
        EMR emr;
        RECTL rclClip;
}
alias EMREXCLUDECLIPRECT* PEMREXCLUDECLIPRECT;
alias TypeDef!(EMREXCLUDECLIPRECT) EMRINTERSECTCLIPRECT;
alias EMRINTERSECTCLIPRECT* PEMRINTERSECTCLIPRECT;

struct EMREXTCREATEFONTINDIRECTW {
        EMR emr;
        DWORD ihFont;
        EXTLOGFONTW elfw;
}
alias EMREXTCREATEFONTINDIRECTW* PEMREXTCREATEFONTINDIRECTW;

struct EXTLOGPEN {
        UINT elpPenStyle;
        UINT elpWidth;
        UINT elpBrushStyle;
        COLORREF elpColor;
        LONG elpHatch;
        DWORD elpNumEntries;
        DWORD[1] elpStyleEntry;
}
alias EXTLOGPEN* PEXTLOGPEN, NPEXTLOGPEN, LPEXTLOGPEN;

struct EMREXTCREATEPEN {
        EMR emr;
        DWORD ihPen;
        DWORD offBmi;
        DWORD cbBmi;
        DWORD offBits;
        DWORD cbBits;
        EXTLOGPEN elp;
}
alias EMREXTCREATEPEN* PEMREXTCREATEPEN;

struct EMREXTFLOODFILL {
        EMR emr;
        POINTL ptlStart;
        COLORREF crColor;
        DWORD iMode;
}
alias EMREXTFLOODFILL* PEMREXTFLOODFILL;

struct EMREXTSELECTCLIPRGN {
        EMR emr;
        DWORD cbRgnData;
        DWORD iMode;
        BYTE [1]RgnData;
}
alias EMREXTSELECTCLIPRGN* PEMREXTSELECTCLIPRGN;

struct EMRTEXT {
        POINTL ptlReference;
        DWORD nChars;
        DWORD offString;
        DWORD fOptions;
        RECTL rcl;
        DWORD offDx;
}
alias EMRTEXT* PEMRTEXT;

struct EMREXTTEXTOUTA {
        EMR emr;
        RECTL rclBounds;
        DWORD iGraphicsMode;
        FLOAT exScale;
        FLOAT eyScale;
        EMRTEXT emrtext;
}
alias EMREXTTEXTOUTA* PEMREXTTEXTOUTA;
alias TypeDef!(EMREXTTEXTOUTA) EMREXTTEXTOUTW;
alias EMREXTTEXTOUTW* PEMREXTTEXTOUTW;

struct EMRFILLPATH {
        EMR emr;
        RECTL rclBounds;
}
alias EMRFILLPATH* PEMRFILLPATH;

alias TypeDef!(EMRFILLPATH) EMRSTROKEANDFILLPATH;
alias EMRSTROKEANDFILLPATH* PEMRSTROKEANDFILLPATH;

alias TypeDef!(EMRFILLPATH) EMRSTROKEPATH;
alias EMRSTROKEPATH* PEMRSTROKEPATH;

struct EMRFILLRGN {
        EMR emr;
        RECTL rclBounds;
        DWORD cbRgnData;
        DWORD ihBrush;
        BYTE[1] RgnData;
}
alias EMRFILLRGN* PEMRFILLRGN;

struct EMRFORMAT {
        DWORD dSignature;
        DWORD nVersion;
        DWORD cbData;
        DWORD offData;
}
alias EMRFORMAT* PEMRFORMAT;

struct EMRFRAMERGN {
        EMR emr;
        RECTL rclBounds;
        DWORD cbRgnData;
        DWORD ihBrush;
        SIZEL szlStroke;
        BYTE[1] RgnData;
}
alias EMRFRAMERGN* PEMRFRAMERGN;

struct EMRGDICOMMENT {
        EMR emr;
        DWORD cbData;
        BYTE[1] Data;
}
alias EMRGDICOMMENT* PEMRGDICOMMENT;

struct EMRINVERTRGN {
        EMR emr;
        RECTL rclBounds;
        DWORD cbRgnData;
        BYTE[1] RgnData;
}
alias EMRINVERTRGN* PEMRINVERTRGN;
alias TypeDef!(EMRINVERTRGN) EMRPAINTRGN;
alias EMRPAINTRGN* PEMRPAINTRGN;

struct EMRLINETO {
        EMR emr;
        POINTL ptl;
}
alias EMRLINETO* PEMRLINETO;
alias TypeDef!(EMRLINETO) EMRMOVETOEX;
alias EMRMOVETOEX* PEMRMOVETOEX;

struct EMRMASKBLT {
        EMR emr;
        RECTL rclBounds;
        LONG xDest;
        LONG yDest;
        LONG cxDest;
        LONG cyDest;
        DWORD dwRop;
        LONG xSrc;
        LONG ySrc;
        XFORM xformSrc;
        COLORREF crBkColorSrc;
        DWORD iUsageSrc;
        DWORD offBmiSrc;
        DWORD cbBmiSrc;
        DWORD offBitsSrc;
        DWORD cbBitsSrc;
        LONG xMask;
        LONG yMask;
        DWORD iUsageMask;
        DWORD offBmiMask;
        DWORD cbBmiMask;
        DWORD offBitsMask;
        DWORD cbBitsMask;
}
alias EMRMASKBLT* PEMRMASKBLT;

struct EMRMODIFYWORLDTRANSFORM {
        EMR emr;
        XFORM xform;
        DWORD iMode;
}
alias EMRMODIFYWORLDTRANSFORM* PEMRMODIFYWORLDTRANSFORM;

struct EMROFFSETCLIPRGN {
        EMR emr;
        POINTL ptlOffset;
}
alias EMROFFSETCLIPRGN* PEMROFFSETCLIPRGN;

struct EMRPLGBLT {
        EMR emr;
        RECTL rclBounds;
        POINTL[3] aptlDest;
        LONG xSrc;
        LONG ySrc;
        LONG cxSrc;
        LONG cySrc;
        XFORM xformSrc;
        COLORREF crBkColorSrc;
        DWORD iUsageSrc;
        DWORD offBmiSrc;
        DWORD cbBmiSrc;
        DWORD offBitsSrc;
        DWORD cbBitsSrc;
        LONG xMask;
        LONG yMask;
        DWORD iUsageMask;
        DWORD offBmiMask;
        DWORD cbBmiMask;
        DWORD offBitsMask;
        DWORD cbBitsMask;
}
alias EMRPLGBLT* PEMRPLGBLT;

struct EMRPOLYDRAW {
        EMR emr;
        RECTL rclBounds;
        DWORD cptl;
        POINTL[1] aptl;
        BYTE[1] abTypes;
}
alias EMRPOLYDRAW* PEMRPOLYDRAW;

struct EMRPOLYDRAW16 {
        EMR emr;
        RECTL rclBounds;
        DWORD cpts;
        POINTS[1] apts;
        BYTE[1] abTypes;
}
alias EMRPOLYDRAW16* PEMRPOLYDRAW16;

struct EMRPOLYLINE {
        EMR emr;
        RECTL rclBounds;
        DWORD cptl;
        POINTL[1] aptl;
}
alias EMRPOLYLINE* PEMRPOLYLINE;
alias TypeDef!(EMRPOLYLINE) EMRPOLYBEZIER;
alias EMRPOLYBEZIER* PEMRPOLYBEZIER;
alias TypeDef!(EMRPOLYLINE) EMRPOLYGON;
alias EMRPOLYGON* PEMRPOLYGON;
alias TypeDef!(EMRPOLYLINE) EMRPOLYBEZIERTO;
alias EMRPOLYBEZIERTO* PEMRPOLYBEZIERTO;
alias TypeDef!(EMRPOLYLINE) EMRPOLYLINETO;
alias EMRPOLYLINETO* PEMRPOLYLINETO;

struct EMRPOLYLINE16 {
        EMR emr;
        RECTL rclBounds;
        DWORD cpts;
        POINTS[1] apts;
}
alias EMRPOLYLINE16* PEMRPOLYLINE16;
alias TypeDef!(EMRPOLYLINE16) EMRPOLYBEZIER16;
alias EMRPOLYBEZIER16* PEMRPOLYBEZIER16;
alias TypeDef!(EMRPOLYLINE16) EMRPOLYGON16;
alias EMRPOLYGON16* PEMRPOLYGON16;
alias TypeDef!(EMRPOLYLINE16) EMRPOLYBEZIERTO16;
alias EMRPOLYBEZIERTO16* PEMRPOLYBEZIERTO16;
alias TypeDef!(EMRPOLYLINE16) EMRPOLYLINETO16;
alias EMRPOLYLINETO16* PEMRPOLYLINETO16;

struct EMRPOLYPOLYLINE {
        EMR emr;
        RECTL rclBounds;
        DWORD nPolys;
        DWORD cptl;
        DWORD[1] aPolyCounts;
        POINTL[1] aptl;
}
alias EMRPOLYPOLYLINE* PEMRPOLYPOLYLINE;
alias TypeDef!(EMRPOLYPOLYLINE) EMRPOLYPOLYGON;
alias EMRPOLYPOLYGON* PEMRPOLYPOLYGON;

struct EMRPOLYPOLYLINE16 {
        EMR emr;
        RECTL rclBounds;
        DWORD nPolys;
        DWORD cpts;
        DWORD[1] aPolyCounts;
        POINTS[1] apts;
}
alias EMRPOLYPOLYLINE16* PEMRPOLYPOLYLINE16;
alias TypeDef!(EMRPOLYPOLYLINE16) EMRPOLYPOLYGON16;
alias EMRPOLYPOLYGON16* PEMRPOLYPOLYGON16;

struct EMRPOLYTEXTOUTA {
        EMR emr;
        RECTL rclBounds;
        DWORD iGraphicsMode;
        FLOAT exScale;
        FLOAT eyScale;
        LONG cStrings;
        EMRTEXT[1] aemrtext;
}
alias EMRPOLYTEXTOUTA* PEMRPOLYTEXTOUTA;
alias TypeDef!(EMRPOLYTEXTOUTA) EMRPOLYTEXTOUTW;
alias EMRPOLYTEXTOUTW* PEMRPOLYTEXTOUTW;

struct EMRRESIZEPALETTE {
        EMR emr;
        DWORD ihPal;
        DWORD cEntries;
}
alias EMRRESIZEPALETTE* PEMRRESIZEPALETTE;

struct EMRRESTOREDC {
        EMR emr;
        LONG iRelative;
}
alias EMRRESTOREDC* PEMRRESTOREDC;

struct EMRROUNDRECT {
        EMR emr;
        RECTL rclBox;
        SIZEL szlCorner;
}
alias EMRROUNDRECT* PEMRROUNDRECT;

struct EMRSCALEVIEWPORTEXTEX {
        EMR emr;
        LONG xNum;
        LONG xDenom;
        LONG yNum;
        LONG yDenom;
}
alias EMRSCALEVIEWPORTEXTEX* PEMRSCALEVIEWPORTEXTEX;
alias TypeDef!(EMRSCALEVIEWPORTEXTEX) EMRSCALEWINDOWEXTEX;
alias EMRSCALEWINDOWEXTEX* PEMRSCALEWINDOWEXTEX;

struct EMRSELECTOBJECT {
        EMR emr;
        DWORD ihObject;
}
alias EMRSELECTOBJECT* PEMRSELECTOBJECT;
alias TypeDef!(EMRSELECTOBJECT) EMRDELETEOBJECT;
alias EMRDELETEOBJECT* PEMRDELETEOBJECT;

struct EMRSELECTPALETTE {
        EMR emr;
        DWORD ihPal;
}
alias EMRSELECTPALETTE* PEMRSELECTPALETTE;

struct EMRSETARCDIRECTION {
        EMR emr;
        DWORD iArcDirection;
}
alias EMRSETARCDIRECTION* PEMRSETARCDIRECTION;

struct EMRSETTEXTCOLOR {
        EMR emr;
        COLORREF crColor;
}
alias EMRSETTEXTCOLOR* PEMRSETTEXTCOLOR;
alias TypeDef!(EMRSETTEXTCOLOR) EMRSETBKCOLOR;
alias EMRSETBKCOLOR* PEMRSETBKCOLOR;

struct EMRSETCOLORADJUSTMENT {
        EMR emr;
        COLORADJUSTMENT ColorAdjustment;
}
alias EMRSETCOLORADJUSTMENT* PEMRSETCOLORADJUSTMENT;

struct EMRSETDIBITSTODEVICE {
        EMR emr;
        RECTL rclBounds;
        LONG xDest;
        LONG yDest;
        LONG xSrc;
        LONG ySrc;
        LONG cxSrc;
        LONG cySrc;
        DWORD offBmiSrc;
        DWORD cbBmiSrc;
        DWORD offBitsSrc;
        DWORD cbBitsSrc;
        DWORD iUsageSrc;
        DWORD iStartScan;
        DWORD cScans;
}
alias EMRSETDIBITSTODEVICE* PEMRSETDIBITSTODEVICE;

struct EMRSETMAPPERFLAGS {
        EMR emr;
        DWORD dwFlags;
}
alias EMRSETMAPPERFLAGS* PEMRSETMAPPERFLAGS;

struct EMRSETMITERLIMIT {
        EMR emr;
        FLOAT eMiterLimit;
}
alias EMRSETMITERLIMIT* PEMRSETMITERLIMIT;

struct EMRSETPALETTEENTRIES {
        EMR emr;
        DWORD ihPal;
        DWORD iStart;
        DWORD cEntries;
        PALETTEENTRY[1] aPalEntries;
}
alias EMRSETPALETTEENTRIES* PEMRSETPALETTEENTRIES;

struct EMRSETPIXELV {
        EMR emr;
        POINTL ptlPixel;
        COLORREF crColor;
}
alias EMRSETPIXELV* PEMRSETPIXELV;

struct EMRSETVIEWPORTEXTEX {
        EMR emr;
        SIZEL szlExtent;
}
alias EMRSETVIEWPORTEXTEX* PEMRSETVIEWPORTEXTEX;
alias TypeDef!(EMRSETVIEWPORTEXTEX) EMRSETWINDOWEXTEX;
alias EMRSETWINDOWEXTEX* PEMRSETWINDOWEXTEX;

struct EMRSETVIEWPORTORGEX {
        EMR emr;
        POINTL ptlOrigin;
}
alias EMRSETVIEWPORTORGEX* PEMRSETVIEWPORTORGEX;
alias TypeDef!(EMRSETVIEWPORTORGEX) EMRSETWINDOWORGEX;
alias EMRSETWINDOWORGEX* PEMRSETWINDOWORGEX;
alias TypeDef!(EMRSETVIEWPORTORGEX) EMRSETBRUSHORGEX;
alias EMRSETBRUSHORGEX* PEMRSETBRUSHORGEX;

struct EMRSETWORLDTRANSFORM {
        EMR emr;
        XFORM xform;
}
alias EMRSETWORLDTRANSFORM* PEMRSETWORLDTRANSFORM;

struct EMRSTRETCHBLT {
        EMR emr;
        RECTL rclBounds;
        LONG xDest;
        LONG yDest;
        LONG cxDest;
        LONG cyDest;
        DWORD dwRop;
        LONG xSrc;
        LONG ySrc;
        XFORM xformSrc;
        COLORREF crBkColorSrc;
        DWORD iUsageSrc;
        DWORD offBmiSrc;
        DWORD cbBmiSrc;
        DWORD offBitsSrc;
        DWORD cbBitsSrc;
        LONG cxSrc;
        LONG cySrc;
}
alias EMRSTRETCHBLT* PEMRSTRETCHBLT;

struct EMRSTRETCHDIBITS {
        EMR emr;
        RECTL rclBounds;
        LONG xDest;
        LONG yDest;
        LONG xSrc;
        LONG ySrc;
        LONG cxSrc;
        LONG cySrc;
        DWORD offBmiSrc;
        DWORD cbBmiSrc;
        DWORD offBitsSrc;
        DWORD cbBitsSrc;
        DWORD iUsageSrc;
        DWORD dwRop;
        LONG cxDest;
        LONG cyDest;
}
alias EMRSTRETCHDIBITS* PEMRSTRETCHDIBITS;

struct EMRABORTPATH {
        EMR emr;
}
alias EMRABORTPATH* PEMRABORTPATH;
alias TypeDef!(EMRABORTPATH) EMRBEGINPATH;
alias EMRBEGINPATH* PEMRBEGINPATH;
alias TypeDef!(EMRABORTPATH) EMRENDPATH;
alias EMRENDPATH* PEMRENDPATH;
alias TypeDef!(EMRABORTPATH) EMRCLOSEFIGURE;
alias EMRCLOSEFIGURE* PEMRCLOSEFIGURE;
alias TypeDef!(EMRABORTPATH) EMRFLATTENPATH;
alias EMRFLATTENPATH* PEMRFLATTENPATH;
alias TypeDef!(EMRABORTPATH) EMRWIDENPATH;
alias EMRWIDENPATH* PEMRWIDENPATH;
alias TypeDef!(EMRABORTPATH) EMRSETMETARGN;
alias EMRSETMETARGN* PEMRSETMETARGN;
alias TypeDef!(EMRABORTPATH) EMRSAVEDC;
alias EMRSAVEDC* PEMRSAVEDC;
alias TypeDef!(EMRABORTPATH) EMRREALIZEPALETTE;
alias EMRREALIZEPALETTE* PEMRREALIZEPALETTE;

struct EMRSELECTCLIPPATH {
        EMR emr;
        DWORD iMode;
}
alias EMRSELECTCLIPPATH* PEMRSELECTCLIPPATH;
alias TypeDef!(EMRSELECTCLIPPATH) EMRSETBKMODE;
alias EMRSETBKMODE* PEMRSETBKMODE;
alias TypeDef!(EMRSELECTCLIPPATH) EMRSETMAPMODE;
alias EMRSETMAPMODE* PEMRSETMAPMODE;
alias TypeDef!(EMRSELECTCLIPPATH) EMRSETPOLYFILLMODE;
alias EMRSETPOLYFILLMODE* PEMRSETPOLYFILLMODE;
alias TypeDef!(EMRSELECTCLIPPATH) EMRSETROP2;
alias EMRSETROP2* PEMRSETROP2;
alias TypeDef!(EMRSELECTCLIPPATH) EMRSETSTRETCHBLTMODE;
alias EMRSETSTRETCHBLTMODE* PEMRSETSTRETCHBLTMODE;
alias TypeDef!(EMRSELECTCLIPPATH) EMRSETICMMODE;
alias EMRSETICMMODE* PEMRSETICMMODE;
alias TypeDef!(EMRSELECTCLIPPATH) EMRSETTEXTALIGN;
alias EMRSETTEXTALIGN* PEMRSETTEXTALIGN;
alias TypeDef!(EMRSELECTCLIPPATH) EMRENABLEICM;
alias EMRENABLEICM* PEMRENABLEICM;
static if (_WIN32_WINNT >= 0x500) {
        alias TypeDef!(EMRSELECTCLIPPATH) EMRSETLAYOUT;
        alias EMRSETLAYOUT* PEMRSETLAYOUT;
}

align(2):
struct METAHEADER {
        WORD mtType;
        WORD mtHeaderSize;
        WORD mtVersion;
        DWORD mtSize;
        WORD mtNoObjects;
        DWORD mtMaxRecord;
        WORD mtNoParameters;
}
alias METAHEADER* PMETAHEADER;
alias METAHEADER* LPMETAHEADER;

align:

struct ENHMETAHEADER {
        DWORD iType = EMR_HEADER;
        DWORD nSize = ENHMETAHEADER.sizeof;
        RECTL rclBounds;
        RECTL rclFrame;
        DWORD dSignature = ENHMETA_SIGNATURE;
        DWORD nVersion;
        DWORD nBytes;
        DWORD nRecords;
        WORD nHandles;
        WORD sReserved;
        DWORD nDescription;
        DWORD offDescription;
        DWORD nPalEntries;
        SIZEL szlDevice;
        SIZEL szlMillimeters;
        DWORD cbPixelFormat;
        DWORD offPixelFormat;
        DWORD bOpenGL;
        static if (_WIN32_WINNT >= 0x500) {
                SIZEL szlMicrometers;
        }
}
alias ENHMETAHEADER* PENHMETAHEADER, LPENHMETAHEADER;

struct METARECORD {
        DWORD rdSize;
        WORD rdFunction;
        WORD[1] rdParm;
}
alias METARECORD* PMETARECORD;
alias METARECORD* LPMETARECORD;

struct ENHMETARECORD {
        DWORD iType;
        DWORD nSize;
        DWORD[1] dParm;
}
alias ENHMETARECORD* PENHMETARECORD, LPENHMETARECORD;

// ---

struct HANDLETABLE {
        HGDIOBJ[1] objectHandle;
}
alias HANDLETABLE* PHANDLETABLE, LPHANDLETABLE;

struct TEXTMETRICA {
        LONG tmHeight;
        LONG tmAscent;
        LONG tmDescent;
        LONG tmInternalLeading;
        LONG tmExternalLeading;
        LONG tmAveCharWidth;
        LONG tmMaxCharWidth;
        LONG tmWeight;
        LONG tmOverhang;
        LONG tmDigitizedAspectX;
        LONG tmDigitizedAspectY;
        BYTE tmFirstChar;
        BYTE tmLastChar;
        BYTE tmDefaultChar;
        BYTE tmBreakChar;
        BYTE tmItalic;
        BYTE tmUnderlined;
        BYTE tmStruckOut;
        BYTE tmPitchAndFamily;
        BYTE tmCharSet;
}
alias TEXTMETRICA* PTEXTMETRICA, NPTEXTMETRICA, LPTEXTMETRICA;

struct TEXTMETRICW {
        LONG tmHeight;
        LONG tmAscent;
        LONG tmDescent;
        LONG tmInternalLeading;
        LONG tmExternalLeading;
        LONG tmAveCharWidth;
        LONG tmMaxCharWidth;
        LONG tmWeight;
        LONG tmOverhang;
        LONG tmDigitizedAspectX;
        LONG tmDigitizedAspectY;
        WCHAR tmFirstChar;
        WCHAR tmLastChar;
        WCHAR tmDefaultChar;
        WCHAR tmBreakChar;
        BYTE tmItalic;
        BYTE tmUnderlined;
        BYTE tmStruckOut;
        BYTE tmPitchAndFamily;
        BYTE tmCharSet;
}
alias TEXTMETRICW* PTEXTMETRICW, NPTEXTMETRICW, LPTEXTMETRICW;

struct RGNDATAHEADER {
        DWORD dwSize;
        DWORD iType;
        DWORD nCount;
        DWORD nRgnSize;
        RECT rcBound;
}
alias RGNDATAHEADER* PRGNDATAHEADER;

struct RGNDATA {
        RGNDATAHEADER rdh;
        char[1] Buffer;
}
alias RGNDATA* PRGNDATA, NPRGNDATA, LPRGNDATA;

/* for GetRandomRgn */
const SYSRGN=4;
struct GCP_RESULTSA {
        DWORD lStructSize;
        LPSTR lpOutString;
        UINT* lpOrder;
        INT* lpDx;
        INT* lpCaretPos;
        LPSTR lpClass;
        LPWSTR lpGlyphs;
        UINT nGlyphs;
        UINT nMaxFit;
}
alias GCP_RESULTSA* LPGCP_RESULTSA;

struct GCP_RESULTSW {
        DWORD lStructSize;
        LPWSTR lpOutString;
        UINT* lpOrder;
        INT* lpDx;
        INT* lpCaretPos;
        LPWSTR lpClass;
        LPWSTR lpGlyphs;
        UINT nGlyphs;
        UINT nMaxFit;
}
alias GCP_RESULTSW* LPGCP_RESULTSW;

struct GLYPHMETRICS {
        UINT gmBlackBoxX;
        UINT gmBlackBoxY;
        POINT gmptGlyphOrigin;
        short gmCellIncX;
        short gmCellIncY;
}
alias GLYPHMETRICS* LPGLYPHMETRICS;

static if (_WIN32_WINNT >= 0x500) {
        struct WCRANGE {
                WCHAR  wcLow;
                USHORT cGlyphs;
        }
        alias WCRANGE* PWCRANGE, LPWCRANGE;

        struct GLYPHSET {
                DWORD cbThis;
                DWORD flAccel;
                DWORD cGlyphsSupported;
                DWORD cRanges;
                WCRANGE[1] ranges;
        }
        alias GLYPHSET* PGLYPHSET, LPGLYPHSET;

        const DWORD GS_8BIT_INDICES = 0x00000001;
}

struct KERNINGPAIR {
        WORD wFirst;
        WORD wSecond;
        int iKernAmount;
}
alias KERNINGPAIR* LPKERNINGPAIR;

struct FIXED {
        WORD fract;
        short value;
}

struct MAT2 {
        FIXED eM11;
        FIXED eM12;
        FIXED eM21;
        FIXED eM22;
}
alias MAT2* LPMAT2;

struct OUTLINETEXTMETRICA {
        UINT otmSize;
        TEXTMETRICA otmTextMetrics;
        BYTE otmFiller;
        PANOSE otmPanoseNumber;
        UINT otmfsSelection;
        UINT otmfsType;
        int otmsCharSlopeRise;
        int otmsCharSlopeRun;
        int otmItalicAngle;
        UINT otmEMSquare;
        int otmAscent;
        int otmDescent;
        UINT otmLineGap;
        UINT otmsCapEmHeight;
        UINT otmsXHeight;
        RECT otmrcFontBox;
        int otmMacAscent;
        int otmMacDescent;
        UINT otmMacLineGap;
        UINT otmusMinimumPPEM;
        POINT otmptSubscriptSize;
        POINT otmptSubscriptOffset;
        POINT otmptSuperscriptSize;
        POINT otmptSuperscriptOffset;
        UINT otmsStrikeoutSize;
        int otmsStrikeoutPosition;
        int otmsUnderscoreSize;
        int otmsUnderscorePosition;
        PSTR otmpFamilyName;
        PSTR otmpFaceName;
        PSTR otmpStyleName;
        PSTR otmpFullName;
}
alias OUTLINETEXTMETRICA* POUTLINETEXTMETRICA, NPOUTLINETEXTMETRICA, LPOUTLINETEXTMETRICA;

struct OUTLINETEXTMETRICW {
        UINT otmSize;
        TEXTMETRICW otmTextMetrics;
        BYTE otmFiller;
        PANOSE otmPanoseNumber;
        UINT otmfsSelection;
        UINT otmfsType;
        int otmsCharSlopeRise;
        int otmsCharSlopeRun;
        int otmItalicAngle;
        UINT otmEMSquare;
        int otmAscent;
        int otmDescent;
        UINT otmLineGap;
        UINT otmsCapEmHeight;
        UINT otmsXHeight;
        RECT otmrcFontBox;
        int otmMacAscent;
        int otmMacDescent;
        UINT otmMacLineGap;
        UINT otmusMinimumPPEM;
        POINT otmptSubscriptSize;
        POINT otmptSubscriptOffset;
        POINT otmptSuperscriptSize;
        POINT otmptSuperscriptOffset;
        UINT otmsStrikeoutSize;
        int otmsStrikeoutPosition;
        int otmsUnderscoreSize;
        int otmsUnderscorePosition;
        PSTR otmpFamilyName;
        PSTR otmpFaceName;
        PSTR otmpStyleName;
        PSTR otmpFullName;
}
alias OUTLINETEXTMETRICW* POUTLINETEXTMETRICW, NPOUTLINETEXTMETRICW, LPOUTLINETEXTMETRICW;

struct RASTERIZER_STATUS {
        short nSize;
        short wFlags;
        short nLanguageID;
}
alias RASTERIZER_STATUS* LPRASTERIZER_STATUS;

struct POLYTEXTA {
        int x;
        int y;
        UINT n;
        LPCSTR lpstr;
        UINT uiFlags;
        RECT rcl;
        int* pdx;
}
alias POLYTEXTA* PPOLYTEXTA, NPPOLYTEXTA, LPPOLYTEXTA;

struct POLYTEXTW {
        int x;
        int y;
        UINT n;
        LPCWSTR lpstr;
        UINT uiFlags;
        RECT rcl;
        int* pdx;
}
alias POLYTEXTW* PPOLYTEXTW, NPPOLYTEXTW, LPPOLYTEXTW;

struct PIXELFORMATDESCRIPTOR {
        WORD nSize;
        WORD nVersion;
        DWORD dwFlags;
        BYTE iPixelType;
        BYTE cColorBits;
        BYTE cRedBits;
        BYTE cRedShift;
        BYTE cGreenBits;
        BYTE cGreenShift;
        BYTE cBlueBits;
        BYTE cBlueShift;
        BYTE cAlphaBits;
        BYTE cAlphaShift;
        BYTE cAccumBits;
        BYTE cAccumRedBits;
        BYTE cAccumGreenBits;
        BYTE cAccumBlueBits;
        BYTE cAccumAlphaBits;
        BYTE cDepthBits;
        BYTE cStencilBits;
        BYTE cAuxBuffers;
        BYTE iLayerType;
        BYTE bReserved;
        DWORD dwLayerMask;
        DWORD dwVisibleMask;
        DWORD dwDamageMask;
}
alias PIXELFORMATDESCRIPTOR* PPIXELFORMATDESCRIPTOR, LPPIXELFORMATDESCRIPTOR;

struct METAFILEPICT {
        LONG mm;
        LONG xExt;
        LONG yExt;
        HMETAFILE hMF;
}
alias METAFILEPICT* LPMETAFILEPICT;

struct LOCALESIGNATURE {
        DWORD[4] lsUsb;
        DWORD[2] lsCsbDefault;
        DWORD[2] lsCsbSupported;
}
alias LOCALESIGNATURE* PLOCALESIGNATURE, LPLOCALESIGNATURE;

alias LONG LCSTYPE; /* What this for? */

align(4):
struct NEWTEXTMETRICA {
        LONG tmHeight;
        LONG tmAscent;
        LONG tmDescent;
        LONG tmInternalLeading;
        LONG tmExternalLeading;
        LONG tmAveCharWidth;
        LONG tmMaxCharWidth;
        LONG tmWeight;
        LONG tmOverhang;
        LONG tmDigitizedAspectX;
        LONG tmDigitizedAspectY;
        BYTE tmFirstChar;
        BYTE tmLastChar;
        BYTE tmDefaultChar;
        BYTE tmBreakChar;
        BYTE tmItalic;
        BYTE tmUnderlined;
        BYTE tmStruckOut;
        BYTE tmPitchAndFamily;
        BYTE tmCharSet;
        DWORD ntmFlags;
        UINT ntmSizeEM;
        UINT ntmCellHeight;
        UINT ntmAvgWidth;
}
alias NEWTEXTMETRICA* PNEWTEXTMETRICA, NPNEWTEXTMETRICA, LPNEWTEXTMETRICA;

struct NEWTEXTMETRICW {
        LONG tmHeight;
        LONG tmAscent;
        LONG tmDescent;
        LONG tmInternalLeading;
        LONG tmExternalLeading;
        LONG tmAveCharWidth;
        LONG tmMaxCharWidth;
        LONG tmWeight;
        LONG tmOverhang;
        LONG tmDigitizedAspectX;
        LONG tmDigitizedAspectY;
        WCHAR tmFirstChar;
        WCHAR tmLastChar;
        WCHAR tmDefaultChar;
        WCHAR tmBreakChar;
        BYTE tmItalic;
        BYTE tmUnderlined;
        BYTE tmStruckOut;
        BYTE tmPitchAndFamily;
        BYTE tmCharSet;
        DWORD ntmFlags;
        UINT ntmSizeEM;
        UINT ntmCellHeight;
        UINT ntmAvgWidth;
}
alias NEWTEXTMETRICW* PNEWTEXTMETRICW, NPNEWTEXTMETRICW, LPNEWTEXTMETRICW;

align:
struct NEWTEXTMETRICEXA {
        NEWTEXTMETRICA ntmTm;
        FONTSIGNATURE ntmFontSig;
}

struct NEWTEXTMETRICEXW {
        NEWTEXTMETRICW ntmTm;
        FONTSIGNATURE ntmFontSig;
}

struct PELARRAY {
        LONG paXCount;
        LONG paYCount;
        LONG paXExt;
        LONG paYExt;
        BYTE paRGBs;
}
alias PELARRAY* PPELARRAY, NPPELARRAY, LPPELARRAY;

struct ENUMLOGFONTA {
        LOGFONTA elfLogFont;
        BYTE[LF_FULLFACESIZE] elfFullName;
        BYTE[LF_FACESIZE] elfStyle;
}
alias ENUMLOGFONTA* LPENUMLOGFONTA;

struct ENUMLOGFONTW {
        LOGFONTW elfLogFont;
        WCHAR[LF_FULLFACESIZE] elfFullName;
        WCHAR[LF_FACESIZE] elfStyle;
}
alias ENUMLOGFONTW* LPENUMLOGFONTW;

struct ENUMLOGFONTEXA {
        LOGFONTA elfLogFont;
        BYTE[LF_FULLFACESIZE] elfFullName;
        BYTE[LF_FACESIZE] elfStyle;
        BYTE[LF_FACESIZE] elfScript;
}
alias ENUMLOGFONTEXA* LPENUMLOGFONTEXA;

struct ENUMLOGFONTEXW {
        LOGFONTW elfLogFont;
        WCHAR[LF_FULLFACESIZE] elfFullName;
        WCHAR[LF_FACESIZE] elfStyle;
        WCHAR[LF_FACESIZE] elfScript;
}
alias ENUMLOGFONTEXW* LPENUMLOGFONTEXW;

struct POINTFX {
        FIXED x;
        FIXED y;
}
alias POINTFX* LPPOINTFX;

struct TTPOLYCURVE {
        WORD wType;
        WORD cpfx;
        POINTFX[1] apfx;
}
alias TTPOLYCURVE* LPTTPOLYCURVE;

struct TTPOLYGONHEADER {
        DWORD cb;
        DWORD dwType;
        POINTFX pfxStart;
}
alias TTPOLYGONHEADER* LPTTPOLYGONHEADER;

struct POINTFLOAT {
        FLOAT x;
        FLOAT y;
}
alias POINTFLOAT* PPOINTFLOAT;

struct GLYPHMETRICSFLOAT {
        FLOAT gmfBlackBoxX;
        FLOAT gmfBlackBoxY;
        POINTFLOAT gmfptGlyphOrigin;
        FLOAT gmfCellIncX;
        FLOAT gmfCellIncY;
}
alias GLYPHMETRICSFLOAT* PGLYPHMETRICSFLOAT, LPGLYPHMETRICSFLOAT;

struct LAYERPLANEDESCRIPTOR {
        WORD nSize;
        WORD nVersion;
        DWORD dwFlags;
        BYTE iPixelType;
        BYTE cColorBits;
        BYTE cRedBits;
        BYTE cRedShift;
        BYTE cGreenBits;
        BYTE cGreenShift;
        BYTE cBlueBits;
        BYTE cBlueShift;
        BYTE cAlphaBits;
        BYTE cAlphaShift;
        BYTE cAccumBits;
        BYTE cAccumRedBits;
        BYTE cAccumGreenBits;
        BYTE cAccumBlueBits;
        BYTE cAccumAlphaBits;
        BYTE cDepthBits;
        BYTE cStencilBits;
        BYTE cAuxBuffers;
        BYTE iLayerPlane;
        BYTE bReserved;
        COLORREF crTransparent;
}
alias LAYERPLANEDESCRIPTOR* PLAYERPLANEDESCRIPTOR, LPLAYERPLANEDESCRIPTOR;

struct BLENDFUNCTION {
        BYTE BlendOp;
        BYTE BlendFlags;
        BYTE SourceConstantAlpha;
        BYTE AlphaFormat;
}
alias BLENDFUNCTION* PBLENDFUNCTION, LPBLENDFUNCTION;

const MM_MAX_NUMAXES = 16;

struct DESIGNVECTOR {
        DWORD dvReserved;
        DWORD dvNumAxes;
        LONG[MM_MAX_NUMAXES] dvValues;
}
alias DESIGNVECTOR* PDESIGNVECTOR, LPDESIGNVECTOR;
const STAMP_DESIGNVECTOR = 0x8000000 + 'd' + ('v' << 8);
const STAMP_AXESLIST     = 0x8000000 + 'a' + ('l' << 8);

static if (_WIN32_WINNT >= 0x500) {

        const MM_MAX_AXES_NAMELEN = 16;

        struct AXISINFOA {
                LONG axMinValue;
                LONG axMaxValue;
                BYTE[MM_MAX_AXES_NAMELEN] axAxisName;
        }
        alias AXISINFOA* PAXISINFOA, LPAXISINFOA;

        struct AXISINFOW {
                LONG axMinValue;
                LONG axMaxValue;
                WCHAR[MM_MAX_AXES_NAMELEN] axAxisName;
        }
        alias AXISINFOW* PAXISINFOW, LPAXISINFOW;

        version (Unicode) {
                alias AXISINFOW AXISINFO;
                alias PAXISINFOW PAXISINFO;
                alias LPAXISINFOW LPAXISINFO;
        }
        else {
                alias AXISINFOA AXISINFO;
                alias PAXISINFOA PAXISINFO;
                alias LPAXISINFOA LPAXISINFO;
        }

        struct AXESLISTA {
                DWORD axlReserved;
                DWORD axlNumAxes;
                AXISINFOA[MM_MAX_NUMAXES] axlAxisInfo;
        }
        alias AXESLISTA* PAXESLISTA, LPAXESLISTA;

        struct AXESLISTW {
                DWORD axlReserved;
                DWORD axlNumAxes;
                AXISINFOW[MM_MAX_NUMAXES] axlAxisInfo;
        }
        alias AXESLISTW* PAXESLISTW, LPAXESLISTW;

        version (Unicode) {
                alias AXESLISTW AXESLIST;
                alias PAXESLISTW PAXESLIST;
                alias LPAXESLISTW LPAXESLIST;
        }
        else {
                alias AXESLISTA AXESLIST;
                alias PAXESLISTA PAXESLIST;
                alias LPAXESLISTA LPAXESLIST;
        }

        struct ENUMLOGFONTEXDVA {
                ENUMLOGFONTEXA elfEnumLogfontEx;
                DESIGNVECTOR   elfDesignVector;
        }
        alias ENUMLOGFONTEXDVA* PENUMLOGFONTEXDVA, LPENUMLOGFONTEXDVA;

        struct ENUMLOGFONTEXDVW {
                ENUMLOGFONTEXW elfEnumLogfontEx;
                DESIGNVECTOR   elfDesignVector;
        }
        alias ENUMLOGFONTEXDVW* PENUMLOGFONTEXDVW, LPENUMLOGFONTEXDVW;

        HFONT CreateFontIndirectExA(const(ENUMLOGFONTEXDVA)*);
        HFONT CreateFontIndirectExW(const(ENUMLOGFONTEXDVW)*);
        version (Unicode)
                alias CreateFontIndirectExW CreateFontIndirectEx;
        else
                alias CreateFontIndirectExA CreateFontIndirectEx;

        struct ENUMTEXTMETRICA {
                NEWTEXTMETRICEXA etmNewTextMetricEx;
                AXESLISTA etmAxesList;
        }
        alias ENUMTEXTMETRICA* PENUMTEXTMETRICA, LPENUMTEXTMETRICA;

        struct ENUMTEXTMETRICW {
                NEWTEXTMETRICEXW etmNewTextMetricEx;
                AXESLISTW etmAxesList;
        }
        alias ENUMTEXTMETRICW* PENUMTEXTMETRICW, LPENUMTEXTMETRICW;

        version (Unicode) {
                alias ENUMTEXTMETRICW ENUMTEXTMETRIC;
                alias PENUMTEXTMETRICW PENUMTEXTMETRIC;
                alias LPENUMTEXTMETRICW LPENUMTEXTMETRIC;
        }
        else {
                alias ENUMTEXTMETRICA ENUMTEXTMETRIC;
                alias PENUMTEXTMETRICA PENUMTEXTMETRIC;
                alias LPENUMTEXTMETRICA LPENUMTEXTMETRIC;
        }
} /* _WIN32_WINNT >= 0x500 */

struct GRADIENT_TRIANGLE {
        ULONG Vertex1;
        ULONG Vertex2;
        ULONG Vertex3;
}
alias GRADIENT_TRIANGLE* PGRADIENT_TRIANGLE, LPGRADIENT_TRIANGLE;

struct GRADIENT_RECT {
        ULONG UpperLeft;
        ULONG LowerRight;
}
alias GRADIENT_RECT* PGRADIENT_RECT, LPGRADIENT_RECT;

struct DISPLAY_DEVICEA {
        DWORD cb;
        CHAR[32] DeviceName;
        CHAR[128] DeviceString;
        DWORD StateFlags;
        CHAR[128] DeviceID;
        CHAR[128] DeviceKey;
}
alias DISPLAY_DEVICEA* PDISPLAY_DEVICEA, LPDISPLAY_DEVICEA;

struct DISPLAY_DEVICEW {
        DWORD cb;
        WCHAR[32] DeviceName;
        WCHAR[128] DeviceString;
        DWORD StateFlags;
        WCHAR[128] DeviceID;
        WCHAR[128] DeviceKey;
}
alias DISPLAY_DEVICEW* PDISPLAY_DEVICEW, LPDISPLAY_DEVICEW;

struct DRAWPATRECT {
        POINT ptPosition;
        POINT ptSize;
        WORD wStyle;
        WORD wPattern;
}
alias DRAWPATRECT* PDRAWPATRECT;

// ---------
// Callbacks

alias BOOL function (HDC, int) ABORTPROC;
alias int function (HDC, HANDLETABLE*, METARECORD*, int, LPARAM) MFENUMPROC;
alias int function (HDC, HANDLETABLE*, const(ENHMETARECORD)*, int, LPARAM) ENHMFENUMPROC;
alias int function (const(LOGFONTA)*, const(TEXTMETRICA)*, DWORD, LPARAM) FONTENUMPROCA, OLDFONTENUMPROCA;
alias int function (const(LOGFONTW)*, const(TEXTMETRICW)*, DWORD, LPARAM) FONTENUMPROCW, OLDFONTENUMPROCW;
alias int function (LPSTR, LPARAM) ICMENUMPROCA;
alias int function (LPWSTR, LPARAM) ICMENUMPROCW;
alias void function (LPVOID, LPARAM) GOBJENUMPROC;
alias void function (int, int, LPARAM) LINEDDAPROC;
alias UINT function (HWND, HMODULE, LPDEVMODEA, LPSTR, LPSTR, LPDEVMODEA, LPSTR, UINT) LPFNDEVMODE;
alias DWORD function (LPSTR, LPSTR, UINT, LPSTR, LPDEVMODEA) LPFNDEVCAPS;


// ---------
// C Macros.
// FIXME:
//POINTS MAKEPOINTS(DWORD dwValue) #define MAKEPOINTS(l) (*((POINTS*)&(l)))

DWORD MAKEROP4(DWORD fore, DWORD back) {
        return ((back<<8) & 0xFF000000) | (fore);
}

COLORREF CMYK(BYTE c, BYTE m, BYTE y, BYTE k) {
        return cast(COLORREF)(k | (y << 8) | (m << 16) | (c << 24));
}

BYTE GetCValue(COLORREF cmyk) {
        return cast(BYTE)(cmyk >> 24);
}

BYTE GetMValue(COLORREF cmyk) {
        return cast(BYTE)(cmyk >> 16);
}

BYTE GetYValue(COLORREF cmyk) {
        return cast(BYTE)(cmyk >> 8);
}

BYTE GetKValue(COLORREF cmyk) {
        return cast(BYTE)cmyk;
}

COLORREF RGB(BYTE r, BYTE g, BYTE b) {
        return cast(COLORREF)(r | (g << 8) | (b << 16));
}

BYTE GetRValue(COLORREF c) {
        return cast(BYTE)c;
}

BYTE GetGValue(COLORREF c) {
        return cast(BYTE)(c >> 8);
}

BYTE GetBValue(COLORREF c) {
        return cast(BYTE)(c >> 16);
}

COLORREF PALETTEINDEX(WORD i) {
        return 0x01000000 | cast(COLORREF) i;
}

COLORREF PALETTERGB(BYTE r, BYTE g, BYTE b) {
        return 0x02000000|RGB(r, g, b);
}

extern(Windows) {
        int AbortDoc(HDC);
        BOOL AbortPath(HDC);
        int AddFontResourceA(LPCSTR);
        int AddFontResourceW(LPCWSTR);
        BOOL AngleArc(HDC, int, int, DWORD, FLOAT, FLOAT);
        BOOL AnimatePalette(HPALETTE, UINT, UINT, const(PALETTEENTRY)*);
        BOOL Arc(HDC, int, int, int, int, int, int, int, int);
        BOOL ArcTo(HDC, int, int, int, int, int, int, int, int);
        BOOL BeginPath(HDC);
        BOOL BitBlt(HDC, int, int, int, int, HDC, int, int, DWORD);
        BOOL CancelDC(HDC);
        BOOL CheckColorsInGamut(HDC, PVOID, PVOID, DWORD);
        BOOL Chord(HDC, int, int, int, int, int, int, int, int);
        int ChoosePixelFormat(HDC, const(PIXELFORMATDESCRIPTOR)*);
        HENHMETAFILE CloseEnhMetaFile(HDC);
        BOOL CloseFigure(HDC);
        HMETAFILE CloseMetaFile(HDC);
        BOOL ColorMatchToTarget(HDC, HDC, DWORD);
        BOOL ColorCorrectPalette(HDC, HPALETTE, DWORD, DWORD);
        int CombineRgn(HRGN, HRGN, HRGN, int);
        BOOL CombineTransform(LPXFORM, const(XFORM)*, const(XFORM)*);
        HENHMETAFILE CopyEnhMetaFileA(HENHMETAFILE, LPCSTR);
        HENHMETAFILE CopyEnhMetaFileW(HENHMETAFILE, LPCWSTR);
        HMETAFILE CopyMetaFileA(HMETAFILE, LPCSTR);
        HMETAFILE CopyMetaFileW(HMETAFILE, LPCWSTR);
        HBITMAP CreateBitmap(int, int, UINT, UINT, PCVOID);
        HBITMAP CreateBitmapIndirect(const(BITMAP)*);
        HBRUSH CreateBrushIndirect(const(LOGBRUSH)*);
        HCOLORSPACE CreateColorSpaceA(LPLOGCOLORSPACEA);
        HCOLORSPACE CreateColorSpaceW(LPLOGCOLORSPACEW);
        HBITMAP CreateCompatibleBitmap(HDC, int, int);
        HDC CreateCompatibleDC(HDC);
        HDC CreateDCA(LPCSTR, LPCSTR, LPCSTR, const(DEVMODEA)*);
        HDC CreateDCW(LPCWSTR, LPCWSTR, LPCWSTR, const(DEVMODEW)*);
        HBITMAP CreateDIBitmap(HDC, const(BITMAPINFOHEADER)*, DWORD, PCVOID, const(BITMAPINFO)*, UINT);
        HBRUSH CreateDIBPatternBrush(HGLOBAL, UINT);
        HBRUSH CreateDIBPatternBrushPt(PCVOID, UINT);
        HBITMAP CreateDIBSection(HDC, const(BITMAPINFO)*, UINT, void**, HANDLE, DWORD);
        HBITMAP CreateDiscardableBitmap(HDC, int, int);
        HRGN CreateEllipticRgn(int, int, int, int);
        HRGN CreateEllipticRgnIndirect(LPCRECT);
        HDC CreateEnhMetaFileA(HDC, LPCSTR, LPCRECT, LPCSTR);
        HDC CreateEnhMetaFileW(HDC, LPCWSTR, LPCRECT, LPCWSTR);
        HFONT CreateFontA(int, int, int, int, int, DWORD, DWORD, DWORD, DWORD, DWORD, DWORD, DWORD, DWORD, LPCSTR);
        HFONT CreateFontW(int, int, int, int, int, DWORD, DWORD, DWORD, DWORD, DWORD, DWORD, DWORD, DWORD, LPCWSTR);
        HFONT CreateFontIndirectA(const(LOGFONTA)*);
        HFONT CreateFontIndirectW(const(LOGFONTW)*);
        HPALETTE CreateHalftonePalette(HDC);
        HBRUSH CreateHatchBrush(int, COLORREF);
        HDC CreateICA(LPCSTR, LPCSTR, LPCSTR, const(DEVMODEA)*);
        HDC CreateICW(LPCWSTR, LPCWSTR, LPCWSTR, const(DEVMODEW)*);
        HDC CreateMetaFileA(LPCSTR);
        HDC CreateMetaFileW(LPCWSTR);
        HPALETTE CreatePalette(const(LOGPALETTE)*);
        HBRUSH CreatePatternBrush(HBITMAP);
        HPEN CreatePen(int, int, COLORREF);
        HPEN CreatePenIndirect(const(LOGPEN)*);
        HRGN CreatePolygonRgn(const(POINT)*, int, int);
        HRGN CreatePolyPolygonRgn(const(POINT)*, const(INT)*, int, int);
        HRGN CreateRectRgn(int, int, int, int);
        HRGN CreateRectRgnIndirect(LPCRECT);
        HRGN CreateRoundRectRgn(int, int, int, int, int, int);
        BOOL CreateScalableFontResourceA(DWORD, LPCSTR, LPCSTR, LPCSTR);
        BOOL CreateScalableFontResourceW(DWORD, LPCWSTR, LPCWSTR, LPCWSTR);
        HBRUSH CreateSolidBrush(COLORREF);
        BOOL DeleteColorSpace(HCOLORSPACE);
        BOOL DeleteDC(HDC);
        BOOL DeleteEnhMetaFile(HENHMETAFILE);
        BOOL DeleteMetaFile(HMETAFILE);
        BOOL DeleteObject(HGDIOBJ);
        int DescribePixelFormat(HDC, int, UINT, LPPIXELFORMATDESCRIPTOR);
        DWORD DeviceCapabilitiesA(LPCSTR, LPCSTR, WORD, LPSTR, const(DEVMODEA)*);
        DWORD DeviceCapabilitiesW(LPCWSTR, LPCWSTR, WORD, LPWSTR, const(DEVMODEW)*);
        BOOL DPtoLP(HDC, LPPOINT, int);
        int DrawEscape(HDC, int, int, LPCSTR);
        BOOL Ellipse(HDC, int, int, int, int);
        int EndDoc(HDC);
        int EndPage(HDC);
        BOOL EndPath(HDC);
        BOOL EnumEnhMetaFile(HDC, HENHMETAFILE, ENHMFENUMPROC, PVOID, LPCRECT);
        int EnumFontFamiliesA(HDC, LPCSTR, FONTENUMPROCA, LPARAM);
        int EnumFontFamiliesW(HDC, LPCWSTR, FONTENUMPROCW, LPARAM);
        int EnumFontFamiliesExA(HDC, PLOGFONTA, FONTENUMPROCA, LPARAM, DWORD);
        int EnumFontFamiliesExW(HDC, PLOGFONTW, FONTENUMPROCW, LPARAM, DWORD);
        int EnumFontsA(HDC, LPCSTR, FONTENUMPROCA, LPARAM);
        int EnumFontsW(HDC, LPCWSTR, FONTENUMPROCW, LPARAM);
        int EnumICMProfilesA(HDC, ICMENUMPROCA, LPARAM);
        int EnumICMProfilesW(HDC, ICMENUMPROCW, LPARAM);
        BOOL EnumMetaFile(HDC, HMETAFILE, MFENUMPROC, LPARAM);
        int EnumObjects(HDC, int, GOBJENUMPROC, LPARAM);
        BOOL EqualRgn(HRGN, HRGN);
        int Escape(HDC, int, int, LPCSTR, PVOID);
        int ExcludeClipRect(HDC, int, int, int, int);
        int ExcludeUpdateRgn(HDC, HWND);
        HPEN ExtCreatePen(DWORD, DWORD, const(LOGBRUSH)*, DWORD, const(DWORD)*);
        HRGN ExtCreateRegion(const(XFORM)*, DWORD, const(RGNDATA)*);
        int ExtEscape(HDC, int, int, LPCSTR, int, LPSTR);
        BOOL ExtFloodFill(HDC, int, int, COLORREF, UINT);
        int ExtSelectClipRgn(HDC, HRGN, int);
        BOOL ExtTextOutA(HDC, int, int, UINT, LPCRECT, LPCSTR, UINT, const(INT)*);
        BOOL ExtTextOutW(HDC, int, int, UINT, LPCRECT, LPCWSTR, UINT, const(INT)*);
        BOOL FillPath(HDC);
        int FillRect(HDC, LPCRECT, HBRUSH);
        int FillRgn(HDC, HRGN, HBRUSH);
        BOOL FixBrushOrgEx(HDC, int, int, LPPOINT);
        BOOL FlattenPath(HDC);
        BOOL FloodFill(HDC, int, int, COLORREF);
        BOOL FrameRgn(HDC, HRGN, HBRUSH, int, int);
        BOOL GdiComment(HDC, UINT, const(BYTE)*);
        BOOL GdiFlush();
        DWORD GdiGetBatchLimit();
        DWORD GdiSetBatchLimit(DWORD);
        int GetArcDirection(HDC);
        BOOL GetAspectRatioFilterEx(HDC, LPSIZE);
        LONG GetBitmapBits(HBITMAP, LONG, PVOID);
        BOOL GetBitmapDimensionEx(HBITMAP, LPSIZE);
        COLORREF GetBkColor(HDC);
        int GetBkMode(HDC);
        UINT GetBoundsRect(HDC, LPRECT, UINT);
        BOOL GetBrushOrgEx(HDC, LPPOINT);
        BOOL GetCharABCWidthsA(HDC, UINT, UINT, LPABC);
        BOOL GetCharABCWidthsW(HDC, UINT, UINT, LPABC);
        BOOL GetCharABCWidthsFloatA(HDC, UINT, UINT, LPABCFLOAT);
        BOOL GetCharABCWidthsFloatW(HDC, UINT, UINT, LPABCFLOAT);
        DWORD GetCharacterPlacementA(HDC, LPCSTR, int, int, LPGCP_RESULTSA, DWORD);
        DWORD GetCharacterPlacementW(HDC, LPCWSTR, int, int, LPGCP_RESULTSW, DWORD);
        BOOL GetCharWidth32A(HDC, UINT, UINT, LPINT);
        BOOL GetCharWidth32W(HDC, UINT, UINT, LPINT);
        BOOL GetCharWidthA(HDC, UINT, UINT, LPINT);
        BOOL GetCharWidthW(HDC, UINT, UINT, LPINT);
        BOOL GetCharWidthFloatA(HDC, UINT, UINT, PFLOAT);
        BOOL GetCharWidthFloatW(HDC, UINT, UINT, PFLOAT);
        int GetClipBox(HDC, LPRECT);
        int GetClipRgn(HDC, HRGN);
        BOOL GetColorAdjustment(HDC, LPCOLORADJUSTMENT);
        HANDLE GetColorSpace(HDC);
        HGDIOBJ GetCurrentObject(HDC, UINT);
        BOOL GetCurrentPositionEx(HDC, LPPOINT);
        HCURSOR GetCursor();
        BOOL GetDCOrgEx(HDC, LPPOINT);
    static if (_WIN32_WINNT >= 0x500)
    {
        DWORD GetDCPenColor(HGDIOBJ);
        COLORREF GetDCBrushColor(HGDIOBJ);
    }
        int GetDeviceCaps(HDC, int);
        BOOL GetDeviceGammaRamp(HDC, PVOID);
        UINT GetDIBColorTable(HDC, UINT, UINT, RGBQUAD*);
        int GetDIBits(HDC, HBITMAP, UINT, UINT, PVOID, LPBITMAPINFO, UINT);
        HENHMETAFILE GetEnhMetaFileA(LPCSTR);
        HENHMETAFILE GetEnhMetaFileW(LPCWSTR);
        UINT GetEnhMetaFileBits(HENHMETAFILE, UINT, LPBYTE);
        UINT GetEnhMetaFileDescriptionA(HENHMETAFILE, UINT, LPSTR);
        UINT GetEnhMetaFileDescriptionW(HENHMETAFILE, UINT, LPWSTR);
        UINT GetEnhMetaFileHeader(HENHMETAFILE, UINT, LPENHMETAHEADER);
        UINT GetEnhMetaFilePaletteEntries(HENHMETAFILE, UINT, LPPALETTEENTRY);
        UINT GetEnhMetaFilePixelFormat(HENHMETAFILE, DWORD, const(PIXELFORMATDESCRIPTOR)*);
        DWORD GetFontData(HDC, DWORD, DWORD, PVOID, DWORD);
        DWORD GetFontLanguageInfo(HDC);
        DWORD GetGlyphOutlineA(HDC, UINT, UINT, LPGLYPHMETRICS, DWORD, PVOID, const(MAT2)*);
        DWORD GetGlyphOutlineW(HDC, UINT, UINT, LPGLYPHMETRICS, DWORD, PVOID, const(MAT2)*);
        int GetGraphicsMode(HDC);
        BOOL GetICMProfileA(HDC, DWORD, LPSTR);
        BOOL GetICMProfileW(HDC, DWORD, LPWSTR);
        DWORD GetKerningPairsA(HDC, DWORD, LPKERNINGPAIR);
        DWORD GetKerningPairsW(HDC, DWORD, LPKERNINGPAIR);
        BOOL GetLogColorSpaceA(HCOLORSPACE, LPLOGCOLORSPACEA, DWORD);
        BOOL GetLogColorSpaceW(HCOLORSPACE, LPLOGCOLORSPACEW, DWORD);
        int GetMapMode(HDC);
        HMETAFILE GetMetaFileA(LPCSTR);
        HMETAFILE GetMetaFileW(LPCWSTR);
        UINT GetMetaFileBitsEx(HMETAFILE, UINT, PVOID);
        int GetMetaRgn(HDC, HRGN);
        BOOL GetMiterLimit(HDC, PFLOAT);
        COLORREF GetNearestColor(HDC, COLORREF);
        UINT GetNearestPaletteIndex(HPALETTE, COLORREF);
        int GetObjectA(HGDIOBJ, int, PVOID);
        int GetObjectW(HGDIOBJ, int, PVOID);
        DWORD GetObjectType(HGDIOBJ);
        UINT GetOutlineTextMetricsA(HDC, UINT, LPOUTLINETEXTMETRICA);
        UINT GetOutlineTextMetricsW(HDC, UINT, LPOUTLINETEXTMETRICW);
        UINT GetPaletteEntries(HPALETTE, UINT, UINT, LPPALETTEENTRY);
        int GetPath(HDC, LPPOINT, PBYTE, int);
        COLORREF GetPixel(HDC, int, int);
        int GetPixelFormat(HDC);
        int GetPolyFillMode(HDC);
        BOOL GetRasterizerCaps(LPRASTERIZER_STATUS, UINT);
        int GetRandomRgn (HDC, HRGN, INT);
        DWORD GetRegionData(HRGN, DWORD, LPRGNDATA);
        int GetRgnBox(HRGN, LPRECT);
        int GetROP2(HDC);
        HGDIOBJ GetStockObject(int);
        int GetStretchBltMode(HDC);
        UINT GetSystemPaletteEntries(HDC, UINT, UINT, LPPALETTEENTRY);
        UINT GetSystemPaletteUse(HDC);
        UINT GetTextAlign(HDC);
        int GetTextCharacterExtra(HDC);
        int GetTextCharset(HDC);
        int GetTextCharsetInfo(HDC, LPFONTSIGNATURE, DWORD);
        COLORREF GetTextColor(HDC);
        BOOL GetTextExtentExPointA(HDC, LPCSTR, int, int, LPINT, LPINT, LPSIZE);
        BOOL GetTextExtentExPointW(HDC, LPCWSTR, int, int, LPINT, LPINT, LPSIZE);
        BOOL GetTextExtentPointA(HDC, LPCSTR, int, LPSIZE);
        BOOL GetTextExtentPointW(HDC, LPCWSTR, int, LPSIZE);
        BOOL GetTextExtentPoint32A(HDC, LPCSTR, int, LPSIZE);
        BOOL GetTextExtentPoint32W(HDC, LPCWSTR, int, LPSIZE);
        int GetTextFaceA(HDC, int, LPSTR);
        int GetTextFaceW(HDC, int, LPWSTR);
        BOOL GetTextMetricsA(HDC, LPTEXTMETRICA);
        BOOL GetTextMetricsW(HDC, LPTEXTMETRICW);
        BOOL GetViewportExtEx(HDC, LPSIZE);
        BOOL GetViewportOrgEx(HDC, LPPOINT);
        BOOL GetWindowExtEx(HDC, LPSIZE);
        BOOL GetWindowOrgEx(HDC, LPPOINT);
        UINT GetWinMetaFileBits(HENHMETAFILE, UINT, LPBYTE, INT, HDC);
        BOOL GetWorldTransform(HDC, LPXFORM);
        int IntersectClipRect(HDC, int, int, int, int);
        BOOL InvertRgn(HDC, HRGN);
        BOOL LineDDA(int, int, int, int, LINEDDAPROC, LPARAM);
        BOOL LineTo(HDC, int, int);
        BOOL LPtoDP(HDC, LPPOINT, int);
        BOOL MaskBlt(HDC, int, int, int, int, HDC, int, int, HBITMAP, int, int, DWORD);
        BOOL ModifyWorldTransform(HDC, const(XFORM)*, DWORD);
        BOOL MoveToEx(HDC, int, int, LPPOINT);
        int OffsetClipRgn(HDC, int, int);
        int OffsetRgn(HRGN, int, int);
        BOOL OffsetViewportOrgEx(HDC, int, int, LPPOINT);
        BOOL OffsetWindowOrgEx(HDC, int, int, LPPOINT);
        BOOL PaintRgn(HDC, HRGN);
        BOOL PatBlt(HDC, int, int, int, int, DWORD);
        HRGN PathToRegion(HDC);
        BOOL Pie(HDC, int, int, int, int, int, int, int, int);
        BOOL PlayEnhMetaFile(HDC, HENHMETAFILE, LPCRECT);
        BOOL PlayEnhMetaFileRecord(HDC, LPHANDLETABLE, const(ENHMETARECORD)*, UINT);
        BOOL PlayMetaFile(HDC, HMETAFILE);
        BOOL PlayMetaFileRecord(HDC, LPHANDLETABLE, LPMETARECORD, UINT);
        BOOL PlgBlt(HDC, const(POINT)*, HDC, int, int, int, int, HBITMAP, int, int);
        BOOL PolyBezier(HDC, const(POINT)*, DWORD);
        BOOL PolyBezierTo(HDC, const(POINT)*, DWORD);
        BOOL PolyDraw(HDC, const(POINT)*, const(BYTE)*, int);
        BOOL Polygon(HDC, const(POINT)*, int);
        BOOL Polyline(HDC, const(POINT)*, int);
        BOOL PolylineTo(HDC, const(POINT)*, DWORD);
        BOOL PolyPolygon(HDC, const(POINT)*, const(INT)*, int);
        BOOL PolyPolyline(HDC, const(POINT)*, const(DWORD)*, DWORD);
        BOOL PolyTextOutA(HDC, const(POLYTEXTA)*, int);
        BOOL PolyTextOutW(HDC, const(POLYTEXTW)*, int);
        BOOL PtInRegion(HRGN, int, int);
        BOOL PtVisible(HDC, int, int);
        UINT RealizePalette(HDC);
        BOOL Rectangle(HDC, int, int, int, int);
        BOOL RectInRegion(HRGN, LPCRECT);
        BOOL RectVisible(HDC, LPCRECT);
        BOOL RemoveFontResourceA(LPCSTR);
        BOOL RemoveFontResourceW(LPCWSTR);

        HDC ResetDCA(HDC, const(DEVMODEA)*);
        HDC ResetDCW(HDC, const(DEVMODEW)*);
        BOOL ResizePalette(HPALETTE, UINT);
        BOOL RestoreDC(HDC, int);
        BOOL RoundRect(HDC, int, int, int, int, int, int);
        int SaveDC(HDC);
        BOOL ScaleViewportExtEx(HDC, int, int, int, int, LPSIZE);
        BOOL ScaleWindowExtEx(HDC, int, int, int, int, LPSIZE);
        BOOL SelectClipPath(HDC, int);
        int SelectClipRgn(HDC, HRGN);
        HGDIOBJ SelectObject(HDC, HGDIOBJ);
        HPALETTE SelectPalette(HDC, HPALETTE, BOOL);
        int SetAbortProc(HDC, ABORTPROC);
        int SetArcDirection(HDC, int);
        LONG SetBitmapBits(HBITMAP, DWORD, PCVOID);
        BOOL SetBitmapDimensionEx(HBITMAP, int, int, LPSIZE);
        COLORREF SetBkColor(HDC, COLORREF);
        int SetBkMode(HDC, int);
        UINT SetBoundsRect(HDC, LPCRECT, UINT);
        BOOL SetBrushOrgEx(HDC, int, int, LPPOINT);
        BOOL SetColorAdjustment(HDC, const(COLORADJUSTMENT)*);
        BOOL SetColorSpace(HDC, HCOLORSPACE);

        BOOL SetDeviceGammaRamp(HDC, PVOID);
        UINT SetDIBColorTable(HDC, UINT, UINT, const(RGBQUAD)*);
        int SetDIBits(HDC, HBITMAP, UINT, UINT, PCVOID, const(BITMAPINFO)*, UINT);
        int SetDIBitsToDevice(HDC, int, int, DWORD, DWORD, int, int, UINT, UINT, PCVOID, const(BITMAPINFO)*, UINT);
        HENHMETAFILE SetEnhMetaFileBits(UINT, const(BYTE)*);
        int SetGraphicsMode(HDC, int);
        int SetICMMode(HDC, int);
        BOOL SetICMProfileA(HDC, LPSTR);
        BOOL SetICMProfileW(HDC, LPWSTR);
        int SetMapMode(HDC, int);

        static if (_WIN32_WINNT >= 0x500) {
                DWORD SetLayout(HDC hdc, DWORD l);
                DWORD GetLayout(HDC hdc);
        }

        DWORD SetMapperFlags(HDC, DWORD);
        HMETAFILE SetMetaFileBitsEx(UINT, const(BYTE)*);
        int SetMetaRgn(HDC);
        BOOL SetMiterLimit(HDC, FLOAT, PFLOAT);
        UINT SetPaletteEntries(HPALETTE, UINT, UINT, const(PALETTEENTRY)*);
        COLORREF SetPixel(HDC, int, int, COLORREF);
        BOOL SetPixelFormat(HDC, int, const(PIXELFORMATDESCRIPTOR)*);
        BOOL SetPixelV(HDC, int, int, COLORREF);
        int SetPolyFillMode(HDC, int);
        BOOL SetRectRgn(HRGN, int, int, int, int);
        int SetROP2(HDC, int);
        int SetStretchBltMode(HDC, int);
        UINT SetSystemPaletteUse(HDC, UINT);
        UINT SetTextAlign(HDC, UINT);
        int SetTextCharacterExtra(HDC, int);
        COLORREF SetTextColor(HDC, COLORREF);
        BOOL SetTextJustification(HDC, int, int);
        BOOL SetViewportExtEx(HDC, int, int, LPSIZE);
        BOOL SetViewportOrgEx(HDC, int, int, LPPOINT);
        BOOL SetWindowExtEx(HDC, int, int, LPSIZE);
        BOOL SetWindowOrgEx(HDC, int, int, LPPOINT);
        HENHMETAFILE SetWinMetaFileBits(UINT, const(BYTE)*, HDC, const(METAFILEPICT)*);
        BOOL SetWorldTransform(HDC, const(XFORM)*);
        int StartDocA(HDC, const(DOCINFOA)*);
        int StartDocW(HDC, const(DOCINFOW)*);
        int StartPage(HDC);
        BOOL StretchBlt(HDC, int, int, int, int, HDC, int, int, int, int, DWORD);
        int StretchDIBits(HDC, int, int, int, int, int, int, int, int, const(VOID)* , const(BITMAPINFO)* , UINT, DWORD);
        BOOL StrokeAndFillPath(HDC);
        BOOL StrokePath(HDC);
        BOOL SwapBuffers(HDC);
        BOOL TextOutA(HDC, int, int, LPCSTR, int);
        BOOL TextOutW(HDC, int, int, LPCWSTR, int);
        BOOL TranslateCharsetInfo(PDWORD, LPCHARSETINFO, DWORD);
        BOOL UnrealizeObject(HGDIOBJ);
        BOOL UpdateColors(HDC);
        BOOL UpdateICMRegKeyA(DWORD, DWORD, LPSTR, UINT);
        BOOL UpdateICMRegKeyW(DWORD, DWORD, LPWSTR, UINT);
        BOOL WidenPath(HDC);
        BOOL wglCopyContext(HGLRC, HGLRC, UINT);
        HGLRC wglCreateContext(HDC);
        HGLRC wglCreateLayerContext(HDC, int);
        BOOL wglDeleteContext(HGLRC);
        BOOL wglDescribeLayerPlane(HDC, int, int, UINT, LPLAYERPLANEDESCRIPTOR);
        HGLRC wglGetCurrentContext();
        HDC wglGetCurrentDC();
        int wglGetLayerPaletteEntries(HDC, int, int, int, COLORREF*);
        PROC wglGetProcAddress(LPCSTR);
        BOOL wglMakeCurrent(HDC, HGLRC);
        BOOL wglRealizeLayerPalette(HDC, int, BOOL);
        int wglSetLayerPaletteEntries(HDC, int, int, int, const(COLORREF)*);
        BOOL wglShareLists(HGLRC, HGLRC);
        BOOL wglSwapLayerBuffers(HDC, UINT);
        BOOL wglUseFontBitmapsA(HDC, DWORD, DWORD, DWORD);
        BOOL wglUseFontBitmapsW(HDC, DWORD, DWORD, DWORD);
        BOOL wglUseFontOutlinesA(HDC, DWORD, DWORD, DWORD, FLOAT, FLOAT, int, LPGLYPHMETRICSFLOAT);
        BOOL wglUseFontOutlinesW(HDC, DWORD, DWORD, DWORD, FLOAT, FLOAT, int, LPGLYPHMETRICSFLOAT);

        static if (_WIN32_WINNT >= 0x500) {
        alias WGLSWAP* PWGLSWAP;
        struct WGLSWAP {
                HDC hdc;
                UINT uiFlags;
        }
        const WGL_SWAPMULTIPLE_MAX = 16;
        DWORD  wglSwapMultipleBuffers(UINT, WGLSWAP*);
}

static if (_WIN32_WINNT >= 0x500) {
                BOOL AlphaBlend(HDC, int, int, int, int, HDC, int, int, int, int, BLENDFUNCTION);
                BOOL GradientFill(HDC, PTRIVERTEX, ULONG, PVOID, ULONG, ULONG);
                BOOL TransparentBlt(HDC, int, int, int, int, HDC, int, int, int, int, UINT);
        }

        static if (_WIN32_WINNT >= 0x500) {
                COLORREF SetDCBrushColor(HDC, COLORREF);
                COLORREF SetDCPenColor(HDC, COLORREF);
                HANDLE AddFontMemResourceEx(PVOID, DWORD, PVOID, DWORD*);
                int AddFontResourceExA(LPCSTR, DWORD, PVOID);
                int AddFontResourceExW(LPCWSTR, DWORD, PVOID);
                BOOL RemoveFontMemResourceEx(HANDLE);
                BOOL RemoveFontResourceExA(LPCSTR, DWORD, PVOID);
                BOOL RemoveFontResourceExW(LPCWSTR, DWORD, PVOID);
                DWORD GetFontUnicodeRanges(HDC, LPGLYPHSET);
                DWORD GetGlyphIndicesA(HDC, LPCSTR, int, LPWORD, DWORD);
                DWORD GetGlyphIndicesW(HDC, LPCWSTR, int, LPWORD, DWORD);
                BOOL GetTextExtentPointI(HDC, LPWORD, int, LPSIZE);
                BOOL GetTextExtentExPointI(HDC, LPWORD, int, int, LPINT, LPINT, LPSIZE);
                BOOL GetCharWidthI(HDC, UINT, UINT, LPWORD, LPINT);
                BOOL GetCharABCWidthsI(HDC, UINT, UINT, LPWORD, LPABC);
        }
} // extern (Windows)

version(Unicode) {
        alias WCHAR BCHAR;
        alias DOCINFOW DOCINFO;
        alias LOGFONTW LOGFONT;

        alias TEXTMETRICW TEXTMETRIC;
        alias NPTEXTMETRICW NPTEXTMETRIC;
        alias ICMENUMPROCW ICMENUMPROC;
        alias FONTENUMPROCW FONTENUMPROC;
        alias DEVMODEW DEVMODE;

        alias EXTLOGFONTW EXTLOGFONT;
        alias GCP_RESULTSW GCP_RESULTS;
        alias OUTLINETEXTMETRICW OUTLINETEXTMETRIC;
        alias POLYTEXTW POLYTEXT;
        alias LOGCOLORSPACEW LOGCOLORSPACE;
        alias NEWTEXTMETRICW NEWTEXTMETRIC;
        alias NEWTEXTMETRICEXW NEWTEXTMETRICEX;
        alias ENUMLOGFONTW ENUMLOGFONT;
        alias ENUMLOGFONTEXW ENUMLOGFONTEX;
        alias DISPLAY_DEVICEW DISPLAY_DEVICE;
        alias AddFontResourceW AddFontResource;

        alias CopyEnhMetaFileW CopyEnhMetaFile;
        alias CopyMetaFileW CopyMetaFile;
        alias CreateColorSpaceW CreateColorSpace;
        alias CreateDCW CreateDC;
        alias CreateEnhMetaFileW CreateEnhMetaFile;
        alias CreateFontW CreateFont;
        alias CreateFontIndirectW CreateFontIndirect;
        alias CreateICW CreateIC;
        alias CreateMetaFileW CreateMetaFile;
        alias CreateScalableFontResourceW CreateScalableFontResource;
        alias DeviceCapabilitiesW DeviceCapabilities;
        alias EnumFontFamiliesW EnumFontFamilies;
        alias EnumFontFamiliesExW EnumFontFamiliesEx;
        alias EnumFontsW EnumFonts;
        alias EnumICMProfilesW EnumICMProfiles;
        alias ExtTextOutW ExtTextOut;
        alias GetCharABCWidthsFloatW GetCharABCWidthsFloat;
        alias GetCharABCWidthsW GetCharABCWidths;
        alias GetCharacterPlacementW GetCharacterPlacement;
        alias GetCharWidth32W GetCharWidth32;
        alias GetCharWidthFloatW GetCharWidthFloat;
        alias GetCharWidthW GetCharWidth;
        alias GetEnhMetaFileW GetEnhMetaFile;
        alias GetEnhMetaFileDescriptionW GetEnhMetaFileDescription;
        alias GetGlyphOutlineW GetGlyphOutline;
        alias GetICMProfileW GetICMProfile;
        alias GetKerningPairsW GetKerningPairs;
        alias GetLogColorSpaceW GetLogColorSpace;
        alias GetMetaFileW GetMetaFile;
        alias GetObjectW GetObject;
        alias GetOutlineTextMetricsW GetOutlineTextMetrics;
        alias GetTextExtentPointW GetTextExtentPoint;
        alias GetTextExtentExPointW GetTextExtentExPoint;
        alias GetTextExtentPoint32W GetTextExtentPoint32;
        alias GetTextFaceW GetTextFace;
        alias GetTextMetricsW GetTextMetrics;
        alias PolyTextOutW PolyTextOut;
        alias RemoveFontResourceW RemoveFontResource;

        alias ResetDCW ResetDC;
        alias SetICMProfileW SetICMProfile;
        alias StartDocW StartDoc;
        alias TextOutW TextOut;
        alias UpdateICMRegKeyW UpdateICMRegKey;
        alias wglUseFontBitmapsW wglUseFontBitmaps;
        alias wglUseFontOutlinesW wglUseFontOutlines;
        static if (_WIN32_WINNT >= 0x500) {
                alias ENUMLOGFONTEXDVW ENUMLOGFONTEXDV;
                alias PENUMLOGFONTEXDVW PENUMLOGFONTEXDV;
                alias LPENUMLOGFONTEXDVW LPENUMLOGFONTEXDV;
                alias AddFontResourceExW AddFontResourceEx;
                alias RemoveFontResourceExW RemoveFontResourceEx;
                alias GetGlyphIndicesW GetGlyphIndices;
        }
} else { /* non-unicode build */
        alias BYTE BCHAR;
        alias DOCINFOA DOCINFO;
        alias LOGFONTA LOGFONT;
        alias TEXTMETRICA TEXTMETRIC;
        alias NPTEXTMETRICA NPTEXTMETRIC;
        alias ICMENUMPROCA ICMENUMPROC;
        alias FONTENUMPROCA FONTENUMPROC;
        alias DEVMODEA DEVMODE;
        alias EXTLOGFONTA EXTLOGFONT;
        alias GCP_RESULTSA GCP_RESULTS;
        alias OUTLINETEXTMETRICA OUTLINETEXTMETRIC;
        alias POLYTEXTA POLYTEXT;
        alias LOGCOLORSPACEA LOGCOLORSPACE;
        alias NEWTEXTMETRICA NEWTEXTMETRIC;
        alias NEWTEXTMETRICEXA NEWTEXTMETRICEX;
        alias ENUMLOGFONTA ENUMLOGFONT;
        alias ENUMLOGFONTEXA ENUMLOGFONTEX;
        alias DISPLAY_DEVICEA DISPLAY_DEVICE;

        alias AddFontResourceA AddFontResource;
        alias CopyEnhMetaFileA CopyEnhMetaFile;
        alias CopyMetaFileA CopyMetaFile;
        alias CreateColorSpaceA CreateColorSpace;
        alias CreateDCA CreateDC;
        alias CreateEnhMetaFileA CreateEnhMetaFile;
        alias CreateFontA CreateFont;
        alias CreateFontIndirectA CreateFontIndirect;
        alias CreateICA CreateIC;
        alias CreateMetaFileA CreateMetaFile;
        alias CreateScalableFontResourceA CreateScalableFontResource;
        alias DeviceCapabilitiesA DeviceCapabilities;
        alias EnumFontFamiliesA EnumFontFamilies;
        alias EnumFontFamiliesExA EnumFontFamiliesEx;
        alias EnumFontsA EnumFonts;
        alias EnumICMProfilesA EnumICMProfiles;
        alias ExtTextOutA ExtTextOut;
        alias GetCharWidthFloatA GetCharWidthFloat;
        alias GetCharWidthA GetCharWidth;
        alias GetCharacterPlacementA GetCharacterPlacement;
        alias GetCharABCWidthsA GetCharABCWidths;
        alias GetCharABCWidthsFloatA GetCharABCWidthsFloat;
        alias GetCharWidth32A GetCharWidth32;
        alias GetEnhMetaFileA GetEnhMetaFile;
        alias GetEnhMetaFileDescriptionA GetEnhMetaFileDescription;
        alias GetGlyphOutlineA GetGlyphOutline;
        alias GetICMProfileA GetICMProfile;
        alias GetKerningPairsA GetKerningPairs;
        alias GetLogColorSpaceA GetLogColorSpace;
        alias GetMetaFileA GetMetaFile;
        alias GetObjectA GetObject;
        alias GetOutlineTextMetricsA GetOutlineTextMetrics;
        alias GetTextExtentPointA GetTextExtentPoint;
        alias GetTextExtentExPointA GetTextExtentExPoint;
        alias GetTextExtentPoint32A GetTextExtentPoint32;
        alias GetTextFaceA GetTextFace;
        alias GetTextMetricsA GetTextMetrics;
        alias PolyTextOutA PolyTextOut;
        alias RemoveFontResourceA RemoveFontResource;
        alias ResetDCA ResetDC;
        alias SetICMProfileA SetICMProfile;
        alias StartDocA StartDoc;
        alias TextOutA TextOut;
        alias UpdateICMRegKeyA UpdateICMRegKey;
        alias wglUseFontBitmapsA wglUseFontBitmaps;
        alias wglUseFontOutlinesA wglUseFontOutlines;
        static if (_WIN32_WINNT >= 0x500) {
                alias ENUMLOGFONTEXDVA ENUMLOGFONTEXDV;
                alias PENUMLOGFONTEXDVA PENUMLOGFONTEXDV;
                alias LPENUMLOGFONTEXDVA LPENUMLOGFONTEXDV;
                alias AddFontResourceExA AddFontResourceEx;
                alias RemoveFontResourceExA RemoveFontResourceEx;
                alias GetGlyphIndicesA GetGlyphIndices;
        }
}

// Common to both ASCII & UNICODE
alias DOCINFO* LPDOCINFO;
alias LOGFONT* PLOGFONT, NPLOGFONT, LPLOGFONT;
alias TEXTMETRIC* PTEXTMETRIC, LPTEXTMETRIC;
alias DEVMODE* PDEVMODE, NPDEVMODE, LPDEVMODE;
alias EXTLOGFONT* PEXTLOGFONT, NPEXTLOGFONT, LPEXTLOGFONT;
alias GCP_RESULTS* LPGCP_RESULTS;
alias OUTLINETEXTMETRIC* POUTLINETEXTMETRIC, NPOUTLINETEXTMETRIC, LPOUTLINETEXTMETRIC;
alias POLYTEXT* PPOLYTEXT, NPPOLYTEXT, LPPOLYTEXT;
alias LOGCOLORSPACE* LPLOGCOLORSPACE;
alias NEWTEXTMETRIC* PNEWTEXTMETRIC, NPNEWTEXTMETRIC, LPNEWTEXTMETRIC;
alias ENUMLOGFONT* LPENUMLOGFONT;
alias ENUMLOGFONTEX* LPENUMLOGFONTEX;
alias DISPLAY_DEVICE* PDISPLAY_DEVICE, LPDISPLAY_DEVICE;
