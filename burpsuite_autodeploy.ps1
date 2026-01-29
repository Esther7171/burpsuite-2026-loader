# ==========================================
# Burp Suite Automated Setup Script (CLEAN)
# Author: CERT Research Use
# ==========================================

# Speed up downloads
Write-Host "Setting download progress to silent mode..."
$ProgressPreference = 'SilentlyContinue'

# ------------------------------------------
# Paths
# ------------------------------------------
$baseDir   = "$env:USERPROFILE\BurpSuite"
$burpJar   = "$baseDir\burpsuite.jar"
$batFile   = "$baseDir\Burp.bat"
$vbsFile   = "$baseDir\Burp-Silent.vbs"
$deskLink  = "$([Environment]::GetFolderPath('Desktop'))\BurpSuite.lnk"

New-Item -ItemType Directory -Path $baseDir -Force | Out-Null

# ------------------------------------------
# Java JDK 21 Check / Install
# ------------------------------------------
if (-not (Get-Command java -ErrorAction SilentlyContinue)) {
    Write-Host "`nDownloading Java JDK 21..."
    $jdkInstaller = "$env:TEMP\jdk21.exe"

    Invoke-WebRequest `
        -Uri "https://download.oracle.com/java/21/latest/jdk-21_windows-x64_bin.exe" `
        -OutFile $jdkInstaller

    Write-Host "Installing Java JDK 21..."
    Start-Process $jdkInstaller "/s" -Wait
    Remove-Item $jdkInstaller -Force
}
else {
    Write-Host "`nJava already installed:"
    java -version
}

# ------------------------------------------
# Reload Environment Variables
# ------------------------------------------
Write-Host "`nReloading environment variables..."
$env:Path = `
    [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" +
    [System.Environment]::GetEnvironmentVariable("Path","User")

# ------------------------------------------
# Download Latest Burp Suite (Official)
# ------------------------------------------
Write-Host "`nDownloading Burp Suite (Official Latest)..."

Invoke-WebRequest `
    -Uri "https://portswigger.net/burp/releases/download?product=pro&type=Jar" `
    -OutFile $burpJar

# ------------------------------------------
# Create BAT Launcher
# ------------------------------------------
$batContent = @"
@echo off
cd /d "%~dp0"
java -jar "burpsuite.jar"
"@

Set-Content -Path $batFile -Value $batContent -Encoding ASCII
Write-Host "Burp.bat created."

# ------------------------------------------
# Create Silent VBS Launcher
# ------------------------------------------
$vbsContent = @"
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run chr(34) & "$batFile" & Chr(34), 0
Set WshShell = Nothing
"@

Set-Content -Path $vbsFile -Value $vbsContent
Write-Host "Silent VBS launcher created."

# ------------------------------------------
# Create Desktop Shortcut
# ------------------------------------------
$WshShell = New-Object -ComObject WScript.Shell
$shortcut = $WshShell.CreateShortcut($deskLink)

$shortcut.TargetPath = $vbsFile
$shortcut.WorkingDirectory = $baseDir
$shortcut.WindowStyle = 1
$shortcut.Description = "Burp Suite Launcher"

# Optional icon (uncomment if you have one)
# $shortcut.IconLocation = "$baseDir\burp.ico"

$shortcut.Save()
Write-Host "Desktop shortcut created."

# ------------------------------------------
# Launch Burp Suite
# ------------------------------------------
Write-Host "`nLaunching Burp Suite..."
Start-Process $vbsFile
