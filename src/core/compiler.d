/**
 * Compiler information and associated routines.
 *
 * Copyright: Copyright Digital Mars 2000 - 2010.
 * License:   <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors:   Walter Bright
 * Source:    $(DRUNTIMESRC core/_compiler.d)
 */

/*          Copyright Digital Mars 2000 - 2010.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE_1_0.txt or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */
module core.compiler;

// Identify the compiler used and its various features.

/// Master list of D compiler vendors.
enum Vendor
{
    unknown = 0,     /// Compiler vendor could not be detected
    digitalMars = 1, /// Digital Mars D (DMD)
    gnu = 2,         /// GNU D Compiler (GDC)
    llvm = 3,        /// LLVM D Compiler (LDC)
    dotNET = 4,      /// D.NET
    sdc = 5,         /// Stupid D Compiler (SDC)
}

/// Vendor specific string naming the compiler, for example: "Digital Mars D".
enum string compilerName = __VENDOR__;
 
/// Which vendor produced this compiler.
version(StdDdoc)          enum Vendor compilerVendor;
else version(DigitalMars) enum Vendor compilerVendor = Vendor.digitalMars;
else version(GNU)         enum Vendor compilerVendor = Vendor.gnu;
else version(LDC)         enum Vendor compilerVendor = Vendor.llvm;
else version(D_NET)       enum Vendor compilerVendor = Vendor.dotNET;
else version(SDC)         enum Vendor compilerVendor = Vendor.sdc;
else                      enum Vendor compilerVendor = Vendor.unknown;

/**
 * The vendor specific version number, as in
 * version_major.version_minor
 */
enum uint compilerMajor = __VERSION__ / 1000;
enum uint compilerMinor = __VERSION__ % 1000;    /// ditto

/**
 * The version of the D Programming Language Specification
 * supported by the compiler.
 */
enum uint languageMajor = 2;
enum uint languageMinor = 0;
