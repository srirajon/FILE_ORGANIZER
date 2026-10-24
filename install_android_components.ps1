$javaHome = "C:\Program Files\Microsoft\jdk-17.0.20.101-hotspot"
$env:JAVA_HOME = $javaHome
$env:Path = "$javaHome\bin;" + $env:Path

$sdkDir = "C:\Android\Sdk"
$sdkManager = "$sdkDir\cmdline-tools\latest\bin\sdkmanager.bat"

# Create licenses directory
$licenseDir = "$sdkDir\licenses"
New-Item -ItemType Directory -Path $licenseDir -Force | Out-Null

# Write standard accepted licenses
$androidLicenses = @"
8933bad161af4178b1185d1a37fbf41ea5269c55
d56f5187479451eabf01fb78af6dfcb131a6481e
24333f8a63b1d973057902287a94944b9b045479
"@
Set-Content -Path "$licenseDir\android-sdk-license" -Value $androidLicenses -Encoding Ascii

$previewLicense = @"
84831b9409646a918e30573bab4c9c91346d8abd
"@
Set-Content -Path "$licenseDir\android-sdk-preview-license" -Value $previewLicense -Encoding Ascii

Write-Host "Licenses pre-accepted. Installing platform-tools, platforms;android-34, build-tools;34.0.0..."
& "$sdkManager" --sdk_root="$sdkDir" "platform-tools" "platforms;android-34" "build-tools;34.0.0"

Write-Host "Configuring Flutter..."
& "C:\src\flutter\bin\flutter.bat" config --android-sdk $sdkDir

Write-Host "Running flutter doctor..."
& "C:\src\flutter\bin\flutter.bat" doctor
