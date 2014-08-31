@echo off
set PATH=%PATH%;%Systemdrive%\Tcl\bin
set CMD=tclsh

where %CMD% 1>NUL 2>NUL
if %ERRORLEVEL% neq 0 (
echo 0.0
) else echo puts $tcl_version;exit 0 | %CMD% 2>NUL
