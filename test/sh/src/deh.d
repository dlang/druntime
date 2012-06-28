import libdeh;

unittest
{
    libdeh.testEH1();

    bool passed;
    try
    {
        libdeh.testEH2();
    }
    catch (Exception)
    {
        passed = true;
    }

    assert(passed);
    passed = false;

    static void libException()
    {
        throw new libdeh.LibException();
    }

    try
    {
        libException();
    }
    catch (Exception e)
    {
        passed = true;
    }

    assert(passed);
    passed = false;
}

void main()
{
}
