module dbuild.main;
import std.process;
import std.file;
import std.algorithm;
import std.array;
import std.path;
import std.conv;
import std.string;
import std.range;

import dbuild.util;

/+
Returns whether to include `file` in `COPY`
+/
bool isValid_COPY(string file)
{
    if (file=="object.d" || file.startsWith("etc/"))
        return true;

    if (!file.startsWith("core/"))
        return false;

    enum excluded = `
## excluded dirs
core/sync/
core/sys/netbsd/
core/sys/bionic/

## excluded files
core/sys/darwin/dlfcn.d
core/sys/linux/stdio.d
core/sys/osx/sys/event.d
core/sys/posix/mqueue.d
core/sys/posix/sys/msg.d

`.splitEntries;

    foreach (a; excluded)
        if (file.startsWith(a))
            return false;
    return true;
}

/+
Returns whether to include `file` in `SRCS`
TODO: check why all those exclusions are needed or if it was a longstanding error
+/
bool isValid_SRCS(string file)
{
    enum excluded = `
## excluded dirs
core/sys/netbsd/
core/sys/bionic/
core/sys/openbsd/
core/sys/osx/
core/sys/darwin/mach/
core/sys/solaris/
core/stdcpp/

## excluded files ; TODO: is there some logic/pattern here (to auto-generate)
core/stdc/wctype.d
core/stdc/tgmath.d
core/sys/darwin/dlfcn.d
core/sys/darwin/execinfo.d
core/sys/darwin/pthread.d
core/sys/darwin/sys/cdefs.d
core/sys/darwin/sys/event.d
core/sys/darwin/sys/mman.d
core/sys/freebsd/pthread_np.d
core/sys/linux/config.d
core/sys/linux/dlfcn.d
core/sys/linux/elf.d
core/sys/linux/epoll.d
core/sys/linux/errno.d
core/sys/linux/execinfo.d
core/sys/linux/fcntl.d
core/sys/linux/ifaddrs.d
core/sys/linux/link.d
core/sys/linux/sched.d
core/sys/linux/sys/auxv.d
core/sys/linux/sys/eventfd.d
core/sys/linux/sys/file.d
core/sys/linux/sys/netinet/tcp.d
core/sys/linux/sys/prctl.d
core/sys/linux/termios.d
core/sys/linux/time.d
core/sys/linux/timerfd.d
core/sys/linux/unistd.d
core/sys/posix/config.d
core/sys/posix/dlfcn.d
core/sys/posix/fcntl.d
core/sys/posix/grp.d
core/sys/posix/iconv.d
core/sys/posix/inttypes.d
core/sys/posix/libgen.d
core/sys/posix/mqueue.d
core/sys/posix/net/if_.d
core/sys/posix/netinet/tcp.d
core/sys/posix/poll.d
core/sys/posix/pthread.d
core/sys/posix/pwd.d
core/sys/posix/sched.d
core/sys/posix/semaphore.d
core/sys/posix/setjmp.d
core/sys/posix/stdio.d
core/sys/posix/stdlib.d
core/sys/posix/sys/filio.d
core/sys/posix/sys/ioccom.d
core/sys/posix/sys/msg.d
core/sys/posix/sys/ttycom.d
core/sys/posix/syslog.d
core/sys/posix/termios.d
core/sys/posix/time.d
core/sys/posix/ucontext.d
core/sys/posix/unistd.d
core/sys/posix/utime.d
test_runner.d

`.splitEntries;

    auto added = `
  core/sys/solaris/sys/priocntl.d
  core/sys/solaris/sys/procset.d
  core/sys/solaris/sys/types.d
  `.splitEntries;

    if (added.canFind(file))
        return true;

    foreach (a; excluded)
        if (file.startsWith(a))
            return false;
    return true;
}

auto files_IMPORTS = `
core/sync/barrier.di
core/sync/condition.di
core/sync/config.di
core/sync/exception.di
core/sync/mutex.di
core/sync/rwmutex.di
core/sync/semaphore.di
  `.splitEntries.array;

/+
Returns whether to include `file` in `DOCS`
+/
bool isValid_DOCS(string file)
{
    file = file.stripExtension.replace("/", ".");
    import std.stdio;

    if (file.startsWith("rt.", "core.stdc.", "core.stdcpp.", "core.sync."))
        return true;

    import std.regex;

    if (matchFirst(file, `^(object|core\.\w+)$`.regex))
        return true;
    return false;
}

void main(string[] args)
{
    auto builder = new Builder;
    builder.generateMakefileVariables(args);
}

/+
this auto-generates Makefile variables
for SRCS,DOCS,COPY, it scans files in source directories and applies exclusion
rules: see isValid_{SRCS,DOCS,COPY}.
+/
class Builder
{

    // Verifies auto-generated `files` match existing `filesGold`
    void verify(string name, string[] files, string[] filesGold)
    {
        auto temp1 = filesGold.sort().array;
        auto temp2 = files.sort().array;

        // PRTEMP: for debuggging (remove beofore submission)
        {
          temp1.join("\n").writeTo("/tmp/z02.temp1.txt");
          temp2.join("\n").writeTo("/tmp/z02.temp2.txt");
        }

        auto temp12 = temp1.setDifference(temp2).array;
        auto temp21 = temp2.setDifference(temp1).array;
        writeln2(name, temp1.length, temp2.length, temp12.length, temp21.length, temp1 == temp2);
        writeln2(temp12.join("\n"));
        writeln2(temp21.join("\n"));
        assert(temp1 == temp2);
    }

    // Verifies auto-generated `entries` match Makefile variable defined in `goldFile`
    void verify2(string[] entries, string goldFile)
    {
        auto gold = getGold(goldFile);
        verify(goldFile, entries, gold.array);
    }

    // reads and normalizes files defined by Makefile variable defined in `goldFile`
    auto getGold(string goldFile)
    {
        return goldFile.readText.splitLines[1 .. $].map!(a => a.strip.replace(` \`,
                ``)).filter!(a => !a.empty && a != `\`).map!(a => a.replace(`\`,
                `/`)).array.sort.release;

    }

    /+
    generate Makefile variables (see list in D20180211T125334)
    +/
    void generateMakefileVariables(string[] args)
    {
        writeln2(args);

        // read environment
        auto aa = environment.toAA;
        auto outDir = aa["ROOT_OF_THEM_ALL"];
        auto TOOL_RDMD = aa["TOOL_RDMD"];
        auto GENERATED_VARS_F = aa["GENERATED_VARS_F"];

        // define some Makefile variables
        version (OSX)
        {
            string OS = "osx";
        }
        else version (linux)
        {
            string OS = "linux";
        }

        auto IMPDIR = `import`;
        auto DOCDIR = `doc`;
        auto srcDir = "src";

        // list D files in `dir` (without `srcDir` path prefix)
        auto getFiles(string dir)
        {
            // dfmt off
            return dirEntries(srcDir.buildPath(dir), "*.d", SpanMode.depth)
                .filter!(a => a.isFile)
                .map!(a => a.name.relativePathRel(srcDir).buildNormalizedPath)
                .array;
            // dfmt on
        }

        // auto-generate other Makefile variables

        // COPY
        auto files_COPY = getFiles(".").filter!isValid_COPY.map!(
                a => `$(IMPDIR)`.buildPath(a)).array;

        // SRCS
        auto files_SRCS = getFiles(".").filter!isValid_SRCS.map!(a => srcDir.buildPath(a)).array;

        // DOCS
        auto files_DOCS = getFiles(".").filter!isValid_DOCS.map!(
                a => `$(DOCDIR)/` ~ a.stripExtension.replace("/", "_") ~ ".html").array;

        // IMPORTS
        files_IMPORTS = files_IMPORTS.map!(a => IMPDIR.buildPath(a)).array;

        // check that behavior doesn't change from what we had in `mak/*`
        {
            verify2(files_SRCS, "mak/SRCS");
            verify2(files_COPY, "mak/COPY");
            verify2(files_DOCS, "mak/DOCS");
            // `IMPORTS` is verbatim, so not checked
        }

        // write Makefile variables to `GENERATED_VARS_F`
        {
            string msg;

            void push(string name, string value)
            {
                msg ~= name ~ `=` ~ value ~ "\n\n";
            }

            void pushAll(string name, string[] names)
            {
                push(name, names.join(" "));
            }

            import std.datetime;

            msg ~= "#autogenerated at " ~ Clock.currTime.toISOExtString
                ~ " see D20180210T162431; do not edit by hand\n\n";

            // D20180211T125334: variables generated
            static foreach (var; `TOOL_RDMD IMPDIR DOCDIR GENERATED_VARS_F`.split)
            {
                push(var, mixin(var));
            }
            pushAll(`COPY`, files_COPY);
            pushAll(`SRCS`, files_SRCS);
            pushAll(`IMPORTS`, files_IMPORTS);
            pushAll(`DOCS`, files_DOCS);

            mkdirRecurse(outDir);
            msg.writeTo(GENERATED_VARS_F);
            writeln2(GENERATED_VARS_F);
        }
    }
}
