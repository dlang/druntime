REM Recursively called by wildtype.bat for each found file
@echo off

set TEXT=%~1
set PATH=%~2
set DESTINATION=%~3
set REMOVE_FIRST_NUM=%4
set PREFIX=%~5
set WORKING_DIR=%6

set TAB=    
:: Creating a Newline variable (the two blank lines are required!):
set \n=^


set NEWLINE=^^^%\n%%\n%^%\n%%\n%

cd %WORKING_DIR%
::echo filename: %PATH%

setlocal ENABLEDELAYEDEXPANSION
set STR=!TEXT:\t=%TAB%!
set STR=!STR:\n=%NEWLINE%!
set STR=!STR:__FILENAME__=%PATH%!
set STR=!STR:~%REMOVE_FIRST_NUM%!
echo !PREFIX!!STR! >> %DESTINATION%
endlocal
