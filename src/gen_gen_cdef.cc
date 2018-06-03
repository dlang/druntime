#include <iostream>
#include <fstream>
#include <string>
#include <initializer_list>
#include <assert.h>
static int counter = 0;
static std::ofstream o("src/gen_cdef.cc");
std::string file_to_module_name(const std::string &f)
{
    assert(f.substr(0, 4) == "src/");
    assert(f.substr(f.size()-2) == ".d");
    std::string ret = f.substr(4, f.size()-6);
    for(char &ch: ret)
    {
        if (ch == '/')
            ch = '.';
    }
    return ret;
}
void struct_begin(const std::string &f, const std::string &hdr)
{
    o << "#include <" << hdr << ">\n";
    o << "struct __HDR_" << counter << " {\n";
    o << "\t__HDR_" << counter << "() {\n";
    o << "std::ofstream o(\"" << f << "\");\n";
    o << "o << \"module " << file_to_module_name(f) << ";\\n\";\n";
}

void struct_end()
{
    o << "}\n};\n";
    o << "__HDR_" << counter << " __hdrv_" << counter << ";\n";
    counter++;
}

struct Gen
{
    Gen(std::initializer_list<std::string> l)
    {
        auto li = l.begin();
        struct_begin(*li, *(li+1));
        for(li+=2; li != l.end(); li++)
        {
            o << "#ifdef " << *li << "\n";
            o << "o << \"enum " << *li << " = \" << " << *li << " << \";\\n\";\n";
            o << "#else\n";
            o << "o << \"// " << *li << " not defined\\n\";\n";
            o << "#endif\n";
        }
        struct_end();
    }
};

int main()
{
    o << "#include <fstream>\n";
    Gen fcntl
    {
        "src/core/sys/posix/fcntl_c.d",
        "fcntl.h",

        "F_DUPFD",
        "F_GETFD",
        "F_SETFD",
        "F_GETFL",
        "F_SETFL",
        "F_GETLK",
        "F_SETLK",
        "F_SETLKW",
        "F_SETOWN",
        "F_GETOWN",
        "F_OGETLK",
        "F_OSETLK",
        "F_OSETLKW",
        "F_DUP2FD",

        "FD_CLOEXEC",

        "F_RDLCK",
        "F_WRLCK",
        "F_UNLCK",
        "F_UNCKSYS",
        "F_DUPFD_CLOEXEC",
        "F_DUP2FD_CLOEXEC",
        "F_ISATTY",
        "F_CLOSEM",
        "F_MAXFD",
        "F_GETNOSIGPIPE",
        "F_SETNOSIGPIPE",

        "O_CREAT",
        "O_EXCL",
        "O_NOCTTY",
        "O_TRUNC",
        "O_APPEND",
        "O_DSYNC",
        "O_RSYNC",
        "O_SYNC",
        "O_RDONLY",
        "O_RDWR",
        "O_WRONLY",
        "O_ACCMODE",
        "O_DIRECTORY",
        "O_CLOEXEC",
        "O_NOFOLLOW",
        "O_NONBLOCK",
        "O_SHLOCK",
        "O_EXLOCK",
        "O_ASYNC",
        "O_FSYNC",
        "O_DIRECT",
        "O_LARGEFILE",
        "O_NOATIME",
        "O_PATH",
        "O_TMPFILE",
        "O_NDELAY",
        "O_SEARCH",
        "O_EXEC",
        "O_FBLOCKING",
        "O_FNONBLOCKING",
        "O_FAPPEND",
        "O_FOFFSET",
        "O_FSYNCWRITE",
        "O_FASYNCWRITE",

        "LOCK_SH",
        "LOCK_EX",
        "LOCK_NB",
        "LOCK_UN",

        "AT_FDCWD",
        "AT_EACCESS",
        "AT_SYMLINK_FOLLOW",
        "AT_SYMLINK_NOFOLLOW",
        "AT_REMOVEDIR",

        "FREAD",
        "FWRITE",
        "FAPPEND",
        "FASYNC",
        "FFSYNC",
        "FNONBLOCK",
        "FNDELAY",
        "FPOSIXSHM",
    };

    Gen poll
    {
        "src/core/sys/posix/poll_c.d",
        "poll.h",
        "POLLIN",
        "POLLRDNORM",
        "POLLRDBAND",
        "POLLPRI",
        "POLLOUT",
        "POLLWRNORM",
        "POLLWRBAND",
        "POLLERR",
        "POLLHUP",
        "POLLNVAL",
        "POLLNORM",
        "POLLSTANDARD",
        "POLLEXTEND",
        "POLLATTRIB",
        "POLLNLINK",
        "POLLWRITE",
    };
    o << "int main(){}\n";
    return 0;
}
