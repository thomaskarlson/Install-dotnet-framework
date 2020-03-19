# ==============================================================================
#    .NET Installer v1.0
# ==============================================================================

param (
  [string]$netframework = "4.8",
  [string]$netcore      = "",
  [string]$arch         = "-64",
  [switch]$force        = $false
)

$version="1.0"


function Get-NetCoreSDKVersion
{
  $_installed="0.0"
  dotnet --info | find  "[$Env:ProgramFiles\dotnet\sdk]" | ForEach-Object {
    $newCoreInstalled=$_.split("[")[0].replace("-preview-",".").trim()
    if ([System.Version]$newCoreInstalled -gt [System.Version]$_installed)
    {
      $_installed=$newCoreInstalled
    }
  }
  $_installed
}

function Get-NetFrameworkVersion
{
  $netFwInstalled=(Get-ItemProperty "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\").Release
  $netFwInstalled
}

function Get-NetFrameworkRequired($version)
{
  $_req=0
  switch($version) {
    "4.5"       { $_req=378389; break; }
    "4.5.1"     { $_req=378675; break; }
    "4.5.2"     { $_req=379893; break; }
    "4.6"	    { $_req=393295; break; }
    "4.6.1"	    { $_req=394254; break; }
    "4.6.2"	    { $_req=394802; break; }
    "4.7"	    { $_req=460798; break; }
    "4.7.1"	    { $_req=461308; break; }
    "4.7.2"	    { $_req=461808; break; }
    "4.8"	    { $_req=528040; break; }
    default     { break }
  }
  $_req
}

function Get-NetFrameworkPackage($version)
{
  $_pkg=0
  switch($version) {
    "4.5"       { $_pkg=0;          break; }
    "4.5.1"     { $_pkg=0;          break; }
    "4.5.2"     { $_pkg=0;          break; }
    "4.6"	    { $_pkg=0;          break; }
    "4.6.1"	    { $_pkg=0;          break; }
    "4.6.2"	    { $_pkg=0;          break; }
    "4.7"	    { $_pkg=55168;      break; }
    "4.7.1"	    { $_pkg=56119;      break; }
    "4.7.2"	    { $_pkg=0;          break; }
    "4.8"	    { $_pkg=2088517;    break; }
    default     { break }
  }
  $_pkg
}

function GetAndInstallPackage($packageId, $netver)
{
  $nver=$netver.replace(".","")
  $InstallerPath="$Env:TEMP\ndp$nver-devpack-enu.exe"  
  
  Write-Host "Downloading installer to '$InstallerPath' ..."

  $progressPreference = 'silentlyContinue'
  Invoke-WebRequest -Uri "http://go.microsoft.com/fwlink/?linkid=$packageId" -OutFile "$InstallerPath"
  $progressPreference = 'Continue'

  if ([System.IO.File]::Exists($InstallerPath))
  {
    Write-Host "Installer downloaded"
    Write-Host "Launching installer, it might take some time, please wait..."
    $stopwatch =  [system.diagnostics.stopwatch]::StartNew()
    & "$InstallerPath" /q /norestart | Out-null
    $elapsed = $stopwatch.Elapsed.TotalSeconds
    Write-Host "Installer ran for $elapsed seconds."
    $stopwatch.Stop()
    $_ok=$true
    switch ($lastexitcode)
    {
        0       { Write-Host "Installation completed successfully."; break; }
        1602    { Write-Host "The user canceled installation." -ForegroundColor red; $_ok=$false; break; }
        1603    { Write-Host "A fatal error occurred during installation." -ForegroundColor red;  $_ok=$false; break; }
        1641    { Write-Host "A restart is required to complete the installation.";
                  Write-Host "This message indicates success.";     break; }
        3010    { Write-Host "A restart is required to complete the installation.";
                  Write-Host "This message indicates success.";     break; }
        5100    { Write-Hosts "The user's computer does not meet system requirements." -ForegroundColor red;$_ok=$false; break; }
        default {Write-Host "Error! Unknown error ($lastexitcode)" -ForegroundColor red; $_ok=$false; break; }
    }
    Remove-Item $InstallerPath
    return $_ok
  }
  else
  {
    Write-Host "Error! Cannot download .NET Framework installer" -ForegroundColor red
    return 1
  }
}

Write-Host "==============================================================================" -ForegroundColor green
Write-Host " .NET Installer v$version" -ForegroundColor green
Write-Host "==============================================================================" -ForegroundColor green
Write-Host ""

Write-Host "Checking for .NET Framework v$netframework availability ..."

$NetFWInstalled=(Get-NetFrameworkVersion)
$NetFWRequired=(Get-NetFrameworkRequired($netframework))

if($NetFWInstalled -lt $NetFWRequired)
{
  Write-Host ".NET Framework installation required"
  $Package=(Get-NetFrameworkPackage($netframework))
  Write-Host "Installing .NET Framework v$netframework ..."
  $_res=(GetAndInstallPackage -packageId $Package -netver $netframework)
  if ($_res)
  {
    Write-Host "Done." -ForegroundColor green
    exit 0
  } else {
    Write-Host "Error." -ForegroundColor red
    exit 1
  }
}
else
{
  Write-Host ".NET Framework v$netframework already installed"
  exit 0
}
