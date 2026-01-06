@echo off
set "FLUTTER_DIR=%CD%\flutter.git"
set "PATH=%FLUTTER_DIR%\bin;%PATH%"
set "TARGET_DIR=%CD%\test"
set "SOURCE_DIR=%~dp0\test"
if not exist %TARGET_DIR%\lib (mkdir %TARGET_DIR%\lib)
pushd %TARGET_DIR% || exit /b 1
call flutter create . --platforms=windows --local-engine=host_debug --local-engine-host=host_debug
copy %SOURCE_DIR%\lib\main.dart %TARGET_DIR%\lib\main.dart
call flutter clean
call flutter run --local-engine=host_debug --local-engine-host=host_debug
popd
