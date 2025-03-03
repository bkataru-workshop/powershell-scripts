# RemoveFromPath.ps1

# Specify the paths to remove as an array
$pathsToRemove = @("C:\Users\Baalateja.Kataru\AppData\Local\Programs\Git\bin", "C:\Users\Baalateja.Kataru\AppData\Local\Programs\Git\usr\bin")

# Fetch the PATH environment variable
$path = $env:PATH

# Split the PATH into an array using ';' as the delimiter
$pathArray = $path -split ';'

# Remove the specified paths from the array
foreach ($pathToRemove in $pathsToRemove) {
    $pathArray = $pathArray | Where-Object { $_ -ne $pathToRemove }
}

# Join the array elements back together separated by ';'
$newPath = $pathArray -join ';'

# Set the new path string as the path
[Environment]::SetEnvironmentVariable("Path", $newPath, [System.EnvironmentVariableTarget]::User)

Write-Host "Successfully removed specified paths from the PATH." -ForegroundColor Green

