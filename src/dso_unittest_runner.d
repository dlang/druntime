/**
 * DSO unittest helper.
 *
 * Copyright: Copyright Martin Nowak 2013.
 * License:   <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors:   Martin Nowak
 * Source: $(DRUNTIMESRC src/_dso_unittest_runner.d)
 */
import core.runtime;

shared static this()
{
    Runtime.moduleUnitTester = &unitTester;
}

private:

bool unitTester()
{
    if (Runtime.args().length != 2) return false;
    auto toTest = Runtime.args()[1];

    foreach(m; ModuleInfo)
    {
        auto name = m.name;
        if (name != toTest) continue;

        if (auto fp = m.unitTest)
        {
            import core.stdc.stdio;
            printf("Testing %.*s\n", cast(int)name.length, name.ptr);

            try
            {
                fp();
            }
            catch (Throwable e)
            {
                auto msg = e.toString();
                fprintf(stderr, "%.*s\n", cast(int)msg.length, msg.ptr);
                return false;
            }
        }
        break;
    }
    return true;
}

void main()
{
}
