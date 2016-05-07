@echo off

set SHARE="\\bignas.home\windows_iso$"

net use z: %SHARE%

z:\run.bat
