REM Generates makefile sequences for Digital Mars make.exe (it isn't supports wildcards by itself)
@echo off

set TEXT=%~1
set PATH=%2
set MASK=%3
set DESTINATION=%~4
set REMOVE_FIRST_NUM=%5
set PREFIX=%~6

set CURR_DIR=%cd%
set ROUTINE=%cd%\wroutine.bat

C:\Windows\System32\forfiles.exe /p %PATH% /m %MASK% /s /c "cmd /c %ROUTINE% \"%TEXT%\" @RELPATH \"%DESTINATION%\" %REMOVE_FIRST_NUM% \"%PREFIX%\" \"%CURR_DIR%\""

echo. >> %DESTINATION%
