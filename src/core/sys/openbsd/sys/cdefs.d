/**
  * D header file for OpenBSD
  *
  */
module core.sys.openbsd.sys.cdefs;

version (OpenBSD):

public import core.sys.posix.config;

// Used core/sys/freebsd/sys/cdefs.d as base
// Values retrieved from: https://cvsweb.openbsd.org/src/sys/sys/cdefs.h
// with the assumption that OpenBSD is compiled with _XOPEN_SOURCE = 600
enum __POSIX_VISIBLE = 200112;
enum __XPG_VISIBLE = 600;
enum __BSD_VISIBLE = true;
enum __ISO_C_VISIBLE = 1999;
