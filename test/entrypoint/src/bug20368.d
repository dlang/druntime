module mymod;

mixin Bug;

mixin template Bug()
{
   void main()
   {
         alias Attribs = __traits(getAttributes, __traits(getMember, mymod, "main"));
   }
}
