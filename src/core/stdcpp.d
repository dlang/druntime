// Written in the D programming language.

/**
 * Interface to C++ STL
 *
 * Copyright: Copyright (c) 2016 D Language Foundation
 * License:   $(HTTP boost.org/LICENSE_1_0.txt, Boost License 1.0).
 * Authors:   $(HTTP digitalmars.com, Walter Bright)
 * Source:    $(DRUNTIMESRC core/stdcpp.d)
 */

module core.stdcpp;

version (CRuntime_DigitalMars)
{
    extern (C++, std)
    {
        alias void function() unexpected_handler;
        unexpected_handler set_unexpected(unexpected_handler f) nothrow;
        void unexpected();

        alias void function() terminate_handler;
        terminate_handler set_terminate(terminate_handler f) nothrow;
        void terminate();

        bool uncaught_exception();

        class exception
        {
            this() nothrow { }
            this(const exception) nothrow { }
            //exception operator=(const exception) nothrow { return this; }
            //virtual ~this() nothrow;
            void dtor() { }
            const(char)* what() const nothrow;
        }

        class bad_exception : exception
        {
            this() nothrow { }
            this(const bad_exception) nothrow { }
            //bad_exception operator=(const bad_exception) nothrow { return this; }
            //virtual ~this() nothrow;
            override const(char)* what() const nothrow;
        }
    }

    extern (C++, std)
    {
        class type_info
        {
            void* pdata;

          public:
            //virtual ~this();
            void dtor() { }     // reserve slot in vtbl[]

            //bool operator==(const type_info rhs) const;
            //bool operator!=(const type_info rhs) const;
            final bool before(const type_info rhs) const;
            final const(char)* name() const;
          protected:
            //type_info();
          private:
            //this(const type_info rhs);
            //type_info operator=(const type_info rhs);
        }

        class bad_cast : core.stdcpp.exception.std.exception
        {
            this() nothrow { }
            this(const bad_cast) nothrow { }
            //bad_cast operator=(const bad_cast) nothrow { return this; }
            //virtual ~this() nothrow;
            override const(char)* what() const nothrow;
        }

        class bad_typeid : core.stdcpp.exception.std.exception
        {
            this() nothrow { }
            this(const bad_typeid) nothrow { }
            //bad_typeid operator=(const bad_typeid) nothrow { return this; }
            //virtual ~this() nothrow;
            override const (char)* what() const nothrow;
        }
    }
}
else version (CRuntime_Glibc)
{
    extern (C++, std)
    {
        alias void function() unexpected_handler;
        unexpected_handler set_unexpected(unexpected_handler f) nothrow;
        void unexpected();

        alias void function() terminate_handler;
        terminate_handler set_terminate(terminate_handler f) nothrow;
        void terminate();

        pure bool uncaught_exception();

        class exception
        {
            this();
            //virtual ~this();
            void dtor1();
            void dtor2();
            const(char)* what() const;
        }

        class bad_exception : exception
        {
            this();
            //virtual ~this();
            override const(char)* what() const;
        }
    }

    extern (C++, __cxxabiv1)
    {
        class __class_type_info;
    }

    extern (C++, std)
    {
        class type_info
        {
            void dtor1();                           // consume destructor slot in vtbl[]
            void dtor2();                           // consume destructor slot in vtbl[]
            final const(char)* name()() const nothrow {
                return _name[0] == '*' ? _name + 1 : _name;
            }
            final bool before()(const type_info _arg) const {
                import core.stdc.string : strcmp;
                return (_name[0] == '*' && _arg._name[0] == '*')
                    ? _name < _arg._name
                    : strcmp(_name, _arg._name) < 0;
            }
            //bool operator==(const type_info) const;
            bool __is_pointer_p() const;
            bool __is_function_p() const;
            bool __do_catch(const type_info, void**, uint) const;
            bool __do_upcast(const __cxxabiv1.__class_type_info, void**) const;

            const(char)* _name;
            this(const(char)*);
        }

        class bad_cast : core.stdcpp.exception.std.exception
        {
            this();
            //~this();
            override const(char)* what() const;
        }

        class bad_typeid : core.stdcpp.exception.std.exception
        {
            this();
            //~this();
            override const(char)* what() const;
        }
    }
}
else version (CRuntime_Microsoft)
{
    extern (C++, std)
    {
        class exception
        {
            this();
            this(const exception);
            //exception operator=(const exception) { return this; }
            //virtual ~this();
            void dtor() { }
            const(char)* what() const;

          private:
            const(char)* mywhat;
            bool dofree;
        }

        class bad_exception : exception
        {
            this(const(char)* msg = "bad exception");
            //virtual ~this();
        }
    }

    struct __type_info_node
    {
        void* _MemPtr;
        __type_info_node* _Next;
    }

    extern __gshared __type_info_node __type_info_root_node;

    extern (C++, std)
    {
        class type_info
        {
            //virtual ~this();
            void dtor() { }     // reserve slot in vtbl[]
            //bool operator==(const type_info rhs) const;
            //bool operator!=(const type_info rhs) const;
            final bool before(const type_info rhs) const;
            final const(char)* name(__type_info_node* p = &__type_info_root_node) const;

          private:
            void* pdata;
            char[1] _name;
            //type_info operator=(const type_info rhs);
        }

        class bad_cast : core.stdcpp.exception.std.exception
        {
            this(const(char)* msg = "bad cast");
            //virtual ~this();
        }

        class bad_typeid : core.stdcpp.exception.std.exception
        {
            this(const(char)* msg = "bad typeid");
            //virtual ~this();
        }
    }
}
