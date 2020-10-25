// Check avoid of destruction of fiber if GC collection will be invoked during Fiber construction

extern(C) __gshared string[] rt_options = [ "gcopt=minPoolSize:1M incPoolSize:4K" ];

import core.memory : GC;

void main()
{
    char[] buf = new char[1024 * 1024 * 16];

    auto f = new Fiber( (){} );
    f.call();
}
