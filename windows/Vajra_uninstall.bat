@echo off

REM Vajra EDR client installer script
REM Author: Arjun Sable, IEOR, IIT Bombay
REM Date: 2023-07-25

set scriptVersion=1.0.0.1
set "bits32=false"
set "LogFile=vajra_uninstall_log.txt"
set "LockFile=install.lock"
set kServiceName=vajra
set kServiceDescription=Vajra EDR client service
set kServiceDisplayName=vajra
if exist "%LogFile%" del "%LogFile%"
if exist "%LockFile%" del "%LockFile%"

echo [+] Cleaning up Vajra EDR client installation files

echo [+] Checking if Vajra EDR client is installed

if exist "%LockFile%" (
    echo [-] Uninstall process is already in progress. Please wait... %LockFile%
    pause
    exit /b
)

REM Create the lock file
type nul > "%LockFile%"

sc query %kServiceName% | findstr /C:"SERVICE_NAME: %kServiceName%" >nul
if %errorlevel% neq 0 (
    echo [-] The Vajra EDR service does not exist
    echo [-] The Vajra EDR service does not exist
    echo [-] Exiting
    pause
    exit /b 1
)

echo [+] The Vajra EDR service exists. Proceeding to uninstall

echo [+] Stopping the Vajra EDR service

sc stop %kServiceName% >nul 2>> "%LogFile%"

echo [+] Removing DNS entry

python %~dp0common\delete_entry.py

echo [+] Removing "%ProgramFiles%\osquery" files

rmdir /s /q "%ProgramFiles%\osquery" >nul 2>> "%LogFile%"
if %errorlevel% equ 0 (
    echo [+] Cleared all the installation directories
) else (
    echo [-] Failed to clear all the installation directories
)
echo [+] Removing "%ProgramFiles%\plgx_osquery\" files

rmdir /s /q "%ProgramFiles%\plgx_osquery\" >nul 2>> "%LogFile%"

@REM Remove service
echo [+] Removing Vajra EDR client service

sc delete %kServiceName% >nul 2>> "%LogFile%"

@REM Removing lock file
if exist "%LockFile%" (
    del "%LockFile%"
) else (
    echo [-] File does not exist.
)
echo [+] Cleanup completed

echo [+] Vajra EDR is successfully removed
pause 