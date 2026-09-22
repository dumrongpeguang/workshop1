<#
.SYNOPSIS
    Checks free disk space on local or remote computers and warns when below a threshold.
.PARAMETER ComputerName
    One or more computer names to check. Defaults to the local computer.
.PARAMETER ThresholdPercent
    Minimum free space percentage before a warning is raised. Defaults to 15.
.EXAMPLE
    .\Check-DiskSpace.ps1 -ComputerName SRV01,SRV02 -ThresholdPercent 20
#>
[CmdletBinding()]
param(
    [string[]]$ComputerName = $env:COMPUTERNAME,
    [ValidateRange(1, 99)]
    [int]$ThresholdPercent = 15
)

foreach ($computer in $ComputerName) {
    try {
        $disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" -ComputerName $computer -ErrorAction Stop
    }
    catch {
        Write-Warning "Unable to query $computer : $_"
        continue
    }

    foreach ($disk in $disks) {
        $freePercent = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 2)
        $status = if ($freePercent -lt $ThresholdPercent) { "WARNING" } else { "OK" }

        [pscustomobject]@{
            ComputerName = $computer
            Drive        = $disk.DeviceID
            SizeGB       = [math]::Round($disk.Size / 1GB, 2)
            FreeGB       = [math]::Round($disk.FreeSpace / 1GB, 2)
            FreePercent  = $freePercent
            Status       = $status
        }

        if ($status -eq "WARNING") {
            Write-Warning "$computer drive $($disk.DeviceID) is low on space: $freePercent% free"
        }
    }
}
