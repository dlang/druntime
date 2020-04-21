/**
 * D header file for Darwin.
 *
 * Copyright: Copyright Martin Nowak 2012.
 * License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 * Authors:   Martin Nowak
 */
module core.sys.darwin.execinfo;

version (OSX)
    version = Darwin;
else version (iOS)
    version = Darwin;
else version (TVOS)
    version = Darwin;
else version (WatchOS)
    version = Darwin;

version (Darwin):
extern (C):
nothrow:
@nogc:

version (GNU)
version = BacktraceExternal;

char** backtrace_symbols(const(void*)* buffer, int size);
void backtrace_symbols_fd(const(void*)* buffer, int size, int fd);

version (BacktraceExternal)
{
    int backtrace(void** buffer, int size);
else
{
    enum _URC_NO_REASON = 0;
    enum _URC_END_OF_STACK = 5;

    alias _Unwind_Context_Ptr = void*;
    alias _Unwind_Trace_Fn = int function(_Unwind_Context_Ptr, void*);
    int _Unwind_Backtrace(_Unwind_Trace_Fn, void*);
    ptrdiff_t _Unwind_GetIP(_Unwind_Context_Ptr context);

    extern (D) int backtrace(void** buffer, int maxSize)
    {
        if (maxSize < 0) return 0;

        struct State
        {
            void** buffer;
            int maxSize;
            int entriesWritten = 0;
        }

        static extern(C) int handler(_Unwind_Context_Ptr context, void* statePtr)
        {
            auto state = cast(State*)statePtr;
            if (state.entriesWritten >= state.maxSize) return _URC_END_OF_STACK;

            auto instructionPtr = _Unwind_GetIP(context);
            if (!instructionPtr) return _URC_END_OF_STACK;

            state.buffer[state.entriesWritten] = cast(void*)instructionPtr;
            ++state.entriesWritten;

            return _URC_NO_REASON;
        }

        State state;
        state.buffer = buffer;
        state.maxSize = maxSize;
        _Unwind_Backtrace(&handler, &state);

        return state.entriesWritten;
    }
}
