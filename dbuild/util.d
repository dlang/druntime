module dbuild.util;

import std.stdio;
import std.process;
import std.file;
import std.algorithm;
import std.array;
import std.path;
import std.conv;
import std.string;
import std.range;
import std.stdio : writeln;
import std.file : write, dirEntries, SpanMode, isFile;

// TODO: consider using `std.experimental.loggger`
void writeln2(string file = __FILE__, int line = __LINE__, T...)(T a)
{
    string msg;
    static foreach (ai; a)
        msg ~= text(" {", ai, "}");
    writeln(file, ":", line, msg);
}

// same as `relativePath` but works with relative paths
auto relativePathRel(string file, string base)
{
    return file.absolutePath.relativePath(base.absolutePath);
}

// convenience function for UFCS chains
void writeTo(string msg, string file)
{
    file.write(msg);
}

// remove comments from `a` (lines starting with [spaces]$comment)
auto removeComments(string a, string comment = `#`)
{
    return a.splitLines.filter!(a => !a.stripLeft.startsWith(comment)).join("\n");
}

// splits a into space delimited nonempty strings, excluding commented lines
auto splitEntries(string a)
{
    return a.removeComments.splitter.filter!(a => !a.empty);
}
