/**
 * D header file for FreeBSD
 *
 * Authors: Iain Buclaw
 */
module core.sys.freebsd.config;

version (FreeBSD):

public import core.sys.posix.config;

// https://svnweb.freebsd.org/base/head/sys/sys/param.h?view=markup
// __FreeBSD_version numbers are documented in the Porter's Handbook.
// NOTE: When adding newer versions of FreeBSD, verify all current versioned
// bindings are still compatible with the release.
enum __FreeBSD_version = __xFreeBSD_version!();

// First version of FreeBSD to support 64-bit stat buffer.
enum INO64_FIRST = 1200000;

// Returns (FreeBSD_ver * 1_00_000), as the major version number in __FreeBSD_version.
// The two digit minor and revision version numbers are not handled.
extern (D) private template __xFreeBSD_version()
{
    enum __xFreeBSD_version = mixin(`{`~
    {
        string ret;
        char ver1, ver2;
        // FreeBSD versions 1 .. 9
        static foreach (i; 1 .. 10)
        {
            ver1 = '0' + i;
            ret ~= q{version (FreeBSD_} ~ ver1 ~ q{) return } ~ ver1 ~ q{_00000; else };
        }
        // FreeBSD versions 10 .. 99
        static foreach (i; 1 .. 10)
        {
            ver1 = '0' + i;
            static foreach (j; 0 .. 10)
            {
                ver2 = '0' + j;
                ret ~= q{version (FreeBSD_} ~ ver1~ver2 ~ q{) return } ~ ver1~ver2 ~ q{_00000; else };
            }
        }
        // Unknown FreeBSD version, or using kFreeBSD
        ret ~= q{version (FreeBSD) version (CRuntime_Glibc) return 10_00000; else };
        ret ~= q{static assert(false, "Unsupported version of FreeBSD"); else };
        // version FreeBSD is not set, not compiling for FreeBSD
        ret ~= q{static assert(false, "__FreeBSD_version requested, but FreeBSD is not set");};
        return ret;
    }()
    ~`}()`);
}
