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

set "VS_PACKAGE_ID=Microsoft.VisualStudio.Community"
set "VS_PACKAGE_TEXT=Visual Studio Community Edition"
set "VS_WORKLOAD_ID=Microsoft.VisualStudio.Workload.NativeDesktop"
set "VS_WORKLOAD_TEXT=Desktop development with C++"
echo Ensure Visual Studio with %VS_WORKLOAD_TEXT% workload is available
for /f "usebackq tokens=*" %%i in (`"%VSWHERE%" -latest -requires %VS_WORKLOAD_ID% -property installationPath`) do set "VSPATH=%%i"
if not defined VSPATH (
    for /f "usebackq tokens=*" %%i in (`"%VSWHERE%" -latest -property installationPath`) do set "VSPATH=%%i"
    if not defined VSPATH (
        echo Installing %VS_PACKAGE_TEXT% with %VS_WORKLOAD_TEXT% workload...
        call "%WINGET%" install --source=winget "%VS_PACKAGE_ID%" --override "--wait --quiet --add %VS_WORKLOAD_ID% --includeRecommended --norestart"
    ) else (
        for /f "usebackq tokens=*" %%i in (`"%VSWHERE%" -latest -property displayName`) do set "VSDISPLAY=%%i"
        echo !VSDISPLAY! found at !VSPATH!
        for /f "usebackq tokens=*" %%i in (`"%VSWHERE%" -latest -property productId`) do set "VSPRODUCTID=%%i"
        echo Adding %VS_WORKLOAD_TEXT% workload...
        for /f "usebackq tokens=*" %%i in (`"%VSWHERE%" -latest -property setupEngineFilePath`) do set "VSINSTALLER=%%i"
        call "!VSINSTALLER!" modify --installPath "!VSPATH!" --quiet --norestart --add !VS_WORKLOAD_ID! --includeRecommended
    )
) else (
    echo Visual Studio with %VS_WORKLOAD_TEXT% workload is already installed at %VSPATH%.
)
