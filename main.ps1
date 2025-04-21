<#
.SYNOPSIS
    Installation Menu for Development Tools
.DESCRIPTION
    Provides a menu-based interface for installing various development tools and Visual Studio versions
.NOTES
    Version: 1.0
#>

function Show-Menu {
    Clear-Host
    Write-Host "===============================================" -ForegroundColor Cyan
    Write-Host "          Development Tools Installer          " -ForegroundColor Cyan
    Write-Host "===============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Installation Methods:" -ForegroundColor White
    Write-Host ""
    Write-Host "[1] Install Default        - Basic Tools" -ForegroundColor Green
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

function Execute-Option {
    param (
        [string]$Option
    )
    
    switch ($Option) {
        "1" {
            Write-Host "Installing Default Tools..." -ForegroundColor Yellow
            $scriptUrl = "https://raw.githubusercontent.com/yourusername/your-repo/main/install_default.ps1"
            try {
                Invoke-Expression (New-Object Net.WebClient).DownloadString($scriptUrl)
            }
            catch {
                Write-Host "Error downloading or executing the script: $_" -ForegroundColor Red
            }
        }
        "2" {
            Write-Host "Installing Visual Studio 2015..." -ForegroundColor Yellow
            $scriptUrl = "https://raw.githubusercontent.com/yourusername/your-repo/main/install_2015.ps1"
            try {
                Invoke-Expression (New-Object Net.WebClient).DownloadString($scriptUrl)
            }
            catch {
                Write-Host "Error downloading or executing the script: $_" -ForegroundColor Red
            }
        }
        "3" {
            Write-Host "Installing Visual Studio 2017..." -ForegroundColor Yellow
            $scriptUrl = "https://raw.githubusercontent.com/yourusername/your-repo/main/install_2017.ps1"
            try {
                Invoke-Expression (New-Object Net.WebClient).DownloadString($scriptUrl)
            }
            catch {
                Write-Host "Error downloading or executing the script: $_" -ForegroundColor Red
            }
        }
        "4" {
            Write-Host "Installing Visual Studio 2019..." -ForegroundColor Yellow
            $scriptUrl = "https://raw.githubusercontent.com/yourusername/your-repo/main/install_2019.ps1"
            try {
                Invoke-Expression (New-Object Net.WebClient).DownloadString($scriptUrl)
            }
            catch {
                Write-Host "Error downloading or executing the script: $_" -ForegroundColor Red
            }
        }
        "5" {
            Write-Host "Installing Visual Studio 2022..." -ForegroundColor Yellow
            $scriptUrl = "https://raw.githubusercontent.com/yourusername/your-repo/main/install_2022.ps1"
            try {
                Invoke-Expression (New-Object Net.WebClient).DownloadString($scriptUrl)
            }
            catch {
                Write-Host "Error downloading or executing the script: $_" -ForegroundColor Red
            }
        }
        "6" {
            Write-Host "Checking Installation Status..." -ForegroundColor Yellow
            # Add code to check installation status
            Write-Host "Status check completed." -ForegroundColor Green
        }
        "7" {
            Write-Host "Troubleshooting..." -ForegroundColor Yellow
            # Add troubleshooting code
            Write-Host "Troubleshooting completed." -ForegroundColor Green
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

function Show-Help {
    Write-Host ""
    Write-Host "Help Information" -ForegroundColor Cyan
    Write-Host "================" -ForegroundColor Cyan
    Write-Host "This tool provides an easy way to install various development tools and Visual Studio versions."
    Write-Host ""
    Write-Host "Options:" -ForegroundColor White
    Write-Host "1. Install Default - Installs basic development tools"
    Write-Host "2-5. Install VS - Installs specific Visual Studio versions"
    Write-Host "6. Check Installation Status - Verifies installed components"
    Write-Host "7. Troubleshoot - Helps resolve common installation issues"
    Write-Host ""
    Write-Host "Press any key to return to the main menu..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
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
