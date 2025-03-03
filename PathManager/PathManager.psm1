function Add-ToPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,
        
        [Parameter()]
        [ValidateSet('User', 'Machine')]
        [string]$Scope = 'User'
    )

    try {
        # Normalize the path
        $Path = [System.IO.Path]::GetFullPath($Path)
        
        # Verify the path exists
        if (-not (Test-Path $Path)) {
            throw "Path '$Path' does not exist."
        }

        # Get current PATH based on scope
        $currentPath = [System.Environment]::GetEnvironmentVariable("PATH", $Scope) -split ';' | Where-Object { $_ }

        if ($currentPath -notcontains $Path) {
            $newPath = ($currentPath + $Path) -join ';'
            
            # Update PATH for the specified scope
            [System.Environment]::SetEnvironmentVariable("PATH", $newPath, $Scope)
            
            # Also update current session
            $env:PATH = ($env:PATH -split ';' | Where-Object { $_ }) -join ';'
            $env:PATH += ";$Path"
            
            Write-Host "Successfully added '$Path' to the PATH ($Scope scope)." -ForegroundColor Green
        } else {
            Write-Host "The path '$Path' is already in the PATH ($Scope scope)." -ForegroundColor Yellow
        }
    }
    catch {
        throw "Failed to add path: $_"
    }
}

function Remove-FromPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Paths,
        
        [Parameter()]
        [ValidateSet('User', 'Machine')]
        [string]$Scope = 'User'
    )

    try {
        # Get current PATH based on scope
        $currentPath = [System.Environment]::GetEnvironmentVariable("PATH", $Scope) -split ';' | Where-Object { $_ }
        
        # Remove specified paths
        $newPath = $currentPath | Where-Object { $path = $_; -not ($Paths | Where-Object { $path -eq $_ }) }
        $newPathString = $newPath -join ';'
        
        # Update PATH for the specified scope
        [System.Environment]::SetEnvironmentVariable("PATH", $newPathString, $Scope)
        
        # Also update current session
        $env:PATH = ($env:PATH -split ';' | Where-Object { $path = $_; -not ($Paths | Where-Object { $path -eq $_ }) }) -join ';'
        
        Write-Host "Successfully removed specified paths from the PATH ($Scope scope)." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to remove paths: $_"
    }
}

function Get-PathContent {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateSet('User', 'Machine', 'All')]
        [string]$Scope = 'All'
    )

    try {
        $results = @()
        
        if ($Scope -in @('Machine', 'All')) {
            $machinePath = [System.Environment]::GetEnvironmentVariable("PATH", 'Machine') -split ';' | Where-Object { $_ }
            $results += $machinePath | ForEach-Object { 
                [PSCustomObject]@{
                    Path = $_
                    Scope = 'Machine'
                    Exists = Test-Path $_
                }
            }
        }
        
        if ($Scope -in @('User', 'All')) {
            $userPath = [System.Environment]::GetEnvironmentVariable("PATH", 'User') -split ';' | Where-Object { $_ }
            $results += $userPath | ForEach-Object { 
                [PSCustomObject]@{
                    Path = $_
                    Scope = 'User'
                    Exists = Test-Path $_
                }
            }
        }
        
        return $results
    }
    catch {
        Write-Error "Failed to get PATH contents: $_"
    }
}

function Update-PathEnvironment {
    [CmdletBinding()]
    param()
    
    try {
        $machinePath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
        $userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
        $env:PATH = "$machinePath;$userPath"
        Write-Host "Successfully refreshed PATH environment variable." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to refresh PATH: $_"
    }
}

function Get-InstalledApplications {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$NameFilter
    )
    
    try {
        $regPaths = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
            "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
        )
        
        $apps = foreach ($path in $regPaths) {
            Get-ChildItem -Path $path | 
            Get-ItemProperty | 
            Where-Object { $_.DisplayName } |
            Select-Object @{N='Name';E={$_.DisplayName}}, 
                        @{N='Version';E={$_.DisplayVersion}}, 
                        @{N='Publisher';E={$_.Publisher}},
                        @{N='InstallLocation';E={$_.InstallLocation}},
                        @{N='UninstallString';E={$_.UninstallString}}
        }
        
        if ($NameFilter) {
            $apps = $apps | Where-Object { $_.Name -like "*$NameFilter*" }
        }
        
        return $apps | Sort-Object Name
    }
    catch {
        Write-Error "Failed to get installed applications: $_"
    }
}

function Add-GitVimToPath {
    [CmdletBinding()]
    param()
    
    try {
        # Find Git path
        $gitPath = ($env:PATH -split ';') | Where-Object { $_ -match "\\git\\(cmd|bin)$" } | Select-Object -First 1
        
        if (-not $gitPath) {
            throw "Git installation path not found in PATH."
        }
        
        # Construct usr/bin path
        $usrBinPath = Join-Path (Split-Path $gitPath -Parent) "usr\bin"
        
        if (-not (Test-Path $usrBinPath)) {
            throw "Git usr/bin path not found at: $usrBinPath"
        }
        
        # Add to path using our Add-ToPath function
        Add-ToPath -Path $usrBinPath -Scope User
    }
    catch {
        Write-Error "Failed to add Git Vim to PATH: $_"
    }
}

function Test-PathEntries {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateSet('User', 'Machine', 'All')]
        [string]$Scope = 'All',

        [Parameter()]
        [switch]$RemoveInvalid
    )

    try {
        $results = Get-PathContent -Scope $Scope
        $invalidPaths = $results | Where-Object { -not $_.Exists }
        
        if ($invalidPaths) {
            Write-Host "Found invalid paths:" -ForegroundColor Yellow
            $invalidPaths | ForEach-Object {
                Write-Host "[$($_.Scope)] $($_.Path)" -ForegroundColor Red
            }

            if ($RemoveInvalid) {
                $invalidPaths | ForEach-Object {
                    Remove-FromPath -Paths $_.Path -Scope $_.Scope
                }
                Write-Host "Invalid paths have been removed." -ForegroundColor Green
            }
        } else {
            Write-Host "All paths are valid." -ForegroundColor Green
        }

        return $invalidPaths
    }
    catch {
        Write-Error "Failed to test PATH entries: $_"
    }
}

function Backup-Path {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$BackupPath = "$env:USERPROFILE\path_backup.json"
    )

    try {
        $backup = @{
            Timestamp = Get-Date
            Machine = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
            User = [System.Environment]::GetEnvironmentVariable("PATH", "User")
        }

        $backup | ConvertTo-Json | Set-Content -Path $BackupPath
        Write-Host "PATH backup created at: $BackupPath" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to backup PATH: $_"
    }
}

function Restore-Path {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$BackupPath,

        [Parameter()]
        [ValidateSet('User', 'Machine', 'All')]
        [string]$Scope = 'All'
    )

    try {
        if (-not (Test-Path $BackupPath)) {
            throw "Backup file not found: $BackupPath"
        }

        $backup = Get-Content -Path $BackupPath | ConvertFrom-Json

        if ($Scope -in @('Machine', 'All')) {
            [System.Environment]::SetEnvironmentVariable("PATH", $backup.Machine, "Machine")
        }
        if ($Scope -in @('User', 'All')) {
            [System.Environment]::SetEnvironmentVariable("PATH", $backup.User, "User")
        }

        Update-PathEnvironment
        Write-Host "PATH restored from backup: $BackupPath" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to restore PATH: $_"
    }
}

function Optimize-Path {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateSet('User', 'Machine', 'All')]
        [string]$Scope = 'All'
    )

    try {
        if ($Scope -in @('Machine', 'All')) {
            $machinePath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") -split ';' |
                Where-Object { $_ } | Select-Object -Unique | Sort-Object
            [System.Environment]::SetEnvironmentVariable("PATH", ($machinePath -join ';'), "Machine")
        }

        if ($Scope -in @('User', 'All')) {
            $userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User") -split ';' |
                Where-Object { $_ } | Select-Object -Unique | Sort-Object
            [System.Environment]::SetEnvironmentVariable("PATH", ($userPath -join ';'), "User")
        }

        Update-PathEnvironment
        Write-Host "PATH has been optimized (sorted and duplicates removed)." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to optimize PATH: $_"
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Add-ToPath',
    'Remove-FromPath',
    'Get-PathContent',
    'Update-PathEnvironment',
    'Get-InstalledApplications',
    'Add-GitVimToPath',
    'Test-PathEntries',
    'Backup-Path',
    'Restore-Path',
    'Optimize-Path'
)
