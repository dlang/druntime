#include <array>

int fromC_val(std::array<int, 5>);
int fromC_ref(const std::array<int, 5>&);

int sumOfElements_ref(const std::array<int, 5>& arr)
{
    int r = 0;
    for (size_t i = 0; i < arr.size(); ++i)
        r += arr[i];
    return r;
}

int sumOfElements_val(std::array<int, 5> arr)
{
    return sumOfElements_ref(arr) + fromC_ref(arr) + fromC_val(arr);
}
