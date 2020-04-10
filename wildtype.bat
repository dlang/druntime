@echo off
REM Generates makefile sequences for Digital Mars make.exe (it doesn't supports wildcards by itself)

set TEXT=%~1
set PATH=%2
set MASK=%3
set DESTINATION=%~4
set REMOVE_FIRST_NUM=%5
set PREFIX=%~6

set WORKING_DIR=%cd%
set ROUTINE=%cd%\wroutine.bat

C:\Windows\System32\forfiles.exe /p %PATH% /m %MASK% /s /c "cmd /c %ROUTINE% @RELPATH"

echo. >> %DESTINATION%
