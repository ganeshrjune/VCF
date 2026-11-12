#requires -Modules VMware.PowerCLI
[CmdletBinding()]
param(
    [string]$VIServer = $env:VCENTER_SERVER,
    [string]$TagCategory = "Automation",
    [string]$TagName = "ManagedBy-GitHubActions",
    [switch]$Apply
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($VIServer)) {
    throw "Set VCENTER_SERVER or pass -VIServer."
}
if ([string]::IsNullOrWhiteSpace($env:VCENTER_USERNAME) -or
    [string]::IsNullOrWhiteSpace($env:VCENTER_PASSWORD)) {
    throw "Set VCENTER_USERNAME and VCENTER_PASSWORD as environment variables."
}

Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP:$false -Confirm:$false | Out-Null
# Lab compatibility only. Prefer a trusted vCenter certificate in production.
Set-PowerCLIConfiguration -Scope User -InvalidCertificateAction Warn -Confirm:$false | Out-Null

$securePassword = ConvertTo-SecureString $env:VCENTER_PASSWORD -AsPlainText -Force
$credential = [System.Management.Automation.PSCredential]::new($env:VCENTER_USERNAME, $securePassword)
$connection = $null

try {
    Write-Host "Connecting to vCenter: $VIServer"
    $connection = Connect-VIServer -Server $VIServer -Credential $credential -ErrorAction Stop

    $category = Get-TagCategory -Name $TagCategory -Server $connection -ErrorAction SilentlyContinue
    $tag = Get-Tag -Name $TagName -Category $TagCategory -Server $connection -ErrorAction SilentlyContinue

    if ($category -and ($category.Cardinality -ne "Multiple" -or
        $category.EntityType -notcontains "VirtualMachine")) {
        throw "Existing category '$TagCategory' must use Multiple cardinality and include VirtualMachine entity type."
    }

    $vms = @(Get-VM -Server $connection | Sort-Object Name)
    if ($vms.Count -eq 0) {
        Write-Warning "No virtual machines were found."
        return
    }

    Write-Host "Found $($vms.Count) VM(s)."
    if (-not $Apply) {
        Write-Host "DRY RUN: no vCenter changes will be made." -ForegroundColor Yellow
        if (-not $category) { Write-Host "[PLAN] Create category '$TagCategory' (Multiple, VirtualMachine)." }
        if (-not $tag) { Write-Host "[PLAN] Create tag '$TagName' in category '$TagCategory'." }
    }

    if ($Apply) {
        if (-not $category) {
            $category = New-TagCategory -Name $TagCategory -Cardinality Multiple -EntityType VirtualMachine -Description "Managed through GitHub Actions" -Server $connection
            Write-Host "Created category '$TagCategory'."
        }
        if (-not $tag) {
            $tag = New-Tag -Name $TagName -Category $category -Description "Applied by GitHub Actions" -Server $connection
            Write-Host "Created tag '$TagName'."
        }
    }

    $changed = 0
    foreach ($vm in $vms) {
        $existing = @()
        if ($tag) {
            $existing = @(Get-TagAssignment -Entity $vm -Server $connection -ErrorAction SilentlyContinue |
                Where-Object { $_.Tag.Id -eq $tag.Id })
        }

        if ($existing.Count -gt 0) {
            Write-Host "[SKIP] $($vm.Name) already has '$TagName'."
            continue
        }

        if ($Apply) {
            New-TagAssignment -Tag $tag -Entity $vm -Server $connection | Out-Null
            Write-Host "[TAGGED] $($vm.Name)"
        }
        else {
            Write-Host "[PLAN] Tag '$($vm.Name)' with '$TagName'."
        }
        $changed++
    }

    if ($Apply) {
        Write-Host "Completed. Tagged $changed VM(s)."
    }
    else {
        Write-Host "Dry run complete. $changed VM(s) would be tagged. Set apply=true in GitHub Actions to make changes."
    }
}
finally {
    if ($connection) {
        Disconnect-VIServer -Server $connection -Confirm:$false | Out-Null
    }
}
