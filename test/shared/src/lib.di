// D import file generated from 'lib.d'
module lib;
void throwException();
Exception collectException(void delegate() dg);
private __gshared Object root;


void alloc();
void access();
void free();
private Object tls_root;

void tls_alloc();
void tls_access();
void tls_free();
shared
{
	uint shared_static_ctor;
	uint shared_static_dtor;
	uint static_ctor;
	uint static_dtor;
}
//no link dependency, the loading will initialize the lib
//shared static this();
//static this();
extern (C) int runTests();

void runTestsImpl();
