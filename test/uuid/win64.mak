# built from the druntime top-level folder
# to be overwritten by caller
DMD=dmd
MODEL=64
DRUNTIMELIB=druntime64.lib

test:
	$(DMD) -m$(MODEL) -conf= -Isrc -I$(PLATFORM_PATH) -defaultlib=$(DRUNTIMELIB) test\uuid\test.d uuid.lib
	del test.exe test.obj

