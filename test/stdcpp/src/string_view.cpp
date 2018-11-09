#include <string_view>
#include <assert.h>

int fromC_val(std::string_view);
int fromC_ref(const std::string_view&);
std::string_view getFromD();

int sumOfElements_ref(const std::string_view& str)
{
    int r = 0;
    for (size_t i = 0; i < str.size(); ++i)
        r += str[i];
    return r;
}

int sumOfElements_val(std::string_view str)
{
    return sumOfElements_ref(str) + fromC_ref(str) + fromC_val(str);
}

std::string_view getFromC()
{
    assert(getFromD().compare("I'm from D!") == 0);
    return std::string_view("I'm from C++!");
}
