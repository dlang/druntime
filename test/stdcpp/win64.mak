# built from the druntime top-level folder
# to be overwritten by caller
DMD=dmd
MODEL=64
DRUNTIMELIB=druntime64.lib
CC=cl

test:
	"$(CC)" -c /Foarray_cpp.obj test\stdcpp\src\array.cpp /EHsc
	"$(DMD)" -m$(MODEL) -conf= -Isrc -defaultlib=$(DRUNTIMELIB) -main -unittest test\stdcpp\src\array.d array_cpp.obj
	array.exe
	del test.exe test.obj array_cpp.obj

