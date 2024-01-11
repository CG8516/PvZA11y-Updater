#Requires -Version 3.0
param([string]$preDir = "", [string]$hasZip = "0")

function SafeQuit {
    # Pause and prompt user to press any key to exit
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    exit
}

function RunAsAdmin() {
    param (
        [string]$dir = "",
        [string]$didDownload = "0",
	[string]$errorMsg = ""
    )
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "Requesting elevation..."
        try {
            Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.PSCommandPath)`" `"$dir`" $didDownload" -Verb RunAs
            exit
        } catch {
            Write-Host "Failed to obtain administrator privileges!"
            SafeQuit
        }
    }
    Write-Host $errorMsg
    SafeQuit
}

$browserDownloadUrl = ""
try {
    if($hasZip -eq "0") {
        # Fetch the releases API URL
        $releasesUrl = "https://api.github.com/repos/CG8516/PvZA11y/releases"
        $releasesInfo = Invoke-RestMethod -Uri $releasesUrl

        # Get the first browser_download_url from the assets
        $browserDownloadUrl = $releasesInfo[0].assets[0].browser_download_url
    }
} catch {
    Write-Host "Failed to obtain latest release information! Check your internet connection and try again."
    SafeQuit
}

# Prompt the user to enter the destination folder path
$destination = $preDir
if($preDir -eq "") {
    $destination = Read-Host "Enter the destination folder path, or leave blank to use current directory"
}

if($destination -eq "") {
    $destination = $pwd
}

# Create the full path for the downloaded file
$fileDownloadPath = Join-Path $destination "PvZA11y_.zip"

try {
    md -Force $destination
} catch {
    RunAsAdmin $destination "0" "Failed to create specified directory!"
}

# Download the file directly
try {
    if($hasZip -eq "0") {
        Invoke-WebRequest -Uri $browserDownloadUrl -OutFile $fileDownloadPath
    }
} catch {
    RunAsAdmin $destination "0" "Failed to download the latest zip! Please check your internet connection and try again."
}

# Check if the file was downloaded successfully
if (Test-Path $fileDownloadPath) {
    # Extract the ZIP file
    try {
        # If running as admin, ensure user has permission to write to files within the folder
        if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            # Grant permission to folder and permBackup.txt, then save all permissions to permBackup.txt, then grant full access to all files in directory, then extract, then restore permissions
            & icacls $destination /grant "$($env:UserName):(f)"
            & icacls "$destination\permBackup.txt" /grant "$($env:UserName):(f)"
            & icacls $destination /save "$destination\permBackup.txt" /t /c
            & icacls $destination /grant "$($env:UserName):(f)" /t /c
            Expand-Archive -Path $fileDownloadPath -DestinationPath $destination -Force -ErrorAction Stop
            $parentDir = Split-Path -Path $destination -Parent
            & icacls $parentDir /restore "$destination\permBackup.txt" /t /c
        } else {
            Expand-Archive -Path $fileDownloadPath -DestinationPath $destination -Force -ErrorAction Stop
        }
    } catch {
        RunAsAdmin $destination "1" "Failed to extract zip! Please ensure you have permission to write to the specified folder"
    }

    # Display a message indicating that the mod has been updated
    Write-Host "The mod has been updated successfully!"
} else {
    Write-Host "Failed to download the file. Please check your internet connection and try again."
}

SafeQuit
