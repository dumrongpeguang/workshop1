<#
.SYNOPSIS
    Restarts the Print Spooler service and clears the print queue on local or remote computers.
.PARAMETER ComputerName
    One or more computer names to target. Defaults to the local computer.
.PARAMETER ClearQueue
    If specified, clears pending print jobs before restarting the spooler.
.EXAMPLE
    .\Restart-Spooler.ps1 -ComputerName PRINTSRV01 -ClearQueue
#>
[CmdletBinding()]
param(
    [string[]]$ComputerName = $env:COMPUTERNAME,
    [switch]$ClearQueue
)

foreach ($computer in $ComputerName) {
    try {
        if ($ClearQueue) {
            $spoolPath = "\\$computer\c$\Windows\System32\spool\PRINTERS"
            Stop-Service -InputObject (Get-Service -Name Spooler -ComputerName $computer) -Force -ErrorAction Stop
            Get-ChildItem -Path $spoolPath -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
        }

        $service = Get-Service -Name Spooler -ComputerName $computer -ErrorAction Stop
        Restart-Service -InputObject $service -Force -ErrorAction Stop

        Write-Host "Spooler restarted successfully on $computer" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to restart Spooler on $computer : $_"
    }
}
