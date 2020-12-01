/**
 * D header file for Darwin.
 *
 * Copyright: Copyright (c) 2020 D Language Foundation
 * Authors: Iain Buclaw
 */
module core.sys.darwin.config;

version (OSX)
    version = Darwin;
else version (iOS)
    version = Darwin;
else version (TVOS)
    version = Darwin;
else version (WatchOS)
    version = Darwin;

version (Darwin):

public import core.sys.posix.config;

// In the OSX Availability headers, a developer can specify a MIN_REQUIRED and
// a MAX_ALLOWED version number to control the OS functionality.  Here, there
// is only a lower bound version number `__MAC_OS_X_VERSION_MIN` exposed, these
// are gated by predefined version conditions added in the compiler, and map to
// the setting of the following compiler options.
//  -mmacosx-version-min=   (on OSX)
//  -miphoneos-version-min= (on iOS)
//  -mtvos-version-min=     (on TVOS)
//  -mwatchos-version-min=  (on WatchOS)

enum __MAC_10_5  = 1050;
enum __MAC_10_6  = 1060;
enum __MAC_10_7  = 1070;
enum __MAC_10_8  = 1080;
enum __MAC_10_9  = 1090;
enum __MAC_10_10 = 101000;
enum __MAC_10_11 = 101100;
enum __MAC_10_12 = 101200;

     version (OSX_10_5)  enum __MAC_OS_X_VERSION_MIN = __MAC_10_5;
else version (OSX_10_6)  enum __MAC_OS_X_VERSION_MIN = __MAC_10_6;
else version (OSX_10_7)  enum __MAC_OS_X_VERSION_MIN = __MAC_10_7;
else version (OSX_10_8)  enum __MAC_OS_X_VERSION_MIN = __MAC_10_8;
else version (OSX_10_9)  enum __MAC_OS_X_VERSION_MIN = __MAC_10_9;
else version (OSX_10_10) enum __MAC_OS_X_VERSION_MIN = __MAC_10_10;
else version (OSX_10_11) enum __MAC_OS_X_VERSION_MIN = __MAC_10_11;
else version (OSX_10_12) enum __MAC_OS_X_VERSION_MIN = __MAC_10_12;
else                     enum __MAC_OS_X_VERSION_MIN = __MAC_10_9;

enum __IPHONE_9_0  = 90000;
enum __IPHONE_9_1  = 90100;
enum __IPHONE_9_2  = 90200;
enum __IPHONE_9_3  = 90300;
enum __IPHONE_10_0 = 100000;
enum __IPHONE_10_1 = 100100;
enum __IPHONE_10_2 = 100200;
enum __IPHONE_10_3 = 100300;

     version (iOS_9_0)  enum __IPHONE_OS_VERSION_MIN = __IPHONE_9_0;
else version (iOS_9_1)  enum __IPHONE_OS_VERSION_MIN = __IPHONE_9_1;
else version (iOS_9_2)  enum __IPHONE_OS_VERSION_MIN = __IPHONE_9_2;
else version (iOS_9_3)  enum __IPHONE_OS_VERSION_MIN = __IPHONE_9_3;
else version (iOS_10_0) enum __IPHONE_OS_VERSION_MIN = __IPHONE_10_0;
else version (iOS_10_1) enum __IPHONE_OS_VERSION_MIN = __IPHONE_10_1;
else version (iOS_10_2) enum __IPHONE_OS_VERSION_MIN = __IPHONE_10_2;
else version (iOS_10_3) enum __IPHONE_OS_VERSION_MIN = __IPHONE_10_3;
else                    enum __IPHONE_OS_VERSION_MIN = __IPHONE_9_0;

enum __TVOS_9_0  = 90000;
enum __TVOS_9_1  = 90100;
enum __TVOS_9_2  = 90200;
enum __TVOS_10_0 = 100000;
enum __TVOS_10_1 = 100100;
enum __TVOS_10_2 = 100200;

version (TVOS_9_0)  enum __TV_OS_VERSION_MIN = __TVOS_9_0;
version (TVOS_9_1)  enum __TV_OS_VERSION_MIN = __TVOS_9_1;
version (TVOS_9_2)  enum __TV_OS_VERSION_MIN = __TVOS_9_2;
version (TVOS_10_0) enum __TV_OS_VERSION_MIN = __TVOS_10_0;
version (TVOS_10_1) enum __TV_OS_VERSION_MIN = __TVOS_10_1;
version (TVOS_10_2) enum __TV_OS_VERSION_MIN = __TVOS_10_2;
else                enum __TV_OS_VERSION_MIN = __TVOS_10_0;

enum __WATCHOS_1_0 = 10000;
enum __WATCHOS_2_0 = 20000;
enum __WATCHOS_3_0 = 30000;
enum __WATCHOS_3_1 = 30100;
enum __WATCHOS_3_2 = 30200;

version (WatchOS_1_0) enum __WATCH_OS_VERSION_MIN = __WATCHOS_1_0;
version (WatchOS_2_0) enum __WATCH_OS_VERSION_MIN = __WATCHOS_2_0;
version (WatchOS_3_0) enum __WATCH_OS_VERSION_MIN = __WATCHOS_3_0;
version (WatchOS_3_1) enum __WATCH_OS_VERSION_MIN = __WATCHOS_3_1;
version (WatchOS_3_2) enum __WATCH_OS_VERSION_MIN = __WATCHOS_3_2;
else                  enum __WATCH_OS_VERSION_MIN = __WATCHOS_3_0;
