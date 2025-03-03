[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('add', 'remove', 'list', 'refresh', 'apps', 'git-vim', 'help')]
    [string]$Command = 'help',

    [Parameter(Position = 1)]
    [string[]]$Paths,

    [Parameter()]
    [ValidateSet('User', 'Machine', 'All')]
    [string]$Scope = 'User',

    [Parameter()]
    [string]$Filter
)

# Import the module
$modulePath = Split-Path $PSCommandPath -Parent
Import-Module (Join-Path $modulePath 'PathManager.psd1') -Force

function Show-Help {
    Write-Host @"
PathManager CLI - Manage PATH environment variable and system utilities

Usage:
    .\PathManagerCLI.ps1 <command> [options]

Commands:
    add <path>           Add one or more paths to PATH
        -Scope          'User' or 'Machine' (default: User)

    remove <path>        Remove one or more paths from PATH
        -Scope          'User' or 'Machine' (default: User)

    list                List all paths in PATH
        -Scope          'User', 'Machine', or 'All' (default: All)

    refresh             Refresh current session's PATH

    apps                List installed applications
        -Filter         Filter applications by name

    git-vim             Add Git's usr/bin to PATH (for Vim)

    help                Show this help message

Examples:
    # Add a path to user PATH
    .\PathManagerCLI.ps1 add "C:\Tools"

    # Remove multiple paths from machine PATH
    .\PathManagerCLI.ps1 remove "C:\Tools","C:\OldPath" -Scope Machine

    # List all paths in both user and machine PATH
    .\PathManagerCLI.ps1 list -Scope All

    # List applications containing 'Microsoft'
    .\PathManagerCLI.ps1 apps -Filter Microsoft

    # Add Git's Vim to PATH
    .\PathManagerCLI.ps1 git-vim
"@ -ForegroundColor Cyan
}

try {
    switch ($Command) {
        'add' {
            if (-not $Paths) {
                throw "Path parameter is required for add command"
            }
            foreach ($path in $Paths) {
                Add-ToPath -Path $path -Scope $Scope
            }
        }
        'remove' {
            if (-not $Paths) {
                throw "Path parameter is required for remove command"
            }
            Remove-FromPath -Paths $Paths -Scope $Scope
        }
        'list' {
            $results = Get-PathContent -Scope $Scope
            Write-Host "`nPATH Environment Variable Contents:" -ForegroundColor Cyan
            foreach ($item in $results) {
                $color = if ($item.Exists) { 'Green' } else { 'Red' }
                Write-Host ("[{0}] {1}" -f $item.Scope, $item.Path) -ForegroundColor $color
            }
            Write-Host ""
        }
        'refresh' {
            Update-PathEnvironment
        }
        'apps' {
            $apps = Get-InstalledApplications -NameFilter $Filter
            Write-Host "`nInstalled Applications:" -ForegroundColor Cyan
            foreach ($app in $apps) {
                Write-Host ("`nName: {0}" -f $app.Name) -ForegroundColor Yellow
                Write-Host ("Version: {0}" -f $app.Version)
                if ($app.Publisher) { Write-Host ("Publisher: {0}" -f $app.Publisher) }
                if ($app.InstallLocation) { Write-Host ("Location: {0}" -f $app.InstallLocation) }
            }
            Write-Host ""
        }
        'git-vim' {
            Add-GitVimToPath
        }
        'help' {
            Show-Help
        }
    }
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "`nUse '.\PathManagerCLI.ps1 help' for usage information." -ForegroundColor Yellow
    exit 1
}