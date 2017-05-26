DRuntime: Runtime Library for the D Programming Language
========================================================

[![GitHub tag](https://img.shields.io/github/tag/dlang/druntime.svg?maxAge=86400)](#)
[![Build status](https://img.shields.io/circleci/project/dlang/druntime.svg?maxAge=86400)](https://circleci.com/gh/dlang/druntime)
[![Code coverage](https://img.shields.io/codecov/c/github/dlang/druntime.svg?maxAge=86400)](https://codecov.io/gh/dlang/druntime)
[![Issue Stats](https://img.shields.io/issuestats/p/github/dlang/druntime.svg?maxAge=2592000)](http://www.issuestats.com/github/dlang/druntime)

This is DRuntime. It is the low-level runtime library
backing the D programming language.

DRuntime is typically linked together with Phobos in a
release such that the compiler only has to link to a
single library to provide the user with the runtime and
the standard library.

Purpose
-------

DRuntime is meant to be an abstraction layer above the
compiler. Different compilers will likely have their
own versions of DRuntime. While the implementations
may differ, the interfaces should be the same.

Features
--------

The runtime library provides the following:

* The Object class, the root of the class hierarchy.
* Implementations of array operations.
* The associative array implementation.
* Type information and RTTI.
* Common threading and fiber infrastructure.
* Synchronization and coordination primitives.
* Exception handling and stack tracing.
* Garbage collection interface and implementation.
* Program startup and shutdown routines.
* Low-level math intrinsics and support code.
* Interfaces to standard C99 functions and types.
* Interfaces to operating system APIs.
* Atomic load/store and binary operations.
* CPU detection/identification for x86.
* System-independent time/duration functionality.
* D ABI demangling helpers.
* Low-level bit operations/intrinsics.
* Unit test, coverage, and trace support code.
* Low-level helpers for compiler-inserted calls.

Issues
------

To report a bug or look up known issues with the runtime library, please visit
the [bug tracker](http://issues.dlang.org/).

Licensing
---------

See the LICENSE file for licensing information.

Building
--------

See the [wiki page](http://wiki.dlang.org/Building_DMD) for build instructions.

Contributing
------------

Walter and Andrei have veto rights when it comes to inclusion of new stuff into DMD, druntime, and phobos. So if you're looking to work on new stuff either pick something from the [list](https://wiki.dlang.org/Walter_Andrei_Action_List). Or get in contact with Walter or Andrei early during the design phase of your project. This way you can avoid a lot of frustration, by not having your project rejected after you already implemented it.
