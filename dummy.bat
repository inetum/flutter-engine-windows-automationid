mkdir .\out
echo TEST > out\test.txt
mkdir .\archive
powershell -Command "Compress-Archive -Force -DestinationPath '.\archive\flutter-%FLUTTER_VERSION%-engine-windows-automationid-x64.zip' -Path .\out"
