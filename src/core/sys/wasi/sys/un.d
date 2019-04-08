module core.sys.wasi.sys.un;

version (WebAssembly):
extern(C):

public import core.sys.wasi.sys.socket: sa_family_t;

//
// Required
//
/*
struct sockaddr_un
{
    sa_family_t sun_family;
    char        sa_data[];
}

sa_family_t    // From core.sys.posix.sys.socket
*/

struct sockaddr_un {
    sa_family_t sun_family;
    char[108] sun_path;
}
