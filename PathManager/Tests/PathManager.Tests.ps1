BeforeAll {
    # Import the module
    $modulePath = Split-Path $PSScriptRoot -Parent
    Import-Module $modulePath -Force
}

Describe "PathManager Module Tests" {
    Context "Add-ToPath" {
        BeforeEach {
            # Create a temporary test directory
            $testPath = Join-Path $TestDrive "TestDir"
            New-Item -Path $testPath -ItemType Directory -Force
            
            # Backup current PATH
            $script:originalPath = $env:PATH
        }

        AfterEach {
            # Restore original PATH
            $env:PATH = $script:originalPath
            
            # Clean up test directory
            Remove-Item -Path $testPath -Force -Recurse -ErrorAction SilentlyContinue
        }

        It "Should add a valid path to USER PATH" {
            Add-ToPath -Path $testPath -Scope User
            $paths = [System.Environment]::GetEnvironmentVariable("PATH", "User") -split ';'
            $paths | Should -Contain $testPath
        }

        It "Should not add duplicate paths" {
            Add-ToPath -Path $testPath -Scope User
            Add-ToPath -Path $testPath -Scope User
            $paths = ([System.Environment]::GetEnvironmentVariable("PATH", "User") -split ';').Where({ $_ -eq $testPath })
            $paths.Count | Should -Be 1
        }

        It "Should throw on invalid path" {
            $ErrorActionPreference = 'Stop'
            Write-Host "Running invalid path test..."
            $result = { Add-ToPath -Path "C:\NonExistentPath123" -Scope User }
            $result | Should -Throw -Because "Adding an invalid path should throw an error"
        }
    }

    Context "Remove-FromPath" {
        BeforeEach {
            $testPath = Join-Path $TestDrive "TestDir"
            New-Item -Path $testPath -ItemType Directory -Force
            $script:originalPath = $env:PATH
            Add-ToPath -Path $testPath -Scope User
        }

        AfterEach {
            $env:PATH = $script:originalPath
            Remove-Item -Path $testPath -Force -Recurse -ErrorAction SilentlyContinue
        }

        It "Should remove path from USER PATH" {
            Remove-FromPath -Paths $testPath -Scope User
            $paths = [System.Environment]::GetEnvironmentVariable("PATH", "User") -split ';'
            $paths | Should -Not -Contain $testPath
        }

        It "Should handle multiple paths" {
            $testPath2 = Join-Path $TestDrive "TestDir2"
            New-Item -Path $testPath2 -ItemType Directory -Force
            Add-ToPath -Path $testPath2 -Scope User

            Remove-FromPath -Paths @($testPath, $testPath2) -Scope User
            $paths = [System.Environment]::GetEnvironmentVariable("PATH", "User") -split ';'
            $paths | Should -Not -Contain $testPath
            $paths | Should -Not -Contain $testPath2
        }
    }

    Context "Get-PathContent" {
        It "Should return path entries" {
            $result = Get-PathContent
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [PSCustomObject]
            $result[0].PSObject.Properties.Name | Should -Contain 'Path'
            $result[0].PSObject.Properties.Name | Should -Contain 'Scope'
            $result[0].PSObject.Properties.Name | Should -Contain 'Exists'
        }

        It "Should filter by scope correctly" {
            $userPaths = Get-PathContent -Scope User
            $machinePaths = Get-PathContent -Scope Machine
            $allPaths = Get-PathContent -Scope All

            $userPaths | ForEach-Object { $_.Scope | Should -Be 'User' }
            $machinePaths | ForEach-Object { $_.Scope | Should -Be 'Machine' }
            $allPaths.Count | Should -BeGreaterThan ($userPaths.Count + $machinePaths.Count - 1)
        }
    }

    Context "Update-PathEnvironment" {
        BeforeEach {
            $script:originalPath = $env:PATH
        }

        AfterEach {
            $env:PATH = $script:originalPath
        }

        It "Should update current session PATH" {
            Update-PathEnvironment
            $env:PATH | Should -Not -BeNullOrEmpty
            $env:PATH.Split(';') | Should -Not -BeNullOrEmpty
        }
    }

    Context "Get-InstalledApplications" {
        It "Should return installed applications" {
            $apps = Get-InstalledApplications
            $apps | Should -Not -BeNullOrEmpty
            $apps | Should -BeOfType [PSCustomObject]
            $apps[0].PSObject.Properties.Name | Should -Contain 'Name'
            $apps[0].PSObject.Properties.Name | Should -Contain 'Version'
        }

        It "Should filter applications by name" {
            $filter = "Microsoft"
            $apps = Get-InstalledApplications -NameFilter $filter
            $apps | ForEach-Object { $_.Name | Should -BeLike "*$filter*" }
        }
    }

    Context "Add-GitVimToPath" {
        BeforeEach {
            $script:originalPath = $env:PATH
        }

        AfterEach {
            $env:PATH = $script:originalPath
        }

        It "Should add Git usr/bin to path if Git is installed" {
            # Skip if Git is not installed
            $gitExists = ($env:PATH -split ';') | Where-Object { $_ -match "\\git\\(cmd|bin)$" }
            if (-not $gitExists) {
                Set-ItResult -Skipped -Because "Git is not installed"
                return
            }

            Add-GitVimToPath
            $usrBinPath = Join-Path (Split-Path ($gitExists | Select-Object -First 1) -Parent) "usr\bin"
            $paths = [System.Environment]::GetEnvironmentVariable("PATH", "User") -split ';'
            $paths | Should -Contain $usrBinPath
        }
    }
}