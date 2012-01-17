/**
 * This module provides OS specific helper function for threads support
 *
 * Copyright: Copyright Digital Mars 2010 - 2010.
 * License:   <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors:   Rainer Schuetze
 */

/*          Copyright Digital Mars 2010 - 2010.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE_1_0.txt or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */

module core.sys.windows.threadaux; // declaration

version( Windows ):

import core.sys.windows.windows;
public import core.thread;

extern(Windows)
HANDLE OpenThread(DWORD dwDesiredAccess, BOOL bInheritHandle, DWORD dwThreadId); // should be in windowsbase

extern (C) extern __gshared int _tls_index;

///////////////////////////////////////////////////////////////////
// get the thread environment block (TEB) of the thread with the given handle
void** getTEB( HANDLE hnd );

// get the thread environment block (TEB) of the thread with the given identifier
void** getTEB( uint id );

// get linear address of TEB of current thread
void** getTEB();

// get the stack bottom (the top address) of the thread with the given handle
void* getThreadStackBottom( HANDLE hnd );

// get the stack bottom (the top address) of the thread with the given identifier
void* getThreadStackBottom( uint id );

// create a thread handle with full access to the thread with the given identifier
HANDLE OpenThreadHandle( uint id );

///////////////////////////////////////////////////////////////////
// enumerate threads of the given process calling the passed function on each thread
// using function instead of delegate here to avoid allocating closure
bool enumProcessThreads( uint procid, bool function( uint id, void* context ) dg, void* context );

bool enumProcessThreads( bool function( uint id, void* context ) dg, void* context );

// get the start of the TLS memory of the thread with the given handle
void* GetTlsDataAddress( HANDLE hnd );

// get the start of the TLS memory of the thread with the given identifier
void* GetTlsDataAddress( uint id );

///////////////////////////////////////////////////////////////////
// run rt_moduleTlsCtor in the context of the given thread
void thread_moduleTlsCtor( uint id );

///////////////////////////////////////////////////////////////////
// run rt_moduleTlsDtor in the context of the given thread
void thread_moduleTlsDtor( uint id );
