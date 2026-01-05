cd %~dp0
if not exist .git (if not exist ../.git (git init))
git clean -dXXf
call ..\flutter.git\bin\flutter create . --platforms=windows  --local-engine=host_debug --local-engine-host=host_debug
call ..\flutter.git\bin\flutter run --local-engine=host_debug --local-engine-host=host_debug
