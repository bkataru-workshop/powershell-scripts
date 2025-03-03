# Function to find Git's installation path from the PATH environment variable
function Find-GitPath {
    $paths = $env:PATH -split ';'
    foreach($path in $paths) {
        if ($path -match "\\git\\cmd$" -or $path -match "\\git\\bin$") {
            return $path
        }
    }
    throw "Git installation path not found in PATH."
}

try {
    # Locate where the git installation's path is
    $gitPath = Find-GitPath
    
    # Construct the path to the adjacent \usr\bin directory
    $usrBinPath = Join-Path (Split-Path $gitPath -Parent) "\usr\bin"

    # Check if the constructed path exists
    if (Test-Path $usrBinPath) {
        # Check if this path is already in PATH to avoid duplicates
        $currentPath = $env:PATH -split ';'
        if ($currentPath -notcontains $usrBinPath) {
            # Add the new path to the environment
            $env:PATH = "$env:PATH;$usrBinPath"

            # Permanent change to PATH for future sessions (for current user)
            [System.Environment]::SetEnvironmentVariable("Path", $env:PATH, [System.EnvironmentVariableTarget]::User)

            Write-Host "Successfully added '$usrBinPath' to the PATH." -ForegroundColor Green
        } else {
            Write-Host "The path '$usrBinPath' is already in the PATH." -ForegroundColor Yellow
        }
    } else {
        Write-Host "The path '$usrBinPath' does not exist." -ForegroundColor Red
    }
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
}