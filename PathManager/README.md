# PathManager

A PowerShell module for managing PATH environment variables and system utilities. PathManager provides robust functionality for viewing, modifying, and managing system PATH entries, as well as listing installed applications.

## Features

* **PATH Management**
  * Add new directories to User or Machine PATH
  * Remove directories from PATH
  * View all PATH entries with their existence status
  * Support for both User and Machine scope modifications
  * Automatic path normalization and validation
  * Prevention of duplicate PATH entries
  * Validation of PATH entries with optional cleanup
  * Backup and restore capabilities for PATH environment
  * Path optimization with duplicate removal and sorting

* **System Utilities**
  * List all installed applications with detailed information (Name, Version, Publisher, Install Location)
  * Filter installed applications by name
  * Refresh PATH environment in current session without restart
  * Integration with Git tools (automatic detection and addition of Git's Vim to PATH)

## Installation

1. Clone or download this repository
2. Import the module using one of these methods:

```powershell
# Option 1: Import directly from the path
Import-Module ./PathManager/PathManager.psd1

# Option 2: Install to a PowerShell module directory
Copy-Item ./PathManager "$env:UserProfile\Documents\PowerShell\Modules" -Recurse
Import-Module PathManager
```

## Basic Usage

### Managing PATH Entries

```powershell
# Add a directory to USER PATH
Add-ToPath -Path "C:\MyTools" -Scope User

# Remove a directory from PATH
Remove-FromPath -Path "C:\OldTools" -Scope User

# View all PATH entries with their existence status
Get-PathContent -Scope All

# Refresh the current session's PATH
Update-PathEnvironment
```

### Additional Features

```powershell
# List installed applications
Get-InstalledApplications
# Filter applications by name
Get-InstalledApplications -NameFilter "Microsoft"

# Add Git's Vim to PATH (if Git is installed)
Add-GitVimToPath
```

## Running Tests

The module uses Pester for testing. To run the tests:

1. Ensure Pester is installed:
```powershell
Install-Module -Name Pester -Force
```

2. Run the tests:
```powershell
Invoke-Pester ./PathManager/Tests/PathManager.Tests.ps1
```

## API Reference

### Add-ToPath
Adds a directory to the system or user PATH.
```powershell
Add-ToPath -Path <string> [-Scope <string>]
```
- `Path`: Directory to add (required)
- `Scope`: 'User' or 'Machine' (default: 'User')

### Remove-FromPath
Removes specified directories from PATH.
```powershell
Remove-FromPath -Paths <string[]> [-Scope <string>]
```
- `Paths`: Array of paths to remove (required)
- `Scope`: 'User' or 'Machine' (default: 'User')

### Get-PathContent
Lists all PATH entries with their scope and existence status.
```powershell
Get-PathContent [-Scope <string>]
```
- `Scope`: 'User', 'Machine', or 'All' (default: 'All')

### Update-PathEnvironment
Refreshes the current session's PATH environment variable.
```powershell
Update-PathEnvironment
```

### Get-InstalledApplications
Lists installed applications with optional name filtering.
```powershell
Get-InstalledApplications [-NameFilter <string>]
```
- `NameFilter`: Optional filter for application names

### Add-GitVimToPath
Adds Git's usr/bin directory (containing Vim) to the user PATH.
```powershell
Add-GitVimToPath
```

### Test-PathEntries
Validates all PATH entries and optionally removes invalid entries.
```powershell
Test-PathEntries [-Scope <string>] [-RemoveInvalid]
```
- `Scope`: 'User', 'Machine', or 'All' (default: 'All')
- `RemoveInvalid`: Switch to automatically remove invalid entries

### Backup-Path
Creates a backup of the current PATH environment variables.
```powershell
Backup-Path [-BackupPath <string>]
```
- `BackupPath`: Path for the backup file (default: $env:USERPROFILE\path_backup.json)

### Restore-Path
Restores PATH environment variables from a backup.
```powershell
Restore-Path -BackupPath <string> [-Scope <string>]
```
- `BackupPath`: Path to the backup file (required)
- `Scope`: 'User', 'Machine', or 'All' (default: 'All')

### Optimize-Path
Sorts PATH entries and removes duplicates.
```powershell
Optimize-Path [-Scope <string>]
```
- `Scope`: 'User', 'Machine', or 'All' (default: 'All')
