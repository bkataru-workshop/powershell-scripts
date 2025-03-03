@{
    RootModule = 'PathManager.psm1'
    ModuleVersion = '1.1.0'
    GUID = 'c3b39024-1f08-4d8f-a704-8d4b471b241e'
    Author = 'System Administrator'
    Description = 'A PowerShell module for managing PATH environment variable and system utilities'
    PowerShellVersion = '5.1'
    
    # Functions to export
    FunctionsToExport = @(
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
    
    # Cmdlets to export
    CmdletsToExport = @()
    
    # Variables to export
    VariablesToExport = '*'
    
    # Aliases to export
    AliasesToExport = @()
    
    PrivateData = @{
        PSData = @{
            Tags = @('Path', 'Environment', 'System', 'Git', 'Vim', 'Backup', 'Restore', 'Optimization')
            LicenseUri = ''
            ProjectUri = ''
            ReleaseNotes = '
            1.1.0
            - Added Test-PathEntries function for validating PATH entries
            - Added Backup-Path and Restore-Path for PATH environment backups
            - Added Optimize-Path for removing duplicates and sorting PATH entries
            - Enhanced error handling and reporting

            1.0.0
            - Initial release
            - Added PATH management functions
            - Added application listing functionality
            - Added Git/Vim integration
            '
        }
    }
}
