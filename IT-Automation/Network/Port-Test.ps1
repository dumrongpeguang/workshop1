<#
.SYNOPSIS
    Tests TCP port connectivity to one or more hosts.
.PARAMETER ComputerName
    One or more hostnames or IP addresses to test.
.PARAMETER Port
    One or more TCP ports to test on each host.
.EXAMPLE
    .\Port-Test.ps1 -ComputerName SRV01 -Port 80,443,3389
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string[]]$ComputerName,

    [Parameter(Mandatory = $true)]
    [int[]]$Port
)

foreach ($target in $ComputerName) {
    foreach ($p in $Port) {
        $result = Test-NetConnection -ComputerName $target -Port $p -WarningAction SilentlyContinue

        [pscustomobject]@{
            Target    = $target
            Port      = $p
            Status    = if ($result.TcpTestSucceeded) { "Open" } else { "Closed/Filtered" }
        }

        if (-not $result.TcpTestSucceeded) {
            Write-Warning "$target : $p is closed or filtered"
        }
    }
}
