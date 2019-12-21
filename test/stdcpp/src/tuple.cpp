#include <tuple>

extern int E_RefCount;

struct Elaborate
{
    int i;

    Elaborate(const Elaborate& rhs)
    {
        i = rhs.i;
        ++E_RefCount;
    }

    ~Elaborate()
    {
        --E_RefCount;
    }
};

typedef std::tuple<float, int> SimpleTuple;
typedef std::tuple<int, Elaborate> ElaborateTuple;

int fromC_val(SimpleTuple, ElaborateTuple, SimpleTuple&, ElaborateTuple&);
int callC_val(SimpleTuple s1, ElaborateTuple e1, SimpleTuple& s2, ElaborateTuple& e2)
{
    return fromC_val(s1, e1, s2, e2);
}
