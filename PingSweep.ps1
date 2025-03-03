<#
.SYNOPSIS
Performs a multithreaded ping sweep and port scan on a specified IP range.

.DESCRIPTION
This script performs a ping sweep to identify live hosts within a given IP range and then conducts a port scan on the live hosts to detect open ports. It utilizes multithreading for enhanced performance and is compatible with PowerShell 5.1.

.PARAMETER IPAddressRange
The IP address range to scan in CIDR notation (e.g., "192.168.1.0/24") or a single IP address.

.PARAMETER Ports
A comma-separated list of ports to scan (e.g., "80,443,3389") or a port range (e.g., "1-1024").

.PARAMETER Threads
The number of threads to use for parallel processing. Increasing threads can improve performance but may also increase system load and potentially trigger security alerts.

.EXAMPLE
.\Invoke-PingPortScan.ps1 -IPAddressRange "192.168.1.0/24" -Ports "80,443,135,445" -Threads 50

This command will perform a ping sweep and port scan on the IP range 192.168.1.0/24, scanning ports 80, 443, 135, and 445 using 50 threads.

.NOTES
Requires PowerShell 5.1 or later.
Ensure you have necessary permissions to perform network scans.
Use responsibly and ethically.
#>
param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$IPAddressRange,

    [Parameter(Mandatory = $true, Position = 1)]
    [string]$Ports,

    [Parameter(Mandatory = $false, Position = 2)]
    [int]$Threads = 50
)

#region Helper Functions

function Get-IPAddressRange {
    param(
        [Parameter(Mandatory = $true)]
        [string]$IPRange
    )

    Write-Host "Get-IPAddressRange received IPRange: '$IPRange'" -ForegroundColor Cyan

    if ($IPRange -like "*/*") {
        Write-Host "IPRange matches CIDR pattern." -ForegroundColor Cyan
        # CIDR Notation
        try {
            Write-Host "Attempting to split IPRange..." -ForegroundColor DarkCyan
            $prefix, $cidr = $IPRange.Split('/')
            Write-Host "Split successful. Prefix: '$prefix', CIDR: '$cidr'" -ForegroundColor DarkCyan

            Write-Host "Attempting to parse prefix as IPAddress: '$prefix'" -ForegroundColor DarkCyan
            $ip = [ipaddress]::Parse($prefix)
            Write-Host "IPAddress parsing successful: '$ip'" -ForegroundColor DarkCyan

            Write-Host "Getting address bytes..." -ForegroundColor DarkCyan
            $addressBytes = $ip.GetAddressBytes()
            Write-Host "Address bytes retrieved. Value of \$ addressBytes: ${addressBytes}" -ForegroundColor DarkCyan # Debugging line

            Write-Host "Attempting to convert CIDR to integer: '$cidr'" -ForegroundColor DarkCyan
            $maskBits = [int]$cidr
            Write-Host "CIDR to integer conversion successful: '$maskBits'" -ForegroundColor DarkCyan

            Write-Host "Attempting [BitConverter]::ToInt32 with \$addressBytes..." -ForegroundColor DarkCyan # Debugging line
            $startIPLong = ([BitConverter]::ToInt32($addressBytes, 0)) - ([BitConverter]::ToInt32($addressBytes, 0) % [math]::Pow(2, (32 - $maskBits)))
            Write-Host "[BitConverter]::ToInt32 calls successful." -ForegroundColor DarkCyan


            for ($i = 0; $i -lt $numberOfAddresses; $i++) {
                $ipBytes = [BitConverter]::GetBytes($startIPLong + $i)
                [ipaddress]::new($ipBytes) | Out-Null
                yield ([ipaddress]::new($ipBytes)).IPAddressToString
            }
        }
        catch {
            Write-Error "Error parsing IP Address Range: $($_.Exception.Message)"
            return $null
        }
    }
    elseif ($IPRange -match "^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$") {
        # Single IP Address
        return $IPRange
    }
    else {
        Write-Error "Invalid IP Address Range format. Please use CIDR notation (e.g., '192.168.1.0/24') or a single IP address."
        return $null
    }
}

function Get-PortNumbers {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PortsString
    )
    $portList = @()
    if ($PortsString -like "*-*") {
        # Port Range
        try {
            $startPort, $endPort = $PortsString.Split('-')
            $startPort = [int]$startPort
            $endPort = [int]$endPort
            if ($startPort -ge 1 -and $endPort -le 65535 -and $startPort -le $endPort) {
                $portList = $startPort..$endPort
            }
            else {
                Write-Error "Invalid port range. Range must be between 1-65535 and start port must be less than or equal to end port."
                return $null
            }
        }
        catch {
            Write-Error "Invalid port range format. Please use 'start-end' format (e.g., '1-1024')."
            return $null
        }
    }
    else {
        # Comma-separated ports
        $PortsString.Split(',') | ForEach-Object {
            try {
                $port = [int]$_
                if ($port -ge 1 -and $port -le 65535) {
                    $portList += $port
                }
                else {
                    Write-Warning "Port '$_' is outside the valid port range (1-65535) and will be ignored."
                }
            }
            catch {
                Write-Warning "Invalid port format '$_'. Only numbers are allowed. Ignoring."
            }
        }
    }
    return $portList | Sort-Object -Unique
}

#endregion Helper Functions

Write-Host "Starting Ping Sweep and Port Scan..." -ForegroundColor Green
Write-Host "IP Range: $($IPAddressRange)" -ForegroundColor Green
Write-Host "Ports: $($Ports)" -ForegroundColor Green
Write-Host "Threads: $($Threads)" -ForegroundColor Green
Write-Host " "

# Get IP Addresses to Scan
$IPAddresses = Get-IPAddressRange -IPRange $IPAddressRange
if (-not $IPAddresses) {
    Write-Error "Failed to parse IP Address Range. Exiting."
    return
}
if ($IPAddresses -is [string]) {
    $IPAddresses = @($IPAddresses) # Ensure it's an array even for single IP
}

# Get Port Numbers to Scan
$PortNumbers = Get-PortNumbers -PortsString $Ports
if (-not $PortNumbers) {
    Write-Error "Failed to parse Port Numbers. Exiting."
    return
}

Write-Host "Pinging IP range to identify live hosts..." -ForegroundColor Yellow

# Ping Sweep
$LiveHosts = @()
$PingJobs = @()

foreach ($IP in $IPAddresses) {
    $PingJobs += Start-Job -ScriptBlock {
        param($CurrentIP)
        if (Test-Connection -ComputerName $CurrentIP -Count 1 -Quiet) {
            Write-Output $CurrentIP
        }
    } -ArgumentList $IP
    if ($PingJobs.Count -ge $Threads) {
        while ($PingJobs.Count -ge $Threads) {
            Start-Sleep -Milliseconds 100
            $PingJobs = $PingJobs | Where-Object {$_.State -ne 'Completed'}
        }
    }
}

# Wait for all Ping Jobs to complete and collect results
Write-Host "Waiting for Ping Sweep to complete..." -ForegroundColor Yellow
while ($PingJobs) {
    Start-Sleep -Seconds 1
    $PingJobs = $PingJobs | Where-Object {$_.State -ne 'Completed'}
}

foreach ($Job in $PingJobs) {
    $LiveHosts += Receive-Job -Job $Job
    Remove-Job -Job $Job
}

if ($LiveHosts) {
    Write-Host "Ping Sweep Complete. Live hosts found:" -ForegroundColor Green
    $LiveHosts | ForEach-Object { Write-Host "  $_" }
    Write-Host " "
} else {
    Write-Host "Ping Sweep Complete. No live hosts found in the specified range." -ForegroundColor Yellow
    return # Exit if no live hosts to scan ports on
}


Write-Host "Starting Port Scan on live hosts..." -ForegroundColor Yellow

# Port Scan
$ScanResults = @()
$ScanJobs = @()

foreach ($LiveHost in $LiveHosts) {
    foreach ($Port in $PortNumbers) {
        $ScanJobs += Start-Job -ScriptBlock {
            param($CurrentHost, $CurrentPort)
            $TCPTest = Test-NetConnection -ComputerName $CurrentHost -Port $CurrentPort -InformationLevel Quiet -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if ($TCPTest) {
                Write-Output "${CurrentHost}:${CurrentPort} - Open"
            }
        } -ArgumentList $LiveHost, $Port
        if ($ScanJobs.Count -ge $Threads) {
            while ($ScanJobs.Count -ge $Threads) {
                Start-Sleep -Milliseconds 100
                $ScanJobs = $ScanJobs | Where-Object {$_.State -ne 'Completed'}
            }
        }
    }
}

# Wait for all Scan Jobs to complete and collect results
Write-Host "Waiting for Port Scan to complete..." -ForegroundColor Yellow
while ($ScanJobs) {
    Start-Sleep -Seconds 1
    $ScanJobs = $ScanJobs | Where-Object {$_.State -ne 'Completed'}
}

foreach ($Job in $ScanJobs) {
    $ScanResults += Receive-Job -Job $Job
    Remove-Job -Job $Job
}

Write-Host " "
Write-Host "Port Scan Complete. Open ports found:" -ForegroundColor Green

if ($ScanResults) {
    $ScanResults | ForEach-Object { Write-Host "  $_" }
} else {
    Write-Host "  No open ports found on the live hosts for the specified ports." -ForegroundColor Yellow
}

Write-Host " "
Write-Host "Script finished." -ForegroundColor Green