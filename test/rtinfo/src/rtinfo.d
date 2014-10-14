void testCustomRTInfo()
{
    static string[] registeredClasses;
    static struct CustomRTInfo(T)
    {
        static assert(is(T == A) || is(T == B));
        static this()
        {
            registeredClasses ~= T.stringof;
        }
    }

    @rtInfo!CustomRTInfo static class A { }
    static class B : A { }

    // @rtInfo test
    assert(registeredClasses.length == 2);
    assert(registeredClasses[0] == "A" || registeredClasses[1] == "A");
    assert(registeredClasses[0] == "B" || registeredClasses[1] == "B");
}

void main()
{
    testCustomRTInfo();
}
