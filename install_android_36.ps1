$javaHome = "C:\Program Files\Microsoft\jdk-17.0.20.101-hotspot"
$env:JAVA_HOME = $javaHome
$env:Path = "$javaHome\bin;C:\src\flutter\bin;" + $env:Path

$sdkDir = "C:\Android\Sdk"
$sdkManager = "$sdkDir\cmdline-tools\latest\bin\sdkmanager.bat"

Write-Host "Installing platforms;android-36 and build-tools..."
cmd.exe /c "echo y | `"$sdkManager`" --sdk_root=`"$sdkDir`" `"platforms;android-36`" `"build-tools;36.0.0`" `"build-tools;34.0.0`" `"build-tools;28.0.3`""

Write-Host "Accepting all licenses..."
cmd.exe /c "echo y | cmd.exe /c `"echo y | C:\src\flutter\bin\flutter.bat doctor --android-licenses`""

Write-Host "Running flutter doctor..."
& "C:\src\flutter\bin\flutter.bat" doctor
