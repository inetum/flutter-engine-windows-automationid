@echo off
setlocal enabledelayedexpansion

set "FLUTTER_VERSION=%~1"
if "%FLUTTER_VERSION%"=="" set "FLUTTER_VERSION=master"
set "FLUTTER_PR=%~2"

echo Configure git
call git config --global core.autocrlf false || exit /b 1
call git config --global core.filemode false || exit /b 1
call git config --global core.longpaths true || exit /b 1
call git config --global core.symlinks true || exit /b 1
call git config --global core.fscache true || exit /b 1
call git config --global core.preloadindex true || exit /b 1

echo Install Chromium depot_tools
:: https://commondatastorage.googleapis.com/chrome-infra-docs/flat/depot_tools/docs/html/depot_tools_tutorial.html#_setting_up
set "DEPOT_TOOLS_DIR=%CD%\depot_tools.git"
if not exist "%DEPOT_TOOLS_DIR%" (
    call git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git "%DEPOT_TOOLS_DIR%" || exit /b 1
)
set "PATH=%DEPOT_TOOLS_DIR%;%PATH%"

echo Configure depot_tools for Windows
set "DEPOT_TOOLS_WIN_TOOLCHAIN=0"
set "VSWHERE=C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe"
for /f "usebackq tokens=*" %%i in (`"%VSWHERE%" -latest -requires Microsoft.VisualStudio.Workload.NativeDesktop -property installationPath`) do set "GYP_MSVS_OVERRIDE_PATH=%%i"
set "WINDOWSSDKDIR=C:\Program Files (x86)\Windows Kits\10"

echo Get Flutter source
:: https://github.com/flutter/flutter/blob/master/engine/src/flutter/docs/contributing/Setting-up-the-Engine-development-environment.md
set "FLUTTER_DIR=%CD%\flutter.git"
if not exist "%FLUTTER_DIR%" (
    call git clone https://github.com/flutter/flutter.git "%FLUTTER_DIR%" || exit /b 1
    call git -C "%FLUTTER_DIR%" remote rename origin upstream || exit /b 1
)
set "PATH=%FLUTTER_DIR%\bin;%PATH%"
set "PATH=%FLUTTER_DIR%\engine\src\flutter\bin;%PATH%"

if defined FLUTTER_VERSION (
echo Set target Flutter version
pushd "%FLUTTER_DIR%" || exit /b 1
call git pull
call git checkout %FLUTTER_VERSION%
call git reset --hard %FLUTTER_VERSION% || exit /b 1
copy /y engine\scripts\standard.gclient .gclient || exit /b 1
popd
)

if not defined NO_GCLIENT_SYNC (
pushd "%FLUTTER_DIR%" || exit /b 1
call gclient sync -D || exit /b 1
popd
)

set "FLUTTER_PR_LIST=%FLUTTER_PR%"
for %%p in (%FLUTTER_PR_LIST:.= %) do (
echo Get Flutter PR patch https://github.com/flutter/flutter/pull/%%p
set "PATCHFILE=%CD%\flutter-PR%%p.patch"
echo Downloading patch to !PATCHFILE!
call powershell -Command "Invoke-WebRequest -Uri 'https://github.com/flutter/flutter/pull/%%p.patch' -OutFile '!PATCHFILE!'" || exit /b 1
echo Patch downloaded to !PATCHFILE!
call git -C "%FLUTTER_DIR%" apply --reject "!PATCHFILE!" || exit /b 1
)

echo Compile Flutter Engine
:: https://github.com/flutter/flutter/blob/master/engine/src/flutter/docs/contributing/Compiling-the-engine.md#compiling-for-windows
pushd "%FLUTTER_DIR%\engine\src"
call python3 ./flutter/tools/gn --runtime-mode debug --no-lto --no-enable-unittests || exit /b 1
call ninja -C ./out/host_debug || exit /b 1
if not defined DEBUG_ONLY (
call python3 ./flutter/tools/gn --runtime-mode profile --lto --no-enable-unittests || exit /b 1
call ninja -C ./out/host_profile || exit /b 1
call python3 ./flutter/tools/gn --runtime-mode release --lto --no-enable-unittests || exit /b 1
call ninja -C ./out/host_release || exit /b 1
)
popd

mkdir flutter\bin\cache\artifacts\engine\windows-x64 || exit /b 1
copy /y "%FLUTTER_DIR%\engine\src\out\host_debug\flutter_windows.dll*" "flutter\bin\cache\artifacts\engine\windows-x64" || exit /b 1
if not defined DEBUG_ONLY (
mkdir flutter\bin\cache\artifacts\engine\windows-x64-release || exit /b 1
copy /y "%FLUTTER_DIR%\engine\src\out\host_release\flutter_windows.dll*" "flutter\bin\cache\artifacts\engine\windows-x64-release" || exit /b 1
mkdir flutter\bin\cache\artifacts\engine\windows-x64-profile || exit /b 1
copy /y "%FLUTTER_DIR%\engine\src\out\host_profile\flutter_windows.dll*" "flutter\bin\cache\artifacts\engine\windows-x64-profile" || exit /b 1
)
powershell -Command "Compress-Archive -Path flutter -DestinationPath flutter_windows_%FLUTTER_VERSION%_PR%FLUTTER_PR%.zip" || exit /b 1

:eof
endlocal
exit /b 0
