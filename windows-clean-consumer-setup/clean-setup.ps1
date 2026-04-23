#requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

$script:results = [System.Collections.Generic.List[object]]::new()

function Add-Result {
    param(
        [string]$App,
        [string]$Status,
        [string]$Details = ""
    )

    $script:results.Add([PSCustomObject]@{
        App     = $App
        Status  = $Status
        Details = $Details
    })
}

function Write-Info {
    param([string]$Message)
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Write-Ok {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-WarnMsg {
    param([string]$Message)
    Write-Host "[SKIP] $Message" -ForegroundColor Yellow
}

function Write-Fail {
    param([string]$Message)
    Write-Host "[FOUT] $Message" -ForegroundColor Red
}

function Test-WingetAvailable {
    try {
        $null = & winget --version 2>$null
        return $LASTEXITCODE -eq 0
    }
    catch {
        return $false
    }
}

function Ensure-Winget {
    if (Test-WingetAvailable) {
        Write-Ok "WinGet is beschikbaar."
        return
    }

    Write-WarnMsg "WinGet is nog niet beschikbaar. Ik probeer App Installer te registreren..."

    try {
        Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
        Start-Sleep -Seconds 5
    }
    catch {
        Write-WarnMsg "Registreren van App Installer lukte niet automatisch."
    }

    if (Test-WingetAvailable) {
        Write-Ok "WinGet is nu beschikbaar."
        return
    }

    Write-Fail "WinGet is nog steeds niet beschikbaar."
    Write-Host "Open Microsoft Store en installeer/update 'App Installer'. Start daarna install.bat opnieuw." -ForegroundColor Yellow
    exit 1
}

function Test-PackageInstalled {
    param(
        [string]$Id,
        [string]$Source,
        [string]$Name
    )

    try {
        $listOutput = & winget list --id $Id --exact --source $Source --accept-source-agreements 2>$null | Out-String
        if ($LASTEXITCODE -eq 0 -and $listOutput -match [regex]::Escape($Id)) {
            return $true
        }
    }
    catch {
    }

    try {
        $listOutputByName = & winget list --name $Name --source $Source --accept-source-agreements 2>$null | Out-String
        if ($LASTEXITCODE -eq 0 -and $listOutputByName -match [regex]::Escape($Name)) {
            return $true
        }
    }
    catch {
    }

    return $false
}

function Install-WingetPackage {
    param(
        [string]$Id,
        [string]$Name,
        [string]$Source = "winget"
    )

    Write-Info "Controleren van $Name"

    if (Test-PackageInstalled -Id $Id -Source $Source -Name $Name) {
        Write-Ok "$Name staat al op het systeem, overslaan."
        Add-Result -App $Name -Status "Overgeslagen"
        return
    }

    Write-Info "Installeren van $Name"

    try {
        & winget install `
            --id $Id `
            --exact `
            --source $Source `
            --accept-package-agreements `
            --accept-source-agreements `
            --silent `
            --disable-interactivity

        if (Test-PackageInstalled -Id $Id -Source $Source -Name $Name) {
            Write-Ok "$Name geïnstalleerd."
            Add-Result -App $Name -Status "Geïnstalleerd"
        }
        else {
            Write-WarnMsg "$Name installatie uitgevoerd, maar niet hard bevestigd."
            Add-Result -App $Name -Status "Onzeker" -Details "Install uitgevoerd, detectie niet bevestigd"
        }
    }
    catch {
        Write-Fail "Installatie mislukt voor $Name"
        Add-Result -App $Name -Status "Mislukt" -Details $_.Exception.Message
    }
}

Write-Info "Clean consumer setup starten"
Ensure-Winget

Write-Info "WinGet bronnen bijwerken"
try {
    & winget source update --accept-source-agreements | Out-Null
}
catch {
    Write-WarnMsg "Bronnen bijwerken gaf een melding, setup gaat verder."
}

$packages = @(
    @{ Id = "Google.Chrome";                Name = "Google Chrome";         Source = "winget"  },
    @{ Id = "AgileBits.1Password";          Name = "1Password";             Source = "winget"  },
    @{ Id = "Microsoft.Office";             Name = "Microsoft 365";         Source = "winget"  },

    @{ Id = "9WZDNCRFJ3TJ";                 Name = "Netflix";               Source = "msstore" },
    @{ Id = "9NXQXXLFST89";                 Name = "Disney+";               Source = "msstore" },
    @{ Id = "9NKSQGP7F2NH";                 Name = "WhatsApp";              Source = "msstore" },

    @{ Id = "Spotify.Spotify";             Name = "Spotify";               Source = "winget"  },
    @{ Id = "VideoLAN.VLC";                Name = "VLC Media Player";      Source = "winget"  },

    @{ Id = "7zip.7zip";                   Name = "7-Zip";                 Source = "winget"  },
    @{ Id = "Adobe.Acrobat.Reader.64-bit"; Name = "Adobe Acrobat Reader";  Source = "winget"  }
)

foreach ($pkg in $packages) {
    Install-WingetPackage -Id $pkg.Id -Name $pkg.Name -Source $pkg.Source
}

Write-Info "Resultaat"
$script:results | Format-Table -AutoSize

Write-Host "`nKlaar." -ForegroundColor Green