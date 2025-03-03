function Show-App {
    $RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall", "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"

    $entries = Get-ChildItem -Path $RegPath # | Get-ItemProperty | Select-Object -ExpandProperty DisplayName

    foreach($obj in $entries) {
        $dname = $obj.GetValue("DisplayName") 
        Write-Output $dname
        # if ($null -ne $dname -and $dname -contains $args[0]) {
        #     Write-Output "Found $($dname)"
        # }
    }
}

Show-App "SolarWinds"