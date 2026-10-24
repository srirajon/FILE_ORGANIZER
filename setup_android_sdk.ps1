$sdkDir = "C:\Android\Sdk"
$toolsDir = "$sdkDir\cmdline-tools\latest"
$zipPath = "C:\Android\cmdline-tools.zip"

Write-Host "1. Creating directories..."
New-Item -ItemType Directory -Path "C:\Android" -Force | Out-Null
New-Item -ItemType Directory -Path "$sdkDir\cmdline-tools" -Force | Out-Null

Write-Host "2. Downloading Android Command-Line Tools (~146MB)..."
curl.exe -L -o $zipPath https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip

Write-Host "3. Extracting Command-Line Tools..."
$tempExtract = "C:\Android\temp_tools"
if (Test-Path $tempExtract) { Remove-Item -Recurse -Force $tempExtract }
Expand-Archive -Path $zipPath -DestinationPath $tempExtract -Force

if (Test-Path $toolsDir) { Remove-Item -Recurse -Force $toolsDir }
Move-Item -Path "$tempExtract\cmdline-tools" -Destination $toolsDir
Remove-Item -Recurse -Force $tempExtract
Remove-Item -Force $zipPath

Write-Host "4. Setting Environment Variables..."
[Environment]::SetEnvironmentVariable("ANDROID_HOME", $sdkDir, "User")
$env:ANDROID_HOME = $sdkDir
$env:Path += ";$toolsDir\bin;$sdkDir\platform-tools"

Write-Host "5. Configuring Flutter Android SDK..."
& "C:\src\flutter\bin\flutter.bat" config --android-sdk $sdkDir

Write-Host "6. Installing platforms and build tools..."
$sdkManager = "$toolsDir\bin\sdkmanager.bat"
$javaExe = (Get-Command java).Source
Write-Host "Using Java: $javaExe"

# Accept licenses and install platform tools
$installCmd = "echo y | `"$sdkManager`" `"platform-tools`" `"platforms;android-34`" `"build-tools;34.0.0`""
cmd.exe /c $installCmd

Write-Host "7. Accepting Flutter Android Licenses..."
cmd.exe /c "echo y | C:\src\flutter\bin\flutter.bat doctor --android-licenses"

Write-Host "Setup Completed!"
