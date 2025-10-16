@echo off
REM Windows CMD batch script to extract custom trusted SSL root certificates (non-Microsoft, non-expired) to custom_roots folder
REM see https://aka.ms/trustcertpartners
 
cd %~dp0
powershell -NoProfile -Command ^
    "$msRootsUrl = 'https://ccadb.my.salesforce-sites.com/microsoft/IncludedCACertificateReportForMSFTCSV'; " ^
    "$customRootsDir = 'custom_roots'; " ^
    "Remove-Item -Recurse -Force $customRootsDir -ErrorAction SilentlyContinue; " ^
    "$csvContent = Invoke-WebRequest -Uri $msRootsUrl | Select-Object -ExpandProperty Content; " ^
    "$msThumbprints = $csvContent | ConvertFrom-Csv | ForEach-Object { ($_.\"SHA-1 Fingerprint\" -replace ' ', '').ToUpper() }; " ^
    "New-Item -ItemType Directory -Path $customRootsDir -Force | Out-Null; " ^
    "Get-ChildItem -Path Cert:\LocalMachine\Root | ForEach-Object { " ^
    "    $thumb = $_.Thumbprint.ToUpper(); " ^
    "    $notExpired = $_.NotAfter -gt (Get-Date); " ^
    "    if ($msThumbprints -notcontains $thumb -and $notExpired) { " ^
    "        $subject = $_.Subject -replace '[^a-zA-Z0-9]', '_'; " ^
    "        $certPath = Join-Path $customRootsDir ($subject + '.cer'); " ^
    "        Export-Certificate -Cert $_ -FilePath $certPath | Out-Null; " ^
    "    } " ^
    "}; " ^
    "Write-Output 'Custom trusted root certificates exported to $customRootsDir.'"

