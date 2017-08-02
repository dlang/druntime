
// Make sure basic stuff works with future Throwable.message
class NoMessage : Throwable
{
    @nogc @safe pure nothrow this(string msg, Throwable next = null)
    {
        super(msg, next);
    }
}

class WithMessage : Throwable
{
    @nogc @safe pure nothrow this(string msg, Throwable next = null)
    {
        super(msg, next);
    }

    override const(char)[] message() const
    {
        return "I have a custom message!";
    }
}

class WithMessageNoOverride : Throwable
{
    @nogc @safe pure nothrow this(string msg, Throwable next = null)
    {
        super(msg, next);
    }

    override const(char)[] message() const
    {
        return "I have a custom message and no override!";
    }
}

void test(Throwable t)
{
    try
    {
        throw t;
    }
    catch (Throwable e)
    {
        printf("%.*s\n", e.message.length, e.message.ptr);
    }
}

void main()
{
     t(new NoMMessage("exception");
     t(new WithMessage("exception");
     t(new WithMessageNoOverride("exception");
}
