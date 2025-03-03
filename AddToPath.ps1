$newPath = "C:\Users\Baalateja.Kataru\AppData\Local\Programs\Git\bin"

# Check if the path already exists in PATH to avoid duplicates
$currentPath = $env:PATH -split ';'

if ($currentPath -notcontains $newPath) {
    # Add the new path to the environment variable for the current session
    $env:PATH = "$env:PATH;$newPath"

    # Permanent change to PATH for future sessions (for the current user)
    [Environment]::SetEnvironmentVariable("Path", $env:PATH, [System.EnvironmentVariableTarget]::User)

    Write-Host "Successfully added '$newPath' to the PATH." -ForegroundColor Green
} else {
    Write-Host "The path '$newPath' is already in the PATH." -ForegroundColor Yellow
}
