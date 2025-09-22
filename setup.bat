@echo off
setlocal enabledelayedexpansion

echo Ensure WinGet is available
set "WINGET=%LOCALAPPDATA%\Microsoft\WindowsApps\winget.exe"
if not exist "%WINGET%" (
    echo Installing WinGet...
    call powershell -Command "irm asheroto.com/winget | iex"
) else (
    echo WinGet is already installed.
)

echo Ensure Git is available
for /f "usebackq tokens=*" %%i in (`where git`) do set "WHERE_GIT=%%i"
set "GIT=%PROGRAMFILES%\Git\bin\git.exe"
if not defined WHERE_GIT (
    if not exist "%GIT%" (
        echo Installing Git...
        call "%WINGET%" install --source=winget "Git.Git"
    ) else (
        echo Git found at %GIT%
    )
) else (
    set "GIT=%WHERE_GIT%"
    echo Git found at %GIT%
)

echo Enable long paths support
call reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem" /f /v "LongPathsEnabled" /t REG_DWORD /d "1"

echo Ensure Visual Studio Locator is available
set "VSWHERE=%LOCALAPPDATA%\Microsoft\WinGet\Links\vswhere.exe"
if not exist "%VSWHERE%" (
    echo Installing Visual Studio Locator...
    call "%WINGET%" install --source=winget Microsoft.VisualStudio.Locator
) else (
    echo Visual Studio Locator found at %VSWHERE%.
)

echo Ensure Visual Studio with Native Desktop workload is available
for /f "usebackq tokens=*" %%i in (`"%VSWHERE%" -latest -requires Microsoft.VisualStudio.Workload.NativeDesktop -property installationPath`) do set "VSPATH=%%i"
if not defined VSPATH (
    for /f "usebackq tokens=*" %%i in (`"%VSWHERE%" -latest -property installationPath`) do set "VSPATH=%%i"
    if not defined VSPATH (
        echo Installing Visual Studio 2022 Community Edition with Native Desktop workload...
        call "%WINGET%" uninstall --source=winget "Microsoft.VisualStudio.2022.Community"
        call "%WINGET%" install --source=winget "Microsoft.VisualStudio.2022.Community" --override "--wait --quiet --add Microsoft.VisualStudio.Workload.NativeDesktop --includeRecommended --includeOptional --norestart"
    ) else (
        echo Visual Studio found at %VSPATH%
        echo Adding Native Desktop workload...
        set "VSINSTALLER=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vs_installer.exe"
        call "%VSINSTALLER%" modify --installPath "%VSPATH%" --quiet --norestart --add Microsoft.VisualStudio.Workload.NativeDesktop --includeRecommended --includeOptional
    )
) else (
    echo Visual Studio with Native Desktop workload is already installed at %VSPATH%.
)

echo Ensure 7zip is available
for /f "usebackq tokens=*" %%i in (`where 7z`) do set "WHERE_SEVENZIP=%%i"
set "SEVENZIP=%ProgramFiles%\7-Zip\7z.exe"
if not defined WHERE_SEVENZIP (
    if not exist "%SEVENZIP%" (
        echo Installing 7zip...
        call "%WINGET%" install --source=winget "7zip.7zip"
    ) else (
        echo 7zip found at %SEVENZIP%
    )
) else (
    set "SEVENZIP=%WHERE_SEVENZIP%"
    echo 7zip found at %SEVENZIP%
)
