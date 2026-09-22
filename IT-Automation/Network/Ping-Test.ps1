<#
.SYNOPSIS
    Tests network connectivity to one or more hosts using ICMP ping.
.PARAMETER ComputerName
    One or more hostnames or IP addresses to test.
.PARAMETER Count
    Number of ping attempts per host. Defaults to 4.
.EXAMPLE
    .\Ping-Test.ps1 -ComputerName google.com,8.8.8.8
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string[]]$ComputerName,

    [ValidateRange(1, 20)]
    [int]$Count = 4
)

foreach ($target in $ComputerName) {
    $result = Test-Connection -ComputerName $target -Count $Count -ErrorAction SilentlyContinue

    if ($result) {
        $avgLatency = ($result | Measure-Object -Property ResponseTime -Average).Average

        [pscustomobject]@{
            Target       = $target
            Status       = "Online"
            PacketsSent  = $Count
            PacketsRecv  = $result.Count
            AvgLatencyMs = [math]::Round($avgLatency, 2)
        }
    }
    else {
        [pscustomobject]@{
            Target       = $target
            Status       = "Unreachable"
            PacketsSent  = $Count
            PacketsRecv  = 0
            AvgLatencyMs = $null
        }
        Write-Warning "$target is unreachable"
    }
}
