module core.sys.posix.sys.utsname;

version(linux)
{
  private enum utsNameLength = 65;
}
else version(OSX)
{
  private enum utsNameLength = 256;
}

extern (C)
{
  struct utsname
  {
    char sysname[utsNameLength];
    char nodename[utsNameLength];
    char release[utsNameLength];
    char update[utsNameLength];
    char machine[utsNameLength];

    version(linux) char __domainname[utsNameLength];
  }

  int uname(utsname* __name);
}
