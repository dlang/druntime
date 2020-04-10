@echo off
REM Called by wildtype.bat for each found file

set PATH=%~1

set TAB=    
:: Creating a Newline variable (the two blank lines are required!):
set \n=^


set NEWLINE=^^^%\n%%\n%^%\n%%\n%

cd %WORKING_DIR%

setlocal ENABLEDELAYEDEXPANSION
set STR=!TEXT:\t=%TAB%!
set STR=!STR:\n=%NEWLINE%!
set STR=!STR:__FILENAME__=%PATH%!
set STR=!STR:~%REMOVE_FIRST_NUM%!
echo !PREFIX!!STR! >> %DESTINATION%
endlocal
