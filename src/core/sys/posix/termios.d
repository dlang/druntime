/**
 * D header file for POSIX.
 *
 * Copyright: Copyright Sean Kelly 2005 - 2009.
 * License:   <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors:   Sean Kelly
 * Standards: The Open Group Base Specifications Issue 6, IEEE Std 1003.1, 2004 Edition
 */

/*          Copyright Sean Kelly 2005 - 2009.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */
module core.sys.posix.termios;

private import core.sys.posix.config;
public import core.sys.posix.sys.types; // for pid_t
private import std.conv;

version (Posix):
extern (C):

//
// Required
//
/*
cc_t
speed_t
tcflag_t

NCCS

struct termios
{
    tcflag_t   c_iflag;
    tcflag_t   c_oflag;
    tcflag_t   c_cflag;
    tcflag_t   c_lflag;
    cc_t[NCCS] c_cc;
}

VEOF
VEOL
VERASE
VINTR
VKILL
VMIN
VQUIT
VSTART
VSTOP
VSUSP
VTIME

BRKINT
ICRNL
IGNBRK
IGNCR
IGNPAR
INLCR
INPCK
ISTRIP
IXOFF
IXON
PARMRK

OPOST

B0
B50
B75
B110
B134
B150
B200
B300
B600
B1200
B1800
B2400
B4800
B9600
B19200
B38400

CSIZE
    CS5
    CS6
    CS7
    CS8
CSTOPB
CREAD
PARENB
PARODD
HUPCL
CLOCAL

ECHO
ECHOE
ECHOK
ECHONL
ICANON
IEXTEN
ISIG
NOFLSH
TOSTOP

TCSANOW
TCSADRAIN
TCSAFLUSH

TCIFLUSH
TCIOFLUSH
TCOFLUSH

TCIOFF
TCION
TCOOFF
TCOON

speed_t cfgetispeed(in termios*);
speed_t cfgetospeed(in termios*);
int     cfsetispeed(termios*, speed_t);
int     cfsetospeed(termios*, speed_t);
int     tcdrain(int);
int     tcflow(int, int);
int     tcflush(int, int);
int     tcgetattr(int, termios*);
int     tcsendbreak(int, int);
int     tcsetattr(int, int, in termios*);
*/

version( linux )
{
    alias ubyte cc_t;
    alias uint  speed_t;
    alias uint  tcflag_t;

    enum NCCS   = 32;

    struct termios
    {
        tcflag_t   c_iflag;
        tcflag_t   c_oflag;
        tcflag_t   c_cflag;
        tcflag_t   c_lflag;
        cc_t       c_line;
        cc_t[NCCS] c_cc;
        speed_t    c_ispeed;
        speed_t    c_ospeed;
    }

    enum VEOF       = 4;
    enum VEOL       = 11;
    enum VERASE     = 2;
    enum VINTR      = 0;
    enum VKILL      = 3;
    enum VMIN       = 6;
    enum VQUIT      = 1;
    enum VSTART     = 8;
    enum VSTOP      = 9;
    enum VSUSP      = 10;
    enum VTIME      = 5;

    enum BRKINT     = octal!2;
    enum ICRNL      = octal!400;
    enum IGNBRK     = octal!1;
    enum IGNCR      = octal!200;
    enum IGNPAR     = octal!4;
    enum INLCR      = octal!100;
    enum INPCK      = octal!20;
    enum ISTRIP     = octal!40;
    enum IXOFF      = octal!10000;
    enum IXON       = octal!2000;
    enum PARMRK     = octal!10;

    enum OPOST      = octal!1;

    enum B0         = octal!0;
    enum B50        = octal!1;
    enum B75        = octal!2;
    enum B110       = octal!3;
    enum B134       = octal!4;
    enum B150       = octal!5;
    enum B200       = octal!6;
    enum B300       = octal!7;
    enum B600       = octal!10;
    enum B1200      = octal!11;
    enum B1800      = octal!12;
    enum B2400      = octal!13;
    enum B4800      = octal!14;
    enum B9600      = octal!15;
    enum B19200     = octal!16;
    enum B38400     = octal!17;

    enum CSIZE      = octal!60;
    enum   CS5      = octal!0;
    enum   CS6      = octal!20;
    enum   CS7      = octal!40;
    enum   CS8      = octal!60;
    enum CSTOPB     = octal!100;
    enum CREAD      = octal!200;
    enum PARENB     = octal!400;
    enum PARODD     = octal!1000;
    enum HUPCL      = octal!2000;
    enum CLOCAL     = octal!4000;

    enum ECHO       = octal!10;
    enum ECHOE      = octal!20;
    enum ECHOK      = octal!40;
    enum ECHONL     = octal!100;
    enum ICANON     = octal!2;
    enum IEXTEN     = octal!100000;
    enum ISIG       = octal!1;
    enum NOFLSH     = octal!200;
    enum TOSTOP     = octal!400;

    enum TCSANOW    = 0;
    enum TCSADRAIN  = 1;
    enum TCSAFLUSH  = 2;

    enum TCIFLUSH   = 0;
    enum TCOFLUSH   = 1;
    enum TCIOFLUSH  = 2;

    enum TCIOFF     = 2;
    enum TCION      = 3;
    enum TCOOFF     = 0;
    enum TCOON      = 1;

    speed_t cfgetispeed(in termios*);
    speed_t cfgetospeed(in termios*);
    int     cfsetispeed(termios*, speed_t);
    int     cfsetospeed(termios*, speed_t);
    int     tcdrain(int);
    int     tcflow(int, int);
    int     tcflush(int, int);
    int     tcgetattr(int, termios*);
    int     tcsendbreak(int, int);
    int     tcsetattr(int, int, in termios*);
}
else version( OSX )
{
    alias ubyte cc_t;
    alias c_ulong  speed_t;
    alias c_ulong  tcflag_t;

    enum NCCS   = 20;

    struct termios
    {
        tcflag_t   c_iflag;
        tcflag_t   c_oflag;
        tcflag_t   c_cflag;
        tcflag_t   c_lflag;
        cc_t[NCCS] c_cc;
        speed_t    c_ispeed;
        speed_t    c_ospeed;
    }

    enum VEOF       = 0;
    enum VEOL       = 1;
    enum VERASE     = 3;
    enum VINTR      = 8;
    enum VKILL      = 5;
    enum VMIN       = 16;
    enum VQUIT      = 9;
    enum VSTART     = 12;
    enum VSTOP      = 13;
    enum VSUSP      = 10;
    enum VTIME      = 17;

    enum BRKINT     = 0x0000002;
    enum ICRNL      = 0x0000100;
    enum IGNBRK     = 0x0000001;
    enum IGNCR      = 0x0000080;
    enum IGNPAR     = 0x0000004;
    enum INLCR      = 0x0000040;
    enum INPCK      = 0x0000010;
    enum ISTRIP     = 0x0000020;
    enum IXOFF      = 0x0000400;
    enum IXON       = 0x0000200;
    enum PARMRK     = 0x0000008;

    enum OPOST      = 0x0000001;

    enum B0         = 0;
    enum B50        = 50;
    enum B75        = 75;
    enum B110       = 110;
    enum B134       = 134;
    enum B150       = 150;
    enum B200       = 200;
    enum B300       = 300;
    enum B600       = 600;
    enum B1200      = 1200;
    enum B1800      = 1800;
    enum B2400      = 2400;
    enum B4800      = 4800;
    enum B9600      = 9600;
    enum B19200     = 19200;
    enum B38400     = 38400;

    enum CSIZE      = 0x0000300;
    enum   CS5      = 0x0000000;
    enum   CS6      = 0x0000100;
    enum   CS7      = 0x0000200;
    enum   CS8      = 0x0000300;
    enum CSTOPB     = 0x0000400;
    enum CREAD      = 0x0000800;
    enum PARENB     = 0x0001000;
    enum PARODD     = 0x0002000;
    enum HUPCL      = 0x0004000;
    enum CLOCAL     = 0x0008000;

    enum ECHO       = 0x00000008;
    enum ECHOE      = 0x00000002;
    enum ECHOK      = 0x00000004;
    enum ECHONL     = 0x00000010;
    enum ICANON     = 0x00000100;
    enum IEXTEN     = 0x00000400;
    enum ISIG       = 0x00000080;
    enum NOFLSH     = 0x80000000;
    enum TOSTOP     = 0x00400000;

    enum TCSANOW    = 0;
    enum TCSADRAIN  = 1;
    enum TCSAFLUSH  = 2;

    enum TCIFLUSH   = 1;
    enum TCOFLUSH   = 2;
    enum TCIOFLUSH  = 3;

    enum TCIOFF     = 3;
    enum TCION      = 4;
    enum TCOOFF     = 1;
    enum TCOON      = 2;

    speed_t cfgetispeed(in termios*);
    speed_t cfgetospeed(in termios*);
    int     cfsetispeed(termios*, speed_t);
    int     cfsetospeed(termios*, speed_t);
    int     tcdrain(int);
    int     tcflow(int, int);
    int     tcflush(int, int);
    int     tcgetattr(int, termios*);
    int     tcsendbreak(int, int);
    int     tcsetattr(int, int, in termios*);

}
else version ( FreeBSD )
{
    alias ubyte cc_t;
    alias uint  speed_t;
    alias uint  tcflag_t;

    enum NCCS   = 20;

    struct termios
    {
        tcflag_t   c_iflag;
        tcflag_t   c_oflag;
        tcflag_t   c_cflag;
        tcflag_t   c_lflag;
        cc_t[NCCS] c_cc;
        speed_t    c_ispeed;
        speed_t    c_ospeed;
    }

    enum VEOF       = 0;
    enum VEOL       = 1;
    enum VERASE     = 3;
    enum VINTR      = 8;
    enum VKILL      = 5;
    enum VMIN       = 16;
    enum VQUIT      = 9;
    enum VSTART     = 12;
    enum VSTOP      = 13;
    enum VSUSP      = 10;
    enum VTIME      = 17;

    enum BRKINT     = 0x0000002;
    enum ICRNL      = 0x0000100;
    enum IGNBRK     = 0x0000001;
    enum IGNCR      = 0x0000080;
    enum IGNPAR     = 0x0000004;
    enum INLCR      = 0x0000040;
    enum INPCK      = 0x0000010;
    enum ISTRIP     = 0x0000020;
    enum IXOFF      = 0x0000400;
    enum IXON       = 0x0000200;
    enum PARMRK     = 0x0000008;

    enum OPOST      = 0x0000001;

    enum B0         = 0;
    enum B50        = 50;
    enum B75        = 75;
    enum B110       = 110;
    enum B134       = 134;
    enum B150       = 150;
    enum B200       = 200;
    enum B300       = 300;
    enum B600       = 600;
    enum B1200      = 1200;
    enum B1800      = 1800;
    enum B2400      = 2400;
    enum B4800      = 4800;
    enum B9600      = 9600;
    enum B19200     = 19200;
    enum B38400     = 38400;

    enum CSIZE      = 0x0000300;
    enum   CS5      = 0x0000000;
    enum   CS6      = 0x0000100;
    enum   CS7      = 0x0000200;
    enum   CS8      = 0x0000300;
    enum CSTOPB     = 0x0000400;
    enum CREAD      = 0x0000800;
    enum PARENB     = 0x0001000;
    enum PARODD     = 0x0002000;
    enum HUPCL      = 0x0004000;
    enum CLOCAL     = 0x0008000;

    enum ECHO       = 0x00000008;
    enum ECHOE      = 0x00000002;
    enum ECHOK      = 0x00000004;
    enum ECHONL     = 0x00000010;
    enum ICANON     = 0x00000100;
    enum IEXTEN     = 0x00000400;
    enum ISIG       = 0x00000080;
    enum NOFLSH     = 0x80000000;
    enum TOSTOP     = 0x00400000;

    enum TCSANOW    = 0;
    enum TCSADRAIN  = 1;
    enum TCSAFLUSH  = 2;

    enum TCIFLUSH   = 1;
    enum TCOFLUSH   = 2;
    enum TCIOFLUSH  = 3;

    enum TCIOFF     = 3;
    enum TCION      = 4;
    enum TCOOFF     = 1;
    enum TCOON      = 2;

    speed_t cfgetispeed(in termios*);
    speed_t cfgetospeed(in termios*);
    int     cfsetispeed(termios*, speed_t);
    int     cfsetospeed(termios*, speed_t);
    int     tcdrain(int);
    int     tcflow(int, int);
    int     tcflush(int, int);
    int     tcgetattr(int, termios*);
    int     tcsendbreak(int, int);
    int     tcsetattr(int, int, in termios*);

}

//
// XOpen (XSI)
//
/*
IXANY

ONLCR
OCRNL
ONOCR
ONLRET
OFILL
NLDLY
    NL0
    NL1
CRDLY
    CR0
    CR1
    CR2
    CR3
TABDLY
    TAB0
    TAB1
    TAB2
    TAB3
BSDLY
    BS0
    BS1
VTDLY
    VT0
    VT1
FFDLY
    FF0
    FF1

pid_t   tcgetsid(int);
*/

version( linux )
{
    enum IXANY      = octal!4000;

    enum ONLCR      = octal!4;
    enum OCRNL      = octal!10;
    enum ONOCR      = octal!20;
    enum ONLRET     = octal!40;
    enum OFILL      = octal!100;
    enum NLDLY      = octal!400;
    enum   NL0      = octal!0;
    enum   NL1      = octal!400;
    enum CRDLY      = octal!3000;
    enum   CR0      = octal!0;
    enum   CR1      = octal!1000;
    enum   CR2      = octal!2000;
    enum   CR3      = octal!3000;
    enum TABDLY     = octal!14000;
    enum   TAB0     = octal!0;
    enum   TAB1     = octal!4000;
    enum   TAB2     = octal!10000;
    enum   TAB3     = octal!14000;
    enum BSDLY      = octal!20000;
    enum   BS0      = octal!0;
    enum   BS1      = octal!20000;
    enum VTDLY      = octal!40000;
    enum   VT0      = octal!0;
    enum   VT1      = octal!40000;
    enum FFDLY      = octal!100000;
    enum   FF0      = octal!0;
    enum   FF1      = octal!100000;

    pid_t   tcgetsid(int);
}

else version (OSX)
{
    enum IXANY      = 0x00000800;

    enum ONLCR      = 0x00000002;
    enum OCRNL      = 0x00000010;
    enum ONOCR      = 0x00000020;
    enum ONLRET     = 0x00000040;
    enum OFILL      = 0x00000080;
    enum NLDLY      = 0x00000300;
    enum   NL0      = 0x00000000;
    enum   NL1      = 0x00000100;
    enum CRDLY      = 0x00003000;
    enum   CR0      = 0x00000000;
    enum   CR1      = 0x00001000;
    enum   CR2      = 0x00002000;
    enum   CR3      = 0x00003000;
    enum TABDLY     = 0x00000c04;
    enum   TAB0     = 0x00000000;
    enum   TAB1     = 0x00000400;
    enum   TAB2     = 0x00000800;
    enum   TAB3     = 0x00000004;
    enum BSDLY      = 0x00008000;
    enum   BS0      = 0x00000000;
    enum   BS1      = 0x00008000;
    enum VTDLY      = 0x00010000;
    enum   VT0      = 0x00000000;
    enum   VT1      = 0x00010000;
    enum FFDLY      = 0x00004000;
    enum   FF0      = 0x00000000;
    enum   FF1      = 0x00004000;

    pid_t tcgetsid (int);
}

else version( FreeBSD )
{
    enum IXANY      = 0x00000800;

    enum ONLCR      = 0x00000002;
    enum OCRNL      = 0x00000010;
    enum ONOCR      = 0x00000020;
    enum ONLRET     = 0x00000040;
    //enum OFILL
    //enum NLDLY
    //enum     NL0
    //enum     NL1
    //enum CRDLY
    //enum     CR0
    //enum     CR1
    //enum     CR2
    //enum     CR3
    enum TABDLY     = 0x00000004;
    enum     TAB0   = 0x00000000;
    //enum     TAB1
    //enum     TAB2
    enum     TAB3   = 0x00000004;
    //enum BSDLY
    //enum     BS0
    //enum     BS1
    //enum VTDLY
    //enum     VT0
    //enum     VT1
    //enum FFDLY
    //enum     FF0
    //enum     FF1

    pid_t   tcgetsid(int);
}

