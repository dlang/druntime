/**
 * D header file for GNU/Hurd
 *
 * Authors: Iain Buclaw
 */
module core.sys.hurd.config;

version (Hurd):

public import core.sys.posix.config;

// man 7 feature_test_macros
// http://www.gnu.org/software/libc/manual/html_node/Feature-Test-Macros.html
enum _GNU_SOURCE = true;
// deduced <features.h>
// http://sourceware.org/git/?p=glibc.git;a=blob;f=include/features.h
enum _DEFAULT_SOURCE = true;
enum _ATFILE_SOURCE = true;
