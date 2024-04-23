Set-ExecutionPolicy RemoteSigned

# Uncomment next line for testing
# $WhatIfPreference = $True

# Test if Temp exists create if it doesn't
$tempPath = Test-Path -Path "C:\Temp"
$TestChromeInstalled = Test-Path -Path "C:\Program Files\Google\Chrome"
$TestDriveInstalled = Test-Path -Path "C:\Program Files\Google\Drive File Stream"
$TestGCPWInstalled = Test-Path -Path "C:\Program Files\Google\Credential Provider"
$TestNableInstalled = Test-Path -Path "C:\Program Files (x86)\N-able Technologies\Windows Agent"
$TestSymantecInstalled = Test-Path -Path "C:\Program Files\Symantec\Symantec Endpoint Protection"

# Test if C:\Temp exists, create if no
if($tempPath) {
    write-output "`nTemp already exists`n" -ForegroundColor Green
    if (Test-Path -Path "C:\Temp\ChromeInstaller.exe") {
        $downloadChrome = $False
    } else { $downloadChrome = $True }
    if (Test-Path -Path "C:\Temp\gcpwstandaloneenterprise64.msi") {
        $downloadGCPW = $False
    } else { $downloadGCPW = $True }
    if (Test-Path -Path "C:\Temp\GoogleDriveSetup.exe") {
        $downloadDrive = $False
    } else { $downloadDrive = $True }
    if ($downloadChrome -and $downloadGCPW -and $downloadDrive) {
        $download = $true
    } else {
        $download = $false
    }
} else {
    Write-Host "Creating temp folder: C:\Temp"
    New-Item -Path "C:\" -Name "Temp" -ItemType "directory"
    $download = $True
}

# Install Functions
function InstallChrome {
    try {
        if ($TestChromeInstalled -eq $False) {
            Write-Verbose "Running Google Chrome setup."
            $setupFile = "C:\Temp\ChromeInstaller.exe"
            Start-Process $setupFile -Verb runAs -ArgumentList '/silent /install'
        } else {Write-Host "Chrome is already installed" -ForegroundColor Green}
    }
    catch {
        Write-Error "An error occured while installing Google Chrome"
    }
}
function InstallDrive {
    try {
        if ($TestDriveInstalled -eq $False) {
            Write-Verbose "Running Google Drive setup."
            $setupFile = "C:\Temp\GoogleDriveSetup.exe"
            Start-Process $setupFile -Verb runAs -ArgumentList '--silent --desktop_shortcut --gsuite_shortcuts=false'
        } else {Write-Host "Drive is already installed" -ForegroundColor Green}
    }
    catch {
        Write-Error "An error occured while installing Google Drive"
    }
}

function InstallGCPW {
    try {
        if ($TestGCPWInstalled -eq $False) {
            Write-Verbose "Running GCPW setup."
            $setupFile = "c:\Temp\gcpwstandaloneenterprise64.msi"
            $params = '/i', $setupFile, '/quiet'
            Start-Process msiexec -Verb runAs -wait -ArgumentList $params
        } else {Write-Host "GCPW is already installed" -ForegroundColor Green}
    }
    catch {
        Write-Error "An error occured while installing GCPW"
    }
}

function InstallNAble {
    try {
        if ($TestNableInstalled -eq $False) {
            if ($nAble -eq "y") {
                if (Test-Path -path "C:\Temp\nAble.exe") {
                    Write-Host "`nInstalling N-Able"
                    Start-Process C:\Temp\nAble.exe -ArgumentList '/s " /qn"' -Wait
                    Write-Host "N-Able Installation Completed!"
                } else {
                    Write-Host = "Installing N-Able"

                    $uri = 'https://ncentral.alphamediausa.com/download/current/winnt/N-central/WindowsAgentSetup.exe'
                    Invoke-Webrequest -uri $uri -OutFile "C:\Temp\WindowsAgentSetup.exe"

                    Import-Csv 'C:\Temp\Markets.csv' | ft

                    $search = Read-Host "Enter Market"
                    $regKey = Read-Host "Enter registration key"
                    $siteID = ""

                    while ($siteID -eq "") {
                        Import-Csv C:\Temp\SiteID.csv | Where-Object { $_.Customer -eq $search } | ft

                        $siteID = Read-Host "`nEnter ID"
                        Write-Host $siteID
                    }

                    $arguments = @(
                        '/s',
                        '/v"',
                        '/qn',
                        "CUSTOMERID=$siteID",
                        'CUSTOMERSPECIFIC=1',
                        "REGISTRATION_TOKEN=$regKey",
                        'SERVERPROTOCOL=HTTPS',
                        'SERVERADDRESS=ncentral.alphamediausa.com',
                        'SERVERPORT=443"'
                    )
                    Start-Process "C:\Temp\WindowsAgentSetup.exe" -ArgumentList $arguments -Wait -WindowStyle Hidden
                    Write-Host = "N-Able Installation Completed!"
                }
            }
        } else {Write-Host "N-Able is already installed" -ForegroundColor Green}
    }
    catch {
        Write-Error "An error occured while installing N-Able"
    }
}

function InstallSymantec {
    try {
        if ($TestSymantecInstalled -eq $False) {
            if ($sym -eq "y") {
                if (Test-Path -Path "C:\Temp\Symantec_Agent_Setup.exe") {
                    Write-Host "`nInstalling Symantec" | Green
                    Start-Process "C:\Temp\Symantec_Agent_Setup.exe" -Verb runAs -Wait
                    Write-Host "Symantec Installation Completed!"
                } else {
                    Write-Host "Symantec_Agent_Setup.exe not found" -ForegroundColor Red
                }
            }
        } else {Write-Host "Symantec is already installed" -ForegroundColor Green}
    }
    catch {
        Write-Error "An error occured while installing N-able"
    }
}

# Prompt
Write-Host "`nIf installing Symantec or N-Able place the install files in C:/Temp"
Write-Host "`nIf yes please rename installer to nAble.exe before continuing" -ForegroundColor Yellow
$nAble = Read-Host "Would you like to run nAble Agent installer? (y/n)"
Write-Host "`nRecommend Symantec Installation Package to not have immediate restart or interactive selected.`nIf yes please ensure file name Symantec_Agent_Setup.exe before continuing" -ForegroundColor Yellow
$sym = Read-Host "Would you like to run Symantec installer? (y/n)"
Write-Host ""

# Download Google Files
$ChromeURL = ""
$ChromePath = ""
$DriveURL = ""
$DrivePath = ""
$GCPWURL = ""
$GCPWPath = ""

if ($downloadChrome) {
    $ChromeURL = "https://dl.google.com/chrome/install/current/chrome_installer.exe"
    $ChromePath = "C:\Temp\ChromeInstaller.exe"
}
if ($downloadDrive) {
    $DriveURL = "https://dl.google.com/drive-file-stream/GoogleDriveSetup.exe"
    $DrivePath = "C:\Temp\GoogleDriveSetup.exe"
}
if ($downloadGCPW) {
    $GCPWURL = "https://dl.google.com/credentialprovider/gcpwstandaloneenterprise64.msi"
    $GCPWPath = "C:\Temp\gcpwstandaloneenterprise64.msi"
}

if ($download) {
    Start-BitsTransfer -Source $ChromeURL, $DriveURL, $GCPWURL -Destination $ChromePath, $DrivePath, $GCPWPath
}

# Run Installers
InstallChrome
InstallDrive
InstallGCPW
InstallNAble
InstallSymantec


#Configure registry for Google Credential Provider
$regPath = "HKLM:\Software\Google\GCPW"
$name = "domains_allowed_to_login"
$value = "$env:computername, alpha.local, alphamediausa.com"

if(!(Test-Path $regPath)) {
    New-item -Path $regPath -Force | Out-Null
    New-ItemProperty -Path $regPath -Name $name -Value $value -PropertyType String -Force
} else {
    New-ItemProperty -Path $regPath -Name $name -Value $value -PropertyType String -Force
}
