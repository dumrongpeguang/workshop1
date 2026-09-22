<#
.SYNOPSIS
    Reports Multi-Factor Authentication (MFA) registration status for Microsoft 365 users.
.DESCRIPTION
    Requires the Microsoft Graph PowerShell SDK (Microsoft.Graph module) and the
    UserAuthenticationMethod.Read.All / User.Read.All permission scopes.
.PARAMETER UserPrincipalName
    One or more user principal names to check. If omitted, checks all users.
.EXAMPLE
    .\Check-MFA.ps1 -UserPrincipalName user@contoso.com
#>
[CmdletBinding()]
param(
    [string[]]$UserPrincipalName
)

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Users)) {
    Write-Error "Microsoft.Graph module is required. Install it with: Install-Module Microsoft.Graph -Scope CurrentUser"
    return
}

Connect-MgGraph -Scopes "UserAuthenticationMethod.Read.All", "User.Read.All" -NoWelcome

$users = if ($UserPrincipalName) {
    $UserPrincipalName | ForEach-Object { Get-MgUser -UserId $_ -ErrorAction SilentlyContinue }
}
else {
    Get-MgUser -All
}

foreach ($user in $users) {
    if (-not $user) { continue }

    $methods = Get-MgUserAuthenticationMethod -UserId $user.Id -ErrorAction SilentlyContinue
    $mfaMethods = $methods | Where-Object { $_.AdditionalProperties["@odata.type"] -ne "#microsoft.graph.passwordAuthenticationMethod" }

    [pscustomobject]@{
        UserPrincipalName = $user.UserPrincipalName
        DisplayName       = $user.DisplayName
        MfaRegistered     = [bool]($mfaMethods.Count -gt 0)
        MethodCount       = $mfaMethods.Count
    }
}
