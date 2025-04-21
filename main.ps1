<#
.SYNOPSIS
    Installation Menu for Development Tools with Auto-Elevation
.DESCRIPTION
    Provides a menu-based interface for installing various development tools and Visual Studio versions.
    Automatically requests administrator privileges if not already running as admin.
.NOTES
    Version: 1.0
#>

# Check if running as administrator and self-elevate if needed
function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Self-elevation mechanism
if (-not (Test-Admin)) {
    Write-Host "This script requires administrator privileges. Requesting elevation..." -ForegroundColor Yellow
    
    # Save the current script path
    $scriptPath = $MyInvocation.MyCommand.Definition
    
    # Prepare the arguments for the new process
    $arguments = "-ExecutionPolicy Bypass -File `"$scriptPath`""
    
    # Start a new PowerShell process with admin rights
    try {
        Start-Process powershell.exe -ArgumentList $arguments -Verb RunAs -Wait
        # Exit the current non-elevated instance
        exit
    }
    catch {
        Write-Host "Failed to get administrator privileges. Please run as administrator manually." -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
        Start-Sleep -Seconds 3
        exit 1
    }
}

# If we get here, we're running as admin
Write-Host "Running with administrator privileges." -ForegroundColor Green

# --- Function for robust Choco command execution ---
function Invoke-ChocoCommand {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Command,
        [Parameter(Mandatory=$true)]
        [string]$ActionDescription
    )
    Write-Host "Executing: $Command" -ForegroundColor Cyan
    try {
        Invoke-Expression $Command
        # Treat non-zero exit code as fatal
        if ($LASTEXITCODE -ne 0) {
            throw "$ActionDescription command failed with exit code $LASTEXITCODE. Check logs for details."
        } else {
            Write-Host "$ActionDescription command completed successfully (Exit Code 0)." -ForegroundColor Green
        }
        return $true
    } catch {
        Write-Error "Error during ${ActionDescription}: $($_.Exception.Message)"
        throw "Failed during $ActionDescription."
    }
}

function Show-Menu {
    Clear-Host
    Write-Host "===============================================" -ForegroundColor Cyan
    Write-Host "          Development Tools Installer          " -ForegroundColor Cyan
    Write-Host "===============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Installation Methods:" -ForegroundColor White
    Write-Host ""
    Write-Host "[1] Install Default        - VS 2019 & Tools" -ForegroundColor Green
    Write-Host "[2] Install VS 2015        - Visual Studio 2015" -ForegroundColor Green
    Write-Host "[3] Install VS 2017        - Visual Studio 2017" -ForegroundColor Green
    Write-Host "[4] Install VS 2019        - Visual Studio 2019" -ForegroundColor Green
    Write-Host "[5] Install VS 2022        - Visual Studio 2022" -ForegroundColor Green
    Write-Host ""
    Write-Host "[6] Check Installation Status" -ForegroundColor White
    Write-Host "[7] Troubleshoot" -ForegroundColor White
    Write-Host "[H] Help" -ForegroundColor White
    Write-Host "[0] Exit" -ForegroundColor White
    Write-Host ""
    Write-Host "===============================================" -ForegroundColor Cyan
    Write-Host ""
}

# --- Check and Install Chocolatey ---
function Install-Chocolatey {
    $ChocoInstallScriptUrl = 'https://community.chocolatey.org/install.ps1'
    $ChocoExePath = Join-Path $env:ProgramData "chocolatey\bin\choco.exe"
    $chocoInstalledOrVerified = $false # Flag to track if Choco is ready

    Write-Host "Checking if Chocolatey is installed..."
    if (Test-Path $ChocoExePath -PathType Leaf) {
        Write-Host "Chocolatey already installed (choco.exe found)." -ForegroundColor Green
        $chocoInstalledOrVerified = $true
    } else {
        Write-Host "Chocolatey not found, attempting installation..." -ForegroundColor Yellow
        try {
            Set-ExecutionPolicy Bypass -Scope Process -Force;
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
            iex ((New-Object System.Net.WebClient).DownloadString($ChocoInstallScriptUrl))
            Write-Host "Chocolatey installation command executed." -ForegroundColor Green

            # --- Retry Loop Verification ---
            $chocoCheckRetries = 6 # Number of times to check
            $chocoCheckInterval = 15 # Seconds between checks
            $chocoBinPath = Join-Path $env:ProgramData "chocolatey\bin"

            Write-Host "Starting verification for choco command (up to $chocoCheckRetries checks, $chocoCheckInterval seconds apart)..."
            # Try adding path to session immediately (best effort)
            if (Test-Path $chocoBinPath -PathType Container) {
                if (($env:Path -split ';') -notcontains $chocoBinPath) {
                    $env:Path += ";$chocoBinPath"
                    Write-Host "Added $chocoBinPath to current session PATH for verification attempts." -ForegroundColor Yellow
                }
            } else {
                Write-Host "Chocolatey bin directory ($chocoBinPath) not found yet, will re-check in loop." -ForegroundColor Yellow
            }

            # Start retry loop
            for ($i = 1; $i -le $chocoCheckRetries; $i++) {
                Write-Host "Verification Attempt $i/${chocoCheckRetries}:" -ForegroundColor Cyan

                # Check using Get-Command (more reliable than just Test-Path)
                if ((Get-Command choco -ErrorAction SilentlyContinue)) {
                    Write-Host "--> SUCCESS: 'choco' command is now discoverable!" -ForegroundColor Green
                    $chocoInstalledOrVerified = $true
                    break # Exit the loop, verification successful
                } else {
                    Write-Host "--> 'choco' command still not found."
                    if ($i -lt $chocoCheckRetries) {
                        Write-Host "    Waiting $chocoCheckInterval seconds before next check..."
                        Start-Sleep -Seconds $chocoCheckInterval
                    }
                }
            } # End for loop

            if (!$chocoInstalledOrVerified) {
                # If loop finished without finding choco
                throw "Chocolatey verification failed after $chocoCheckRetries attempts. 'choco' command not discoverable. Installation likely failed or is taking an excessive amount of time. Please check the Chocolatey logs and C:\ProgramData\chocolatey\bin manually."
            }

            Write-Host "Chocolatey successfully installed and command verified!" -ForegroundColor Green

        } catch {
            Write-Error "CRITICAL ERROR during Chocolatey installation process: $($_.Exception.Message)"
            if ($_.Exception.Message -notlike "Failed during*") {
                Write-Error "Underlying failure reason: $($_.Exception.InnerException.Message)"
            }
            if ($Host.Name -eq 'ConsoleHost') { Read-Host "Press Enter to exit..." }
            exit 1
        }
    }

    # --- Final Sanity Check ---
    if (!$chocoInstalledOrVerified) {
        Write-Host "Performing final check for 'choco' command availability..."
        if (! (Get-Command choco -ErrorAction SilentlyContinue)) {
            Write-Error "CRITICAL ERROR: 'choco' command is unexpectedly unavailable before proceeding to package installations. Cannot continue."
            if ($Host.Name -eq 'ConsoleHost') { Read-Host "Press Enter to exit..." }
            exit 1
        } else {
            $chocoInstalledOrVerified = $true
        }
    }
    Write-Host "'choco' command is available and ready for use." -ForegroundColor Green
    return $true
}

# --- Install Python 3.11 ---
function Install-Python {
    Write-Host "--- Starting Python 3.11 Installation ---" -ForegroundColor Cyan
    $pythonPackageId = "python311"
    $pythonInstallDir = "C:\Python311"
    $pythonExePath = Join-Path $pythonInstallDir "python.exe"
    Write-Host "Checking for existing Python 3.11 at $pythonInstallDir..."
    if (Test-Path $pythonExePath -PathType Leaf) {
        Write-Host "Python 3.11 appears to be already installed at $pythonInstallDir." -ForegroundColor Green
        return $true
    } else {
        Write-Host "Python 3.11 not found at $pythonInstallDir. Proceeding with installation..." -ForegroundColor Yellow
        $pythonParams = "'/InstallDir:$pythonInstallDir /AddToPath InstallAllUsers=1 /Quiet'"
        $pythonChocoCommand = "choco install $pythonPackageId --params $pythonParams -y"
        try {
            Invoke-ChocoCommand -Command $pythonChocoCommand -ActionDescription "Python 3.11 Installation"
            if (Test-Path $pythonExePath -PathType Leaf) {
                Write-Host "Verification: $pythonExePath found after installation attempt." -ForegroundColor Green
                return $true
            } else { 
                Write-Warning "Python installation command finished, but $pythonExePath was not found. Manual verification recommended." 
                return $false
            }
        } catch {
            Write-Error "Python 3.11 installation failed. Stopping script."
            if ($Host.Name -eq 'ConsoleHost') { Read-Host "Press Enter to exit..." }
            exit 1
        }
    }
}

# --- Install Visual Studio functions ---
function Install-VS2015 {
    Write-Host "--- Starting Visual Studio 2015 Community Installation ---" -ForegroundColor Cyan
    $vsPackageId = "visualstudio2015community"
    $vsParams = "--quiet"
    $vsChocoCommand = "choco install $vsPackageId --params `"$vsParams`" -y"
    $vsActionDescription = "Visual Studio 2015 Community Installation"

    try {
        Invoke-ChocoCommand -Command $vsChocoCommand -ActionDescription $vsActionDescription
        Write-Host "$vsActionDescription command submitted. Installation runs in background and may take time." -ForegroundColor Yellow
        return $true
    } catch {
        Write-Error "$vsActionDescription failed. Stopping script."
        if ($Host.Name -eq 'ConsoleHost') { Read-Host "Press Enter to exit..." }
        exit 1
    }
}

function Install-VS2017 {
    Write-Host "--- Starting Visual Studio 2017 Community Installation ---" -ForegroundColor Cyan
    $vsPackageId = "visualstudio2017community"
    $vsParams = "--add Microsoft.VisualStudio.Workload.ManagedDesktop --add Microsoft.VisualStudio.Workload.NativeDesktop --add Microsoft.VisualStudio.Workload.Universal --add Microsoft.VisualStudio.Component.Language.zh-CN --includeRecommended --quiet"
    $vsChocoCommand = "choco install $vsPackageId --params `"$vsParams`" -y"
    $vsActionDescription = "Visual Studio 2017 Community Installation"

    try {
        Invoke-ChocoCommand -Command $vsChocoCommand -ActionDescription $vsActionDescription
        Write-Host "$vsActionDescription command submitted. Installation runs in background and may take time." -ForegroundColor Yellow
        return $true
    } catch {
        Write-Error "$vsActionDescription failed. Stopping script."
        if ($Host.Name -eq 'ConsoleHost') { Read-Host "Press Enter to exit..." }
        exit 1
    }
}

function Install-VS2019 {
    Write-Host "--- Starting Visual Studio 2019 Community Installation (with Chinese Lang Pack) ---" -ForegroundColor Cyan
    $vsPackageId = "visualstudio2019community"
    $vsParams = "--add Microsoft.VisualStudio.Workload.ManagedDesktop --add Microsoft.VisualStudio.Workload.NativeDesktop --add Microsoft.VisualStudio.Workload.Universal --add Microsoft.VisualStudio.Component.Language.zh-CN --includeRecommended --quiet"
    $vsChocoCommand = "choco install $vsPackageId --params `"$vsParams`" -y"
    $vsActionDescription = "Visual Studio 2019 Community Installation"

    try {
        Invoke-ChocoCommand -Command $vsChocoCommand -ActionDescription $vsActionDescription
        Write-Host "$vsActionDescription command submitted. Installation runs in background and may take time." -ForegroundColor Yellow
        return $true
    } catch {
        Write-Error "$vsActionDescription failed. Stopping script."
        if ($Host.Name -eq 'ConsoleHost') { Read-Host "Press Enter to exit..." }
        exit 1
    }
}

function Install-VS2022 {
    Write-Host "--- Starting Visual Studio 2022 Community Installation ---" -ForegroundColor Cyan
    $vsPackageId = "visualstudio2022community"
    $vsParams = "--add Microsoft.VisualStudio.Workload.ManagedDesktop --add Microsoft.VisualStudio.Workload.NativeDesktop --add Microsoft.VisualStudio.Workload.Universal --add Microsoft.VisualStudio.Component.Language.zh-CN --includeRecommended --quiet"
    $vsChocoCommand = "choco install $vsPackageId --params `"$vsParams`" -y"
    $vsActionDescription = "Visual Studio 2022 Community Installation"

    try {
        Invoke-ChocoCommand -Command $vsChocoCommand -ActionDescription $vsActionDescription
        Write-Host "$vsActionDescription command submitted. Installation runs in background and may take time." -ForegroundColor Yellow
        return $true
    } catch {
        Write-Error "$vsActionDescription failed. Stopping script."
        if ($Host.Name -eq 'ConsoleHost') { Read-Host "Press Enter to exit..." }
        exit 1
    }
}

function Check-InstallationStatus {
    Write-Host "Checking Installation Status..." -ForegroundColor Yellow
    # Check for installed Visual Studio versions
    $vsVersions = @()
    
    # Check for VS 2015
    if (Test-Path "C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\devenv.exe") {
        $vsVersions += "Visual Studio 2015"
    }
    
    # Check for VS 2017
    if (Test-Path "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\Common7\IDE\devenv.exe") {
        $vsVersions += "Visual Studio 2017 Community"
    }
    
    # Check for VS 2019
    if (Test-Path "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\Common7\IDE\devenv.exe") {
        $vsVersions += "Visual Studio 2019 Community"
    }
    
    # Check for VS 2022
    if (Test-Path "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\devenv.exe") {
        $vsVersions += "Visual Studio 2022 Community"
    }
    
    # Check for Python 3.11
    if (Test-Path "C:\Python311\python.exe") {
        $vsVersions += "Python 3.11"
    }
    
    # Check for Chocolatey
    if (Test-Path "C:\ProgramData\chocolatey\bin\choco.exe") {
        $vsVersions += "Chocolatey"
    }
    
    if ($vsVersions.Count -eq 0) {
        Write-Host "No development tools found installed." -ForegroundColor Yellow
    } else {
        Write-Host "Installed development tools:" -ForegroundColor Green
        foreach ($version in $vsVersions) {
            Write-Host " - $version" -ForegroundColor Green
        }
    }
}

function Show-Troubleshoot {
    Write-Host "Troubleshooting..." -ForegroundColor Yellow
    Write-Host "1. Checking PowerShell execution policy..." -ForegroundColor White
    $policy = Get-ExecutionPolicy
    Write-Host "   Current execution policy: $policy" -ForegroundColor Cyan
    
    Write-Host "2. Checking administrator privileges..." -ForegroundColor White
    if (Test-Admin) {
        Write-Host "   Running with administrator privileges: Yes" -ForegroundColor Green
    } else {
        Write-Host "   Running with administrator privileges: No" -ForegroundColor Red
        Write-Host "   Please run this script as administrator." -ForegroundColor Yellow
    }
    
    Write-Host "3. Checking internet connectivity..." -ForegroundColor White
    try {
        $internetTest = Test-Connection -ComputerName "www.microsoft.com" -Count 1 -Quiet
        if ($internetTest) {
            Write-Host "   Internet connectivity: Available" -ForegroundColor Green
        } else {
            Write-Host "   Internet connectivity: Not available" -ForegroundColor Red
        }
    } catch {
        Write-Host "   Internet connectivity: Error checking" -ForegroundColor Red
    }
    
    Write-Host "4. Checking disk space..." -ForegroundColor White
    $drive = Get-PSDrive C
    $freeSpaceGB = [math]::Round($drive.Free / 1GB, 2)
    if ($freeSpaceGB -gt 10) {
        Write-Host "   Free space on C: drive: $freeSpaceGB GB (Sufficient)" -ForegroundColor Green
    } else {
        Write-Host "   Free space on C: drive: $freeSpaceGB GB (Low)" -ForegroundColor Red
        Write-Host "   Visual Studio requires at least 10 GB of free space." -ForegroundColor Yellow
    }
    
    Write-Host "Troubleshooting completed." -ForegroundColor Green
}

function Show-Help {
    Write-Host ""
    Write-Host "Help Information" -ForegroundColor Cyan
    Write-Host "================" -ForegroundColor Cyan
    Write-Host "This tool provides an easy way to install various development tools and Visual Studio versions."
    Write-Host ""
    Write-Host "Options:" -ForegroundColor White
    Write-Host "1. Install Default - Installs VS 2019 and basic development tools"
    Write-Host "2. Install VS 2015 - Installs Visual Studio 2015 Community Edition"
    Write-Host "3. Install VS 2017 - Installs Visual Studio 2017 Community Edition"
    Write-Host "4. Install VS 2019 - Installs Visual Studio 2019 Community Edition"
    Write-Host "5. Install VS 2022 - Installs Visual Studio 2022 Community Edition"
    Write-Host "6. Check Installation Status - Verifies installed components"
    Write-Host "7. Troubleshoot - Helps resolve common installation issues"
    Write-Host ""
    Write-Host "Press any key to return to the main menu..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Execute-Option {
    param (
        [string]$Option
    )
    
    switch ($Option) {
        "1" {
            Write-Host "Installing Default Tools (VS 2019)..." -ForegroundColor Yellow
            if (Install-Chocolatey) {
                if (Install-Python) {
                    Install-VS2019
                }
            }
        }
        "2" {
            Write-Host "Installing Visual Studio 2015..." -ForegroundColor Yellow
            if (Install-Chocolatey) {
                if (Install-Python) {
                    Install-VS2015
                }
            }
        }
        "3" {
            Write-Host "Installing Visual Studio 2017..." -ForegroundColor Yellow
            if (Install-Chocolatey) {
                if (Install-Python) {
                    Install-VS2017
                }
            }
        }
        "4" {
            Write-Host "Installing Visual Studio 2019..." -ForegroundColor Yellow
            if (Install-Chocolatey) {
                if (Install-Python) {
                    Install-VS2019
                }
            }
        }
        "5" {
            Write-Host "Installing Visual Studio 2022..." -ForegroundColor Yellow
            if (Install-Chocolatey) {
                if (Install-Python) {
                    Install-VS2022
                }
            }
        }
        "6" {
            Check-InstallationStatus
        }
        "7" {
            Show-Troubleshoot
        }
        "H" {
            Show-Help
        }
        "0" {
            Write-Host "Exiting..." -ForegroundColor Yellow
            exit
        }
        default {
            Write-Host "Invalid option. Please try again." -ForegroundColor Red
        }
    }
}

# Set execution policy for this session to bypass
try {
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
} catch {
    Write-Host "Warning: Could not set execution policy to Bypass for this session." -ForegroundColor Yellow
}

# Main program loop
do {
    Show-Menu
    $choice = Read-Host "Choose a menu option using your keyboard [1,2,3...H,0]"
    $choice = $choice.ToUpper()
    Execute-Option -Option $choice
    
    if ($choice -ne "0") {
        Write-Host ""
        Write-Host "Press any key to return to the main menu..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
} while ($choice -ne "0")
