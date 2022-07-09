# Proxy Makefile for backwards compatibility after move to DMD

DMD_DIR=../dmd

target:
	$(QUIET)$(MAKE) -C $(DMD_DIR)/druntime -f posix.mak $@
	rm -rf import generated && cp -a $(DMD_DIR)/{druntime/import,generated} ./

doc:
	$(QUIET)$(MAKE) -C $(DMD_DIR)/druntime -f posix.mak $@

# import:
# 	$(QUIET)$(MAKE) -C $(DMD_DIR)/druntime -f posix.mak $@

# copy:
# 	$(QUIET)$(MAKE) -C $(DMD_DIR)/druntime -f posix.mak $@

# dll:
# 	$(QUIET)$(MAKE) -C $(DMD_DIR)/druntime -f posix.mak $@

# lib:
# 	$(QUIET)$(MAKE) -C $(DMD_DIR)/druntime -f posix.mak $@

# unittest:
# 	$(QUIET)$(MAKE) -C $(DMD_DIR)/druntime -f posix.mak $@

# benchmark:
# 	$(QUIET)$(MAKE) -C $(DMD_DIR)/druntime -f posix.mak $@

# benchmark-compile-only:
# 	$(QUIET)$(MAKE) -C $(DMD_DIR)/druntime -f posix.mak $@

# checkwhitespace:
# 	$(QUIET)$(MAKE) -C $(DMD_DIR)/druntime -f posix.mak $@

# detab:
# 	$(QUIET)$(MAKE) -C $(DMD_DIR)/druntime -f posix.mak $@

# gitzip:
# 	$(QUIET)$(MAKE) -C $(DMD_DIR)/druntime -f posix.mak $@

# zip:
# 	$(QUIET)$(MAKE) -C $(DMD_DIR)/druntime -f posix.mak $@

# install:
# 	$(QUIET)$(MAKE) -C $(DMD_DIR)/druntime -f posix.mak $@

# clean:
# 	$(QUIET)$(MAKE) -C $(DMD_DIR)/druntime -f posix.mak $@

# test_extractor:
# 	$(QUIET)$(MAKE) -C $(DMD_DIR)/druntime -f posix.mak $@

# betterc:
# 	$(QUIET)$(MAKE) -C $(DMD_DIR)/druntime -f posix.mak $@

# style:
# 	$(QUIET)$(MAKE) -C $(DMD_DIR)/druntime -f posix.mak $@

# style_lint:
# 	$(QUIET)$(MAKE) -C $(DMD_DIR)/druntime -f posix.mak $@

# publictests:
# 	$(QUIET)$(MAKE) -C $(DMD_DIR)/druntime -f posix.mak $@

# auto-tester-build:
# 	$(QUIET)$(MAKE) -C $(DMD_DIR)/druntime -f posix.mak $@

# auto-tester-test:
# 	$(QUIET)$(MAKE) -C $(DMD_DIR)/druntime -f posix.mak $@

# buildkite-test:
# 	$(QUIET)$(MAKE) -C $(DMD_DIR)/druntime -f posix.mak $@
