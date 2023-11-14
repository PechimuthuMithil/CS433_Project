@echo off

REM Vajra EDR client installer script
REM Author: Arjun Sable, IEOR, IIT Bombay
REM Date: 2023-07-25

set scriptVersion=1.0.0.1
set "bits32=false"
set "LogFile=vajra_install_log.txt"
set "LockFile=install.lock"
set kServiceName=vajra
set kServiceDescription=Vajra EDR client service
set kServiceDisplayName=vajra
set kServiceBinaryPath="%ProgramFiles%\osquery\osqueryd\osqueryd.exe"
set welManifestPath="%ProgramFiles%\osquery\osquery.man"
set startupArgs=--flagfile="%ProgramFiles%\osquery\osquery.flags"
if exist "%LogFile%" del "%LogFile%"
if exist "%LockFile%" del "%LockFile%"
echo [+] Installing Vajra EDR client version %scriptVersion% on your system, an indegenously developed endpoint security system at Indian Institute of Technology, Bombay (an institute of national importance).
call :LogError INFO: Vajra EDR client installation script version %scriptVersion%
@REM ------------------------------------- Part 1 : Testing the system compatibility -------------------------------------
REM Check if lock file exists

if exist "%LockFile%" (
    echo [-] Installation is already in progress. Please wait... %LockFile%
    pause
    exit /b
)

REM Create the lock file
type nul > "%LockFile%"

@REM Check Admin privileges
echo [+] Verifying that script is running with Admin privileges.

:check_Permissions    
    net session >nul 2>&1 
    if %errorLevel% == 0 (
        echo [+] SUCCESS: Script running with Admin privileges! Proceeding with the installation.
        call :LogError SUCCESS: Script running with Admin privileges!
    ) else (
        echo [-] ERROR: Please run this script with Admin privileges! Right click on Filename and Run as Administrator.
        call :LogError ERROR: Script running without Admin privileges!
        call :removelock
        pause
        exit /b 1
    )

@REM Check Windows version
for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
if "%version%" == "10.0" set "windows_version=10"
if "%version%" == "6.3" set "windows_version=8.1"
if "%version%" == "6.2" set "windows_version=8"
if "%version%" == "6.1" set "windows_version=7"
if "%version%" == "6.0" set "windows_version=vista"
if "%version%" == "5.2" set "windows_version=XP64"
if "%version%" == "5.1" set "windows_version=XP"
if "%version%" == "5.0" set "windows_version=2000"
if "%version%" == "4.10" set "windows_version=98"

@REM Check architecture
reg Query "HKLM\Hardware\Description\System\CentralProcessor\0" | find /i "x86" > NUL 
if %errorlevel% equ 0 (
    set "architecture=32"
    set "bits32=true"
) else (
    set "architecture=64"
    set "bits32=false"
)
call :LogError INFO: Windows version %windows_version% and %architecture% bits

if not "%windows_version%" == "7" if not "%windows_version%" == "8" if not "%windows_version%" == "8.1" if not "%windows_version%" == "10" (
    echo [-] Vajra EDR client does not support current Windows version.
    echo [-] Vajra EDR client currently supports Windows 7, Windows 8, Windows 8.1, Windows 10 and Windows 11.
    echo [-] Aborting the installation process.
    call :LogError ERROR: Vajra client does not support %windows_version% and %architecture% bits
    call :removelock
    pause
    exit /b 1
) else (
    echo [+] Vajra EDR client supports the current Windows version %windows_version% and %architecture% bits.
    echo [+] Continuing the installation process.
)

GOTO :CheckVajraService

@REM 
:removelock
    if exist "%LockFile%" (
        del "%LockFile%"
    ) else (
        echo [-] File does not exist.
    )
    goto :eof

@REM Function to cleanup in case of installation failure
:cleanup
    @REM Delete files
    echo [+] Cleaning up Vajra EDR client installation files
    echo [+] Stopping the Vajra EDR service
    sc stop %kServiceName% >nul 2>> "%LogFile%"
    rmdir /s /q "%ProgramFiles%\osquery" >nul 2>> "%LogFile%"
    if %errorlevel% equ 0 (
        echo [+] Cleared Osquery installation directory !
    ) else (
        echo [-] Failed to clear all the installation directory !
    )
    
    rmdir /s /q "%ProgramFiles%\plgx_osquery\" >nul 2>> "%LogFile%"
    if %errorlevel% equ 0 (
        echo [+] Cleared Osquery extension installation directory !
    ) else (
        echo [-] Failed to clear all the installation directory !
    )
    @REM Remove service
    echo [+] Removing Vajra EDR client service

    sc delete %kServiceName% >nul 2>> "%LogFile%"
    call :removelock
    echo [+] Cleanup completed
    goto :eof

@REM Log error messages function
:LogError
    echo %* >> "%LogFile%"
    exit /b
    
@REM Check if Vajra service is already running
:CheckVajraService
    sc query %kServiceName% | findstr "RUNNING" >nul
    if %errorlevel% equ 0 (
        echo [-] ERROR: The Vajra EDR service is already running. Exiting...
        call :LogError ERROR: The Vajra service is already running
        call :removelock
        pause
        exit /b 1
    ) else (
        echo [+] The Vajra EDR service is not running. Proceeding with the installation...
        call :LogError SUCCESS: The Vajra service is does not exist
    )


@REM ----------------------- Part 2 : Installing the client -----------------------
:main
@REM Set the service variables

set OsquerydFilename=osqueryd.exe
set ExtnFilename=plgx_win_extension.ext.exe
set OsqueryFlagsFilename=osquery.flags
set OsqueryExtnLoadFilename=extensions.load
set OsqueryCertFilename=cert.pem
set OsqueryEnrollmentSecretFilename=enrollment_secret.txt
set OsqueryManifestFilename=osquery.man

echo [+] Creating installation directories 

@REM Create necessary directories
mkdir "%ProgramFiles%\osquery" >nul 2>> "%LogFile%"
mkdir "%ProgramFiles%\osquery\osqueryd" >nul 2>> "%LogFile%"
mkdir "%ProgramFiles%\osquery\packs" >nul 2>> "%LogFile%"
mkdir "%ProgramFiles%\osquery\log" >nul 2>> "%LogFile%"
mkdir "%ProgramFiles%\osquery\certs" >nul 2>> "%LogFile%"

@REM Copying executables and other files in the installation directory
echo [+] Copying executables and other files in the installation directory
setlocal enabledelayedexpansion
set "SourceFolder=%~dp0"
set "ProgramFilesFolder=%ProgramFiles%\osquery"
set "CertFolderName=%ProgramFiles%\osquery\certs"
set "OsquerydFolderName=%ProgramFiles%\osquery\osqueryd"

echo [+] Running python script
@REM Python script to enter the DNS entry in the host directory
python !SourceFolder!common\pseudoDNS.py
@REM Copying files for 64 bit OS
if "%bits32%"=="false" (
    set "ArchSubfolder=x64"
    set "FilesToCopy=%OsqueryFlagsFilename% %ExtnFilename% %OsqueryManifestFilename% %OsqueryExtnLoadFilename%"
) else (
    @REM Copying files for 32 bit OS
    set "ArchSubfolder=x86"
    set "FilesToCopy=%OsqueryFlagsFilename%"
)
@REM Copying common files
for %%F in (%FilesToCopy%) do (
    echo [+] Copying file from : !SourceFolder!%ArchSubfolder%\%%F to : %ProgramFilesFolder%\%%F"
    copy /Y "!SourceFolder!%ArchSubfolder%\%%F" "%ProgramFilesFolder%\%%F" >nul 2>> "%LogFile%"
)

@REM %OsqueryPackFile1% %OsqueryPackFile2% %OsqueryPackFile3% %OsqueryPackFile4% %OsqueryPackFile5% %OsqueryPackFile6% %OsqueryPackFile7% %OsqueryPackFile8% %OsqueryPackFile9% %OsqueryPackFile10%
for %%F in (%OsqueryEnrollmentSecretFilename% %OsqueryCertFilename%) do (
    echo [+] Copying file from : !SourceFolder!common\%%F to : %ProgramFilesFolder%\%%F"
    copy /Y "!SourceFolder!common\%%F" "%ProgramFilesFolder%\%%F" >nul 2>> "%LogFile%"
)

@REM Copying osqueryd executable file 
echo [+] Copying file from : %SourceFolder%%ArchSubfolder%\%OsquerydFilename% to : %OsquerydFolderName%\%OsquerydFilename%"
copy /Y "%SourceFolder%%ArchSubfolder%\%OsquerydFilename%" "%OsquerydFolderName%\%OsquerydFilename%" >nul 2>> "%LogFile%"

@REM Copying SSL certificate file
echo [+] Copying file from : %SourceFolder%common\%OsqueryCertFilename% to : %CertFolderName%\%OsqueryCertFilename%"
copy /Y "%SourceFolder%common\%OsqueryCertFilename%" "%CertFolderName%\%OsqueryCertFilename%" >nul 2>> "%LogFile%"

echo [+] All files copied successfully!

@REM Creating the service
echo [+] Creating Vajra EDR client service

@REM Creating the service
sc create %kServiceName% binPath= "\"C:\Program Files\osquery\osqueryd\osqueryd.exe\" \"--flagfile\" \"C:\Program Files\osquery\osquery.flags\" \"--allow_unsafe\"" start= auto DisplayName= %kServiceDisplayName% >nul 2>> "%LogFile%"
if %errorlevel% equ 0 (
    echo [+] Vajra EDR client service started successful !
) else (
    echo [-] Failed to start Vajra EDR service!
    call :cleanup

)
@REM Starting the service
sc start %kServiceName% >nul 2>> "%LogFile%"

@REM sc create osqueryd binPath= "C:\Program Files\osquery\osqueryd\osqueryd.exe" --flagfile="C:\Program Files\osquery\osquery.flags" start= auto DisplayName= osqueryd description= osquery daemon service

REM Check if the service was created successfully
if %errorlevel% equ 0 (
    echo [+] Vajra EDR client installation successful !
) else (
    echo [-] Vajra EDR client installation failed !
    call :cleanup
)

@REM Removing the Lock file
del "%LockFile%"
pause