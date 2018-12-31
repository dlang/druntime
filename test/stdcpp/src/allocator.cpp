#include <memory>

//Anything that will instantiate an allocator
#include <vector>

struct Mystruct { int a; };
void foo()
{
    std::vector<int> a;
    std::vector<float> b;
    std::vector<Mystruct> c;
}
