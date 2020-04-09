$(mak\COPY)
$(mak\IMPORTS)

import: $(IMPORTS)

######################## Header .di file copy ##############################

copydir: $(IMPDIR)
	@if not exist $(IMPDIR)\core\gc                         mkdir $(IMPDIR)\core\gc
	@if not exist $(IMPDIR)\core\stdc                       mkdir $(IMPDIR)\core\stdc
	@if not exist $(IMPDIR)\core\stdcpp                     mkdir $(IMPDIR)\core\stdcpp
	@if not exist $(IMPDIR)\core\internal                   mkdir $(IMPDIR)\core\internal
	@if not exist $(IMPDIR)\core\internal\array             mkdir $(IMPDIR)\core\internal\array
	@if not exist $(IMPDIR)\core\internal\util              mkdir $(IMPDIR)\core\internal\util
	@if not exist $(IMPDIR)\core\sys\bionic                 mkdir $(IMPDIR)\core\sys\bionic
	@if not exist $(IMPDIR)\core\sys\darwin\mach            mkdir $(IMPDIR)\core\sys\darwin\mach
	@if not exist $(IMPDIR)\core\sys\darwin\netinet         mkdir $(IMPDIR)\core\sys\darwin\netinet
	@if not exist $(IMPDIR)\core\sys\darwin\sys             mkdir $(IMPDIR)\core\sys\darwin\sys
	@if not exist $(IMPDIR)\core\sys\freebsd\netinet        mkdir $(IMPDIR)\core\sys\freebsd\netinet
	@if not exist $(IMPDIR)\core\sys\freebsd\sys            mkdir $(IMPDIR)\core\sys\freebsd\sys
	@if not exist $(IMPDIR)\core\sys\dragonflybsd\netinet   mkdir $(IMPDIR)\core\sys\dragonflybsd\netinet
	@if not exist $(IMPDIR)\core\sys\dragonflybsd\sys       mkdir $(IMPDIR)\core\sys\dragonflybsd\sys
	@if not exist $(IMPDIR)\core\sys\linux\netinet          mkdir $(IMPDIR)\core\sys\linux\netinet
	@if not exist $(IMPDIR)\core\sys\linux\sys              mkdir $(IMPDIR)\core\sys\linux\sys
	@if not exist $(IMPDIR)\core\sys\netbsd                 mkdir $(IMPDIR)\core\sys\netbsd
	@if not exist $(IMPDIR)\core\sys\netbsd\sys             mkdir $(IMPDIR)\core\sys\netbsd\sys
	@if not exist $(IMPDIR)\core\sys\openbsd                mkdir $(IMPDIR)\core\sys\openbsd
	@if not exist $(IMPDIR)\core\sys\openbsd\sys            mkdir $(IMPDIR)\core\sys\openbsd\sys
	@if not exist $(IMPDIR)\core\sys\posix\arpa             mkdir $(IMPDIR)\core\sys\posix\arpa
	@if not exist $(IMPDIR)\core\sys\posix\net              mkdir $(IMPDIR)\core\sys\posix\net
	@if not exist $(IMPDIR)\core\sys\posix\netinet          mkdir $(IMPDIR)\core\sys\posix\netinet
	@if not exist $(IMPDIR)\core\sys\posix\sys              mkdir $(IMPDIR)\core\sys\posix\sys
	@if not exist $(IMPDIR)\core\sys\solaris\sys            mkdir $(IMPDIR)\core\sys\solaris\sys
	@if not exist $(IMPDIR)\core\sys\windows                mkdir $(IMPDIR)\core\sys\windows
	@if not exist $(IMPDIR)\core\sys\windows                mkdir $(IMPDIR)\core\sys\windows
	@if not exist $(IMPDIR)\core\thread                     mkdir $(IMPDIR)\core\thread
	@if not exist $(IMPDIR)\etc\linux                       mkdir $(IMPDIR)\etc\linux

