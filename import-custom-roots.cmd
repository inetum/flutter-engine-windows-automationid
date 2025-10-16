@echo off
REM Windows CMD batch script to import all .cer files from custom_roots into Local Machine Root store

cd %~dp0
powershell -NoProfile -Command "Get-ChildItem -Path custom_roots -Filter *.cer | ForEach-Object { Import-Certificate -FilePath $_.FullName -CertStoreLocation Cert:\LocalMachine\Root | Out-Null }"
