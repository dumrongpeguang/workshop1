<#
.SYNOPSIS
    Generates a report of Microsoft 365 license assignments for all users.
.DESCRIPTION
    Requires the Microsoft Graph PowerShell SDK (Microsoft.Graph module) and the
    User.Read.All / Organization.Read.All permission scopes.
.PARAMETER OutputPath
    Optional path to export the report as CSV.
.EXAMPLE
    .\User-License-Report.ps1 -OutputPath C:\Reports\Licenses.csv
#>
[CmdletBinding()]
param(
    [string]$OutputPath
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Users)) {
    Write-Error "Microsoft.Graph module is required. Install it with: Install-Module Microsoft.Graph -Scope CurrentUser"
    return
}

Connect-MgGraph -Scopes "User.Read.All", "Organization.Read.All" -NoWelcome

$skus = Get-MgSubscribedSku
$skuLookup = @{}
foreach ($sku in $skus) {
    $skuLookup[$sku.SkuId] = $sku.SkuPartNumber
}

$report = Get-MgUser -All -Property Id, DisplayName, UserPrincipalName, AssignedLicenses | ForEach-Object {
    $licenseNames = $_.AssignedLicenses | ForEach-Object {
        if ($skuLookup.ContainsKey($_.SkuId)) { $skuLookup[$_.SkuId] } else { $_.SkuId }
    }

    [pscustomobject]@{
        DisplayName       = $_.DisplayName
        UserPrincipalName = $_.UserPrincipalName
        LicenseCount      = $_.AssignedLicenses.Count
        Licenses          = ($licenseNames -join "; ")
    }
}

$report

if ($OutputPath) {
    $report | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
    Write-Host "Report exported to $OutputPath" -ForegroundColor Green
}
