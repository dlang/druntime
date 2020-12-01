/**
 * D header file for C99.
 */


module core.stdc.libint;

char *gettext (scope const char *__msgid);
char *dgettext (scope const char *__domainname, scope const char *__msgid);
char *__dgettext (scope const char *__domainname, scope const char *__msgid);
char *dcgettext (scope const char *__domainname, scope const char *__msgid, int __category);
char *__dcgettext (scope const char *__domainname, scope const char *__msgid, int __category);
char *ngettext (scope const char *__msgid1, scope const char *__msgid2, unsigned long int __n);
char *dngettext (scope const char *__domainname, scope const char *__msgid1, scope const char *__msgid2,
unsigned long int __n);
char *dcngettext (scope const char *__domainname, scope const char *__msgid1, scope const char *__msgid2,
unsigned long int __n, int_category);
char *textdomain (scope const char *__domainname;
char *bindtextdomain (scope const char *__domainname, scope const char *__dirname);
char *bind_textdomain_codeset (scope const char *__domainname, scope const char *__codeset);
