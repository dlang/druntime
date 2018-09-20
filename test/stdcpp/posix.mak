# built from the druntime top-level folder
# to be overwritten by caller
DMD=dmd

test:
	$(CC) -c -o array_cpp.o test/stdcpp/src/array.cpp
	$(DMD) -m$(MODEL) -conf= -Isrc -defaultlib=$(DRUNTIME) -main -unittest test/stdcpp/src/array.d array_cpp.o
	./array
	rm test test.o array_cpp.o
