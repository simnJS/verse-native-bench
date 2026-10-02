@echo off
rem Runs Verse through WSL on the new VerseVM and/or the BPVM. See tools\verse-run.sh.
rem Backslashes become slashes: the WSL shell would otherwise read them as escapes.
setlocal
set "ARGS=%*"
if defined ARGS set "ARGS=%ARGS:\=/%"
set "SCRIPT=%~dp0tools\verse-run.sh"
set "SCRIPT=%SCRIPT:\=/%"
wsl.exe -d Ubuntu-24.04 -- bash "$(wslpath '%SCRIPT%')" %ARGS%
