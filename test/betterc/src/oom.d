// TODO: add an issue number if this is accepted
import core.stdc.stdlib : malloc, free;
import core.memory : onOutOfMemoryError;

extern(C) void main()
{
    auto m = malloc(1);
    if (!m)
        onOutOfMemoryError();
    else
        free(m);
}
