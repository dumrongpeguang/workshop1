<#
.SYNOPSIS
    Resolves DNS records for one or more hostnames and reports success or failure.
.PARAMETER ComputerName
    One or more hostnames to resolve.
.PARAMETER RecordType
    DNS record type to query. Defaults to A.
.EXAMPLE
    .\DNS-Test.ps1 -ComputerName example.com -RecordType MX
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string[]]$ComputerName,

    [ValidateSet("A", "AAAA", "CNAME", "MX", "TXT", "NS")]
    [string]$RecordType = "A"
)

foreach ($name in $ComputerName) {
    try {
        $records = Resolve-DnsName -Name $name -Type $RecordType -ErrorAction Stop

        foreach ($record in $records) {
            [pscustomobject]@{
                Name       = $name
                Type       = $record.Type
                Result     = if ($record.IPAddress) { $record.IPAddress } else { $record.NameHost }
                Status     = "Success"
            }
        }
    }
    catch {
        [pscustomobject]@{
            Name   = $name
            Type   = $RecordType
            Result = $null
            Status = "Failed: $($_.Exception.Message)"
        }
        Write-Warning "DNS resolution failed for $name : $_"
    }
}
