/***********************************************************************\
*                                winnt.d                                *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*             Translated from MinGW API for MS-Windows 3.12             *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/
module core.sys.windows.winnt;
nothrow @nogc:
version(Windows):

public import core.sys.windows.basetsd, core.sys.windows.windef, core.sys.windows.winerror;
private import core.sys.windows.w32api;

/* Translation Notes:
The following macros are unneeded for D:
FIELD_OFFSET(t,f), CONTAINING_RECORD(address, type, field)
*/

alias void   VOID;
alias char   CHAR, CCHAR;
alias wchar  WCHAR;
alias bool   BOOLEAN;
alias byte   FCHAR;
alias ubyte  UCHAR;
alias short  SHORT;
alias ushort LANGID, FSHORT;
alias uint   LCID, FLONG, ACCESS_MASK;
alias long   LONGLONG, USN;
alias ulong  DWORDLONG, ULONGLONG;

alias void*  PVOID, LPVOID;
alias char*  PSZ, PCHAR, PCCHAR, LPCH, PCH, LPSTR, PSTR;
alias wchar* PWCHAR, LPWCH, PWCH, LPWSTR, PWSTR;
alias bool*  PBOOLEAN;
alias ubyte* PUCHAR;
alias short* PSHORT;
alias int*   PLONG;
alias uint*  PLCID, PACCESS_MASK;
alias long*  PLONGLONG;
alias ulong* PDWORDLONG, PULONGLONG;

// FIXME(MinGW) for __WIN64
alias void*  PVOID64;

// const versions
alias const(char)*  LPCCH, PCSTR, LPCSTR;
alias const(wchar)* LPCWCH, PCWCH, LPCWSTR, PCWSTR;

version (Unicode) {
        alias WCHAR TCHAR, _TCHAR;
} else {
        alias CHAR TCHAR, _TCHAR;
}

alias TCHAR         TBYTE;
alias TCHAR*        PTCH, PTBYTE, LPTCH, PTSTR, LPTSTR, LP, PTCHAR;
alias const(TCHAR)* LPCTSTR;
alias const(TCHAR)* PCTSTR;

const char ANSI_NULL = '\0';
const wchar UNICODE_NULL = '\0';

const APPLICATION_ERROR_MASK       = 0x20000000;
const ERROR_SEVERITY_SUCCESS       = 0x00000000;
const ERROR_SEVERITY_INFORMATIONAL = 0x40000000;
const ERROR_SEVERITY_WARNING       = 0x80000000;
const ERROR_SEVERITY_ERROR         = 0xC0000000;

// MinGW: also in ddk/ntifs.h
enum : USHORT {
        COMPRESSION_FORMAT_NONE     = 0x0000,
        COMPRESSION_FORMAT_DEFAULT  = 0x0001,
        COMPRESSION_FORMAT_LZNT1    = 0x0002,
        COMPRESSION_ENGINE_STANDARD = 0x0000,
        COMPRESSION_ENGINE_MAXIMUM  = 0x0100,
        COMPRESSION_ENGINE_HIBER    = 0x0200
}

// ACCESS_DENIED_OBJECT_ACE, etc
const DWORD
        ACE_OBJECT_TYPE_PRESENT           = 0x00000001,
        ACE_INHERITED_OBJECT_TYPE_PRESENT = 0x00000002;

// ACE_HEADER.AceType
// also in ddk/ntifs.h
enum : BYTE {
        ACCESS_ALLOWED_ACE_TYPE,
        ACCESS_DENIED_ACE_TYPE,
        SYSTEM_AUDIT_ACE_TYPE,
        SYSTEM_ALARM_ACE_TYPE
}

// ACE_HEADER.AceFlags
const BYTE
        OBJECT_INHERIT_ACE         = 0x01,
        CONTAINER_INHERIT_ACE      = 0x02,
        NO_PROPAGATE_INHERIT_ACE   = 0x04,
        INHERIT_ONLY_ACE           = 0x08,
        INHERITED_ACE              = 0x10,
        VALID_INHERIT_FLAGS        = 0x1F,
        SUCCESSFUL_ACCESS_ACE_FLAG = 0x40,
        FAILED_ACCESS_ACE_FLAG     = 0x80;

// Access Mask Format
const ACCESS_MASK
        DELETE                   = 0x00010000,
        READ_CONTROL             = 0x00020000,
        WRITE_DAC                = 0x00040000,
        WRITE_OWNER              = 0x00080000,
        SYNCHRONIZE              = 0x00100000,
        ACCESS_SYSTEM_SECURITY   = 0x01000000,
        MAXIMUM_ALLOWED          = 0x02000000,
        GENERIC_READ             = 0x80000000,
        GENERIC_WRITE            = 0x40000000,
        GENERIC_EXECUTE          = 0x20000000,
        GENERIC_ALL              = 0x10000000,
        STANDARD_RIGHTS_REQUIRED = 0x000F0000,
        STANDARD_RIGHTS_READ     = 0x00020000,
        STANDARD_RIGHTS_WRITE    = 0x00020000,
        STANDARD_RIGHTS_EXECUTE  = 0x00020000,
        STANDARD_RIGHTS_ALL      = 0x001F0000,
        SPECIFIC_RIGHTS_ALL      = 0x0000FFFF;


const DWORD INVALID_FILE_ATTRIBUTES = -1;

// MinGW: Also in ddk/winddk.h
const DWORD
        FILE_LIST_DIRECTORY       = 0x00000001,
        FILE_READ_DATA            = 0x00000001,
        FILE_ADD_FILE             = 0x00000002,
        FILE_WRITE_DATA           = 0x00000002,
        FILE_ADD_SUBDIRECTORY     = 0x00000004,
        FILE_APPEND_DATA          = 0x00000004,
        FILE_CREATE_PIPE_INSTANCE = 0x00000004,
        FILE_READ_EA              = 0x00000008,
        FILE_READ_PROPERTIES      = 0x00000008,
        FILE_WRITE_EA             = 0x00000010,
        FILE_WRITE_PROPERTIES     = 0x00000010,
        FILE_EXECUTE              = 0x00000020,
        FILE_TRAVERSE             = 0x00000020,
        FILE_DELETE_CHILD         = 0x00000040,
        FILE_READ_ATTRIBUTES      = 0x00000080,
        FILE_WRITE_ATTRIBUTES     = 0x00000100;

const DWORD
        FILE_SHARE_READ        = 0x00000001,
        FILE_SHARE_WRITE       = 0x00000002,
        FILE_SHARE_DELETE      = 0x00000004,
        FILE_SHARE_VALID_FLAGS = 0x00000007;

const DWORD
        FILE_ATTRIBUTE_READONLY            = 0x00000001,
        FILE_ATTRIBUTE_HIDDEN              = 0x00000002,
        FILE_ATTRIBUTE_SYSTEM              = 0x00000004,
        FILE_ATTRIBUTE_DIRECTORY           = 0x00000010,
        FILE_ATTRIBUTE_ARCHIVE             = 0x00000020,
        FILE_ATTRIBUTE_DEVICE              = 0x00000040,
        FILE_ATTRIBUTE_NORMAL              = 0x00000080,
        FILE_ATTRIBUTE_TEMPORARY           = 0x00000100,
        FILE_ATTRIBUTE_SPARSE_FILE         = 0x00000200,
        FILE_ATTRIBUTE_REPARSE_POINT       = 0x00000400,
        FILE_ATTRIBUTE_COMPRESSED          = 0x00000800,
        FILE_ATTRIBUTE_OFFLINE             = 0x00001000,
        FILE_ATTRIBUTE_NOT_CONTENT_INDEXED = 0x00002000,
        FILE_ATTRIBUTE_ENCRYPTED           = 0x00004000,
        FILE_ATTRIBUTE_VALID_FLAGS         = 0x00007fb7,
        FILE_ATTRIBUTE_VALID_SET_FLAGS     = 0x000031a7;

// These are not documented on MSDN
const FILE_COPY_STRUCTURED_STORAGE = 0x00000041;
const FILE_STRUCTURED_STORAGE      = 0x00000441;

// Nor are these
const FILE_VALID_OPTION_FLAGS          = 0x00ffffff;
const FILE_VALID_PIPE_OPTION_FLAGS     = 0x00000032;
const FILE_VALID_MAILSLOT_OPTION_FLAGS = 0x00000032;
const FILE_VALID_SET_FLAGS             = 0x00000036;

const ULONG
        FILE_SUPERSEDE           = 0x00000000,
        FILE_OPEN                = 0x00000001,
        FILE_CREATE              = 0x00000002,
        FILE_OPEN_IF             = 0x00000003,
        FILE_OVERWRITE           = 0x00000004,
        FILE_OVERWRITE_IF        = 0x00000005,
        FILE_MAXIMUM_DISPOSITION = 0x00000005;

const ULONG
        FILE_DIRECTORY_FILE            = 0x00000001,
        FILE_WRITE_THROUGH             = 0x00000002,
        FILE_SEQUENTIAL_ONLY           = 0x00000004,
        FILE_NO_INTERMEDIATE_BUFFERING = 0x00000008,
        FILE_SYNCHRONOUS_IO_ALERT      = 0x00000010,
        FILE_SYNCHRONOUS_IO_NONALERT   = 0x00000020,
        FILE_NON_DIRECTORY_FILE        = 0x00000040,
        FILE_CREATE_TREE_CONNECTION    = 0x00000080,
        FILE_COMPLETE_IF_OPLOCKED      = 0x00000100,
        FILE_NO_EA_KNOWLEDGE           = 0x00000200,
        FILE_OPEN_FOR_RECOVERY         = 0x00000400,
        FILE_RANDOM_ACCESS             = 0x00000800,
        FILE_DELETE_ON_CLOSE           = 0x00001000,
        FILE_OPEN_BY_FILE_ID           = 0x00002000,
        FILE_OPEN_FOR_BACKUP_INTENT    = 0x00004000,
        FILE_NO_COMPRESSION            = 0x00008000,
        FILE_RESERVE_OPFILTER          = 0x00100000,
        FILE_OPEN_REPARSE_POINT        = 0x00200000,
        FILE_OPEN_NO_RECALL            = 0x00400000,
        FILE_OPEN_FOR_FREE_SPACE_QUERY = 0x00800000;


const ACCESS_MASK
        FILE_ALL_ACCESS      = STANDARD_RIGHTS_REQUIRED | SYNCHRONIZE | 0x01FF,
        FILE_GENERIC_EXECUTE = STANDARD_RIGHTS_EXECUTE | FILE_READ_ATTRIBUTES
                               | FILE_EXECUTE | SYNCHRONIZE,
        FILE_GENERIC_READ    = STANDARD_RIGHTS_READ | FILE_READ_DATA
                               | FILE_READ_ATTRIBUTES | FILE_READ_EA | SYNCHRONIZE,
        FILE_GENERIC_WRITE   = STANDARD_RIGHTS_WRITE | FILE_WRITE_DATA
                               | FILE_WRITE_ATTRIBUTES | FILE_WRITE_EA | FILE_APPEND_DATA
                               | SYNCHRONIZE;

// MinGW: end winddk.h
// MinGW: also in ddk/ntifs.h
const DWORD
        FILE_NOTIFY_CHANGE_FILE_NAME    = 0x00000001,
        FILE_NOTIFY_CHANGE_DIR_NAME     = 0x00000002,
        FILE_NOTIFY_CHANGE_NAME         = 0x00000003,
        FILE_NOTIFY_CHANGE_ATTRIBUTES   = 0x00000004,
        FILE_NOTIFY_CHANGE_SIZE         = 0x00000008,
        FILE_NOTIFY_CHANGE_LAST_WRITE   = 0x00000010,
        FILE_NOTIFY_CHANGE_LAST_ACCESS  = 0x00000020,
        FILE_NOTIFY_CHANGE_CREATION     = 0x00000040,
        FILE_NOTIFY_CHANGE_EA           = 0x00000080,
        FILE_NOTIFY_CHANGE_SECURITY     = 0x00000100,
        FILE_NOTIFY_CHANGE_STREAM_NAME  = 0x00000200,
        FILE_NOTIFY_CHANGE_STREAM_SIZE  = 0x00000400,
        FILE_NOTIFY_CHANGE_STREAM_WRITE = 0x00000800,
        FILE_NOTIFY_VALID_MASK          = 0x00000fff;

const DWORD
        FILE_CASE_SENSITIVE_SEARCH      = 0x00000001,
        FILE_CASE_PRESERVED_NAMES       = 0x00000002,
        FILE_UNICODE_ON_DISK            = 0x00000004,
        FILE_PERSISTENT_ACLS            = 0x00000008,
        FILE_FILE_COMPRESSION           = 0x00000010,
        FILE_VOLUME_QUOTAS              = 0x00000020,
        FILE_SUPPORTS_SPARSE_FILES      = 0x00000040,
        FILE_SUPPORTS_REPARSE_POINTS    = 0x00000080,
        FILE_SUPPORTS_REMOTE_STORAGE    = 0x00000100,
        FS_LFN_APIS                     = 0x00004000,
        FILE_VOLUME_IS_COMPRESSED       = 0x00008000,
        FILE_SUPPORTS_OBJECT_IDS        = 0x00010000,
        FILE_SUPPORTS_ENCRYPTION        = 0x00020000,
        FILE_NAMED_STREAMS              = 0x00040000,
        FILE_READ_ONLY_VOLUME           = 0x00080000,
        FILE_SEQUENTIAL_WRITE_ONCE      = 0x00100000,
        FILE_SUPPORTS_TRANSACTIONS      = 0x00200000;

// These are not documented on MSDN
const ACCESS_MASK
        IO_COMPLETION_QUERY_STATE  = 1,
        IO_COMPLETION_MODIFY_STATE = 2,
        IO_COMPLETION_ALL_ACCESS   = STANDARD_RIGHTS_REQUIRED | SYNCHRONIZE | 3;
// MinGW: end ntifs.h

// MinGW: also in ddk/winddk.h
const DWORD
        DUPLICATE_CLOSE_SOURCE    = 1,
        DUPLICATE_SAME_ACCESS     = 2,
        DUPLICATE_SAME_ATTRIBUTES = 4;
// MinGW: end winddk.k

const DWORD
        MAILSLOT_NO_MESSAGE   = -1,
        MAILSLOT_WAIT_FOREVER = -1;

const ACCESS_MASK
        PROCESS_TERMINATE         = 0x0001,
        PROCESS_CREATE_THREAD     = 0x0002,
        PROCESS_SET_SESSIONID     = 0x0004,
        PROCESS_VM_OPERATION      = 0x0008,
        PROCESS_VM_READ           = 0x0010,
        PROCESS_VM_WRITE          = 0x0020,
        PROCESS_DUP_HANDLE        = 0x0040,
        PROCESS_CREATE_PROCESS    = 0x0080,
        PROCESS_SET_QUOTA         = 0x0100,
        PROCESS_SET_INFORMATION   = 0x0200,
        PROCESS_QUERY_INFORMATION = 0x0400,
        PROCESS_ALL_ACCESS        = STANDARD_RIGHTS_REQUIRED | SYNCHRONIZE | 0x0FFF;

const ACCESS_MASK
        THREAD_TERMINATE            = 0x0001,
        THREAD_SUSPEND_RESUME       = 0x0002,
        THREAD_GET_CONTEXT          = 0x0008,
        THREAD_SET_CONTEXT          = 0x0010,
        THREAD_SET_INFORMATION      = 0x0020,
        THREAD_QUERY_INFORMATION    = 0x0040,
        THREAD_SET_THREAD_TOKEN     = 0x0080,
        THREAD_IMPERSONATE          = 0x0100,
        THREAD_DIRECT_IMPERSONATION = 0x0200,
        THREAD_ALL_ACCESS           = STANDARD_RIGHTS_REQUIRED|SYNCHRONIZE|0x3FF;

// These are not documented on MSDN
const THREAD_BASE_PRIORITY_LOWRT =  15;
const THREAD_BASE_PRIORITY_MAX   =   2;
const THREAD_BASE_PRIORITY_MIN   =  -2;
const THREAD_BASE_PRIORITY_IDLE  = -15;

const DWORD EXCEPTION_NONCONTINUABLE      =  1;
const size_t EXCEPTION_MAXIMUM_PARAMETERS = 15;

// These are not documented on MSDN
const ACCESS_MASK
        MUTANT_QUERY_STATE = 1,
        MUTANT_ALL_ACCESS =  STANDARD_RIGHTS_REQUIRED | SYNCHRONIZE | MUTANT_QUERY_STATE;

const ACCESS_MASK
        TIMER_QUERY_STATE  = 1,
        TIMER_MODIFY_STATE = 2,
        TIMER_ALL_ACCESS   = STANDARD_RIGHTS_REQUIRED | SYNCHRONIZE | TIMER_QUERY_STATE
                             | TIMER_MODIFY_STATE;

const SID_IDENTIFIER_AUTHORITY
        SECURITY_NULL_SID_AUTHORITY        = {[5: 0]},
        SECURITY_WORLD_SID_AUTHORITY       = {[5: 1]},
        SECURITY_LOCAL_SID_AUTHORITY       = {[5: 2]},
        SECURITY_CREATOR_SID_AUTHORITY     = {[5: 3]},
        SECURITY_NON_UNIQUE_AUTHORITY      = {[5: 4]},
        SECURITY_NT_AUTHORITY              = {[5: 5]},
        SECURITY_MANDATORY_LABEL_AUTHORITY = {[5: 6]};

const DWORD
        SECURITY_NULL_RID                   =  0,
        SECURITY_WORLD_RID                  =  0,
        SECURITY_LOCAL_RID                  =  0,
        SECURITY_CREATOR_OWNER_RID          =  0,
        SECURITY_CREATOR_GROUP_RID          =  1,
        SECURITY_DIALUP_RID                 =  1,
        SECURITY_NETWORK_RID                =  2,
        SECURITY_BATCH_RID                  =  3,
        SECURITY_INTERACTIVE_RID            =  4,
        SECURITY_LOGON_IDS_RID              =  5,
        SECURITY_SERVICE_RID                =  6,
        SECURITY_LOCAL_SYSTEM_RID           = 18,
        SECURITY_BUILTIN_DOMAIN_RID         = 32,
        SECURITY_PRINCIPAL_SELF_RID         = 10,
        SECURITY_CREATOR_OWNER_SERVER_RID   =  2,
        SECURITY_CREATOR_GROUP_SERVER_RID   =  3,
        SECURITY_LOGON_IDS_RID_COUNT        =  3,
        SECURITY_ANONYMOUS_LOGON_RID        =  7,
        SECURITY_PROXY_RID                  =  8,
        SECURITY_ENTERPRISE_CONTROLLERS_RID =  9,
        SECURITY_SERVER_LOGON_RID           = SECURITY_ENTERPRISE_CONTROLLERS_RID,
        SECURITY_AUTHENTICATED_USER_RID     = 11,
        SECURITY_RESTRICTED_CODE_RID        = 12,
        SECURITY_NT_NON_UNIQUE_RID          = 21,
        SID_REVISION                        =  1;

enum : DWORD {
        DOMAIN_USER_RID_ADMIN        = 0x01F4,
        DOMAIN_USER_RID_GUEST        = 0x01F5,
        DOMAIN_GROUP_RID_ADMINS      = 0x0200,
        DOMAIN_GROUP_RID_USERS       = 0x0201,
        DOMAIN_ALIAS_RID_ADMINS      = 0x0220,
        DOMAIN_ALIAS_RID_USERS       = 0x0221,
        DOMAIN_ALIAS_RID_GUESTS      = 0x0222,
        DOMAIN_ALIAS_RID_POWER_USERS = 0x0223,
        DOMAIN_ALIAS_RID_ACCOUNT_OPS = 0x0224,
        DOMAIN_ALIAS_RID_SYSTEM_OPS  = 0x0225,
        DOMAIN_ALIAS_RID_PRINT_OPS   = 0x0226,
        DOMAIN_ALIAS_RID_BACKUP_OPS  = 0x0227,
        DOMAIN_ALIAS_RID_REPLICATOR  = 0x0228
}

enum : WORD {
        SECURITY_MANDATORY_UNTRUSTED_RID         = 0,
        SECURITY_MANDATORY_LOW_RID               = 0x1000,
        SECURITY_MANDATORY_MEDIUM_RID            = 0x2000,
        SECURITY_MANDATORY_HIGH_RID              = 0x3000,
        SECURITY_MANDATORY_SYSTEM_RID            = 0x4000,
        SECURITY_MANDATORY_PROTECTED_PROCESS_RID = 0x5000,
        SECURITY_MANDATORY_MAXIMUM_USER_RID      = SECURITY_MANDATORY_SYSTEM_RID
}

const TCHAR[]
        SE_CREATE_TOKEN_NAME           = "SeCreateTokenPrivilege",
        SE_ASSIGNPRIMARYTOKEN_NAME     = "SeAssignPrimaryTokenPrivilege",
        SE_LOCK_MEMORY_NAME            = "SeLockMemoryPrivilege",
        SE_INCREASE_QUOTA_NAME         = "SeIncreaseQuotaPrivilege",
        SE_UNSOLICITED_INPUT_NAME      = "SeUnsolicitedInputPrivilege",
        SE_MACHINE_ACCOUNT_NAME        = "SeMachineAccountPrivilege",
        SE_TCB_NAME                    = "SeTcbPrivilege",
        SE_SECURITY_NAME               = "SeSecurityPrivilege",
        SE_TAKE_OWNERSHIP_NAME         = "SeTakeOwnershipPrivilege",
        SE_LOAD_DRIVER_NAME            = "SeLoadDriverPrivilege",
        SE_SYSTEM_PROFILE_NAME         = "SeSystemProfilePrivilege",
        SE_SYSTEMTIME_NAME             = "SeSystemtimePrivilege",
        SE_PROF_SINGLE_PROCESS_NAME    = "SeProfileSingleProcessPrivilege",
        SE_INC_BASE_PRIORITY_NAME      = "SeIncreaseBasePriorityPrivilege",
        SE_CREATE_PAGEFILE_NAME        = "SeCreatePagefilePrivilege",
        SE_CREATE_PERMANENT_NAME       = "SeCreatePermanentPrivilege",
        SE_BACKUP_NAME                 = "SeBackupPrivilege",
        SE_RESTORE_NAME                = "SeRestorePrivilege",
        SE_SHUTDOWN_NAME               = "SeShutdownPrivilege",
        SE_DEBUG_NAME                  = "SeDebugPrivilege",
        SE_AUDIT_NAME                  = "SeAuditPrivilege",
        SE_SYSTEM_ENVIRONMENT_NAME     = "SeSystemEnvironmentPrivilege",
        SE_CHANGE_NOTIFY_NAME          = "SeChangeNotifyPrivilege",
        SE_REMOTE_SHUTDOWN_NAME        = "SeRemoteShutdownPrivilege",
        SE_CREATE_GLOBAL_NAME          = "SeCreateGlobalPrivilege",
        SE_UNDOCK_NAME                 = "SeUndockPrivilege",
        SE_MANAGE_VOLUME_NAME          = "SeManageVolumePrivilege",
        SE_IMPERSONATE_NAME            = "SeImpersonatePrivilege",
        SE_ENABLE_DELEGATION_NAME      = "SeEnableDelegationPrivilege",
        SE_SYNC_AGENT_NAME             = "SeSyncAgentPrivilege",
        SE_TRUSTED_CREDMAN_ACCESS_NAME = "SeTrustedCredManAccessPrivilege",
        SE_RELABEL_NAME                = "SeRelabelPrivilege",
        SE_INCREASE_WORKING_SET_NAME   = "SeIncreaseWorkingSetPrivilege",
        SE_TIME_ZONE_NAME              = "SeTimeZonePrivilege",
        SE_CREATE_SYMBOLIC_LINK_NAME   = "SeCreateSymbolicLinkPrivilege";

const DWORD
        SE_GROUP_MANDATORY          = 0x00000001,
        SE_GROUP_ENABLED_BY_DEFAULT = 0x00000002,
        SE_GROUP_ENABLED            = 0x00000004,
        SE_GROUP_OWNER              = 0x00000008,
        SE_GROUP_USE_FOR_DENY_ONLY  = 0x00000010,
        SE_GROUP_INTEGRITY          = 0x00000020,
        SE_GROUP_INTEGRITY_ENABLED  = 0x00000040,
        SE_GROUP_RESOURCE           = 0x20000000,
        SE_GROUP_LOGON_ID           = 0xC0000000;

// Primary language identifiers
enum : USHORT {
        LANG_NEUTRAL,
        LANG_ARABIC,
        LANG_BULGARIAN,
        LANG_CATALAN,
        LANG_CHINESE,
        LANG_CZECH,
        LANG_DANISH,
        LANG_GERMAN,
        LANG_GREEK,
        LANG_ENGLISH,
        LANG_SPANISH,
        LANG_FINNISH,
        LANG_FRENCH,
        LANG_HEBREW,
        LANG_HUNGARIAN,
        LANG_ICELANDIC,
        LANG_ITALIAN,
        LANG_JAPANESE,
        LANG_KOREAN,
        LANG_DUTCH,
        LANG_NORWEGIAN,
        LANG_POLISH,
        LANG_PORTUGUESE,    // = 0x16
        LANG_ROMANIAN          = 0x18,
        LANG_RUSSIAN,
        LANG_CROATIAN,      // = 0x1A
        LANG_SERBIAN           = 0x1A,
        LANG_BOSNIAN           = 0x1A,
        LANG_SLOVAK,
        LANG_ALBANIAN,
        LANG_SWEDISH,
        LANG_THAI,
        LANG_TURKISH,
        LANG_URDU,
        LANG_INDONESIAN,
        LANG_UKRAINIAN,
        LANG_BELARUSIAN,
        LANG_SLOVENIAN,
        LANG_ESTONIAN,
        LANG_LATVIAN,
        LANG_LITHUANIAN,    // = 0x27
        LANG_FARSI             = 0x29,
        LANG_PERSIAN           = 0x29,
        LANG_VIETNAMESE,
        LANG_ARMENIAN,
        LANG_AZERI,
        LANG_BASQUE,
        LANG_LOWER_SORBIAN, // = 0x2E
        LANG_UPPER_SORBIAN     = 0x2E,
        LANG_MACEDONIAN,    // = 0x2F
        LANG_TSWANA            = 0x32,
        LANG_XHOSA             = 0x34,
        LANG_ZULU,
        LANG_AFRIKAANS,
        LANG_GEORGIAN,
        LANG_FAEROESE,
        LANG_HINDI,
        LANG_MALTESE,
        LANG_SAMI,
        LANG_IRISH,         // = 0x3C
        LANG_MALAY             = 0x3E,
        LANG_KAZAK,
        LANG_KYRGYZ,
        LANG_SWAHILI,       // = 0x41
        LANG_UZBEK             = 0x43,
        LANG_TATAR,
        LANG_BENGALI,
        LANG_PUNJABI,
        LANG_GUJARATI,
        LANG_ORIYA,
        LANG_TAMIL,
        LANG_TELUGU,
        LANG_KANNADA,
        LANG_MALAYALAM,
        LANG_ASSAMESE,
        LANG_MARATHI,
        LANG_SANSKRIT,
        LANG_MONGOLIAN,
        LANG_TIBETAN,
        LANG_WELSH,
        LANG_KHMER,
        LANG_LAO,           // = 0x54
        LANG_GALICIAN          = 0x56,
        LANG_KONKANI,
        LANG_MANIPURI,
        LANG_SINDHI,
        LANG_SYRIAC,
        LANG_SINHALESE,     // = 0x5B
        LANG_INUKTITUT         = 0x5D,
        LANG_AMHARIC,
        LANG_TAMAZIGHT,
        LANG_KASHMIRI,
        LANG_NEPALI,
        LANG_FRISIAN,
        LANG_PASHTO,
        LANG_FILIPINO,
        LANG_DIVEHI,        // = 0x65
        LANG_HAUSA             = 0x68,
        LANG_YORUBA            = 0x6A,
        LANG_QUECHUA,
        LANG_SOTHO,
        LANG_BASHKIR,
        LANG_LUXEMBOURGISH,
        LANG_GREENLANDIC,
        LANG_IGBO,          // = 0x70
        LANG_TIGRIGNA          = 0x73,
        LANG_YI                = 0x78,
        LANG_MAPUDUNGUN        = 0x7A,
        LANG_MOHAWK            = 0x7C,
        LANG_BRETON            = 0x7E,
        LANG_UIGHUR            = 0x80,
        LANG_MAORI,
        LANG_OCCITAN,
        LANG_CORSICAN,
        LANG_ALSATIAN,
        LANG_YAKUT,
        LANG_KICHE,
        LANG_KINYARWANDA,
        LANG_WOLOF,         // = 0x88
        LANG_DARI              = 0x8C,
        LANG_MALAGASY,      // = 0x8D

        LANG_SERBIAN_NEUTRAL   = 0x7C1A,
        LANG_BOSNIAN_NEUTRAL   = 0x781A,

        LANG_INVARIANT         = 0x7F
}


// Sublanguage identifiers
enum : USHORT {
        SUBLANG_NEUTRAL,
        SUBLANG_DEFAULT,
        SUBLANG_SYS_DEFAULT,
        SUBLANG_CUSTOM_DEFAULT,                  // =  3
        SUBLANG_UI_CUSTOM_DEFAULT                   =  3,
        SUBLANG_CUSTOM_UNSPECIFIED,              // =  4

        SUBLANG_AFRIKAANS_SOUTH_AFRICA              =  1,
        SUBLANG_ALBANIAN_ALBANIA                    =  1,
        SUBLANG_ALSATIAN_FRANCE                     =  1,
        SUBLANG_AMHARIC_ETHIOPIA                    =  1,

        SUBLANG_ARABIC_SAUDI_ARABIA                 =  1,
        SUBLANG_ARABIC_IRAQ,
        SUBLANG_ARABIC_EGYPT,
        SUBLANG_ARABIC_LIBYA,
        SUBLANG_ARABIC_ALGERIA,
        SUBLANG_ARABIC_MOROCCO,
        SUBLANG_ARABIC_TUNISIA,
        SUBLANG_ARABIC_OMAN,
        SUBLANG_ARABIC_YEMEN,
        SUBLANG_ARABIC_SYRIA,
        SUBLANG_ARABIC_JORDAN,
        SUBLANG_ARABIC_LEBANON,
        SUBLANG_ARABIC_KUWAIT,
        SUBLANG_ARABIC_UAE,
        SUBLANG_ARABIC_BAHRAIN,
        SUBLANG_ARABIC_QATAR,                    // = 16

        SUBLANG_ARMENIAN_ARMENIA                    =  1,
        SUBLANG_ASSAMESE_INDIA                      =  1,

        SUBLANG_AZERI_LATIN                         =  1,
        SUBLANG_AZERI_CYRILLIC,                  // =  2

        SUBLANG_BASHKIR_RUSSIA                      =  1,
        SUBLANG_BASQUE_BASQUE                       =  1,
        SUBLANG_BELARUSIAN_BELARUS                  =  1,
        SUBLANG_BENGALI_INDIA                       =  1,

        SUBLANG_BOSNIAN_BOSNIA_HERZEGOVINA_LATIN    =  5,
        SUBLANG_BOSNIAN_BOSNIA_HERZEGOVINA_CYRILLIC =  8,

        SUBLANG_BRETON_FRANCE                       =  1,
        SUBLANG_BULGARIAN_BULGARIA                  =  1,
        SUBLANG_CATALAN_CATALAN                     =  1,

        SUBLANG_CHINESE_TRADITIONAL                 =  1,
        SUBLANG_CHINESE_SIMPLIFIED,
        SUBLANG_CHINESE_HONGKONG,
        SUBLANG_CHINESE_SINGAPORE,
        SUBLANG_CHINESE_MACAU,                   // =  5

        SUBLANG_CORSICAN_FRANCE                     =  1,

        SUBLANG_CROATIAN_CROATIA                    =  1,
        SUBLANG_CROATIAN_BOSNIA_HERZEGOVINA_LATIN   =  4,

        SUBLANG_CZECH_CZECH_REPUBLIC                =  1,
        SUBLANG_DANISH_DENMARK                      =  1,
        SUBLANG_DIVEHI_MALDIVES                     =  1,

        SUBLANG_DUTCH                               =  1,
        SUBLANG_DUTCH_BELGIAN,                   // =  2

        SUBLANG_ENGLISH_US                          =  1,
        SUBLANG_ENGLISH_UK,
        SUBLANG_ENGLISH_AUS,
        SUBLANG_ENGLISH_CAN,
        SUBLANG_ENGLISH_NZ,
        SUBLANG_ENGLISH_EIRE,                    // =  6
        SUBLANG_ENGLISH_IRELAND                     =  6,
        SUBLANG_ENGLISH_SOUTH_AFRICA,
        SUBLANG_ENGLISH_JAMAICA,
        SUBLANG_ENGLISH_CARIBBEAN,
        SUBLANG_ENGLISH_BELIZE,
        SUBLANG_ENGLISH_TRINIDAD,
        SUBLANG_ENGLISH_ZIMBABWE,
        SUBLANG_ENGLISH_PHILIPPINES,             // = 13
        SUBLANG_ENGLISH_INDIA                       = 16,
        SUBLANG_ENGLISH_MALAYSIA,
        SUBLANG_ENGLISH_SINGAPORE,               // = 18

        SUBLANG_ESTONIAN_ESTONIA                    =  1,
        SUBLANG_FAEROESE_FAROE_ISLANDS              =  1,
        SUBLANG_FILIPINO_PHILIPPINES                =  1,
        SUBLANG_FINNISH_FINLAND                     =  1,

        SUBLANG_FRENCH                              =  1,
        SUBLANG_FRENCH_BELGIAN,
        SUBLANG_FRENCH_CANADIAN,
        SUBLANG_FRENCH_SWISS,
        SUBLANG_FRENCH_LUXEMBOURG,
        SUBLANG_FRENCH_MONACO,                   // =  6

        SUBLANG_FRISIAN_NETHERLANDS                 =  1,
        SUBLANG_GALICIAN_GALICIAN                   =  1,
        SUBLANG_GEORGIAN_GEORGIA                    =  1,

        SUBLANG_GERMAN                              =  1,
        SUBLANG_GERMAN_SWISS,
        SUBLANG_GERMAN_AUSTRIAN,
        SUBLANG_GERMAN_LUXEMBOURG,
        SUBLANG_GERMAN_LIECHTENSTEIN,            // =  5

        SUBLANG_GREEK_GREECE                        =  1,
        SUBLANG_GREENLANDIC_GREENLAND               =  1,
        SUBLANG_GUJARATI_INDIA                      =  1,
        SUBLANG_HAUSA_NIGERIA                       =  1,
        SUBLANG_HEBREW_ISRAEL                       =  1,
        SUBLANG_HINDI_INDIA                         =  1,
        SUBLANG_HUNGARIAN_HUNGARY                   =  1,
        SUBLANG_ICELANDIC_ICELAND                   =  1,
        SUBLANG_IGBO_NIGERIA                        =  1,
        SUBLANG_INDONESIAN_INDONESIA                =  1,

        SUBLANG_INUKTITUT_CANADA                    =  1,
        SUBLANG_INUKTITUT_CANADA_LATIN              =  1,

        SUBLANG_IRISH_IRELAND                       =  1,

        SUBLANG_ITALIAN                             =  1,
        SUBLANG_ITALIAN_SWISS,                   // =  2

        SUBLANG_JAPANESE_JAPAN                      =  1,

        SUBLANG_KASHMIRI_INDIA                      =  2,
        SUBLANG_KASHMIRI_SASIA                      =  2,

        SUBLANG_KAZAK_KAZAKHSTAN                    =  1,
        SUBLANG_KHMER_CAMBODIA                      =  1,
        SUBLANG_KICHE_GUATEMALA                     =  1,
        SUBLANG_KINYARWANDA_RWANDA                  =  1,
        SUBLANG_KONKANI_INDIA                       =  1,
        SUBLANG_KOREAN                              =  1,
        SUBLANG_KYRGYZ_KYRGYZSTAN                   =  1,
        SUBLANG_LAO_LAO_PDR                         =  1,
        SUBLANG_LATVIAN_LATVIA                      =  1,

        SUBLANG_LITHUANIAN                          =  1,
        SUBLANG_LITHUANIAN_LITHUANIA                =  1,

        SUBLANG_LOWER_SORBIAN_GERMANY               =  1,
        SUBLANG_LUXEMBOURGISH_LUXEMBOURG            =  1,
        SUBLANG_MACEDONIAN_MACEDONIA                =  1,
        SUBLANG_MALAYALAM_INDIA                     =  1,
        SUBLANG_MALTESE_MALTA                       =  1,
        SUBLANG_MAORI_NEW_ZEALAND                   =  1,
        SUBLANG_MAPUDUNGUN_CHILE                    =  1,
        SUBLANG_MARATHI_INDIA                       =  1,
        SUBLANG_MOHAWK_MOHAWK                       =  1,

        SUBLANG_MONGOLIAN_CYRILLIC_MONGOLIA         =  1,
        SUBLANG_MONGOLIAN_PRC,                   // =  2

        SUBLANG_MALAY_MALAYSIA                      =  1,
        SUBLANG_MALAY_BRUNEI_DARUSSALAM,         // =  2

        SUBLANG_NEPALI_NEPAL                        =  1,
        SUBLANG_NEPALI_INDIA,                    // =  2

        SUBLANG_NORWEGIAN_BOKMAL                    =  1,
        SUBLANG_NORWEGIAN_NYNORSK,               // =  2

        SUBLANG_OCCITAN_FRANCE                      =  1,
        SUBLANG_ORIYA_INDIA                         =  1,
        SUBLANG_PASHTO_AFGHANISTAN                  =  1,
        SUBLANG_PERSIAN_IRAN                        =  1,
        SUBLANG_POLISH_POLAND                       =  1,

        SUBLANG_PORTUGUESE_BRAZILIAN                =  1,
        SUBLANG_PORTUGUESE                          =  2,
        SUBLANG_PORTUGUESE_PORTUGAL,             // =  2

        SUBLANG_PUNJABI_INDIA                       =  1,

        SUBLANG_QUECHUA_BOLIVIA                     =  1,
        SUBLANG_QUECHUA_ECUADOR,
        SUBLANG_QUECHUA_PERU,                    // =  3

        SUBLANG_ROMANIAN_ROMANIA                    =  1,
        SUBLANG_ROMANSH_SWITZERLAND                 =  1,
        SUBLANG_RUSSIAN_RUSSIA                      =  1,

        SUBLANG_SAMI_NORTHERN_NORWAY                =  1,
        SUBLANG_SAMI_NORTHERN_SWEDEN,
        SUBLANG_SAMI_NORTHERN_FINLAND,           // =  3
        SUBLANG_SAMI_SKOLT_FINLAND                  =  3,
        SUBLANG_SAMI_INARI_FINLAND                  =  3,
        SUBLANG_SAMI_LULE_NORWAY,
        SUBLANG_SAMI_LULE_SWEDEN,
        SUBLANG_SAMI_SOUTHERN_NORWAY,
        SUBLANG_SAMI_SOUTHERN_SWEDEN,            // =  7

        SUBLANG_SANSKRIT_INDIA                      =  1,

        SUBLANG_SERBIAN_LATIN                       =  2,
        SUBLANG_SERBIAN_CYRILLIC,                // =  3
        SUBLANG_SERBIAN_BOSNIA_HERZEGOVINA_LATIN    =  6,
        SUBLANG_SERBIAN_BOSNIA_HERZEGOVINA_CYRILLIC =  7,

        SUBLANG_SINDHI_AFGHANISTAN                  =  2,
        SUBLANG_SINHALESE_SRI_LANKA                 =  1,
        SUBLANG_SOTHO_NORTHERN_SOUTH_AFRICA         =  1,
        SUBLANG_SLOVAK_SLOVAKIA                     =  1,
        SUBLANG_SLOVENIAN_SLOVENIA                  =  1,

        SUBLANG_SPANISH                             =  1,
        SUBLANG_SPANISH_MEXICAN,
        SUBLANG_SPANISH_MODERN,
        SUBLANG_SPANISH_GUATEMALA,
        SUBLANG_SPANISH_COSTA_RICA,
        SUBLANG_SPANISH_PANAMA,
        SUBLANG_SPANISH_DOMINICAN_REPUBLIC,
        SUBLANG_SPANISH_VENEZUELA,
        SUBLANG_SPANISH_COLOMBIA,
        SUBLANG_SPANISH_PERU,
        SUBLANG_SPANISH_ARGENTINA,
        SUBLANG_SPANISH_ECUADOR,
        SUBLANG_SPANISH_CHILE,
        SUBLANG_SPANISH_URUGUAY,
        SUBLANG_SPANISH_PARAGUAY,
        SUBLANG_SPANISH_BOLIVIA,
        SUBLANG_SPANISH_EL_SALVADOR,
        SUBLANG_SPANISH_HONDURAS,
        SUBLANG_SPANISH_NICARAGUA,
        SUBLANG_SPANISH_PUERTO_RICO,
        SUBLANG_SPANISH_US,                      // = 21

        SUBLANG_SWEDISH                             =  1,
        SUBLANG_SWEDISH_SWEDEN                      =  1,
        SUBLANG_SWEDISH_FINLAND,                 // =  2

        SUBLANG_SYRIAC                              =  1,
        SUBLANG_TAJIK_TAJIKISTAN                    =  1,
        SUBLANG_TAMAZIGHT_ALGERIA_LATIN             =  2,
        SUBLANG_TAMIL_INDIA                         =  1,
        SUBLANG_TATAR_RUSSIA                        =  1,
        SUBLANG_TELUGU_INDIA                        =  1,
        SUBLANG_THAI_THAILAND                       =  1,
        SUBLANG_TIBETAN_PRC                         =  1,
        SUBLANG_TIBETAN_BHUTAN                      =  2,
        SUBLANG_TIGRIGNA_ERITREA                    =  1,
        SUBLANG_TSWANA_SOUTH_AFRICA                 =  1,
        SUBLANG_TURKISH_TURKEY                      =  1,
        SUBLANG_TURKMEN_TURKMENISTAN                =  1,
        SUBLANG_UIGHUR_PRC                          =  1,
        SUBLANG_UKRAINIAN_UKRAINE                   =  1,
        SUBLANG_UPPER_SORBIAN_GERMANY               =  1,

        SUBLANG_URDU_PAKISTAN                       =  1,
        SUBLANG_URDU_INDIA,                      // =  2

        SUBLANG_UZBEK_LATIN                         =  1,
        SUBLANG_UZBEK_CYRILLIC,                  // =  2

        SUBLANG_VIETNAMESE_VIETNAM                  =  1,
        SUBLANG_WELSH_UNITED_KINGDOM                =  1,
        SUBLANG_WOLOF_SENEGAL                       =  1,
        SUBLANG_YORUBA_NIGERIA                      =  1,
        SUBLANG_XHOSA_SOUTH_AFRICA                  =  1,
        SUBLANG_YAKUT_RUSSIA                        =  1,
        SUBLANG_YI_PRC                              =  1,
        SUBLANG_ZULU_SOUTH_AFRICA                   =  1
}

// This is not documented on MSDN
const NLS_VALID_LOCALE_MASK = 1048575;

// Sorting identifiers
enum : WORD {
        SORT_DEFAULT              = 0,
        SORT_JAPANESE_XJIS        = 0,
        SORT_JAPANESE_UNICODE     = 1,
        SORT_CHINESE_BIG5         = 0,
        SORT_CHINESE_PRCP         = 0,
        SORT_CHINESE_UNICODE      = 1,
        SORT_CHINESE_PRC          = 2,
        SORT_CHINESE_BOPOMOFO     = 3,
        SORT_KOREAN_KSC           = 0,
        SORT_KOREAN_UNICODE       = 1,
        SORT_GERMAN_PHONE_BOOK    = 1,
        SORT_HUNGARIAN_DEFAULT    = 0,
        SORT_HUNGARIAN_TECHNICAL  = 1,
        SORT_GEORGIAN_TRADITIONAL = 0,
        SORT_GEORGIAN_MODERN      = 1
}

WORD MAKELANGID()(USHORT p, USHORT s) { return cast(WORD)((s << 10) | p); }
WORD MAKELANGID()(int p, int s) { return MAKELANGID(cast(ushort) p, cast(ushort) s); }
WORD PRIMARYLANGID()(WORD lgid) { return cast(WORD)(lgid & 0x3FF); }
WORD SUBLANGID()(WORD lgid) { return cast(WORD)(lgid >>> 10); }

DWORD MAKELCID()(WORD lgid, WORD srtid) { return (cast(DWORD) srtid << 16) | cast(DWORD) lgid; }
// ???
//DWORD MAKESORTLCID(WORD lgid, WORD srtid, WORD ver) { return (MAKELCID(lgid, srtid)) | ((cast(DWORD)ver) << 20); }
WORD LANGIDFROMLCID()(LCID lcid) { return cast(WORD) lcid; }
WORD SORTIDFROMLCID()(LCID lcid) { return cast(WORD) ((lcid >>> 16) & 0x0F); }
WORD SORTVERSIONFROMLCID()(LCID lcid) { return cast(WORD) ((lcid >>> 20) & 0x0F); }

const WORD LANG_SYSTEM_DEFAULT = (SUBLANG_SYS_DEFAULT << 10) | LANG_NEUTRAL;
const WORD LANG_USER_DEFAULT   = (SUBLANG_DEFAULT << 10) | LANG_NEUTRAL;
const DWORD LOCALE_NEUTRAL     = (SORT_DEFAULT << 16)
                                 | (SUBLANG_NEUTRAL << 10) | LANG_NEUTRAL;

// ---
enum : BYTE {
        ACL_REVISION    = 2,
        ACL_REVISION_DS = 4
}

// These are not documented on MSDN
enum : BYTE {
        ACL_REVISION1    = 1,
        ACL_REVISION2,
        ACL_REVISION3,
        ACL_REVISION4 // = 4
}

const BYTE
        MIN_ACL_REVISION = 2,
        MAX_ACL_REVISION = 4;

/+
// These aren't necessary for D.
const MINCHAR=0x80;
const MAXCHAR=0x7f;
const MINSHORT=0x8000;
const MAXSHORT=0x7fff;
const MINLONG=0x80000000;
const MAXLONG=0x7fffffff;
const MAXBYTE=0xff;
const MAXWORD=0xffff;
const MAXDWORD=0xffffffff;
+/

// SYSTEM_INFO.dwProcessorType
enum : DWORD {
        PROCESSOR_INTEL_386     =   386,
        PROCESSOR_INTEL_486     =   486,
        PROCESSOR_INTEL_PENTIUM =   586,
        PROCESSOR_MIPS_R4000    =  4000,
        PROCESSOR_ALPHA_21064   = 21064,
        PROCESSOR_INTEL_IA64    =  2200
}

// SYSTEM_INFO.wProcessorArchitecture
enum : WORD {
        PROCESSOR_ARCHITECTURE_INTEL,
        PROCESSOR_ARCHITECTURE_MIPS,
        PROCESSOR_ARCHITECTURE_ALPHA,
        PROCESSOR_ARCHITECTURE_PPC,
        PROCESSOR_ARCHITECTURE_SHX,
        PROCESSOR_ARCHITECTURE_ARM,
        PROCESSOR_ARCHITECTURE_IA64,
        PROCESSOR_ARCHITECTURE_ALPHA64,
        PROCESSOR_ARCHITECTURE_MSIL,
        PROCESSOR_ARCHITECTURE_AMD64,
        PROCESSOR_ARCHITECTURE_IA32_ON_WIN64, // = 10
        PROCESSOR_ARCHITECTURE_UNKNOWN = 0xFFFF
}

// IsProcessorFeaturePresent()
enum : DWORD {
        PF_FLOATING_POINT_PRECISION_ERRATA,
        PF_FLOATING_POINT_EMULATED,
        PF_COMPARE_EXCHANGE_DOUBLE,
        PF_MMX_INSTRUCTIONS_AVAILABLE,
        PF_PPC_MOVEMEM_64BIT_OK,
        PF_ALPHA_BYTE_INSTRUCTIONS,
        PF_XMMI_INSTRUCTIONS_AVAILABLE,
        PF_3DNOW_INSTRUCTIONS_AVAILABLE,
        PF_RDTSC_INSTRUCTION_AVAILABLE,
        PF_PAE_ENABLED,
        PF_XMMI64_INSTRUCTIONS_AVAILABLE
}

// MinGW: also in ddk/ntifs.h
enum : DWORD {
        FILE_ACTION_ADDED = 1,
        FILE_ACTION_REMOVED,
        FILE_ACTION_MODIFIED,
        FILE_ACTION_RENAMED_OLD_NAME,
        FILE_ACTION_RENAMED_NEW_NAME,
        FILE_ACTION_ADDED_STREAM,
        FILE_ACTION_REMOVED_STREAM,
        FILE_ACTION_MODIFIED_STREAM,
        FILE_ACTION_REMOVED_BY_DELETE,
        FILE_ACTION_ID_NOT_TUNNELLED,
        FILE_ACTION_TUNNELLED_ID_COLLISION // = 11
}
// MinGW: end ntifs.h

const DWORD
        HEAP_NO_SERIALIZE             = 0x01,
        HEAP_GROWABLE                 = 0x02,
        HEAP_GENERATE_EXCEPTIONS      = 0x04,
        HEAP_ZERO_MEMORY              = 0x08,
        HEAP_REALLOC_IN_PLACE_ONLY    = 0x10,
        HEAP_TAIL_CHECKING_ENABLED    = 0x20,
        HEAP_FREE_CHECKING_ENABLED    = 0x40,
        HEAP_DISABLE_COALESCE_ON_FREE = 0x80;

// These are not documented on MSDN
const HEAP_CREATE_ALIGN_16       = 0;
const HEAP_CREATE_ENABLE_TRACING = 0x020000;
const HEAP_MAXIMUM_TAG           = 0x000FFF;
const HEAP_PSEUDO_TAG_FLAG       = 0x008000;
const HEAP_TAG_SHIFT             = 16;
// ???
//MACRO #define HEAP_MAKE_TAG_FLAGS(b,o) ((DWORD)((b)+(o)<<16)))

const ACCESS_MASK
        KEY_QUERY_VALUE        = 0x000001,
        KEY_SET_VALUE          = 0x000002,
        KEY_CREATE_SUB_KEY     = 0x000004,
        KEY_ENUMERATE_SUB_KEYS = 0x000008,
        KEY_NOTIFY             = 0x000010,
        KEY_CREATE_LINK        = 0x000020,
        KEY_WRITE              = 0x020006,
        KEY_EXECUTE            = 0x020019,
        KEY_READ               = 0x020019,
        KEY_ALL_ACCESS         = 0x0F003F;

static if (_WIN32_WINNT >= 0x502) {
        const ACCESS_MASK
                KEY_WOW64_64KEY    = 0x000100,
                KEY_WOW64_32KEY    = 0x000200;
}

const DWORD
        REG_WHOLE_HIVE_VOLATILE = 1,
        REG_REFRESH_HIVE        = 2,
        REG_NO_LAZY_FLUSH       = 4;

const DWORD
        REG_OPTION_RESERVED       =  0,
        REG_OPTION_NON_VOLATILE   =  0,
        REG_OPTION_VOLATILE       =  1,
        REG_OPTION_CREATE_LINK    =  2,
        REG_OPTION_BACKUP_RESTORE =  4,
        REG_OPTION_OPEN_LINK      =  8,
        REG_LEGAL_OPTION          = 15;

const SECURITY_INFORMATION
        OWNER_SECURITY_INFORMATION            = 0x00000001,
        GROUP_SECURITY_INFORMATION            = 0x00000002,
        DACL_SECURITY_INFORMATION             = 0x00000004,
        SACL_SECURITY_INFORMATION             = 0x00000008,
        LABEL_SECURITY_INFORMATION            = 0x00000010,
        UNPROTECTED_SACL_SECURITY_INFORMATION = 0x10000000,
        UNPROTECTED_DACL_SECURITY_INFORMATION = 0x20000000,
        PROTECTED_SACL_SECURITY_INFORMATION   = 0x40000000,
        PROTECTED_DACL_SECURITY_INFORMATION   = 0x80000000;

const DWORD MAXIMUM_PROCESSORS = 32;

// VirtualAlloc(), etc
// -------------------

enum : DWORD {
        PAGE_NOACCESS          = 0x0001,
        PAGE_READONLY          = 0x0002,
        PAGE_READWRITE         = 0x0004,
        PAGE_WRITECOPY         = 0x0008,
        PAGE_EXECUTE           = 0x0010,
        PAGE_EXECUTE_READ      = 0x0020,
        PAGE_EXECUTE_READWRITE = 0x0040,
        PAGE_EXECUTE_WRITECOPY = 0x0080,
        PAGE_GUARD             = 0x0100,
        PAGE_NOCACHE           = 0x0200
}

enum : DWORD {
        MEM_COMMIT      = 0x00001000,
        MEM_RESERVE     = 0x00002000,
        MEM_DECOMMIT    = 0x00004000,
        MEM_RELEASE     = 0x00008000,
        MEM_FREE        = 0x00010000,
        MEM_PRIVATE     = 0x00020000,
        MEM_MAPPED      = 0x00040000,
        MEM_RESET       = 0x00080000,
        MEM_TOP_DOWN    = 0x00100000,
        MEM_WRITE_WATCH = 0x00200000, // MinGW (???): 98/Me
        MEM_PHYSICAL    = 0x00400000,
        MEM_4MB_PAGES   = 0x80000000
}

// MinGW: also in ddk/ntifs.h
// CreateFileMapping()
const DWORD
        SEC_BASED     = 0x00200000,
        SEC_NO_CHANGE = 0x00400000,
        SEC_FILE      = 0x00800000,
        SEC_IMAGE     = 0x01000000,
        SEC_VLM       = 0x02000000,
        SEC_RESERVE   = 0x04000000,
        SEC_COMMIT    = 0x08000000,
        SEC_NOCACHE   = 0x10000000,
        MEM_IMAGE     = SEC_IMAGE;
// MinGW: end ntifs.h

// ???
const ACCESS_MASK
        SECTION_QUERY       = 0x000001,
        SECTION_MAP_WRITE   = 0x000002,
        SECTION_MAP_READ    = 0x000004,
        SECTION_MAP_EXECUTE = 0x000008,
        SECTION_EXTEND_SIZE = 0x000010,
        SECTION_ALL_ACCESS  = 0x0F001F;

// These are not documented on MSDN
const MESSAGE_RESOURCE_UNICODE = 1;
const RTL_CRITSECT_TYPE        = 0;
const RTL_RESOURCE_TYPE        = 1;

// COFF file format
// ----------------

// IMAGE_FILE_HEADER.Characteristics
const WORD
        IMAGE_FILE_RELOCS_STRIPPED         = 0x0001,
        IMAGE_FILE_EXECUTABLE_IMAGE        = 0x0002,
        IMAGE_FILE_LINE_NUMS_STRIPPED      = 0x0004,
        IMAGE_FILE_LOCAL_SYMS_STRIPPED     = 0x0008,
        IMAGE_FILE_AGGRESIVE_WS_TRIM       = 0x0010,
        IMAGE_FILE_LARGE_ADDRESS_AWARE     = 0x0020,
        IMAGE_FILE_BYTES_REVERSED_LO       = 0x0080,
        IMAGE_FILE_32BIT_MACHINE           = 0x0100,
        IMAGE_FILE_DEBUG_STRIPPED          = 0x0200,
        IMAGE_FILE_REMOVABLE_RUN_FROM_SWAP = 0x0400,
        IMAGE_FILE_NET_RUN_FROM_SWAP       = 0x0800,
        IMAGE_FILE_SYSTEM                  = 0x1000,
        IMAGE_FILE_DLL                     = 0x2000,
        IMAGE_FILE_UP_SYSTEM_ONLY          = 0x4000,
        IMAGE_FILE_BYTES_REVERSED_HI       = 0x8000;

// IMAGE_FILE_HEADER.Machine
enum : WORD {
        IMAGE_FILE_MACHINE_UNKNOWN   = 0x0000,
        IMAGE_FILE_MACHINE_I386      = 0x014C,
        IMAGE_FILE_MACHINE_R3000     = 0x0162,
        IMAGE_FILE_MACHINE_R4000     = 0x0166,
        IMAGE_FILE_MACHINE_R10000    = 0x0168,
        IMAGE_FILE_MACHINE_WCEMIPSV2 = 0x0169,
        IMAGE_FILE_MACHINE_ALPHA     = 0x0184,
        IMAGE_FILE_MACHINE_SH3       = 0x01A2,
        IMAGE_FILE_MACHINE_SH3DSP    = 0x01A3,
        IMAGE_FILE_MACHINE_SH4       = 0x01A6,
        IMAGE_FILE_MACHINE_SH5       = 0x01A8,
        IMAGE_FILE_MACHINE_ARM       = 0x01C0,
        IMAGE_FILE_MACHINE_THUMB     = 0x01C2,
        IMAGE_FILE_MACHINE_AM33      = 0x01D3,
        IMAGE_FILE_MACHINE_POWERPC   = 0x01F0,
        IMAGE_FILE_MACHINE_POWERPCFP = 0x01F1,
        IMAGE_FILE_MACHINE_IA64      = 0x0200,
        IMAGE_FILE_MACHINE_MIPS16    = 0x0266,
        IMAGE_FILE_MACHINE_MIPSFPU   = 0x0366,
        IMAGE_FILE_MACHINE_MIPSFPU16 = 0x0466,
        IMAGE_FILE_MACHINE_EBC       = 0x0EBC,
        IMAGE_FILE_MACHINE_AMD64     = 0x8664,
        IMAGE_FILE_MACHINE_M32R      = 0x9041
}

// ???
enum  {
        IMAGE_DOS_SIGNATURE    = 0x5A4D,
        IMAGE_OS2_SIGNATURE    = 0x454E,
        IMAGE_OS2_SIGNATURE_LE = 0x454C,
        IMAGE_VXD_SIGNATURE    = 0x454C,
        IMAGE_NT_SIGNATURE     = 0x4550
}

// IMAGE_OPTIONAL_HEADER.Magic
enum : WORD {
        IMAGE_NT_OPTIONAL_HDR32_MAGIC = 0x010B,
        IMAGE_ROM_OPTIONAL_HDR_MAGIC  = 0x0107,
        IMAGE_NT_OPTIONAL_HDR64_MAGIC = 0x020B
}

// IMAGE_OPTIONAL_HEADER.Subsystem
enum : WORD {
        IMAGE_SUBSYSTEM_UNKNOWN                  =  0,
        IMAGE_SUBSYSTEM_NATIVE,
        IMAGE_SUBSYSTEM_WINDOWS_GUI,
        IMAGE_SUBSYSTEM_WINDOWS_CUI,          // =  3
        IMAGE_SUBSYSTEM_OS2_CUI                  =  5,
        IMAGE_SUBSYSTEM_POSIX_CUI                =  7,
        IMAGE_SUBSYSTEM_NATIVE_WINDOWS,
        IMAGE_SUBSYSTEM_WINDOWS_CE_GUI,
        IMAGE_SUBSYSTEM_EFI_APPLICATION,
        IMAGE_SUBSYSTEM_EFI_BOOT_SERVICE_DRIVER,
        IMAGE_SUBSYSTEM_EFI_RUNTIME_DRIVER,
        IMAGE_SUBSYSTEM_EFI_ROM,
        IMAGE_SUBSYSTEM_XBOX,                 // = 14
        IMAGE_SUBSYSTEM_WINDOWS_BOOT_APPLICATION = 16
}

// IMAGE_OPTIONAL_HEADER.DllCharacteristics
const WORD
        IMAGE_DLL_CHARACTERISTICS_DYNAMIC_BASE         = 0x0040,
        IMAGE_DLL_CHARACTERISTICS_FORCE_INTEGRITY      = 0x0080,
        IMAGE_DLL_CHARACTERISTICS_NX_COMPAT            = 0x0100,
        IMAGE_DLLCHARACTERISTICS_NO_ISOLATION          = 0x0200,
        IMAGE_DLLCHARACTERISTICS_NO_SEH                = 0x0400,
        IMAGE_DLLCHARACTERISTICS_NO_BIND               = 0x0800,
        IMAGE_DLLCHARACTERISTICS_WDM_DRIVER            = 0x2000,
        IMAGE_DLLCHARACTERISTICS_TERMINAL_SERVER_AWARE = 0x8000;

// ???
const IMAGE_SEPARATE_DEBUG_SIGNATURE = 0x4944;

const size_t
        IMAGE_NUMBEROF_DIRECTORY_ENTRIES =  16,
        IMAGE_SIZEOF_ROM_OPTIONAL_HEADER =  56,
        IMAGE_SIZEOF_STD_OPTIONAL_HEADER =  28,
        IMAGE_SIZEOF_NT_OPTIONAL_HEADER  = 224,
        IMAGE_SIZEOF_SHORT_NAME          =   8,
        IMAGE_SIZEOF_SECTION_HEADER      =  40,
        IMAGE_SIZEOF_SYMBOL              =  18,
        IMAGE_SIZEOF_AUX_SYMBOL          =  18,
        IMAGE_SIZEOF_RELOCATION          =  10,
        IMAGE_SIZEOF_BASE_RELOCATION     =   8,
        IMAGE_SIZEOF_LINENUMBER          =   6,
        IMAGE_SIZEOF_ARCHIVE_MEMBER_HDR  =  60,
        SIZEOF_RFPO_DATA                 =  16;

PIMAGE_SECTION_HEADER IMAGE_FIRST_SECTION(PIMAGE_NT_HEADERS h) {
        return cast(PIMAGE_SECTION_HEADER)
                (&h.OptionalHeader + h.FileHeader.SizeOfOptionalHeader);
}

// ImageDirectoryEntryToDataEx()
enum : USHORT {
        IMAGE_DIRECTORY_ENTRY_EXPORT             =  0,
        IMAGE_DIRECTORY_ENTRY_IMPORT,
        IMAGE_DIRECTORY_ENTRY_RESOURCE,
        IMAGE_DIRECTORY_ENTRY_EXCEPTION,
        IMAGE_DIRECTORY_ENTRY_SECURITY,
        IMAGE_DIRECTORY_ENTRY_BASERELOC,
        IMAGE_DIRECTORY_ENTRY_DEBUG,
        IMAGE_DIRECTORY_ENTRY_COPYRIGHT,      // =  7
        IMAGE_DIRECTORY_ENTRY_ARCHITECTURE       =  7,
        IMAGE_DIRECTORY_ENTRY_GLOBALPTR,
        IMAGE_DIRECTORY_ENTRY_TLS,
        IMAGE_DIRECTORY_ENTRY_LOAD_CONFIG,
        IMAGE_DIRECTORY_ENTRY_BOUND_IMPORT,
        IMAGE_DIRECTORY_ENTRY_IAT,
        IMAGE_DIRECTORY_ENTRY_DELAY_IMPORT,
        IMAGE_DIRECTORY_ENTRY_COM_DESCRIPTOR, // = 14
}

// IMAGE_SECTION_HEADER.Characteristics
const DWORD
        IMAGE_SCN_TYPE_REG               = 0x00000000,
        IMAGE_SCN_TYPE_DSECT             = 0x00000001,
        IMAGE_SCN_TYPE_NOLOAD            = 0x00000002,
        IMAGE_SCN_TYPE_GROUP             = 0x00000004,
        IMAGE_SCN_TYPE_NO_PAD            = 0x00000008,
        IMAGE_SCN_TYPE_COPY              = 0x00000010,
        IMAGE_SCN_CNT_CODE               = 0x00000020,
        IMAGE_SCN_CNT_INITIALIZED_DATA   = 0x00000040,
        IMAGE_SCN_CNT_UNINITIALIZED_DATA = 0x00000080,
        IMAGE_SCN_LNK_OTHER              = 0x00000100,
        IMAGE_SCN_LNK_INFO               = 0x00000200,
        IMAGE_SCN_TYPE_OVER              = 0x00000400,
        IMAGE_SCN_LNK_REMOVE             = 0x00000800,
        IMAGE_SCN_LNK_COMDAT             = 0x00001000,
        IMAGE_SCN_MEM_FARDATA            = 0x00008000,
        IMAGE_SCN_GPREL                  = 0x00008000,
        IMAGE_SCN_MEM_PURGEABLE          = 0x00020000,
        IMAGE_SCN_MEM_16BIT              = 0x00020000,
        IMAGE_SCN_MEM_LOCKED             = 0x00040000,
        IMAGE_SCN_MEM_PRELOAD            = 0x00080000,
        IMAGE_SCN_ALIGN_1BYTES           = 0x00100000,
        IMAGE_SCN_ALIGN_2BYTES           = 0x00200000,
        IMAGE_SCN_ALIGN_4BYTES           = 0x00300000,
        IMAGE_SCN_ALIGN_8BYTES           = 0x00400000,
        IMAGE_SCN_ALIGN_16BYTES          = 0x00500000,
        IMAGE_SCN_ALIGN_32BYTES          = 0x00600000,
        IMAGE_SCN_ALIGN_64BYTES          = 0x00700000,
        IMAGE_SCN_ALIGN_128BYTES         = 0x00800000,
        IMAGE_SCN_ALIGN_256BYTES         = 0x00900000,
        IMAGE_SCN_ALIGN_512BYTES         = 0x00A00000,
        IMAGE_SCN_ALIGN_1024BYTES        = 0x00B00000,
        IMAGE_SCN_ALIGN_2048BYTES        = 0x00C00000,
        IMAGE_SCN_ALIGN_4096BYTES        = 0x00D00000,
        IMAGE_SCN_ALIGN_8192BYTES        = 0x00E00000,
        IMAGE_SCN_LNK_NRELOC_OVFL        = 0x01000000,
        IMAGE_SCN_MEM_DISCARDABLE        = 0x02000000,
        IMAGE_SCN_MEM_NOT_CACHED         = 0x04000000,
        IMAGE_SCN_MEM_NOT_PAGED          = 0x08000000,
        IMAGE_SCN_MEM_SHARED             = 0x10000000,
        IMAGE_SCN_MEM_EXECUTE            = 0x20000000,
        IMAGE_SCN_MEM_READ               = 0x40000000,
        IMAGE_SCN_MEM_WRITE              = 0x80000000;

/*      The following constants are mostlydocumented at
 *      http://download.microsoft.com/download/1/6/1/161ba512-40e2-4cc9-843a-923143f3456c/pecoff.doc
 *      but don't seem to be defined in the HTML docs.
 */
enum : SHORT {
        IMAGE_SYM_UNDEFINED =  0,
        IMAGE_SYM_ABSOLUTE  = -1,
        IMAGE_SYM_DEBUG     = -2
}

enum : ubyte {
        IMAGE_SYM_TYPE_NULL,
        IMAGE_SYM_TYPE_VOID,
        IMAGE_SYM_TYPE_CHAR,
        IMAGE_SYM_TYPE_SHORT,
        IMAGE_SYM_TYPE_INT,
        IMAGE_SYM_TYPE_LONG,
        IMAGE_SYM_TYPE_FLOAT,
        IMAGE_SYM_TYPE_DOUBLE,
        IMAGE_SYM_TYPE_STRUCT,
        IMAGE_SYM_TYPE_UNION,
        IMAGE_SYM_TYPE_ENUM,
        IMAGE_SYM_TYPE_MOE,
        IMAGE_SYM_TYPE_BYTE,
        IMAGE_SYM_TYPE_WORD,
        IMAGE_SYM_TYPE_UINT,
        IMAGE_SYM_TYPE_DWORD // = 15
}
const IMAGE_SYM_TYPE_PCODE = 32768; // ???

enum : ubyte {
        IMAGE_SYM_DTYPE_NULL,
        IMAGE_SYM_DTYPE_POINTER,
        IMAGE_SYM_DTYPE_FUNCTION,
        IMAGE_SYM_DTYPE_ARRAY
}

enum : BYTE {
        IMAGE_SYM_CLASS_END_OF_FUNCTION  = 0xFF,
        IMAGE_SYM_CLASS_NULL             =   0,
        IMAGE_SYM_CLASS_AUTOMATIC,
        IMAGE_SYM_CLASS_EXTERNAL,
        IMAGE_SYM_CLASS_STATIC,
        IMAGE_SYM_CLASS_REGISTER,
        IMAGE_SYM_CLASS_EXTERNAL_DEF,
        IMAGE_SYM_CLASS_LABEL,
        IMAGE_SYM_CLASS_UNDEFINED_LABEL,
        IMAGE_SYM_CLASS_MEMBER_OF_STRUCT,
        IMAGE_SYM_CLASS_ARGUMENT,
        IMAGE_SYM_CLASS_STRUCT_TAG,
        IMAGE_SYM_CLASS_MEMBER_OF_UNION,
        IMAGE_SYM_CLASS_UNION_TAG,
        IMAGE_SYM_CLASS_TYPE_DEFINITION,
        IMAGE_SYM_CLASS_UNDEFINED_STATIC,
        IMAGE_SYM_CLASS_ENUM_TAG,
        IMAGE_SYM_CLASS_MEMBER_OF_ENUM,
        IMAGE_SYM_CLASS_REGISTER_PARAM,
        IMAGE_SYM_CLASS_BIT_FIELD,    // =  18
        IMAGE_SYM_CLASS_FAR_EXTERNAL     =  68,
        IMAGE_SYM_CLASS_BLOCK            = 100,
        IMAGE_SYM_CLASS_FUNCTION,
        IMAGE_SYM_CLASS_END_OF_STRUCT,
        IMAGE_SYM_CLASS_FILE,
        IMAGE_SYM_CLASS_SECTION,
        IMAGE_SYM_CLASS_WEAK_EXTERNAL,// = 105
        IMAGE_SYM_CLASS_CLR_TOKEN        = 107
}

enum : BYTE {
        IMAGE_COMDAT_SELECT_NODUPLICATES = 1,
        IMAGE_COMDAT_SELECT_ANY,
        IMAGE_COMDAT_SELECT_SAME_SIZE,
        IMAGE_COMDAT_SELECT_EXACT_MATCH,
        IMAGE_COMDAT_SELECT_ASSOCIATIVE,
        IMAGE_COMDAT_SELECT_LARGEST,
        IMAGE_COMDAT_SELECT_NEWEST    // = 7
}

enum : DWORD {
        IMAGE_WEAK_EXTERN_SEARCH_NOLIBRARY = 1,
        IMAGE_WEAK_EXTERN_SEARCH_LIBRARY,
        IMAGE_WEAK_EXTERN_SEARCH_ALIAS
}

enum : WORD {
        IMAGE_REL_I386_ABSOLUTE       = 0x0000,
        IMAGE_REL_I386_DIR16          = 0x0001,
        IMAGE_REL_I386_REL16          = 0x0002,
        IMAGE_REL_I386_DIR32          = 0x0006,
        IMAGE_REL_I386_DIR32NB        = 0x0007,
        IMAGE_REL_I386_SEG12          = 0x0009,
        IMAGE_REL_I386_SECTION        = 0x000A,
        IMAGE_REL_I386_SECREL         = 0x000B,
        IMAGE_REL_I386_TOKEN          = 0x000C,
        IMAGE_REL_I386_SECREL7        = 0x000D,
        IMAGE_REL_I386_REL32          = 0x0014
}

enum : WORD {
        IMAGE_REL_AMD64_ABSOLUTE      = 0x0000,
        IMAGE_REL_AMD64_ADDR64        = 0x0001,
        IMAGE_REL_AMD64_ADDR32        = 0x0002,
        IMAGE_REL_AMD64_ADDR32NB      = 0x0003,
        IMAGE_REL_AMD64_REL32         = 0x0004,
        IMAGE_REL_AMD64_REL32_1       = 0x0005,
        IMAGE_REL_AMD64_REL32_2       = 0x0006,
        IMAGE_REL_AMD64_REL32_3       = 0x0007,
        IMAGE_REL_AMD64_REL32_4       = 0x0008,
        IMAGE_REL_AMD64_REL32_5       = 0x0009,
        IMAGE_REL_AMD64_SECTION       = 0x000A,
        IMAGE_REL_AMD64_SECREL        = 0x000B,
        IMAGE_REL_AMD64_SECREL7       = 0x000C,
        IMAGE_REL_AMD64_TOKEN         = 0x000D,
        IMAGE_REL_AMD64_SREL32        = 0x000E,
        IMAGE_REL_AMD64_PAIR          = 0x000F,
        IMAGE_REL_AMD64_SSPAN32       = 0x0010
}

enum : WORD {
        IMAGE_REL_IA64_ABSOLUTE       = 0x0000,
        IMAGE_REL_IA64_IMM14          = 0x0001,
        IMAGE_REL_IA64_IMM22          = 0x0002,
        IMAGE_REL_IA64_IMM64          = 0x0003,
        IMAGE_REL_IA64_DIR32          = 0x0004,
        IMAGE_REL_IA64_DIR64          = 0x0005,
        IMAGE_REL_IA64_PCREL21B       = 0x0006,
        IMAGE_REL_IA64_PCREL21M       = 0x0007,
        IMAGE_REL_IA64_PCREL21F       = 0x0008,
        IMAGE_REL_IA64_GPREL22        = 0x0009,
        IMAGE_REL_IA64_LTOFF22        = 0x000A,
        IMAGE_REL_IA64_SECTION        = 0x000B,
        IMAGE_REL_IA64_SECREL22       = 0x000C,
        IMAGE_REL_IA64_SECREL64I      = 0x000D,
        IMAGE_REL_IA64_SECREL32       = 0x000E,
        IMAGE_REL_IA64_DIR32NB        = 0x0010,
        IMAGE_REL_IA64_SREL14         = 0x0011,
        IMAGE_REL_IA64_SREL22         = 0x0012,
        IMAGE_REL_IA64_SREL32         = 0x0013,
        IMAGE_REL_IA64_UREL32         = 0x0014,
        IMAGE_REL_IA64_PCREL60X       = 0x0015,
        IMAGE_REL_IA64_PCREL60B       = 0x0016,
        IMAGE_REL_IA64_PCREL60F       = 0x0017,
        IMAGE_REL_IA64_PCREL60I       = 0x0018,
        IMAGE_REL_IA64_PCREL60M       = 0x0019,
        IMAGE_REL_IA64_IMMGPREL64     = 0x001A,
        IMAGE_REL_IA64_TOKEN          = 0x001B,
        IMAGE_REL_IA64_GPREL32        = 0x001C,
        IMAGE_REL_IA64_ADDEND         = 0x001F
}

enum : WORD {
        IMAGE_REL_SH3_ABSOLUTE        = 0x0000,
        IMAGE_REL_SH3_DIRECT16        = 0x0001,
        IMAGE_REL_SH3_DIRECT32        = 0x0002,
        IMAGE_REL_SH3_DIRECT8         = 0x0003,
        IMAGE_REL_SH3_DIRECT8_WORD    = 0x0004,
        IMAGE_REL_SH3_DIRECT8_LONG    = 0x0005,
        IMAGE_REL_SH3_DIRECT4         = 0x0006,
        IMAGE_REL_SH3_DIRECT4_WORD    = 0x0007,
        IMAGE_REL_SH3_DIRECT4_LONG    = 0x0008,
        IMAGE_REL_SH3_PCREL8_WORD     = 0x0009,
        IMAGE_REL_SH3_PCREL8_LONG     = 0x000A,
        IMAGE_REL_SH3_PCREL12_WORD    = 0x000B,
        IMAGE_REL_SH3_STARTOF_SECTION = 0x000C,
        IMAGE_REL_SH3_SIZEOF_SECTION  = 0x000D,
        IMAGE_REL_SH3_SECTION         = 0x000E,
        IMAGE_REL_SH3_SECREL          = 0x000F,
        IMAGE_REL_SH3_DIRECT32_NB     = 0x0010,
        IMAGE_REL_SH3_GPREL4_LONG     = 0x0011,
        IMAGE_REL_SH3_TOKEN           = 0x0012,
        IMAGE_REL_SHM_PCRELPT         = 0x0013,
        IMAGE_REL_SHM_REFLO           = 0x0014,
        IMAGE_REL_SHM_REFHALF         = 0x0015,
        IMAGE_REL_SHM_RELLO           = 0x0016,
        IMAGE_REL_SHM_RELHALF         = 0x0017,
        IMAGE_REL_SHM_PAIR            = 0x0018,
        IMAGE_REL_SHM_NOMODE          = 0x8000
}

enum : WORD {
        IMAGE_REL_M32R_ABSOLUTE       = 0x0000,
        IMAGE_REL_M32R_ADDR32         = 0x0001,
        IMAGE_REL_M32R_ADDR32NB       = 0x0002,
        IMAGE_REL_M32R_ADDR24         = 0x0003,
        IMAGE_REL_M32R_GPREL16        = 0x0004,
        IMAGE_REL_M32R_PCREL24        = 0x0005,
        IMAGE_REL_M32R_PCREL16        = 0x0006,
        IMAGE_REL_M32R_PCREL8         = 0x0007,
        IMAGE_REL_M32R_REFHALF        = 0x0008,
        IMAGE_REL_M32R_REFHI          = 0x0009,
        IMAGE_REL_M32R_REFLO          = 0x000A,
        IMAGE_REL_M32R_PAIR           = 0x000B,
        IMAGE_REL_M32R_SECTION        = 0x000C,
        IMAGE_REL_M32R_SECREL         = 0x000D,
        IMAGE_REL_M32R_TOKEN          = 0x000E
}

enum : WORD {
        IMAGE_REL_MIPS_ABSOLUTE       = 0x0000,
        IMAGE_REL_MIPS_REFHALF        = 0x0001,
        IMAGE_REL_MIPS_REFWORD        = 0x0002,
        IMAGE_REL_MIPS_JMPADDR        = 0x0003,
        IMAGE_REL_MIPS_REFHI          = 0x0004,
        IMAGE_REL_MIPS_REFLO          = 0x0005,
        IMAGE_REL_MIPS_GPREL          = 0x0006,
        IMAGE_REL_MIPS_LITERAL        = 0x0007,
        IMAGE_REL_MIPS_SECTION        = 0x000A,
        IMAGE_REL_MIPS_SECREL         = 0x000B,
        IMAGE_REL_MIPS_SECRELLO       = 0x000C,
        IMAGE_REL_MIPS_SECRELHI       = 0x000D,
        IMAGE_REL_MIPS_JMPADDR16      = 0x0010,
        IMAGE_REL_MIPS_REFWORDNB      = 0x0022,
        IMAGE_REL_MIPS_PAIR           = 0x0025
}


enum : WORD {
        IMAGE_REL_ALPHA_ABSOLUTE,
        IMAGE_REL_ALPHA_REFLONG,
        IMAGE_REL_ALPHA_REFQUAD,
        IMAGE_REL_ALPHA_GPREL32,
        IMAGE_REL_ALPHA_LITERAL,
        IMAGE_REL_ALPHA_LITUSE,
        IMAGE_REL_ALPHA_GPDISP,
        IMAGE_REL_ALPHA_BRADDR,
        IMAGE_REL_ALPHA_HINT,
        IMAGE_REL_ALPHA_INLINE_REFLONG,
        IMAGE_REL_ALPHA_REFHI,
        IMAGE_REL_ALPHA_REFLO,
        IMAGE_REL_ALPHA_PAIR,
        IMAGE_REL_ALPHA_MATCH,
        IMAGE_REL_ALPHA_SECTION,
        IMAGE_REL_ALPHA_SECREL,
        IMAGE_REL_ALPHA_REFLONGNB,
        IMAGE_REL_ALPHA_SECRELLO,
        IMAGE_REL_ALPHA_SECRELHI // = 18
}

enum : WORD {
        IMAGE_REL_PPC_ABSOLUTE,
        IMAGE_REL_PPC_ADDR64,
        IMAGE_REL_PPC_ADDR32,
        IMAGE_REL_PPC_ADDR24,
        IMAGE_REL_PPC_ADDR16,
        IMAGE_REL_PPC_ADDR14,
        IMAGE_REL_PPC_REL24,
        IMAGE_REL_PPC_REL14,
        IMAGE_REL_PPC_TOCREL16,
        IMAGE_REL_PPC_TOCREL14,
        IMAGE_REL_PPC_ADDR32NB,
        IMAGE_REL_PPC_SECREL,
        IMAGE_REL_PPC_SECTION,
        IMAGE_REL_PPC_IFGLUE,
        IMAGE_REL_PPC_IMGLUE,
        IMAGE_REL_PPC_SECREL16,
        IMAGE_REL_PPC_REFHI,
        IMAGE_REL_PPC_REFLO,
        IMAGE_REL_PPC_PAIR // = 18
}

// ???
const IMAGE_REL_PPC_TYPEMASK = 0x00FF;
const IMAGE_REL_PPC_NEG      = 0x0100;
const IMAGE_REL_PPC_BRTAKEN  = 0x0200;
const IMAGE_REL_PPC_BRNTAKEN = 0x0400;
const IMAGE_REL_PPC_TOCDEFN  = 0x0800;

enum {
        IMAGE_REL_BASED_ABSOLUTE,
        IMAGE_REL_BASED_HIGH,
        IMAGE_REL_BASED_LOW,
        IMAGE_REL_BASED_HIGHLOW,
        IMAGE_REL_BASED_HIGHADJ,
        IMAGE_REL_BASED_MIPS_JMPADDR
}
// End of constants documented in pecoff.doc

const size_t IMAGE_ARCHIVE_START_SIZE = 8;

const TCHAR[]
        IMAGE_ARCHIVE_START            = "!<arch>\n",
        IMAGE_ARCHIVE_END              = "`\n",
        IMAGE_ARCHIVE_PAD              = "\n",
        IMAGE_ARCHIVE_LINKER_MEMBER    = "/               ",
        IMAGE_ARCHIVE_LONGNAMES_MEMBER = "//              ";

const IMAGE_ORDINAL_FLAG32 = 0x80000000;

ulong IMAGE_ORDINAL64(ulong Ordinal) { return Ordinal & 0xFFFF; }
uint IMAGE_ORDINAL32(uint Ordinal)   { return Ordinal & 0xFFFF; }

bool IMAGE_SNAP_BY_ORDINAL32(uint Ordinal) {
        return (Ordinal & IMAGE_ORDINAL_FLAG32) != 0;
}

const ulong IMAGE_ORDINAL_FLAG64 = 0x8000000000000000;

bool IMAGE_SNAP_BY_ORDINAL64(ulong Ordinal) {
        return (Ordinal & IMAGE_ORDINAL_FLAG64) != 0;
}

// ???
const IMAGE_RESOURCE_NAME_IS_STRING    = 0x80000000;
const IMAGE_RESOURCE_DATA_IS_DIRECTORY = 0x80000000;

enum : DWORD {
        IMAGE_DEBUG_TYPE_UNKNOWN,
        IMAGE_DEBUG_TYPE_COFF,
        IMAGE_DEBUG_TYPE_CODEVIEW,
        IMAGE_DEBUG_TYPE_FPO,
        IMAGE_DEBUG_TYPE_MISC,
        IMAGE_DEBUG_TYPE_EXCEPTION,
        IMAGE_DEBUG_TYPE_FIXUP,
        IMAGE_DEBUG_TYPE_OMAP_TO_SRC,
        IMAGE_DEBUG_TYPE_OMAP_FROM_SRC,
        IMAGE_DEBUG_TYPE_BORLAND // = 9
}

enum : ubyte {
        FRAME_FPO,
        FRAME_TRAP,
        FRAME_TSS,
        FRAME_NONFPO
}

// ???
const IMAGE_DEBUG_MISC_EXENAME = 1;

// ???
const N_BTMASK = 0x000F;
const N_TMASK  = 0x0030;
const N_TMASK1 = 0x00C0;
const N_TMASK2 = 0x00F0;
const N_BTSHFT = 4;
const N_TSHIFT = 2;

const int
        IS_TEXT_UNICODE_ASCII16            = 0x0001,
        IS_TEXT_UNICODE_STATISTICS         = 0x0002,
        IS_TEXT_UNICODE_CONTROLS           = 0x0004,
        IS_TEXT_UNICODE_SIGNATURE          = 0x0008,
        IS_TEXT_UNICODE_REVERSE_ASCII16    = 0x0010,
        IS_TEXT_UNICODE_REVERSE_STATISTICS = 0x0020,
        IS_TEXT_UNICODE_REVERSE_CONTROLS   = 0x0040,
        IS_TEXT_UNICODE_REVERSE_SIGNATURE  = 0x0080,
        IS_TEXT_UNICODE_ILLEGAL_CHARS      = 0x0100,
        IS_TEXT_UNICODE_ODD_LENGTH         = 0x0200,
        IS_TEXT_UNICODE_NULL_BYTES         = 0x1000,
        IS_TEXT_UNICODE_UNICODE_MASK       = 0x000F,
        IS_TEXT_UNICODE_REVERSE_MASK       = 0x00F0,
        IS_TEXT_UNICODE_NOT_UNICODE_MASK   = 0x0F00,
        IS_TEXT_UNICODE_NOT_ASCII_MASK     = 0xF000;

const DWORD
        SERVICE_KERNEL_DRIVER       = 0x0001,
        SERVICE_FILE_SYSTEM_DRIVER  = 0x0002,
        SERVICE_ADAPTER             = 0x0004,
        SERVICE_RECOGNIZER_DRIVER   = 0x0008,
        SERVICE_WIN32_OWN_PROCESS   = 0x0010,
        SERVICE_WIN32_SHARE_PROCESS = 0x0020,
        SERVICE_INTERACTIVE_PROCESS = 0x0100,
        SERVICE_DRIVER              = 0x000B,
        SERVICE_WIN32               = 0x0030,
        SERVICE_TYPE_ALL            = 0x013F;

enum : DWORD {
        SERVICE_BOOT_START   = 0,
        SERVICE_SYSTEM_START = 1,
        SERVICE_AUTO_START   = 2,
        SERVICE_DEMAND_START = 3,
        SERVICE_DISABLED     = 4
}

enum : DWORD {
        SERVICE_ERROR_IGNORE   = 0,
        SERVICE_ERROR_NORMAL   = 1,
        SERVICE_ERROR_SEVERE   = 2,
        SERVICE_ERROR_CRITICAL = 3
}


const uint
        SE_OWNER_DEFAULTED          = 0x0001,
        SE_GROUP_DEFAULTED          = 0x0002,
        SE_DACL_PRESENT             = 0x0004,
        SE_DACL_DEFAULTED           = 0x0008,
        SE_SACL_PRESENT             = 0x0010,
        SE_SACL_DEFAULTED           = 0x0020,
        SE_DACL_AUTO_INHERIT_REQ    = 0x0100,
        SE_SACL_AUTO_INHERIT_REQ    = 0x0200,
        SE_DACL_AUTO_INHERITED      = 0x0400,
        SE_SACL_AUTO_INHERITED      = 0x0800,
        SE_DACL_PROTECTED           = 0x1000,
        SE_SACL_PROTECTED           = 0x2000,
        SE_SELF_RELATIVE            = 0x8000;

enum SECURITY_IMPERSONATION_LEVEL {
        SecurityAnonymous,
        SecurityIdentification,
        SecurityImpersonation,
        SecurityDelegation
}
alias SECURITY_IMPERSONATION_LEVEL* PSECURITY_IMPERSONATION_LEVEL;

alias BOOLEAN SECURITY_CONTEXT_TRACKING_MODE;
alias BOOLEAN* PSECURITY_CONTEXT_TRACKING_MODE;

const size_t SECURITY_DESCRIPTOR_MIN_LENGTH = 20;

const DWORD
        SECURITY_DESCRIPTOR_REVISION  = 1,
        SECURITY_DESCRIPTOR_REVISION1 = 1;

const DWORD
        SE_PRIVILEGE_ENABLED_BY_DEFAULT = 0x00000001,
        SE_PRIVILEGE_ENABLED            = 0x00000002,
        SE_PRIVILEGE_USED_FOR_ACCESS    = 0x80000000;

const DWORD PRIVILEGE_SET_ALL_NECESSARY = 1;

const SECURITY_IMPERSONATION_LEVEL
        SECURITY_MAX_IMPERSONATION_LEVEL = SECURITY_IMPERSONATION_LEVEL.SecurityDelegation,
        DEFAULT_IMPERSONATION_LEVEL      = SECURITY_IMPERSONATION_LEVEL.SecurityImpersonation;

const BOOLEAN
        SECURITY_DYNAMIC_TRACKING = true,
        SECURITY_STATIC_TRACKING  = false;

// also in ddk/ntifs.h
const DWORD
        TOKEN_ASSIGN_PRIMARY    = 0x0001,
        TOKEN_DUPLICATE         = 0x0002,
        TOKEN_IMPERSONATE       = 0x0004,
        TOKEN_QUERY             = 0x0008,
        TOKEN_QUERY_SOURCE      = 0x0010,
        TOKEN_ADJUST_PRIVILEGES = 0x0020,
        TOKEN_ADJUST_GROUPS     = 0x0040,
        TOKEN_ADJUST_DEFAULT    = 0x0080,

        TOKEN_ALL_ACCESS        = STANDARD_RIGHTS_REQUIRED
                              | TOKEN_ASSIGN_PRIMARY
                              | TOKEN_DUPLICATE
                              | TOKEN_IMPERSONATE
                              | TOKEN_QUERY
                              | TOKEN_QUERY_SOURCE
                              | TOKEN_ADJUST_PRIVILEGES
                              | TOKEN_ADJUST_GROUPS
                              | TOKEN_ADJUST_DEFAULT,
        TOKEN_READ              = STANDARD_RIGHTS_READ | TOKEN_QUERY,
        TOKEN_WRITE             = STANDARD_RIGHTS_WRITE
                              | TOKEN_ADJUST_PRIVILEGES
                              | TOKEN_ADJUST_GROUPS
                              | TOKEN_ADJUST_DEFAULT,
        TOKEN_EXECUTE           = STANDARD_RIGHTS_EXECUTE;

const size_t TOKEN_SOURCE_LENGTH = 8;
// end ddk/ntifs.h

enum : DWORD {
        DLL_PROCESS_DETACH,
        DLL_PROCESS_ATTACH,
        DLL_THREAD_ATTACH,
        DLL_THREAD_DETACH
}

enum : DWORD {
        DBG_CONTINUE              = 0x00010002,
        DBG_TERMINATE_THREAD      = 0x40010003,
        DBG_TERMINATE_PROCESS     = 0x40010004,
        DBG_CONTROL_C             = 0x40010005,
        DBG_CONTROL_BREAK         = 0x40010008,
        DBG_EXCEPTION_NOT_HANDLED = 0x80010001
}

enum : DWORD {
        TAPE_ABSOLUTE_POSITION,
        TAPE_LOGICAL_POSITION,
        TAPE_PSEUDO_LOGICAL_POSITION
}

enum : DWORD {
        TAPE_REWIND,
        TAPE_ABSOLUTE_BLOCK,
        TAPE_LOGICAL_BLOCK,
        TAPE_PSEUDO_LOGICAL_BLOCK,
        TAPE_SPACE_END_OF_DATA,
        TAPE_SPACE_RELATIVE_BLOCKS,
        TAPE_SPACE_FILEMARKS,
        TAPE_SPACE_SEQUENTIAL_FMKS,
        TAPE_SPACE_SETMARKS,
        TAPE_SPACE_SEQUENTIAL_SMKS
}

const DWORD
        TAPE_DRIVE_FIXED            = 0x00000001,
        TAPE_DRIVE_SELECT           = 0x00000002,
        TAPE_DRIVE_INITIATOR        = 0x00000004,
        TAPE_DRIVE_ERASE_SHORT      = 0x00000010,
        TAPE_DRIVE_ERASE_LONG       = 0x00000020,
        TAPE_DRIVE_ERASE_BOP_ONLY   = 0x00000040,
        TAPE_DRIVE_ERASE_IMMEDIATE  = 0x00000080,
        TAPE_DRIVE_TAPE_CAPACITY    = 0x00000100,
        TAPE_DRIVE_TAPE_REMAINING   = 0x00000200,
        TAPE_DRIVE_FIXED_BLOCK      = 0x00000400,
        TAPE_DRIVE_VARIABLE_BLOCK   = 0x00000800,
        TAPE_DRIVE_WRITE_PROTECT    = 0x00001000,
        TAPE_DRIVE_EOT_WZ_SIZE      = 0x00002000,
        TAPE_DRIVE_ECC              = 0x00010000,
        TAPE_DRIVE_COMPRESSION      = 0x00020000,
        TAPE_DRIVE_PADDING          = 0x00040000,
        TAPE_DRIVE_REPORT_SMKS      = 0x00080000,
        TAPE_DRIVE_GET_ABSOLUTE_BLK = 0x00100000,
        TAPE_DRIVE_GET_LOGICAL_BLK  = 0x00200000,
        TAPE_DRIVE_SET_EOT_WZ_SIZE  = 0x00400000,
        TAPE_DRIVE_EJECT_MEDIA      = 0x01000000,
        TAPE_DRIVE_CLEAN_REQUESTS   = 0x02000000,
        TAPE_DRIVE_SET_CMP_BOP_ONLY = 0x04000000,
        TAPE_DRIVE_RESERVED_BIT     = 0x80000000;

const DWORD
        TAPE_DRIVE_LOAD_UNLOAD      = 0x80000001,
        TAPE_DRIVE_TENSION          = 0x80000002,
        TAPE_DRIVE_LOCK_UNLOCK      = 0x80000004,
        TAPE_DRIVE_REWIND_IMMEDIATE = 0x80000008,
        TAPE_DRIVE_SET_BLOCK_SIZE   = 0x80000010,
        TAPE_DRIVE_LOAD_UNLD_IMMED  = 0x80000020,
        TAPE_DRIVE_TENSION_IMMED    = 0x80000040,
        TAPE_DRIVE_LOCK_UNLK_IMMED  = 0x80000080,
        TAPE_DRIVE_SET_ECC          = 0x80000100,
        TAPE_DRIVE_SET_COMPRESSION  = 0x80000200,
        TAPE_DRIVE_SET_PADDING      = 0x80000400,
        TAPE_DRIVE_SET_REPORT_SMKS  = 0x80000800,
        TAPE_DRIVE_ABSOLUTE_BLK     = 0x80001000,
        TAPE_DRIVE_ABS_BLK_IMMED    = 0x80002000,
        TAPE_DRIVE_LOGICAL_BLK      = 0x80004000,
        TAPE_DRIVE_LOG_BLK_IMMED    = 0x80008000,
        TAPE_DRIVE_END_OF_DATA      = 0x80010000,
        TAPE_DRIVE_RELATIVE_BLKS    = 0x80020000,
        TAPE_DRIVE_FILEMARKS        = 0x80040000,
        TAPE_DRIVE_SEQUENTIAL_FMKS  = 0x80080000,
        TAPE_DRIVE_SETMARKS         = 0x80100000,
        TAPE_DRIVE_SEQUENTIAL_SMKS  = 0x80200000,
        TAPE_DRIVE_REVERSE_POSITION = 0x80400000,
        TAPE_DRIVE_SPACE_IMMEDIATE  = 0x80800000,
        TAPE_DRIVE_WRITE_SETMARKS   = 0x81000000,
        TAPE_DRIVE_WRITE_FILEMARKS  = 0x82000000,
        TAPE_DRIVE_WRITE_SHORT_FMKS = 0x84000000,
        TAPE_DRIVE_WRITE_LONG_FMKS  = 0x88000000,
        TAPE_DRIVE_WRITE_MARK_IMMED = 0x90000000,
        TAPE_DRIVE_FORMAT           = 0xA0000000,
        TAPE_DRIVE_FORMAT_IMMEDIATE = 0xC0000000,
        TAPE_DRIVE_HIGH_FEATURES    = 0x80000000;

enum : DWORD {
        TAPE_FIXED_PARTITIONS     = 0,
        TAPE_SELECT_PARTITIONS    = 1,
        TAPE_INITIATOR_PARTITIONS = 2
}

enum : DWORD {
        TAPE_SETMARKS,
        TAPE_FILEMARKS,
        TAPE_SHORT_FILEMARKS,
        TAPE_LONG_FILEMARKS
}

enum : DWORD {
        TAPE_ERASE_SHORT,
        TAPE_ERASE_LONG
}

enum : DWORD {
        TAPE_LOAD,
        TAPE_UNLOAD,
        TAPE_TENSION,
        TAPE_LOCK,
        TAPE_UNLOCK,
        TAPE_FORMAT
}

enum : ULONG32 {
        VER_PLATFORM_WIN32s,
        VER_PLATFORM_WIN32_WINDOWS,
        VER_PLATFORM_WIN32_NT
}

enum : UCHAR {
        VER_NT_WORKSTATION = 1,
        VER_NT_DOMAIN_CONTROLLER,
        VER_NT_SERVER
}

const USHORT
        VER_SUITE_SMALLBUSINESS            = 0x0001,
        VER_SUITE_ENTERPRISE               = 0x0002,
        VER_SUITE_BACKOFFICE               = 0x0004,
        VER_SUITE_TERMINAL                 = 0x0010,
        VER_SUITE_SMALLBUSINESS_RESTRICTED = 0x0020,
        VER_SUITE_EMBEDDEDNT               = 0x0040,
        VER_SUITE_DATACENTER               = 0x0080,
        VER_SUITE_SINGLEUSERTS             = 0x0100,
        VER_SUITE_PERSONAL                 = 0x0200,
        VER_SUITE_BLADE                    = 0x0400,
        VER_SUITE_STORAGE_SERVER           = 0x2000,
        VER_SUITE_COMPUTE_SERVER           = 0x4000;

const ULONG
        WT_EXECUTEDEFAULT            = 0x00000000,
        WT_EXECUTEINIOTHREAD         = 0x00000001,
        WT_EXECUTEINWAITTHREAD       = 0x00000004,
        WT_EXECUTEONLYONCE           = 0x00000008,
        WT_EXECUTELONGFUNCTION       = 0x00000010,
        WT_EXECUTEINTIMERTHREAD      = 0x00000020,
        WT_EXECUTEINPERSISTENTTHREAD = 0x00000080,
        WT_TRANSFER_IMPERSONATION    = 0x00000100;

static if (_WIN32_WINNT >= 0x500) {
        const DWORD
                VER_MINORVERSION     = 0x01,
                VER_MAJORVERSION     = 0x02,
                VER_BUILDNUMBER      = 0x04,
                VER_PLATFORMID       = 0x08,
                VER_SERVICEPACKMINOR = 0x10,
                VER_SERVICEPACKMAJOR = 0x20,
                VER_SUITENAME        = 0x40,
                VER_PRODUCT_TYPE     = 0x80;

        enum : DWORD {
                VER_EQUAL = 1,
                VER_GREATER,
                VER_GREATER_EQUAL,
                VER_LESS,
                VER_LESS_EQUAL,
                VER_AND,
                VER_OR // = 7
        }
}

static if (_WIN32_WINNT >= 0x501) {
        enum : ULONG {
                ACTIVATION_CONTEXT_SECTION_ASSEMBLY_INFORMATION       = 1,
                ACTIVATION_CONTEXT_SECTION_DLL_REDIRECTION,
                ACTIVATION_CONTEXT_SECTION_WINDOW_CLASS_REDIRECTION,
                ACTIVATION_CONTEXT_SECTION_COM_SERVER_REDIRECTION,
                ACTIVATION_CONTEXT_SECTION_COM_INTERFACE_REDIRECTION,
                ACTIVATION_CONTEXT_SECTION_COM_TYPE_LIBRARY_REDIRECTION,
                ACTIVATION_CONTEXT_SECTION_COM_PROGID_REDIRECTION, // = 7
                ACTIVATION_CONTEXT_SECTION_CLR_SURROGATES             = 9
        }
}

// Macros
BYTE BTYPE(BYTE x) { return cast(BYTE) (x & N_BTMASK); }
bool ISPTR(uint x) { return (x & N_TMASK) == (IMAGE_SYM_DTYPE_POINTER << N_BTSHFT); }
bool ISFCN(uint x) { return (x & N_TMASK) == (IMAGE_SYM_DTYPE_FUNCTION << N_BTSHFT); }
bool ISARY(uint x) { return (x & N_TMASK) == (IMAGE_SYM_DTYPE_ARRAY << N_BTSHFT); }
bool ISTAG(uint x) {
        return x == IMAGE_SYM_CLASS_STRUCT_TAG
            || x == IMAGE_SYM_CLASS_UNION_TAG
            || x == IMAGE_SYM_CLASS_ENUM_TAG;
}
uint INCREF(uint x) {
        return ((x & ~N_BTMASK) << N_TSHIFT) | (IMAGE_SYM_DTYPE_POINTER << N_BTSHFT)
          | (x & N_BTMASK);
}
uint DECREF(uint x) { return ((x >>> N_TSHIFT) & ~N_BTMASK) | (x & N_BTMASK); }

const DWORD TLS_MINIMUM_AVAILABLE = 64;

const ULONG
        IO_REPARSE_TAG_RESERVED_ZERO  = 0,
        IO_REPARSE_TAG_RESERVED_ONE   = 1,
        IO_REPARSE_TAG_RESERVED_RANGE = IO_REPARSE_TAG_RESERVED_ONE,
        IO_REPARSE_TAG_SYMBOLIC_LINK  = IO_REPARSE_TAG_RESERVED_ZERO,
        IO_REPARSE_TAG_MOUNT_POINT    = 0xA0000003,
        IO_REPARSE_TAG_SYMLINK        = 0xA000000C,
        IO_REPARSE_TAG_VALID_VALUES   = 0xE000FFFF;

/*      Although these are semantically boolean, they are documented and
 *      implemented to return ULONG; this behaviour is preserved for compatibility
 */
ULONG IsReparseTagMicrosoft(ULONG x)     { return x & 0x80000000; }
ULONG IsReparseTagHighLatency(ULONG x)   { return x & 0x40000000; }
ULONG IsReparseTagNameSurrogate(ULONG x) { return x & 0x20000000; }

bool IsReparseTagValid(ULONG x) {
        return !(x & ~IO_REPARSE_TAG_VALID_VALUES) && (x > IO_REPARSE_TAG_RESERVED_RANGE);
}

// Doesn't seem to make sense, but anyway....
ULONG WT_SET_MAX_THREADPOOL_THREADS(ref ULONG Flags, ushort Limit) {
        return Flags |= Limit << 16;
}

import core.sys.windows.basetyps;
/* also in core.sys.windows.basetyps
struct GUID {
        uint  Data1;
        ushort Data2;
        ushort Data3;
        ubyte  Data4[8];
}
alias GUID* REFGUID, LPGUID;
*/

struct GENERIC_MAPPING {
        ACCESS_MASK GenericRead;
        ACCESS_MASK GenericWrite;
        ACCESS_MASK GenericExecute;
        ACCESS_MASK GenericAll;
}
alias GENERIC_MAPPING* PGENERIC_MAPPING;

struct ACE_HEADER {
        BYTE AceType;
        BYTE AceFlags;
        WORD AceSize;
}
alias ACE_HEADER* PACE_HEADER;

struct ACCESS_ALLOWED_ACE {
        ACE_HEADER  Header;
        ACCESS_MASK Mask;
        DWORD       SidStart;
}
alias ACCESS_ALLOWED_ACE* PACCESS_ALLOWED_ACE;

struct ACCESS_DENIED_ACE {
        ACE_HEADER  Header;
        ACCESS_MASK Mask;
        DWORD       SidStart;
}
alias ACCESS_DENIED_ACE* PACCESS_DENIED_ACE;

struct SYSTEM_AUDIT_ACE {
        ACE_HEADER  Header;
        ACCESS_MASK Mask;
        DWORD       SidStart;
}
alias SYSTEM_AUDIT_ACE *PSYSTEM_AUDIT_ACE;

struct SYSTEM_ALARM_ACE {
        ACE_HEADER  Header;
        ACCESS_MASK Mask;
        DWORD       SidStart;
}
alias SYSTEM_ALARM_ACE* PSYSTEM_ALARM_ACE;

struct ACCESS_ALLOWED_OBJECT_ACE {
        ACE_HEADER  Header;
        ACCESS_MASK Mask;
        DWORD       Flags;
        GUID        ObjectType;
        GUID        InheritedObjectType;
        DWORD       SidStart;
}
alias ACCESS_ALLOWED_OBJECT_ACE* PACCESS_ALLOWED_OBJECT_ACE;

struct ACCESS_DENIED_OBJECT_ACE {
        ACE_HEADER  Header;
        ACCESS_MASK Mask;
        DWORD       Flags;
        GUID        ObjectType;
        GUID        InheritedObjectType;
        DWORD       SidStart;
}
alias ACCESS_DENIED_OBJECT_ACE* PACCESS_DENIED_OBJECT_ACE;

struct SYSTEM_AUDIT_OBJECT_ACE {
        ACE_HEADER  Header;
        ACCESS_MASK Mask;
        DWORD       Flags;
        GUID        ObjectType;
        GUID        InheritedObjectType;
        DWORD       SidStart;
}
alias SYSTEM_AUDIT_OBJECT_ACE* PSYSTEM_AUDIT_OBJECT_ACE;

struct SYSTEM_ALARM_OBJECT_ACE {
        ACE_HEADER  Header;
        ACCESS_MASK Mask;
        DWORD       Flags;
        GUID        ObjectType;
        GUID        InheritedObjectType;
        DWORD       SidStart;
}
alias SYSTEM_ALARM_OBJECT_ACE* PSYSTEM_ALARM_OBJECT_ACE;

struct ACL {
        BYTE AclRevision;
        BYTE Sbz1;
        WORD AclSize;
        WORD AceCount;
        WORD Sbz2;
}
alias ACL* PACL;

struct ACL_REVISION_INFORMATION {
        DWORD AclRevision;
}

struct ACL_SIZE_INFORMATION {
        DWORD AceCount;
        DWORD AclBytesInUse;
        DWORD AclBytesFree;
}

version (X86) {
        // ???
        const SIZE_OF_80387_REGISTERS     = 80;
        const CONTEXT_i386                = 0x010000;
        const CONTEXT_i486                = 0x010000;
        const CONTEXT_CONTROL             = CONTEXT_i386 | 0x01;
        const CONTEXT_INTEGER             = CONTEXT_i386 | 0x02;
        const CONTEXT_SEGMENTS            = CONTEXT_i386 | 0x04;
        const CONTEXT_FLOATING_POINT      = CONTEXT_i386 | 0x08;
        const CONTEXT_DEBUG_REGISTERS     = CONTEXT_i386 | 0x10;
        const CONTEXT_EXTENDED_REGISTERS  = CONTEXT_i386 | 0x20;
        const CONTEXT_FULL                = CONTEXT_CONTROL | CONTEXT_INTEGER | CONTEXT_SEGMENTS;
        const MAXIMUM_SUPPORTED_EXTENSION = 512;

        struct FLOATING_SAVE_AREA {
                DWORD    ControlWord;
                DWORD    StatusWord;
                DWORD    TagWord;
                DWORD    ErrorOffset;
                DWORD    ErrorSelector;
                DWORD    DataOffset;
                DWORD    DataSelector;
                BYTE[80] RegisterArea;
                DWORD    Cr0NpxState;
        }

        struct CONTEXT {
                DWORD ContextFlags;
                DWORD Dr0;
                DWORD Dr1;
                DWORD Dr2;
                DWORD Dr3;
                DWORD Dr6;
                DWORD Dr7;
                FLOATING_SAVE_AREA FloatSave;
                DWORD SegGs;
                DWORD SegFs;
                DWORD SegEs;
                DWORD SegDs;
                DWORD Edi;
                DWORD Esi;
                DWORD Ebx;
                DWORD Edx;
                DWORD Ecx;
                DWORD Eax;
                DWORD Ebp;
                DWORD Eip;
                DWORD SegCs;
                DWORD EFlags;
                DWORD Esp;
                DWORD SegSs;
                BYTE[MAXIMUM_SUPPORTED_EXTENSION] ExtendedRegisters;
        }

} else version(X86_64)
{
        const CONTEXT_AMD64 = 0x100000;

        const CONTEXT_CONTROL         = (CONTEXT_AMD64 | 0x1L);
        const CONTEXT_INTEGER         = (CONTEXT_AMD64 | 0x2L);
        const CONTEXT_SEGMENTS        = (CONTEXT_AMD64 | 0x4L);
        const CONTEXT_FLOATING_POINT  = (CONTEXT_AMD64 | 0x8L);
        const CONTEXT_DEBUG_REGISTERS = (CONTEXT_AMD64 | 0x10L);

        const CONTEXT_FULL = (CONTEXT_CONTROL | CONTEXT_INTEGER | CONTEXT_FLOATING_POINT);
        const CONTEXT_ALL  = (CONTEXT_CONTROL | CONTEXT_INTEGER | CONTEXT_SEGMENTS | CONTEXT_FLOATING_POINT | CONTEXT_DEBUG_REGISTERS);

        const CONTEXT_EXCEPTION_ACTIVE    = 0x8000000;
        const CONTEXT_SERVICE_ACTIVE      = 0x10000000;
        const CONTEXT_EXCEPTION_REQUEST   = 0x40000000;
        const CONTEXT_EXCEPTION_REPORTING = 0x80000000;

        const INITIAL_MXCSR = 0x1f80;
        const INITIAL_FPCSR = 0x027f;

        align(16) struct M128A
        {
                ULONGLONG Low;
                LONGLONG High;
        }
        alias M128A* PM128A;

        struct XMM_SAVE_AREA32
        {
                WORD ControlWord;
                WORD StatusWord;
                BYTE TagWord;
                BYTE Reserved1;
                WORD ErrorOpcode;
                DWORD ErrorOffset;
                WORD ErrorSelector;
                WORD Reserved2;
                DWORD DataOffset;
                WORD DataSelector;
                WORD Reserved3;
                DWORD MxCsr;
                DWORD MxCsr_Mask;
                M128A[8] FloatRegisters;
                M128A[16] XmmRegisters;
                BYTE[96] Reserved4;
        }
        alias XMM_SAVE_AREA32 PXMM_SAVE_AREA32;
        const LEGACY_SAVE_AREA_LENGTH = XMM_SAVE_AREA32.sizeof;

        align(16) struct CONTEXT
        {
                DWORD64 P1Home;
                DWORD64 P2Home;
                DWORD64 P3Home;
                DWORD64 P4Home;
                DWORD64 P5Home;
                DWORD64 P6Home;
                DWORD ContextFlags;
                DWORD MxCsr;
                WORD SegCs;
                WORD SegDs;
                WORD SegEs;
                WORD SegFs;
                WORD SegGs;
                WORD SegSs;
                DWORD EFlags;
                DWORD64 Dr0;
                DWORD64 Dr1;
                DWORD64 Dr2;
                DWORD64 Dr3;
                DWORD64 Dr6;
                DWORD64 Dr7;
                DWORD64 Rax;
                DWORD64 Rcx;
                DWORD64 Rdx;
                DWORD64 Rbx;
                DWORD64 Rsp;
                DWORD64 Rbp;
                DWORD64 Rsi;
                DWORD64 Rdi;
                DWORD64 R8;
                DWORD64 R9;
                DWORD64 R10;
                DWORD64 R11;
                DWORD64 R12;
                DWORD64 R13;
                DWORD64 R14;
                DWORD64 R15;
                DWORD64 Rip;
                union
                {
                        XMM_SAVE_AREA32 FltSave;
                        XMM_SAVE_AREA32 FloatSave;
                        struct
                        {
                                M128A[2] Header;
                                M128A[8] Legacy;
                                M128A Xmm0;
                                M128A Xmm1;
                                M128A Xmm2;
                                M128A Xmm3;
                                M128A Xmm4;
                                M128A Xmm5;
                                M128A Xmm6;
                                M128A Xmm7;
                                M128A Xmm8;
                                M128A Xmm9;
                                M128A Xmm10;
                                M128A Xmm11;
                                M128A Xmm12;
                                M128A Xmm13;
                                M128A Xmm14;
                                M128A Xmm15;
                        };
                };
                M128A[26] VectorRegister;
                DWORD64 VectorControl;
                DWORD64 DebugControl;
                DWORD64 LastBranchToRip;
                DWORD64 LastBranchFromRip;
                DWORD64 LastExceptionToRip;
                DWORD64 LastExceptionFromRip;
        }

} else {
        static assert(false, "Unsupported CPU");
        // Versions for PowerPC, Alpha, SHX, and MIPS removed.
}

alias CONTEXT* PCONTEXT, LPCONTEXT;

struct EXCEPTION_RECORD {
        DWORD ExceptionCode;
        DWORD ExceptionFlags;
        EXCEPTION_RECORD* ExceptionRecord;
        PVOID ExceptionAddress;
        DWORD NumberParameters;
        DWORD[EXCEPTION_MAXIMUM_PARAMETERS] ExceptionInformation;
}
alias EXCEPTION_RECORD* PEXCEPTION_RECORD, LPEXCEPTION_RECORD;

struct EXCEPTION_POINTERS {
        PEXCEPTION_RECORD ExceptionRecord;
        PCONTEXT          ContextRecord;
}
alias EXCEPTION_POINTERS* PEXCEPTION_POINTERS, LPEXCEPTION_POINTERS;

union LARGE_INTEGER {
        struct {
                uint LowPart;
                int  HighPart;
        }
        long QuadPart;
}
alias LARGE_INTEGER* PLARGE_INTEGER;

union ULARGE_INTEGER {
        struct {
                uint LowPart;
                uint HighPart;
        }
        ulong QuadPart;
}
alias ULARGE_INTEGER* PULARGE_INTEGER;

alias LARGE_INTEGER LUID;
alias LUID* PLUID;

const LUID SYSTEM_LUID = { QuadPart:999 };

align(4) struct LUID_AND_ATTRIBUTES {
        LUID  Luid;
        DWORD Attributes;
}
alias LUID_AND_ATTRIBUTES* PLUID_AND_ATTRIBUTES;

struct PRIVILEGE_SET {
        DWORD PrivilegeCount;
        DWORD Control;
        LUID_AND_ATTRIBUTES _Privilege;

        LUID_AND_ATTRIBUTES* Privilege() return { return &_Privilege; }
}
alias PRIVILEGE_SET* PPRIVILEGE_SET;

struct SECURITY_ATTRIBUTES {
        DWORD  nLength;
        LPVOID lpSecurityDescriptor;
        BOOL   bInheritHandle;
}
alias SECURITY_ATTRIBUTES* PSECURITY_ATTRIBUTES, LPSECURITY_ATTRIBUTES;

struct SECURITY_QUALITY_OF_SERVICE {
        DWORD   Length;
        SECURITY_IMPERSONATION_LEVEL   ImpersonationLevel;
        SECURITY_CONTEXT_TRACKING_MODE ContextTrackingMode;
        BOOLEAN EffectiveOnly;
}
alias SECURITY_QUALITY_OF_SERVICE* PSECURITY_QUALITY_OF_SERVICE;

alias PVOID PACCESS_TOKEN;

struct SE_IMPERSONATION_STATE {
        PACCESS_TOKEN Token;
        BOOLEAN       CopyOnOpen;
        BOOLEAN       EffectiveOnly;
        SECURITY_IMPERSONATION_LEVEL Level;
}
alias SE_IMPERSONATION_STATE* PSE_IMPERSONATION_STATE;

struct SID_IDENTIFIER_AUTHORITY {
        BYTE[6] Value;
}
alias SID_IDENTIFIER_AUTHORITY* PSID_IDENTIFIER_AUTHORITY, LPSID_IDENTIFIER_AUTHORITY;

alias PVOID PSID;

struct SID {
        BYTE  Revision;
        BYTE  SubAuthorityCount;
        SID_IDENTIFIER_AUTHORITY IdentifierAuthority;
        DWORD _SubAuthority;

        DWORD* SubAuthority() return { return &_SubAuthority; }
}
alias SID* PISID;

struct SID_AND_ATTRIBUTES {
        PSID  Sid;
        DWORD Attributes;
}
alias SID_AND_ATTRIBUTES* PSID_AND_ATTRIBUTES;

struct TOKEN_SOURCE {
        CHAR[TOKEN_SOURCE_LENGTH] SourceName;
        LUID SourceIdentifier;
}
alias TOKEN_SOURCE* PTOKEN_SOURCE;

struct TOKEN_CONTROL {
        LUID         TokenId;
        LUID         AuthenticationId;
        LUID         ModifiedId;
        TOKEN_SOURCE TokenSource;
}
alias TOKEN_CONTROL* PTOKEN_CONTROL;

struct TOKEN_DEFAULT_DACL {
        PACL DefaultDacl;
}
alias TOKEN_DEFAULT_DACL* PTOKEN_DEFAULT_DACL;

struct TOKEN_GROUPS {
        DWORD GroupCount;
        SID_AND_ATTRIBUTES _Groups;

        SID_AND_ATTRIBUTES* Groups() return { return &_Groups; }
}
alias TOKEN_GROUPS* PTOKEN_GROUPS, LPTOKEN_GROUPS;

struct TOKEN_OWNER {
        PSID Owner;
}
alias TOKEN_OWNER* PTOKEN_OWNER;

struct TOKEN_PRIMARY_GROUP {
        PSID PrimaryGroup;
}
alias TOKEN_PRIMARY_GROUP* PTOKEN_PRIMARY_GROUP;

struct TOKEN_PRIVILEGES {
        DWORD PrivilegeCount;
        LUID_AND_ATTRIBUTES _Privileges;

        LUID_AND_ATTRIBUTES* Privileges() return { return &_Privileges; }
}
alias TOKEN_PRIVILEGES* PTOKEN_PRIVILEGES, LPTOKEN_PRIVILEGES;

enum TOKEN_TYPE {
        TokenPrimary = 1,
        TokenImpersonation
}
alias TOKEN_TYPE* PTOKEN_TYPE;

struct TOKEN_STATISTICS {
        LUID          TokenId;
        LUID          AuthenticationId;
        LARGE_INTEGER ExpirationTime;
        TOKEN_TYPE    TokenType;
        SECURITY_IMPERSONATION_LEVEL ImpersonationLevel;
        DWORD         DynamicCharged;
        DWORD         DynamicAvailable;
        DWORD         GroupCount;
        DWORD         PrivilegeCount;
        LUID          ModifiedId;
}
alias TOKEN_STATISTICS* PTOKEN_STATISTICS;

struct TOKEN_USER {
        SID_AND_ATTRIBUTES User;
}
alias TOKEN_USER* PTOKEN_USER;

alias DWORD SECURITY_INFORMATION;
alias SECURITY_INFORMATION* PSECURITY_INFORMATION;
alias WORD SECURITY_DESCRIPTOR_CONTROL;
alias SECURITY_DESCRIPTOR_CONTROL* PSECURITY_DESCRIPTOR_CONTROL;

struct SECURITY_DESCRIPTOR {
        BYTE Revision;
        BYTE Sbz1;
        SECURITY_DESCRIPTOR_CONTROL Control;
        PSID Owner;
        PSID Group;
        PACL Sacl;
        PACL Dacl;
}
alias SECURITY_DESCRIPTOR* PSECURITY_DESCRIPTOR, PISECURITY_DESCRIPTOR;

enum TOKEN_INFORMATION_CLASS {
        TokenUser = 1,
        TokenGroups,
        TokenPrivileges,
        TokenOwner,
        TokenPrimaryGroup,
        TokenDefaultDacl,
        TokenSource,
        TokenType,
        TokenImpersonationLevel,
        TokenStatistics,
        TokenRestrictedSids,
        TokenSessionId,
        TokenGroupsAndPrivileges,
        TokenSessionReference,
        TokenSandBoxInert,
        TokenAuditPolicy,
        TokenOrigin
}

enum SID_NAME_USE {
        SidTypeUser = 1,
        SidTypeGroup,
        SidTypeDomain,
        SidTypeAlias,
        SidTypeWellKnownGroup,
        SidTypeDeletedAccount,
        SidTypeInvalid,
        SidTypeUnknown,
        SidTypeComputer
}
alias SID_NAME_USE* PSID_NAME_USE;

struct QUOTA_LIMITS {
        SIZE_T PagedPoolLimit;
        SIZE_T NonPagedPoolLimit;
        SIZE_T MinimumWorkingSetSize;
        SIZE_T MaximumWorkingSetSize;
        SIZE_T PagefileLimit;
        LARGE_INTEGER TimeLimit;
}
alias QUOTA_LIMITS* PQUOTA_LIMITS;

struct IO_COUNTERS {
        ULONGLONG ReadOperationCount;
        ULONGLONG WriteOperationCount;
        ULONGLONG OtherOperationCount;
        ULONGLONG ReadTransferCount;
        ULONGLONG WriteTransferCount;
        ULONGLONG OtherTransferCount;
}
alias IO_COUNTERS* PIO_COUNTERS;

struct FILE_NOTIFY_INFORMATION {
        DWORD NextEntryOffset;
        DWORD Action;
        DWORD FileNameLength;
        WCHAR _FileName;

        WCHAR* FileName() return { return &_FileName; }
}
alias FILE_NOTIFY_INFORMATION* PFILE_NOTIFY_INFORMATION;

struct TAPE_ERASE {
        DWORD   Type;
        BOOLEAN Immediate;
}
alias TAPE_ERASE* PTAPE_ERASE;

struct TAPE_GET_DRIVE_PARAMETERS {
        BOOLEAN ECC;
        BOOLEAN Compression;
        BOOLEAN DataPadding;
        BOOLEAN ReportSetmarks;
        DWORD   DefaultBlockSize;
        DWORD   MaximumBlockSize;
        DWORD   MinimumBlockSize;
        DWORD   MaximumPartitionCount;
        DWORD   FeaturesLow;
        DWORD   FeaturesHigh;
        DWORD   EOTWarningZoneSize;
}
alias TAPE_GET_DRIVE_PARAMETERS* PTAPE_GET_DRIVE_PARAMETERS;

struct TAPE_GET_MEDIA_PARAMETERS {
        LARGE_INTEGER Capacity;
        LARGE_INTEGER Remaining;
        DWORD         BlockSize;
        DWORD         PartitionCount;
        BOOLEAN       WriteProtected;
}
alias TAPE_GET_MEDIA_PARAMETERS* PTAPE_GET_MEDIA_PARAMETERS;

struct TAPE_GET_POSITION {
        ULONG Type;
        ULONG Partition;
        ULONG OffsetLow;
        ULONG OffsetHigh;
}
alias TAPE_GET_POSITION* PTAPE_GET_POSITION;

struct TAPE_PREPARE {
        DWORD   Operation;
        BOOLEAN Immediate;
}
alias TAPE_PREPARE* PTAPE_PREPARE;

struct TAPE_SET_DRIVE_PARAMETERS {
        BOOLEAN ECC;
        BOOLEAN Compression;
        BOOLEAN DataPadding;
        BOOLEAN ReportSetmarks;
        ULONG   EOTWarningZoneSize;
}
alias TAPE_SET_DRIVE_PARAMETERS* PTAPE_SET_DRIVE_PARAMETERS;

struct TAPE_SET_MEDIA_PARAMETERS {
        ULONG BlockSize;
}
alias TAPE_SET_MEDIA_PARAMETERS* PTAPE_SET_MEDIA_PARAMETERS;

struct TAPE_SET_POSITION {
        DWORD         Method;
        DWORD         Partition;
        LARGE_INTEGER Offset;
        BOOLEAN       Immediate;
}
alias TAPE_SET_POSITION* PTAPE_SET_POSITION;

struct TAPE_WRITE_MARKS {
        DWORD   Type;
        DWORD   Count;
        BOOLEAN Immediate;
}
alias TAPE_WRITE_MARKS* PTAPE_WRITE_MARKS;

struct TAPE_CREATE_PARTITION {
        DWORD Method;
        DWORD Count;
        DWORD Size;
}
alias TAPE_CREATE_PARTITION* PTAPE_CREATE_PARTITION;

struct MEMORY_BASIC_INFORMATION {
        PVOID BaseAddress;
        PVOID AllocationBase;
        DWORD AllocationProtect;
        DWORD RegionSize;
        DWORD State;
        DWORD Protect;
        DWORD Type;
}
alias MEMORY_BASIC_INFORMATION* PMEMORY_BASIC_INFORMATION;

struct MESSAGE_RESOURCE_ENTRY {
        WORD Length;
        WORD Flags;
        BYTE _Text;

        BYTE* Text() return { return &_Text; }
}
alias MESSAGE_RESOURCE_ENTRY* PMESSAGE_RESOURCE_ENTRY;

struct MESSAGE_RESOURCE_BLOCK {
        DWORD LowId;
        DWORD HighId;
        DWORD OffsetToEntries;
}
alias MESSAGE_RESOURCE_BLOCK* PMESSAGE_RESOURCE_BLOCK;

struct MESSAGE_RESOURCE_DATA {
        DWORD NumberOfBlocks;
        MESSAGE_RESOURCE_BLOCK _Blocks;

        MESSAGE_RESOURCE_BLOCK* Blocks() return { return &_Blocks; }
}
alias MESSAGE_RESOURCE_DATA* PMESSAGE_RESOURCE_DATA;

struct LIST_ENTRY {
        LIST_ENTRY* Flink;
        LIST_ENTRY* Blink;
}
alias LIST_ENTRY* PLIST_ENTRY;

struct SINGLE_LIST_ENTRY {
        SINGLE_LIST_ENTRY* Next;
}
alias SINGLE_LIST_ENTRY SLIST_ENTRY;
alias SINGLE_LIST_ENTRY* PSINGLE_LIST_ENTRY, PSLIST_ENTRY;

union SLIST_HEADER {
        ULONGLONG       Alignment;
        struct {
                SLIST_ENTRY Next;
                WORD        Depth;
                WORD        Sequence;
        }
}
alias SLIST_HEADER* PSLIST_HEADER;

struct RTL_CRITICAL_SECTION_DEBUG {
        WORD       Type;
        WORD       CreatorBackTraceIndex;
        RTL_CRITICAL_SECTION* CriticalSection;
        LIST_ENTRY ProcessLocksList;
        DWORD      EntryCount;
        DWORD      ContentionCount;
        DWORD[2]   Spare;
}
alias RTL_CRITICAL_SECTION_DEBUG* PRTL_CRITICAL_SECTION_DEBUG;

struct RTL_CRITICAL_SECTION {
        PRTL_CRITICAL_SECTION_DEBUG DebugInfo;
        LONG   LockCount;
        LONG   RecursionCount;
        HANDLE OwningThread;
        HANDLE LockSemaphore;
        DWORD  Reserved;
}
alias RTL_CRITICAL_SECTION* PRTL_CRITICAL_SECTION;

struct EVENTLOGRECORD {
        DWORD Length;
        DWORD Reserved;
        DWORD RecordNumber;
        DWORD TimeGenerated;
        DWORD TimeWritten;
        DWORD EventID;
        WORD  EventType;
        WORD  NumStrings;
        WORD  EventCategory;
        WORD  ReservedFlags;
        DWORD ClosingRecordNumber;
        DWORD StringOffset;
        DWORD UserSidLength;
        DWORD UserSidOffset;
        DWORD DataLength;
        DWORD DataOffset;
}
alias EVENTLOGRECORD* PEVENTLOGRECORD;

struct OSVERSIONINFOA {
        DWORD     dwOSVersionInfoSize;
        DWORD     dwMajorVersion;
        DWORD     dwMinorVersion;
        DWORD     dwBuildNumber;
        DWORD     dwPlatformId;
        CHAR[128] szCSDVersion;
}
alias OSVERSIONINFOA* POSVERSIONINFOA, LPOSVERSIONINFOA;

struct OSVERSIONINFOW {
        DWORD      dwOSVersionInfoSize;
        DWORD      dwMajorVersion;
        DWORD      dwMinorVersion;
        DWORD      dwBuildNumber;
        DWORD      dwPlatformId;
        WCHAR[128] szCSDVersion;
}
alias OSVERSIONINFOW* POSVERSIONINFOW, LPOSVERSIONINFOW;

struct OSVERSIONINFOEXA {
        DWORD     dwOSVersionInfoSize;
        DWORD     dwMajorVersion;
        DWORD     dwMinorVersion;
        DWORD     dwBuildNumber;
        DWORD     dwPlatformId;
        CHAR[128] szCSDVersion;
        WORD      wServicePackMajor;
        WORD      wServicePackMinor;
        WORD      wSuiteMask;
        BYTE      wProductType;
        BYTE      wReserved;
}
alias OSVERSIONINFOEXA* POSVERSIONINFOEXA, LPOSVERSIONINFOEXA;

struct OSVERSIONINFOEXW {
        DWORD      dwOSVersionInfoSize;
        DWORD      dwMajorVersion;
        DWORD      dwMinorVersion;
        DWORD      dwBuildNumber;
        DWORD      dwPlatformId;
        WCHAR[128] szCSDVersion;
        WORD       wServicePackMajor;
        WORD       wServicePackMinor;
        WORD       wSuiteMask;
        BYTE       wProductType;
        BYTE       wReserved;
}
alias OSVERSIONINFOEXW* POSVERSIONINFOEXW, LPOSVERSIONINFOEXW;

align(2) struct IMAGE_VXD_HEADER {
        WORD     e32_magic;
        BYTE     e32_border;
        BYTE     e32_worder;
        DWORD    e32_level;
        WORD     e32_cpu;
        WORD     e32_os;
        DWORD    e32_ver;
        DWORD    e32_mflags;
        DWORD    e32_mpages;
        DWORD    e32_startobj;
        DWORD    e32_eip;
        DWORD    e32_stackobj;
        DWORD    e32_esp;
        DWORD    e32_pagesize;
        DWORD    e32_lastpagesize;
        DWORD    e32_fixupsize;
        DWORD    e32_fixupsum;
        DWORD    e32_ldrsize;
        DWORD    e32_ldrsum;
        DWORD    e32_objtab;
        DWORD    e32_objcnt;
        DWORD    e32_objmap;
        DWORD    e32_itermap;
        DWORD    e32_rsrctab;
        DWORD    e32_rsrccnt;
        DWORD    e32_restab;
        DWORD    e32_enttab;
        DWORD    e32_dirtab;
        DWORD    e32_dircnt;
        DWORD    e32_fpagetab;
        DWORD    e32_frectab;
        DWORD    e32_impmod;
        DWORD    e32_impmodcnt;
        DWORD    e32_impproc;
        DWORD    e32_pagesum;
        DWORD    e32_datapage;
        DWORD    e32_preload;
        DWORD    e32_nrestab;
        DWORD    e32_cbnrestab;
        DWORD    e32_nressum;
        DWORD    e32_autodata;
        DWORD    e32_debuginfo;
        DWORD    e32_debuglen;
        DWORD    e32_instpreload;
        DWORD    e32_instdemand;
        DWORD    e32_heapsize;
        BYTE[12] e32_res3;
        DWORD    e32_winresoff;
        DWORD    e32_winreslen;
        WORD     e32_devid;
        WORD     e32_ddkver;
}
alias IMAGE_VXD_HEADER* PIMAGE_VXD_HEADER;

align(4):
struct IMAGE_FILE_HEADER {
        WORD  Machine;
        WORD  NumberOfSections;
        DWORD TimeDateStamp;
        DWORD PointerToSymbolTable;
        DWORD NumberOfSymbols;
        WORD  SizeOfOptionalHeader;
        WORD  Characteristics;
}
alias IMAGE_FILE_HEADER* PIMAGE_FILE_HEADER;
// const IMAGE_SIZEOF_FILE_HEADER = IMAGE_FILE_HEADER.sizeof;

struct IMAGE_DATA_DIRECTORY {
        DWORD VirtualAddress;
        DWORD Size;
}
alias IMAGE_DATA_DIRECTORY* PIMAGE_DATA_DIRECTORY;

struct IMAGE_OPTIONAL_HEADER32 {
        WORD  Magic;
        BYTE  MajorLinkerVersion;
        BYTE  MinorLinkerVersion;
        DWORD SizeOfCode;
        DWORD SizeOfInitializedData;
        DWORD SizeOfUninitializedData;
        DWORD AddressOfEntryPoint;
        DWORD BaseOfCode;
        DWORD BaseOfData;
        DWORD ImageBase;
        DWORD SectionAlignment;
        DWORD FileAlignment;
        WORD  MajorOperatingSystemVersion;
        WORD  MinorOperatingSystemVersion;
        WORD  MajorImageVersion;
        WORD  MinorImageVersion;
        WORD  MajorSubsystemVersion;
        WORD  MinorSubsystemVersion;
        DWORD Win32VersionValue;
        DWORD SizeOfImage;
        DWORD SizeOfHeaders;
        DWORD CheckSum;
        WORD  Subsystem;
        WORD  DllCharacteristics;
        DWORD SizeOfStackReserve;
        DWORD SizeOfStackCommit;
        DWORD SizeOfHeapReserve;
        DWORD SizeOfHeapCommit;
        DWORD LoaderFlags;
        DWORD NumberOfRvaAndSizes;
        IMAGE_DATA_DIRECTORY[IMAGE_NUMBEROF_DIRECTORY_ENTRIES] DataDirectory;
}
alias IMAGE_OPTIONAL_HEADER32* PIMAGE_OPTIONAL_HEADER32;

struct IMAGE_OPTIONAL_HEADER64 {
        WORD      Magic;
        BYTE      MajorLinkerVersion;
        BYTE      MinorLinkerVersion;
        DWORD     SizeOfCode;
        DWORD     SizeOfInitializedData;
        DWORD     SizeOfUninitializedData;
        DWORD     AddressOfEntryPoint;
        DWORD     BaseOfCode;
        ULONGLONG ImageBase;
        DWORD     SectionAlignment;
        DWORD     FileAlignment;
        WORD      MajorOperatingSystemVersion;
        WORD      MinorOperatingSystemVersion;
        WORD      MajorImageVersion;
        WORD      MinorImageVersion;
        WORD      MajorSubsystemVersion;
        WORD      MinorSubsystemVersion;
        DWORD     Win32VersionValue;
        DWORD     SizeOfImage;
        DWORD     SizeOfHeaders;
        DWORD     CheckSum;
        WORD      Subsystem;
        WORD      DllCharacteristics;
        ULONGLONG SizeOfStackReserve;
        ULONGLONG SizeOfStackCommit;
        ULONGLONG SizeOfHeapReserve;
        ULONGLONG SizeOfHeapCommit;
        DWORD     LoaderFlags;
        DWORD     NumberOfRvaAndSizes;
        IMAGE_DATA_DIRECTORY[IMAGE_NUMBEROF_DIRECTORY_ENTRIES] DataDirectory;
}
alias IMAGE_OPTIONAL_HEADER64* PIMAGE_OPTIONAL_HEADER64;

struct IMAGE_ROM_OPTIONAL_HEADER {
        WORD     Magic;
        BYTE     MajorLinkerVersion;
        BYTE     MinorLinkerVersion;
        DWORD    SizeOfCode;
        DWORD    SizeOfInitializedData;
        DWORD    SizeOfUninitializedData;
        DWORD    AddressOfEntryPoint;
        DWORD    BaseOfCode;
        DWORD    BaseOfData;
        DWORD    BaseOfBss;
        DWORD    GprMask;
        DWORD[4] CprMask;
        DWORD    GpValue;
}
alias IMAGE_ROM_OPTIONAL_HEADER* PIMAGE_ROM_OPTIONAL_HEADER;

align(2):
struct IMAGE_DOS_HEADER {
        WORD     e_magic;
        WORD     e_cblp;
        WORD     e_cp;
        WORD     e_crlc;
        WORD     e_cparhdr;
        WORD     e_minalloc;
        WORD     e_maxalloc;
        WORD     e_ss;
        WORD     e_sp;
        WORD     e_csum;
        WORD     e_ip;
        WORD     e_cs;
        WORD     e_lfarlc;
        WORD     e_ovno;
        WORD[4] e_res;
        WORD     e_oemid;
        WORD     e_oeminfo;
        WORD[10] e_res2;
        LONG     e_lfanew;
}
alias IMAGE_DOS_HEADER* PIMAGE_DOS_HEADER;

struct IMAGE_OS2_HEADER {
        WORD ne_magic;
        CHAR ne_ver;
        CHAR ne_rev;
        WORD ne_enttab;
        WORD ne_cbenttab;
        LONG ne_crc;
        WORD ne_flags;
        WORD ne_autodata;
        WORD ne_heap;
        WORD ne_stack;
        LONG ne_csip;
        LONG ne_sssp;
        WORD ne_cseg;
        WORD ne_cmod;
        WORD ne_cbnrestab;
        WORD ne_segtab;
        WORD ne_rsrctab;
        WORD ne_restab;
        WORD ne_modtab;
        WORD ne_imptab;
        LONG ne_nrestab;
        WORD ne_cmovent;
        WORD ne_align;
        WORD ne_cres;
        BYTE ne_exetyp;
        BYTE ne_flagsothers;
        WORD ne_pretthunks;
        WORD ne_psegrefbytes;
        WORD ne_swaparea;
        WORD ne_expver;
}
alias IMAGE_OS2_HEADER* PIMAGE_OS2_HEADER;

align(4) struct IMAGE_NT_HEADERS32 {
        DWORD                 Signature;
        IMAGE_FILE_HEADER     FileHeader;
        IMAGE_OPTIONAL_HEADER OptionalHeader;
}
alias IMAGE_NT_HEADERS32* PIMAGE_NT_HEADERS32;

align(4) struct IMAGE_NT_HEADERS64 {
        DWORD                 Signature;
        IMAGE_FILE_HEADER     FileHeader;
        IMAGE_OPTIONAL_HEADER OptionalHeader;
}
alias IMAGE_NT_HEADERS64* PIMAGE_NT_HEADERS64;

struct IMAGE_ROM_HEADERS {
        IMAGE_FILE_HEADER         FileHeader;
        IMAGE_ROM_OPTIONAL_HEADER OptionalHeader;
}
alias IMAGE_ROM_HEADERS* PIMAGE_ROM_HEADERS;

struct IMAGE_SECTION_HEADER {
        BYTE[IMAGE_SIZEOF_SHORT_NAME] Name;
        union _Misc {
                DWORD PhysicalAddress;
                DWORD VirtualSize;
        }
        _Misc Misc;
        DWORD VirtualAddress;
        DWORD SizeOfRawData;
        DWORD PointerToRawData;
        DWORD PointerToRelocations;
        DWORD PointerToLinenumbers;
        WORD  NumberOfRelocations;
        WORD  NumberOfLinenumbers;
        DWORD Characteristics;
}
alias IMAGE_SECTION_HEADER* PIMAGE_SECTION_HEADER;

struct IMAGE_SYMBOL {
        union _N {
                BYTE[8]   ShortName;
                struct Name {
                        DWORD Short;
                        DWORD Long;
                }
                PBYTE[2]  LongName;
        }
        _N    N;
        DWORD Value;
        SHORT SectionNumber;
        WORD  Type;
        BYTE  StorageClass;
        BYTE  NumberOfAuxSymbols;
}
alias IMAGE_SYMBOL* PIMAGE_SYMBOL;

union IMAGE_AUX_SYMBOL {
        struct _Sym {
                DWORD           TagIndex;
                union _Misc {
                        struct _LnSz {
                                WORD    Linenumber;
                                WORD    Size;
                        }
                        _LnSz       LnSz;
                        DWORD       TotalSize;
                }
                _Misc Misc;
                union _FcnAry {
                        struct _Function {
                                DWORD   PointerToLinenumber;
                                DWORD   PointerToNextFunction;
                        }
                        _Function   Function;
                        struct _Array {
                                WORD[4] Dimension;
                        }
                        _Array      Array;
                }
                _FcnAry         FcnAry;
                WORD            TvIndex;
        }
        _Sym                Sym;
        struct _File {
                BYTE[IMAGE_SIZEOF_SYMBOL] Name;
        }
        _File               File;
        struct _Section {
                DWORD           Length;
                WORD            NumberOfRelocations;
                WORD            NumberOfLinenumbers;
                DWORD           CheckSum;
                SHORT           Number;
                BYTE            Selection;
        }
        _Section            Section;
}
alias IMAGE_AUX_SYMBOL* PIMAGE_AUX_SYMBOL;

struct IMAGE_COFF_SYMBOLS_HEADER {
        DWORD NumberOfSymbols;
        DWORD LvaToFirstSymbol;
        DWORD NumberOfLinenumbers;
        DWORD LvaToFirstLinenumber;
        DWORD RvaToFirstByteOfCode;
        DWORD RvaToLastByteOfCode;
        DWORD RvaToFirstByteOfData;
        DWORD RvaToLastByteOfData;
}
alias IMAGE_COFF_SYMBOLS_HEADER* PIMAGE_COFF_SYMBOLS_HEADER;

struct IMAGE_RELOCATION {
        union {
                DWORD VirtualAddress;
                DWORD RelocCount;
        }
        DWORD     SymbolTableIndex;
        WORD      Type;
}
alias IMAGE_RELOCATION* PIMAGE_RELOCATION;

align(4) struct IMAGE_BASE_RELOCATION {
        DWORD VirtualAddress;
        DWORD SizeOfBlock;
}
alias IMAGE_BASE_RELOCATION* PIMAGE_BASE_RELOCATION;

align(2) struct IMAGE_LINENUMBER {
        union _Type {
                DWORD SymbolTableIndex;
                DWORD VirtualAddress;
        }
        _Type Type;
        WORD  Linenumber;
}
alias IMAGE_LINENUMBER* PIMAGE_LINENUMBER;

align(4):
struct IMAGE_ARCHIVE_MEMBER_HEADER {
        BYTE[16] Name;
        BYTE[12] Date;
        BYTE[6]  UserID;
        BYTE[6]  GroupID;
        BYTE[8]  Mode;
        BYTE[10] Size;
        BYTE[2]  EndHeader;
}
alias IMAGE_ARCHIVE_MEMBER_HEADER* PIMAGE_ARCHIVE_MEMBER_HEADER;

struct IMAGE_EXPORT_DIRECTORY {
        DWORD Characteristics;
        DWORD TimeDateStamp;
        WORD  MajorVersion;
        WORD  MinorVersion;
        DWORD Name;
        DWORD Base;
        DWORD NumberOfFunctions;
        DWORD NumberOfNames;
        DWORD AddressOfFunctions;
        DWORD AddressOfNames;
        DWORD AddressOfNameOrdinals;
}
alias IMAGE_EXPORT_DIRECTORY* PIMAGE_EXPORT_DIRECTORY;

struct IMAGE_IMPORT_BY_NAME {
        WORD Hint;
        BYTE _Name;

        BYTE* Name() return {
                return &_Name;
        }
}
alias IMAGE_IMPORT_BY_NAME* PIMAGE_IMPORT_BY_NAME;

struct IMAGE_THUNK_DATA32 {
        union _u1 {
                DWORD ForwarderString;
                DWORD Function;
                DWORD Ordinal;
                DWORD AddressOfData;
        }
        _u1 u1;
}
alias IMAGE_THUNK_DATA32* PIMAGE_THUNK_DATA32;

struct IMAGE_THUNK_DATA64 {
        union _u1 {
                ULONGLONG ForwarderString;
                ULONGLONG Function;
                ULONGLONG Ordinal;
                ULONGLONG AddressOfData;
        }
        _u1 u1;
}
alias IMAGE_THUNK_DATA64* PIMAGE_THUNK_DATA64;

struct IMAGE_IMPORT_DESCRIPTOR {
        union {
                DWORD Characteristics;
                DWORD OriginalFirstThunk;
        }
        DWORD TimeDateStamp;
        DWORD ForwarderChain;
        DWORD Name;
        DWORD FirstThunk;
}
alias IMAGE_IMPORT_DESCRIPTOR* PIMAGE_IMPORT_DESCRIPTOR;

struct IMAGE_BOUND_IMPORT_DESCRIPTOR {
        DWORD TimeDateStamp;
        WORD  OffsetModuleName;
        WORD  NumberOfModuleForwarderRefs;
}
alias IMAGE_BOUND_IMPORT_DESCRIPTOR* PIMAGE_BOUND_IMPORT_DESCRIPTOR;

struct IMAGE_BOUND_FORWARDER_REF {
        DWORD TimeDateStamp;
        WORD  OffsetModuleName;
        WORD  Reserved;
}
alias IMAGE_BOUND_FORWARDER_REF* PIMAGE_BOUND_FORWARDER_REF;

struct IMAGE_TLS_DIRECTORY32 {
        DWORD StartAddressOfRawData;
        DWORD EndAddressOfRawData;
        DWORD AddressOfIndex;
        DWORD AddressOfCallBacks;
        DWORD SizeOfZeroFill;
        DWORD Characteristics;
}
alias IMAGE_TLS_DIRECTORY32* PIMAGE_TLS_DIRECTORY32;

struct IMAGE_TLS_DIRECTORY64 {
        ULONGLONG StartAddressOfRawData;
        ULONGLONG EndAddressOfRawData;
        ULONGLONG AddressOfIndex;
        ULONGLONG AddressOfCallBacks;
        DWORD     SizeOfZeroFill;
        DWORD     Characteristics;
}
alias IMAGE_TLS_DIRECTORY64* PIMAGE_TLS_DIRECTORY64;

struct IMAGE_RESOURCE_DIRECTORY {
        DWORD Characteristics;
        DWORD TimeDateStamp;
        WORD  MajorVersion;
        WORD  MinorVersion;
        WORD  NumberOfNamedEntries;
        WORD  NumberOfIdEntries;
}
alias IMAGE_RESOURCE_DIRECTORY* PIMAGE_RESOURCE_DIRECTORY;

struct IMAGE_RESOURCE_DIRECTORY_ENTRY {
        union {
                /+struct {
                        DWORD NameOffset:31;
                        DWORD NameIsString:1;
                }+/
                DWORD Name;
                WORD Id;
        }
        DWORD OffsetToData;
                /+struct {
                        DWORD OffsetToDirectory:31;
                        DWORD DataIsDirectory:1;
                }+/

        uint NameOffset()        { return Name & 0x7FFFFFFF; }
        bool NameIsString()      { return cast(bool)(Name & 0x80000000); }
        uint OffsetToDirectory() { return OffsetToData & 0x7FFFFFFF; }
        bool DataIsDirectory()   { return cast(bool)(OffsetToData & 0x80000000); }

        uint NameOffset(uint n) {
                Name = (Name & 0x80000000) | (n & 0x7FFFFFFF);
                return n & 0x7FFFFFFF;
        }

        bool NameIsString(bool n) {
                Name = (Name & 0x7FFFFFFF) | (n << 31); return n;
        }

        uint OffsetToDirectory(uint o) {
                OffsetToData = (OffsetToData & 0x80000000) | (o & 0x7FFFFFFF);
                return o & 0x7FFFFFFF;
        }

        bool DataIsDirectory(bool d) {
                OffsetToData = (OffsetToData & 0x7FFFFFFF) | (d << 31); return d;
        }
}
alias IMAGE_RESOURCE_DIRECTORY_ENTRY* PIMAGE_RESOURCE_DIRECTORY_ENTRY;

struct IMAGE_RESOURCE_DIRECTORY_STRING {
        WORD Length;
        CHAR _NameString;

        CHAR* NameString() return { return &_NameString; }
}
alias IMAGE_RESOURCE_DIRECTORY_STRING* PIMAGE_RESOURCE_DIRECTORY_STRING;

struct IMAGE_RESOURCE_DIR_STRING_U {
        WORD  Length;
        WCHAR _NameString;

        WCHAR* NameString() return { return &_NameString; }
}
alias IMAGE_RESOURCE_DIR_STRING_U* PIMAGE_RESOURCE_DIR_STRING_U;

struct IMAGE_RESOURCE_DATA_ENTRY {
        DWORD OffsetToData;
        DWORD Size;
        DWORD CodePage;
        DWORD Reserved;
}
alias IMAGE_RESOURCE_DATA_ENTRY* PIMAGE_RESOURCE_DATA_ENTRY;

struct IMAGE_LOAD_CONFIG_DIRECTORY {
        DWORD    Characteristics;
        DWORD    TimeDateStamp;
        WORD     MajorVersion;
        WORD     MinorVersion;
        DWORD    GlobalFlagsClear;
        DWORD    GlobalFlagsSet;
        DWORD    CriticalSectionDefaultTimeout;
        DWORD    DeCommitFreeBlockThreshold;
        DWORD    DeCommitTotalFreeThreshold;
        PVOID    LockPrefixTable;
        DWORD    MaximumAllocationSize;
        DWORD    VirtualMemoryThreshold;
        DWORD    ProcessHeapFlags;
        DWORD[4] Reserved;
}
alias IMAGE_LOAD_CONFIG_DIRECTORY* PIMAGE_LOAD_CONFIG_DIRECTORY;

struct IMAGE_LOAD_CONFIG_DIRECTORY64 {
        DWORD     Characteristics;
        DWORD     TimeDateStamp;
        WORD      MajorVersion;
        WORD      MinorVersion;
        DWORD     GlobalFlagsClear;
        DWORD     GlobalFlagsSet;
        DWORD     CriticalSectionDefaultTimeout;
        ULONGLONG DeCommitFreeBlockThreshold;
        ULONGLONG DeCommitTotalFreeThreshold;
        ULONGLONG LockPrefixTable;
        ULONGLONG MaximumAllocationSize;
        ULONGLONG VirtualMemoryThreshold;
        ULONGLONG ProcessAffinityMask;
        DWORD     ProcessHeapFlags;
        WORD      CSDFlags;
        WORD      Reserved1;
        ULONGLONG EditList;
        DWORD[2]  Reserved;
}
alias IMAGE_LOAD_CONFIG_DIRECTORY64* PIMAGE_LOAD_CONFIG_DIRECTORY64;

struct IMAGE_RUNTIME_FUNCTION_ENTRY {
        DWORD BeginAddress;
        DWORD EndAddress;
        PVOID ExceptionHandler;
        PVOID HandlerData;
        DWORD PrologEndAddress;
}
alias IMAGE_RUNTIME_FUNCTION_ENTRY* PIMAGE_RUNTIME_FUNCTION_ENTRY;

struct IMAGE_CE_RUNTIME_FUNCTION_ENTRY {
        uint      FuncStart;
        union {
                ubyte PrologLen;
                uint  _bf;
        }
/+
        unsigned int FuncLen:22;
        unsigned int ThirtyTwoBit:1;
        unsigned int ExceptionFlag:1;
+/
        uint FuncLen()       { return (_bf >> 8) & 0x3FFFFF; }
        bool ThirtyTwoBit()  { return cast(bool)(_bf & 0x40000000); }
        bool ExceptionFlag() { return cast(bool)(_bf & 0x80000000); }

        uint FuncLen(uint f) {
                _bf = (_bf & ~0x3FFFFF00) | ((f & 0x3FFFFF) << 8); return f & 0x3FFFFF;
        }

        bool ThirtyTwoBit(bool t) {
                _bf = (_bf & ~0x40000000) | (t << 30); return t;
        }

        bool ExceptionFlag(bool e) {
                _bf = (_bf & ~0x80000000) | (e << 31); return e;
        }
}
alias IMAGE_CE_RUNTIME_FUNCTION_ENTRY* PIMAGE_CE_RUNTIME_FUNCTION_ENTRY;

struct IMAGE_DEBUG_DIRECTORY {
        DWORD Characteristics;
        DWORD TimeDateStamp;
        WORD  MajorVersion;
        WORD  MinorVersion;
        DWORD Type;
        DWORD SizeOfData;
        DWORD AddressOfRawData;
        DWORD PointerToRawData;
}
alias IMAGE_DEBUG_DIRECTORY* PIMAGE_DEBUG_DIRECTORY;

struct FPO_DATA {
        DWORD  ulOffStart;
        DWORD  cbProcSize;
        DWORD  cdwLocals;
        WORD   cdwParams;
        ubyte  cbProlog;
        ubyte  _bf;
/+
        WORD cbRegs:3;
        WORD fHasSEH:1;
        WORD fUseBP:1;
        WORD reserved:1;
        WORD cbFrame:2;
+/
        ubyte cbRegs()  { return cast(ubyte)(_bf & 0x07); }
        bool fHasSEH()  { return cast(bool)(_bf & 0x08); }
        bool fUseBP()   { return cast(bool)(_bf & 0x10); }
        bool reserved() { return cast(bool)(_bf & 0x20); }
        ubyte cbFrame() { return cast(ubyte)(_bf >> 6); }

        ubyte cbRegs(ubyte c) {
                _bf = cast(ubyte) ((_bf & ~0x07) | (c & 0x07));
                return cast(ubyte)(c & 0x07);
        }

        bool fHasSEH(bool f)  { _bf = cast(ubyte)((_bf & ~0x08) | (f << 3)); return f; }
        bool fUseBP(bool f)   { _bf = cast(ubyte)((_bf & ~0x10) | (f << 4)); return f; }
        bool reserved(bool r) { _bf = cast(ubyte)((_bf & ~0x20) | (r << 5)); return r; }

        ubyte cbFrame(ubyte c) {
                _bf = cast(ubyte) ((_bf & ~0xC0) | ((c & 0x03) << 6));
                return cast(ubyte)(c & 0x03);
        }
}
alias FPO_DATA* PFPO_DATA;

struct IMAGE_DEBUG_MISC {
        DWORD   DataType;
        DWORD   Length;
        BOOLEAN Unicode;
        BYTE[3] Reserved;
        BYTE    _Data;

        BYTE*   Data() return { return &_Data; }
}
alias IMAGE_DEBUG_MISC* PIMAGE_DEBUG_MISC;

struct IMAGE_FUNCTION_ENTRY {
        DWORD StartingAddress;
        DWORD EndingAddress;
        DWORD EndOfPrologue;
}
alias IMAGE_FUNCTION_ENTRY* PIMAGE_FUNCTION_ENTRY;

struct IMAGE_FUNCTION_ENTRY64 {
        ULONGLONG     StartingAddress;
        ULONGLONG     EndingAddress;
        union {
                ULONGLONG EndOfPrologue;
                ULONGLONG UnwindInfoAddress;
        }
}
alias IMAGE_FUNCTION_ENTRY64* PIMAGE_FUNCTION_ENTRY64;

struct IMAGE_SEPARATE_DEBUG_HEADER {
        WORD     Signature;
        WORD     Flags;
        WORD     Machine;
        WORD     Characteristics;
        DWORD    TimeDateStamp;
        DWORD    CheckSum;
        DWORD    ImageBase;
        DWORD    SizeOfImage;
        DWORD    NumberOfSections;
        DWORD    ExportedNamesSize;
        DWORD    DebugDirectorySize;
        DWORD    SectionAlignment;
        DWORD[2] Reserved;
}
alias IMAGE_SEPARATE_DEBUG_HEADER* PIMAGE_SEPARATE_DEBUG_HEADER;

enum SERVICE_NODE_TYPE {
        DriverType               = SERVICE_KERNEL_DRIVER,
        FileSystemType           = SERVICE_FILE_SYSTEM_DRIVER,
        Win32ServiceOwnProcess   = SERVICE_WIN32_OWN_PROCESS,
        Win32ServiceShareProcess = SERVICE_WIN32_SHARE_PROCESS,
        AdapterType              = SERVICE_ADAPTER,
        RecognizerType           = SERVICE_RECOGNIZER_DRIVER
}

enum SERVICE_LOAD_TYPE {
        BootLoad    = SERVICE_BOOT_START,
        SystemLoad  = SERVICE_SYSTEM_START,
        AutoLoad    = SERVICE_AUTO_START,
        DemandLoad  = SERVICE_DEMAND_START,
        DisableLoad = SERVICE_DISABLED
}

enum SERVICE_ERROR_TYPE {
        IgnoreError   = SERVICE_ERROR_IGNORE,
        NormalError   = SERVICE_ERROR_NORMAL,
        SevereError   = SERVICE_ERROR_SEVERE,
        CriticalError = SERVICE_ERROR_CRITICAL
}
alias SERVICE_ERROR_TYPE _CM_ERROR_CONTROL_TYPE;

//DAC: According to MSJ, 'UnderTheHood', May 1996, this
// structure is not documented in any official Microsoft header file.
alias void EXCEPTION_REGISTRATION_RECORD;

align:
struct NT_TIB {
        EXCEPTION_REGISTRATION_RECORD *ExceptionList;
        PVOID StackBase;
        PVOID StackLimit;
        PVOID SubSystemTib;
        union {
                PVOID FiberData;
                DWORD Version;
        }
        PVOID ArbitraryUserPointer;
        NT_TIB *Self;
}
alias NT_TIB* PNT_TIB;

struct REPARSE_DATA_BUFFER {
        DWORD  ReparseTag;
        WORD   ReparseDataLength;
        WORD   Reserved;
        union {
                struct _GenericReparseBuffer {
                        BYTE  _DataBuffer;

                        BYTE* DataBuffer() return { return &_DataBuffer; }
                }
                _GenericReparseBuffer GenericReparseBuffer;
                struct _SymbolicLinkReparseBuffer {
                        WORD  SubstituteNameOffset;
                        WORD  SubstituteNameLength;
                        WORD  PrintNameOffset;
                        WORD  PrintNameLength;
                        // ??? This is in MinGW, but absent in MSDN docs
                        ULONG Flags;
                        WCHAR _PathBuffer;

                        WCHAR* PathBuffer() return { return &_PathBuffer; }
                }
                _SymbolicLinkReparseBuffer SymbolicLinkReparseBuffer;
                struct _MountPointReparseBuffer {
                        WORD  SubstituteNameOffset;
                        WORD  SubstituteNameLength;
                        WORD  PrintNameOffset;
                        WORD  PrintNameLength;
                        WCHAR _PathBuffer;

                        WCHAR* PathBuffer() return { return &_PathBuffer; }
                }
                _MountPointReparseBuffer MountPointReparseBuffer;
        }
}
alias REPARSE_DATA_BUFFER *PREPARSE_DATA_BUFFER;

struct REPARSE_GUID_DATA_BUFFER {
        DWORD    ReparseTag;
        WORD     ReparseDataLength;
        WORD     Reserved;
        GUID     ReparseGuid;
        struct _GenericReparseBuffer {
                BYTE _DataBuffer;

                BYTE* DataBuffer() return { return &_DataBuffer; }
        }
        _GenericReparseBuffer GenericReparseBuffer;
}
alias REPARSE_GUID_DATA_BUFFER* PREPARSE_GUID_DATA_BUFFER;

const size_t
        REPARSE_DATA_BUFFER_HEADER_SIZE = REPARSE_DATA_BUFFER.GenericReparseBuffer.offsetof,
        REPARSE_GUID_DATA_BUFFER_HEADER_SIZE = REPARSE_GUID_DATA_BUFFER.GenericReparseBuffer.offsetof,
        MAXIMUM_REPARSE_DATA_BUFFER_SIZE = 16384;


struct REPARSE_POINT_INFORMATION {
        WORD ReparseDataLength;
        WORD UnparsedNameLength;
}
alias REPARSE_POINT_INFORMATION* PREPARSE_POINT_INFORMATION;

union FILE_SEGMENT_ELEMENT {
        PVOID64   Buffer;
        ULONGLONG Alignment;
}
alias FILE_SEGMENT_ELEMENT* PFILE_SEGMENT_ELEMENT;

// JOBOBJECT_BASIC_LIMIT_INFORMATION.LimitFlags constants
const DWORD
        JOB_OBJECT_LIMIT_WORKINGSET                 = 0x0001,
        JOB_OBJECT_LIMIT_PROCESS_TIME               = 0x0002,
        JOB_OBJECT_LIMIT_JOB_TIME                   = 0x0004,
        JOB_OBJECT_LIMIT_ACTIVE_PROCESS             = 0x0008,
        JOB_OBJECT_LIMIT_AFFINITY                   = 0x0010,
        JOB_OBJECT_LIMIT_PRIORITY_CLASS             = 0x0020,
        JOB_OBJECT_LIMIT_PRESERVE_JOB_TIME          = 0x0040,
        JOB_OBJECT_LIMIT_SCHEDULING_CLASS           = 0x0080,
        JOB_OBJECT_LIMIT_PROCESS_MEMORY             = 0x0100,
        JOB_OBJECT_LIMIT_JOB_MEMORY                 = 0x0200,
        JOB_OBJECT_LIMIT_DIE_ON_UNHANDLED_EXCEPTION = 0x0400,
        JOB_OBJECT_BREAKAWAY_OK                     = 0x0800,
        JOB_OBJECT_SILENT_BREAKAWAY                 = 0x1000;

// JOBOBJECT_BASIC_UI_RESTRICTIONS.UIRestrictionsClass constants
const DWORD
        JOB_OBJECT_UILIMIT_HANDLES          = 0x0001,
        JOB_OBJECT_UILIMIT_READCLIPBOARD    = 0x0002,
        JOB_OBJECT_UILIMIT_WRITECLIPBOARD   = 0x0004,
        JOB_OBJECT_UILIMIT_SYSTEMPARAMETERS = 0x0008,
        JOB_OBJECT_UILIMIT_DISPLAYSETTINGS  = 0x0010,
        JOB_OBJECT_UILIMIT_GLOBALATOMS      = 0x0020,
        JOB_OBJECT_UILIMIT_DESKTOP          = 0x0040,
        JOB_OBJECT_UILIMIT_EXITWINDOWS      = 0x0080;

// JOBOBJECT_SECURITY_LIMIT_INFORMATION.SecurityLimitFlags constants
const DWORD
        JOB_OBJECT_SECURITY_NO_ADMIN         = 0x0001,
        JOB_OBJECT_SECURITY_RESTRICTED_TOKEN = 0x0002,
        JOB_OBJECT_SECURITY_ONLY_TOKEN       = 0x0004,
        JOB_OBJECT_SECURITY_FILTER_TOKENS    = 0x0008;

// JOBOBJECT_END_OF_JOB_TIME_INFORMATION.EndOfJobTimeAction constants
enum : DWORD {
        JOB_OBJECT_TERMINATE_AT_END_OF_JOB,
        JOB_OBJECT_POST_AT_END_OF_JOB
}

enum : DWORD {
        JOB_OBJECT_MSG_END_OF_JOB_TIME = 1,
        JOB_OBJECT_MSG_END_OF_PROCESS_TIME,
        JOB_OBJECT_MSG_ACTIVE_PROCESS_LIMIT,
        JOB_OBJECT_MSG_ACTIVE_PROCESS_ZERO,
        JOB_OBJECT_MSG_NEW_PROCESS,
        JOB_OBJECT_MSG_EXIT_PROCESS,
        JOB_OBJECT_MSG_ABNORMAL_EXIT_PROCESS,
        JOB_OBJECT_MSG_PROCESS_MEMORY_LIMIT,
        JOB_OBJECT_MSG_JOB_MEMORY_LIMIT
}

enum JOBOBJECTINFOCLASS {
        JobObjectBasicAccountingInformation = 1,
        JobObjectBasicLimitInformation,
        JobObjectBasicProcessIdList,
        JobObjectBasicUIRestrictions,
        JobObjectSecurityLimitInformation,
        JobObjectEndOfJobTimeInformation,
        JobObjectAssociateCompletionPortInformation,
        JobObjectBasicAndIoAccountingInformation,
        JobObjectExtendedLimitInformation,
        JobObjectJobSetInformation,
        MaxJobObjectInfoClass
}

struct JOBOBJECT_BASIC_ACCOUNTING_INFORMATION {
        LARGE_INTEGER TotalUserTime;
        LARGE_INTEGER TotalKernelTime;
        LARGE_INTEGER ThisPeriodTotalUserTime;
        LARGE_INTEGER ThisPeriodTotalKernelTime;
        DWORD         TotalPageFaultCount;
        DWORD         TotalProcesses;
        DWORD         ActiveProcesses;
        DWORD         TotalTerminatedProcesses;
}
alias JOBOBJECT_BASIC_ACCOUNTING_INFORMATION* PJOBOBJECT_BASIC_ACCOUNTING_INFORMATION;

struct JOBOBJECT_BASIC_LIMIT_INFORMATION {
        LARGE_INTEGER PerProcessUserTimeLimit;
        LARGE_INTEGER PerJobUserTimeLimit;
        DWORD         LimitFlags;
        SIZE_T        MinimumWorkingSetSize;
        SIZE_T        MaximumWorkingSetSize;
        DWORD         ActiveProcessLimit;
        ULONG_PTR     Affinity;
        DWORD         PriorityClass;
        DWORD         SchedulingClass;
}
alias JOBOBJECT_BASIC_LIMIT_INFORMATION* PJOBOBJECT_BASIC_LIMIT_INFORMATION;

struct JOBOBJECT_BASIC_PROCESS_ID_LIST {
        DWORD     NumberOfAssignedProcesses;
        DWORD     NumberOfProcessIdsInList;
        ULONG_PTR _ProcessIdList;

        ULONG_PTR* ProcessIdList() return { return &_ProcessIdList; }
}
alias JOBOBJECT_BASIC_PROCESS_ID_LIST* PJOBOBJECT_BASIC_PROCESS_ID_LIST;

struct JOBOBJECT_BASIC_UI_RESTRICTIONS {
        DWORD UIRestrictionsClass;
}
alias JOBOBJECT_BASIC_UI_RESTRICTIONS* PJOBOBJECT_BASIC_UI_RESTRICTIONS;

struct JOBOBJECT_SECURITY_LIMIT_INFORMATION {
        DWORD             SecurityLimitFlags;
        HANDLE            JobToken;
        PTOKEN_GROUPS     SidsToDisable;
        PTOKEN_PRIVILEGES PrivilegesToDelete;
        PTOKEN_GROUPS     RestrictedSids;
}
alias JOBOBJECT_SECURITY_LIMIT_INFORMATION* PJOBOBJECT_SECURITY_LIMIT_INFORMATION;

struct JOBOBJECT_END_OF_JOB_TIME_INFORMATION {
        DWORD EndOfJobTimeAction;
}
alias JOBOBJECT_END_OF_JOB_TIME_INFORMATION* PJOBOBJECT_END_OF_JOB_TIME_INFORMATION;

struct JOBOBJECT_ASSOCIATE_COMPLETION_PORT {
        PVOID  CompletionKey;
        HANDLE CompletionPort;
}
alias JOBOBJECT_ASSOCIATE_COMPLETION_PORT* PJOBOBJECT_ASSOCIATE_COMPLETION_PORT;

struct JOBOBJECT_BASIC_AND_IO_ACCOUNTING_INFORMATION {
        JOBOBJECT_BASIC_ACCOUNTING_INFORMATION BasicInfo;
        IO_COUNTERS IoInfo;
}
alias JOBOBJECT_BASIC_AND_IO_ACCOUNTING_INFORMATION *PJOBOBJECT_BASIC_AND_IO_ACCOUNTING_INFORMATION;

struct JOBOBJECT_EXTENDED_LIMIT_INFORMATION {
        JOBOBJECT_BASIC_LIMIT_INFORMATION BasicLimitInformation;
        IO_COUNTERS IoInfo;
        SIZE_T      ProcessMemoryLimit;
        SIZE_T      JobMemoryLimit;
        SIZE_T      PeakProcessMemoryUsed;
        SIZE_T      PeakJobMemoryUsed;
}
alias JOBOBJECT_EXTENDED_LIMIT_INFORMATION* PJOBOBJECT_EXTENDED_LIMIT_INFORMATION;

struct JOBOBJECT_JOBSET_INFORMATION {
        DWORD MemberLevel;
}
alias JOBOBJECT_JOBSET_INFORMATION* PJOBOBJECT_JOBSET_INFORMATION;

// MinGW: Making these defines conditional on _WIN32_WINNT will break ddk includes
//static if (_WIN32_WINNT >= 0x500) {

const DWORD
        ES_SYSTEM_REQUIRED  = 0x00000001,
        ES_DISPLAY_REQUIRED = 0x00000002,
        ES_USER_PRESENT     = 0x00000004,
        ES_CONTINUOUS       = 0x80000000;

enum LATENCY_TIME {
        LT_DONT_CARE,
        LT_LOWEST_LATENCY
}
alias LATENCY_TIME* PLATENCY_TIME;

enum SYSTEM_POWER_STATE {
        PowerSystemUnspecified,
        PowerSystemWorking,
        PowerSystemSleeping1,
        PowerSystemSleeping2,
        PowerSystemSleeping3,
        PowerSystemHibernate,
        PowerSystemShutdown,
        PowerSystemMaximum
}
alias SYSTEM_POWER_STATE* PSYSTEM_POWER_STATE;

const POWER_SYSTEM_MAXIMUM = SYSTEM_POWER_STATE.PowerSystemMaximum;

enum POWER_ACTION {
        PowerActionNone,
        PowerActionReserved,
        PowerActionSleep,
        PowerActionHibernate,
        PowerActionShutdown,
        PowerActionShutdownReset,
        PowerActionShutdownOff,
        PowerActionWarmEject
}
alias POWER_ACTION* PPOWER_ACTION;

static if (_WIN32_WINNT >= 0x600) {
        enum SYSTEM_POWER_CONDITION {
                PoAc,
                PoDc,
                PoHot,
                PoConditionMaximum
        }
        alias SYSTEM_POWER_CONDITION* PSYSTEM_POWER_CONDITION;
}

enum DEVICE_POWER_STATE {
        PowerDeviceUnspecified,
        PowerDeviceD0,
        PowerDeviceD1,
        PowerDeviceD2,
        PowerDeviceD3,
        PowerDeviceMaximum
}
alias DEVICE_POWER_STATE* PDEVICE_POWER_STATE;

align(4):
struct BATTERY_REPORTING_SCALE {
        DWORD Granularity;
        DWORD Capacity;
}
alias BATTERY_REPORTING_SCALE* PBATTERY_REPORTING_SCALE;

struct POWER_ACTION_POLICY {
        POWER_ACTION Action;
        ULONG        Flags;
        ULONG        EventCode;
}
alias POWER_ACTION_POLICY* PPOWER_ACTION_POLICY;

// POWER_ACTION_POLICY.Flags constants
const ULONG
        POWER_ACTION_QUERY_ALLOWED  = 0x00000001,
        POWER_ACTION_UI_ALLOWED     = 0x00000002,
        POWER_ACTION_OVERRIDE_APPS  = 0x00000004,
        POWER_ACTION_LIGHTEST_FIRST = 0x10000000,
        POWER_ACTION_LOCK_CONSOLE   = 0x20000000,
        POWER_ACTION_DISABLE_WAKES  = 0x40000000,
        POWER_ACTION_CRITICAL       = 0x80000000;

// POWER_ACTION_POLICY.EventCode constants
const ULONG
        POWER_LEVEL_USER_NOTIFY_TEXT  = 0x00000001,
        POWER_LEVEL_USER_NOTIFY_SOUND = 0x00000002,
        POWER_LEVEL_USER_NOTIFY_EXEC  = 0x00000004,
        POWER_USER_NOTIFY_BUTTON      = 0x00000008,
        POWER_USER_NOTIFY_SHUTDOWN    = 0x00000010,
        POWER_FORCE_TRIGGER_RESET     = 0x80000000;

const size_t
        DISCHARGE_POLICY_CRITICAL = 0,
        DISCHARGE_POLICY_LOW      = 1,
        NUM_DISCHARGE_POLICIES    = 4;

enum : BYTE {
        PO_THROTTLE_NONE,
        PO_THROTTLE_CONSTANT,
        PO_THROTTLE_DEGRADE,
        PO_THROTTLE_ADAPTIVE,
        PO_THROTTLE_MAXIMUM
}

struct SYSTEM_POWER_LEVEL {
        BOOLEAN             Enable;
        UCHAR[3]            Spare;
        ULONG               BatteryLevel;
        POWER_ACTION_POLICY PowerPolicy;
        SYSTEM_POWER_STATE  MinSystemState;
}
alias SYSTEM_POWER_LEVEL* PSYSTEM_POWER_LEVEL;

struct SYSTEM_POWER_POLICY {
        ULONG               Revision;
        POWER_ACTION_POLICY PowerButton;
        POWER_ACTION_POLICY SleepButton;
        POWER_ACTION_POLICY LidClose;
        SYSTEM_POWER_STATE  LidOpenWake;
        ULONG               Reserved;
        POWER_ACTION_POLICY Idle;
        ULONG               IdleTimeout;
        UCHAR               IdleSensitivity;
        UCHAR               DynamicThrottle;
        UCHAR[2]            Spare2;
        SYSTEM_POWER_STATE  MinSleep;
        SYSTEM_POWER_STATE  MaxSleep;
        SYSTEM_POWER_STATE  ReducedLatencySleep;
        ULONG               WinLogonFlags;
        ULONG               Spare3;
        ULONG               DozeS4Timeout;
        ULONG               BroadcastCapacityResolution;
        SYSTEM_POWER_LEVEL[NUM_DISCHARGE_POLICIES] DischargePolicy;
        ULONG               VideoTimeout;
        BOOLEAN             VideoDimDisplay;
        ULONG[3]            VideoReserved;
        ULONG               SpindownTimeout;
        BOOLEAN             OptimizeForPower;
        UCHAR               FanThrottleTolerance;
        UCHAR               ForcedThrottle;
        UCHAR               MinThrottle;
        POWER_ACTION_POLICY OverThrottled;
}
alias SYSTEM_POWER_POLICY* PSYSTEM_POWER_POLICY;

struct SYSTEM_POWER_CAPABILITIES {
        BOOLEAN                    PowerButtonPresent;
        BOOLEAN                    SleepButtonPresent;
        BOOLEAN                    LidPresent;
        BOOLEAN                    SystemS1;
        BOOLEAN                    SystemS2;
        BOOLEAN                    SystemS3;
        BOOLEAN                    SystemS4;
        BOOLEAN                    SystemS5;
        BOOLEAN                    HiberFilePresent;
        BOOLEAN                    FullWake;
        BOOLEAN                    VideoDimPresent;
        BOOLEAN                    ApmPresent;
        BOOLEAN                    UpsPresent;
        BOOLEAN                    ThermalControl;
        BOOLEAN                    ProcessorThrottle;
        UCHAR                      ProcessorMinThrottle;
        UCHAR                      ProcessorMaxThrottle;
        UCHAR[4]                   spare2;
        BOOLEAN                    DiskSpinDown;
        UCHAR[8]                   spare3;
        BOOLEAN                    SystemBatteriesPresent;
        BOOLEAN                    BatteriesAreShortTerm;
        BATTERY_REPORTING_SCALE[3] BatteryScale;
        SYSTEM_POWER_STATE         AcOnLineWake;
        SYSTEM_POWER_STATE         SoftLidWake;
        SYSTEM_POWER_STATE         RtcWake;
        SYSTEM_POWER_STATE         MinDeviceWakeState;
        SYSTEM_POWER_STATE         DefaultLowLatencyWake;
}
alias SYSTEM_POWER_CAPABILITIES* PSYSTEM_POWER_CAPABILITIES;

struct SYSTEM_BATTERY_STATE {
        BOOLEAN    AcOnLine;
        BOOLEAN    BatteryPresent;
        BOOLEAN    Charging;
        BOOLEAN    Discharging;
        BOOLEAN[4] Spare1;
        ULONG      MaxCapacity;
        ULONG      RemainingCapacity;
        ULONG      Rate;
        ULONG      EstimatedTime;
        ULONG      DefaultAlert1;
        ULONG      DefaultAlert2;
}
alias SYSTEM_BATTERY_STATE* PSYSTEM_BATTERY_STATE;

enum POWER_INFORMATION_LEVEL {
        SystemPowerPolicyAc,
        SystemPowerPolicyDc,
        VerifySystemPolicyAc,
        VerifySystemPolicyDc,
        SystemPowerCapabilities,
        SystemBatteryState,
        SystemPowerStateHandler,
        ProcessorStateHandler,
        SystemPowerPolicyCurrent,
        AdministratorPowerPolicy,
        SystemReserveHiberFile,
        ProcessorInformation,
        SystemPowerInformation,
        ProcessorStateHandler2,
        LastWakeTime,
        LastSleepTime,
        SystemExecutionState,
        SystemPowerStateNotifyHandler,
        ProcessorPowerPolicyAc,
        ProcessorPowerPolicyDc,
        VerifyProcessorPowerPolicyAc,
        VerifyProcessorPowerPolicyDc,
        ProcessorPowerPolicyCurrent
}

//#if 1 /* (WIN32_WINNT >= 0x0500) */
struct SYSTEM_POWER_INFORMATION {
        ULONG MaxIdlenessAllowed;
        ULONG Idleness;
        ULONG TimeRemaining;
        UCHAR CoolingMode;
}
alias SYSTEM_POWER_INFORMATION* PSYSTEM_POWER_INFORMATION;
//#endif

struct PROCESSOR_POWER_POLICY_INFO {
        ULONG    TimeCheck;
        ULONG    DemoteLimit;
        ULONG    PromoteLimit;
        UCHAR    DemotePercent;
        UCHAR    PromotePercent;
        UCHAR[2] Spare;
        uint     _bf;

        bool AllowDemotion()  { return cast(bool)(_bf & 1); }
        bool AllowPromotion() { return cast(bool)(_bf & 2); }

        bool AllowDemotion(bool a)  { _bf = (_bf & ~1) | a; return a; }
        bool AllowPromotion(bool a) { _bf = (_bf & ~2) | (a << 1); return a; }
/+
        ULONG  AllowDemotion : 1;
        ULONG  AllowPromotion : 1;
        ULONG  Reserved : 30;
+/
}
alias PROCESSOR_POWER_POLICY_INFO* PPROCESSOR_POWER_POLICY_INFO;

struct PROCESSOR_POWER_POLICY {
        ULONG    Revision;
        UCHAR    DynamicThrottle;
        UCHAR[3] Spare;
        ULONG    Reserved;
        ULONG    PolicyCount;
        PROCESSOR_POWER_POLICY_INFO[3] Policy;
}
alias PROCESSOR_POWER_POLICY* PPROCESSOR_POWER_POLICY;

struct ADMINISTRATOR_POWER_POLICY {
        SYSTEM_POWER_STATE MinSleep;
        SYSTEM_POWER_STATE MaxSleep;
        ULONG              MinVideoTimeout;
        ULONG              MaxVideoTimeout;
        ULONG              MinSpindownTimeout;
        ULONG              MaxSpindownTimeout;
}
alias ADMINISTRATOR_POWER_POLICY* PADMINISTRATOR_POWER_POLICY;

//}//#endif /* _WIN32_WINNT >= 0x500 */

extern (Windows) {
        alias void function(PVOID, DWORD, PVOID) PIMAGE_TLS_CALLBACK;

        static if (_WIN32_WINNT >= 0x500) {
                alias LONG function(PEXCEPTION_POINTERS) PVECTORED_EXCEPTION_HANDLER;
                alias void function(PVOID, BOOLEAN) WAITORTIMERCALLBACKFUNC;
        }
}

static if (_WIN32_WINNT >= 0x501) {
        enum HEAP_INFORMATION_CLASS {
                HeapCompatibilityInformation
        }

        enum ACTIVATION_CONTEXT_INFO_CLASS {
                ActivationContextBasicInformation = 1,
                ActivationContextDetailedInformation,
                AssemblyDetailedInformationInActivationContext,
                FileInformationInAssemblyOfAssemblyInActivationContext
        }

        struct ACTIVATION_CONTEXT_ASSEMBLY_DETAILED_INFORMATION {
                DWORD         ulFlags;
                DWORD         ulEncodedAssemblyIdentityLength;
                DWORD         ulManifestPathType;
                DWORD         ulManifestPathLength;
                LARGE_INTEGER liManifestLastWriteTime;
                DWORD         ulPolicyPathType;
                DWORD         ulPolicyPathLength;
                LARGE_INTEGER liPolicyLastWriteTime;
                DWORD         ulMetadataSatelliteRosterIndex;
                DWORD         ulManifestVersionMajor;
                DWORD         ulManifestVersionMinor;
                DWORD         ulPolicyVersionMajor;
                DWORD         ulPolicyVersionMinor;
                DWORD         ulAssemblyDirectoryNameLength;
                PCWSTR        lpAssemblyEncodedAssemblyIdentity;
                PCWSTR        lpAssemblyManifestPath;
                PCWSTR        lpAssemblyPolicyPath;
                PCWSTR        lpAssemblyDirectoryName;
        }
        alias ACTIVATION_CONTEXT_ASSEMBLY_DETAILED_INFORMATION*
          PACTIVATION_CONTEXT_ASSEMBLY_DETAILED_INFORMATION;
        alias const(ACTIVATION_CONTEXT_ASSEMBLY_DETAILED_INFORMATION)*
          PCACTIVATION_CONTEXT_ASSEMBLY_DETAILED_INFORMATION;

        struct ACTIVATION_CONTEXT_DETAILED_INFORMATION {
                DWORD  dwFlags;
                DWORD  ulFormatVersion;
                DWORD  ulAssemblyCount;
                DWORD  ulRootManifestPathType;
                DWORD  ulRootManifestPathChars;
                DWORD  ulRootConfigurationPathType;
                DWORD  ulRootConfigurationPathChars;
                DWORD  ulAppDirPathType;
                DWORD  ulAppDirPathChars;
                PCWSTR lpRootManifestPath;
                PCWSTR lpRootConfigurationPath;
                PCWSTR lpAppDirPath;
        }
        alias ACTIVATION_CONTEXT_DETAILED_INFORMATION*
          PACTIVATION_CONTEXT_DETAILED_INFORMATION;
        alias const(ACTIVATION_CONTEXT_DETAILED_INFORMATION)*
          PCACTIVATION_CONTEXT_DETAILED_INFORMATION;

        struct ACTIVATION_CONTEXT_QUERY_INDEX {
                ULONG ulAssemblyIndex;
                ULONG ulFileIndexInAssembly;
        }
        alias ACTIVATION_CONTEXT_QUERY_INDEX*        PACTIVATION_CONTEXT_QUERY_INDEX;
        alias const(ACTIVATION_CONTEXT_QUERY_INDEX)* PCACTIVATION_CONTEXT_QUERY_INDEX;

        struct ASSEMBLY_FILE_DETAILED_INFORMATION {
                DWORD  ulFlags;
                DWORD  ulFilenameLength;
                DWORD  ulPathLength;
                PCWSTR lpFileName;
                PCWSTR lpFilePath;
        }
        alias ASSEMBLY_FILE_DETAILED_INFORMATION*
          PASSEMBLY_FILE_DETAILED_INFORMATION;
        alias const(ASSEMBLY_FILE_DETAILED_INFORMATION)*
          PCASSEMBLY_FILE_DETAILED_INFORMATION;
}

version (Unicode) {
        alias OSVERSIONINFOW OSVERSIONINFO;
        alias OSVERSIONINFOEXW OSVERSIONINFOEX;
} else {
        alias OSVERSIONINFOA OSVERSIONINFO;
        alias OSVERSIONINFOEXA OSVERSIONINFOEX;
}

alias OSVERSIONINFO*   POSVERSIONINFO,   LPOSVERSIONINFO;
alias OSVERSIONINFOEX* POSVERSIONINFOEX, LPOSVERSIONINFOEX;


static if (_WIN32_WINNT >= 0x500) {
        extern (Windows) ULONGLONG VerSetConditionMask(ULONGLONG, DWORD, BYTE);
}

version (Win64) {
        const WORD IMAGE_NT_OPTIONAL_HDR_MAGIC = IMAGE_NT_OPTIONAL_HDR64_MAGIC;

        alias IMAGE_ORDINAL_FLAG64 IMAGE_ORDINAL_FLAG;
        alias IMAGE_SNAP_BY_ORDINAL64 IMAGE_SNAP_BY_ORDINAL;
        alias IMAGE_ORDINAL64 IMAGE_ORDINAL;
        alias IMAGE_OPTIONAL_HEADER64 IMAGE_OPTIONAL_HEADER;
        alias IMAGE_NT_HEADERS64 IMAGE_NT_HEADERS;
        alias IMAGE_THUNK_DATA64 IMAGE_THUNK_DATA;
        alias IMAGE_TLS_DIRECTORY64 IMAGE_TLS_DIRECTORY;
} else {
        const WORD IMAGE_NT_OPTIONAL_HDR_MAGIC = IMAGE_NT_OPTIONAL_HDR32_MAGIC;

        alias IMAGE_ORDINAL_FLAG32 IMAGE_ORDINAL_FLAG;
        alias IMAGE_ORDINAL32 IMAGE_ORDINAL;
        alias IMAGE_SNAP_BY_ORDINAL32 IMAGE_SNAP_BY_ORDINAL;
        alias IMAGE_OPTIONAL_HEADER32 IMAGE_OPTIONAL_HEADER;
        alias IMAGE_NT_HEADERS32 IMAGE_NT_HEADERS;
        alias IMAGE_THUNK_DATA32 IMAGE_THUNK_DATA;
        alias IMAGE_TLS_DIRECTORY32 IMAGE_TLS_DIRECTORY;
}

alias IMAGE_OPTIONAL_HEADER* PIMAGE_OPTIONAL_HEADER;
alias IMAGE_NT_HEADERS* PIMAGE_NT_HEADERS;
alias IMAGE_THUNK_DATA* PIMAGE_THUNK_DATA;
alias IMAGE_TLS_DIRECTORY* PIMAGE_TLS_DIRECTORY;

// TODO: MinGW implements these in assembly.  How to translate?
PVOID GetCurrentFiber();
PVOID GetFiberData();
