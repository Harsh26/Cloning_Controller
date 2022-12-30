@echo off
if EXIST "%programfiles%\swipl" set mynewpath="%programfiles%\swipl\bin\swipl-win.exe"

if EXIST "%programfiles(x86)%\swipl" set mynewpath="%programfiles(x86)%\swipl\bin\swipl-win.exe"

%START "swipl" %mynewpath% -q -s "initialize.pl" -g main
%START "swipl" %mynewpath% -q -s "initialize.pl" -g main
 
set /a port = 0
:while1
	START "swipl" %mynewpath% -q -s "initialize.pl" -g main(%port%)

set /a port = %port% + 1
	
if %port% leq 3 goto :while1