module libdeh;

void throwing()
{
    throw new Exception("throwing");
}

void catching()
{
    bool passed;
    try
    {
        throwing();
    }
    catch(Exception)
    {
        passed = true;
    }
    assert(passed);
}

void testEH1()
{
    bool passed;
    try
    {
        throwing();
    }
    catch(Exception)
    {
        passed = true;
    }
    assert(passed);

    catching();
}

void testEH2()
{
    throwing();
}

class LibException : Exception
{
    this()
    {
        super("LibException");
    }
}
