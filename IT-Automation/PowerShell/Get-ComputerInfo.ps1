<#
.SYNOPSIS
    Collects basic hardware, OS, and network information from local or remote computers.
.PARAMETER ComputerName
    One or more computer names to query. Defaults to the local computer.
.EXAMPLE
    .\Get-ComputerInfo.ps1 -ComputerName SRV01,SRV02 | Format-Table -AutoSize
#>
[CmdletBinding()]
param(
    [string[]]$ComputerName = $env:COMPUTERNAME
)

foreach ($computer in $ComputerName) {
    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $computer -ErrorAction Stop
        $cs = Get-CimInstance -ClassName Win32_ComputerSystem -ComputerName $computer -ErrorAction Stop
        $bios = Get-CimInstance -ClassName Win32_BIOS -ComputerName $computer -ErrorAction Stop
    }
    catch {
        Write-Warning "Unable to query $computer : $_"
        continue
    }

    [pscustomobject]@{
        ComputerName    = $computer
        Manufacturer    = $cs.Manufacturer
        Model           = $cs.Model
        OSName          = $os.Caption
        OSVersion       = $os.Version
        SerialNumber    = $bios.SerialNumber
        TotalMemoryGB   = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
        LastBootUpTime  = $os.LastBootUpTime
    }
}
