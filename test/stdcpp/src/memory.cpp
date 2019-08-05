#include <memory>

std::unique_ptr<int> passThrough(std::unique_ptr<int> x)
{
    return std::move(x);
}
std::unique_ptr<int> changeIt(std::unique_ptr<int> x)
{
    x.reset();
    return std::unique_ptr<int>(new int(20));
}
