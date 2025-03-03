# Fetch the PATH environment variable
$path = $env:PATH

# Split the PATH into an array using ':' as the delimiter
$pathArray = $path -split ';'

# Display the title
Write-Host "Contents of the PATH Environment Variable:" -ForegroundColor Cyan

# Loop through each path in the array and display it
foreach($item in $pathArray) {
    Write-Host "- $item" -ForegroundColor Yellow
}