param (
    [string]$appName,
    [string]$domainName,
    [string]$siteRoot,
    [string]$AppPoolName,
    [string]$DotNetVersion,
    [string]$ServiceAccount,
    [string]$ServicePassword
)

$appPath = "$siteRoot\$appName"

# Ensure IIS Module is available
Import-Module WebAdministration -ErrorAction Stop

# Create Application Directory if not exists
if (!(Test-Path $appPath)) {
    New-Item -Path $appPath -ItemType Directory -Force
    Write-Host "Created directory: $appPath"
}

# Check if App Pool exists before creating
$existingAppPool = Get-Item "IIS:\AppPools\$AppPoolName" -ErrorAction SilentlyContinue
if (-not $existingAppPool) {
    New-WebAppPool -Name $AppPoolName
    Write-Host "Application Pool '$AppPoolName' created successfully."
}

# Configure Application Pool
Set-ItemProperty "IIS:\AppPools\$AppPoolName" -Name managedRuntimeVersion -Value $DotNetVersion
Set-ItemProperty "IIS:\AppPools\$AppPoolName" -Name processModel.identityType -Value 3  # 3 = SpecificUser
Set-ItemProperty "IIS:\AppPools\$AppPoolName" -Name processModel.userName -Value $ServiceAccount
Set-ItemProperty "IIS:\AppPools\$AppPoolName" -Name processModel.password -Value $ServicePassword

Write-Host "Configured Application Pool '$AppPoolName' with service account '$ServiceAccount'."

# Create IIS Application under the site
$siteName = $domainName
$appExists = Get-WebApplication -Site $siteName | Where-Object { $_.path -eq "/$appName" }

if (-not $appExists) {
    New-WebApplication -Site $siteName -Name $appName -PhysicalPath $appPath -ApplicationPool $AppPoolName
    Write-Host "IIS Application '$appName' created under '$domainName'."
} else {
    Write-Host "IIS Application '$appName' already exists under '$domainName'."
}

# Assign Application Pool
Set-ItemProperty "IIS:\Sites\$siteName\$appName" -Name applicationPool -Value $AppPoolName
Write-Host "Assigned Application Pool '$AppPoolName' to Application '$appName'."
