@echo off
setlocal enabledelayedexpansion

set "FLUTTER_VERSION=3.37.0-0.1.pre"
set "FLUTTER_PR=175405,175406"

echo Configure git
call git config --global core.autocrlf false || exit /b 1
call git config --global core.filemode false || exit /b 1
call git config --global core.longpaths true || exit /b 1
call git config --global core.symlinks true || exit /b 1
call git config --global core.fscache true || exit /b 1
call git config --global core.preloadindex true || exit /b 1

echo Install Chromium depot_tools
:: https://commondatastorage.googleapis.com/chrome-infra-docs/flat/depot_tools/docs/html/depot_tools_tutorial.html#_setting_up
set "DEPOT_TOOLS_DIR=%CD%\depot_tools"
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
set "FLUTTER_DIR=%CD%\flutter"
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
call gclient sync -D || exit /b 1
popd
)

for %%p in (%FLUTTER_PR%) do (
echo Get Flutter PR patch https://github.com/flutter/flutter/pull/%%p
set "PATCHFILE=%CD%\flutter-PR%%p.patch"
echo Downloading patch to !PATCHFILE!
call curl.exe -s -# -L -o "!PATCHFILE!" "https://github.com/flutter/flutter/pull/%%p.patch" || exit /b 1
echo Patch downloaded to !PATCHFILE!
call git -C "%FLUTTER_DIR%" apply --reject "!PATCHFILE!" || exit /b 1
)

echo Compile Flutter Engine
:: https://github.com/flutter/flutter/blob/master/engine/src/flutter/docs/contributing/Compiling-the-engine.md#compiling-for-windows
pushd "%FLUTTER_DIR%\engine\src"
call python3 ./flutter/tools/gn --runtime-mode debug --no-lto --no-enable-unittests || exit /b 1
call ninja -C ./out/host_release || exit /b 1
call python3 ./flutter/tools/gn --runtime-mode profile --lto --no-enable-unittests || exit /b 1
call ninja -C ./out/host_release || exit /b 1
call python3 ./flutter/tools/gn --runtime-mode release --lto --no-enable-unittests || exit /b 1
call ninja -C ./out/host_release || exit /b 1
popd

@REM echo Archive Flutter Engine
@REM set "ARCHIVE_NAME=flutter-%FLUTTER_VERSION%-engine-PR%FLUTTER_PR%-x64.zip"
:: PowerShell Compress-Archive is too slow, use 7-Zip instead
:: call powershell -Command "Compress-Archive -Force -DestinationPath '%USERPROFILE%\Downloads\flutter-%FLUTTER_VERSION%-engine-windows-automationid-x64.zip' -Path '%FLUTTER_DIR%\engine\src\out'"
@REM call "C:\Program Files\7-Zip\7z.exe" a -Tzip "%CD%\%ARCHIVE_NAME%" "%FLUTTER_DIR%\engine\src\out" || exit /b 1

:eof
endlocal
exit /b 0
