module test.stdcpp.tuple;

import core.stdcpp.tuple;

unittest
{
    auto s1 = SimpleTuple(.1f, 40);
    assert(s1 == AliasSeq!(.1, 10 * 4));

    {
        auto e1 = ElaborateTuple(10, Elaborate(4));
        assert(e1 == AliasSeq!(10, Elaborate(4)));
        auto e2 = e1;
        assert(e2 == e1);
        assert(E_RefCount == 1);
    }
    assert(E_RefCount == 0);

    auto s2 = SimpleTuple(10, 17);
    auto e2 = ElaborateTuple(0, Elaborate(9));
    assert(120 == callC_val(SimpleTuple(12.5, 70), ElaborateTuple(0, Elaborate(1)), s2, e2));
    assert(E_RefCount == 0);
}

alias AliasSeq(Args...) = Args;

extern(C++):

__gshared int E_RefCount = 0;

struct Elaborate
{
    int i;
    this(this) { ++E_RefCount; }
    ~this() { --E_RefCount; }
}

alias SimpleTuple = tuple!(float, int);
alias ElaborateTuple = tuple!(int, Elaborate);

int callC_val(SimpleTuple, ElaborateTuple, ref SimpleTuple, ref ElaborateTuple);

int fromC_val(SimpleTuple s1, ElaborateTuple e1, ref SimpleTuple s2, ref ElaborateTuple e2)
{
    return cast(int)(s1.get!0 + s2.get!0 + s1.get!1 + s2.get!1 + (e1.get!1.i + e2.get!1.i) * E_RefCount);
}
