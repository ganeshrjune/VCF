#requires -Modules VMware.PowerCLI
[CmdletBinding()]
param(
    [string]$VIServer = $env:VCENTER_SERVER
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($VIServer)) {
    throw "Set VCENTER_SERVER or pass -VIServer."
}
if ([string]::IsNullOrWhiteSpace($env:VCENTER_USERNAME)) {
    throw "Set VCENTER_USERNAME as an environment variable."
}
if ([string]::IsNullOrWhiteSpace($env:VCENTER_PASSWORD)) {
    throw "Set VCENTER_PASSWORD as an environment variable."
}

# Session-only settings: do not persist PowerCLI configuration on the runner.
# Warn is suitable for a lab with a self-signed certificate; use a trusted
# certificate and strict validation for production environments.
Set-PowerCLIConfiguration -Scope Session -InvalidCertificateAction Warn -ParticipateInCEIP:$false -Confirm:$false | Out-Null

$securePassword = ConvertTo-SecureString $env:VCENTER_PASSWORD -AsPlainText -Force
$credential = [System.Management.Automation.PSCredential]::new(
    $env:VCENTER_USERNAME,
    $securePassword
)

$connection = $null

try {
    Write-Host "Testing connection to vCenter: $VIServer"
    $connection = Connect-VIServer -Server $VIServer -Credential $credential -ErrorAction Stop

    $serviceInstance = Get-View -Id "ServiceInstance" -Server $connection -ErrorAction Stop
    $about = $serviceInstance.Content.About
    $vmCount = @(Get-VM -Server $connection -ErrorAction Stop).Count

    Write-Host ""
    Write-Host "vCenter connection successful." -ForegroundColor Green
    [PSCustomObject]@{
        Server      = $connection.Name
        Product     = $about.Name
        Version     = $about.Version
        Build       = $about.Build
        ApiVersion  = $about.ApiVersion
        VisibleVMs  = $vmCount
        ConnectedAs = $env:VCENTER_USERNAME
    } | Format-List
}
catch {
    Write-Error "vCenter connection test failed: $($_.Exception.Message)"
    throw
}
finally {
    if ($connection) {
        Disconnect-VIServer -Server $connection -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
        Write-Host "Disconnected from vCenter."
    }
}
