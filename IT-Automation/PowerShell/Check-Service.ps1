<#
.SYNOPSIS
    Checks the status of one or more Windows services and optionally restarts them if stopped.
.PARAMETER ServiceName
    Name(s) of the service(s) to check.
.PARAMETER ComputerName
    Target computer. Defaults to the local computer.
.PARAMETER AutoRestart
    If specified, stopped services will be started automatically.
.EXAMPLE
    .\Check-Service.ps1 -ServiceName Spooler,BITS -AutoRestart
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string[]]$ServiceName,

    [string]$ComputerName = $env:COMPUTERNAME,

    [switch]$AutoRestart
)

foreach ($name in $ServiceName) {
    try {
        $service = Get-Service -Name $name -ComputerName $ComputerName -ErrorAction Stop
    }
    catch {
        Write-Warning "Service '$name' not found on $ComputerName : $_"
        continue
    }

    [pscustomobject]@{
        ComputerName = $ComputerName
        ServiceName  = $service.Name
        DisplayName  = $service.DisplayName
        Status       = $service.Status
    }

    if ($service.Status -ne 'Running') {
        Write-Warning "$name on $ComputerName is $($service.Status)"

        if ($AutoRestart) {
            try {
                Start-Service -InputObject $service -ErrorAction Stop
                Write-Host "Started service '$name' on $ComputerName" -ForegroundColor Green
            }
            catch {
                Write-Error "Failed to start service '$name' on $ComputerName : $_"
            }
        }
    }
}
