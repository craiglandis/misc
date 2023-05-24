<#
This script creates a 20GB file with random data in order to create a reproducible timeout with VM Inspector with a Windows VM
https://learn.microsoft.com/en-us/troubleshoot/azure/virtual-machines/vm-inspector-azure-virtual-machines

It downloads and uses RDFC.exe to create a file containing random data. 

"fsutil file createNew" creates a large file instantly but without random data in it, so not sufficient for reproducing the timeout.

Other techniques below such as combining binary files into another file usign PowerShell Set-Content or CMD copy /B - took even longer to create a 20GB file than rdfc, or got stuck.

get-content -path $file1Path -Encoding Byte -Read 512 | set-content -path $file2Path -Encoding Byte

cmd /c copy /b $file1path + $file2path $file3Path | out-null

The script should only be used on a test VM as it replaces C:\Windows\Microsoft.NET\Framework\v4.0.30319\Config\machine.config in order to reproduce the timeout (renames original to machine.config.<timestamp>).

C:\Windows\Microsoft.NET\Framework\v4.0.30319\Config\machine.config is a file that is collected by VM Inspector and is not in use by Windows so can be swapped out with the large file.

However if you plan to use the VM for anything else you'll want to swap back in the original machine.config, which the script renames to machine.config.<timestamp>

Steps to reproduce VM inspector timeout: 

1. Create a a Windows VM with Standard_LRS HDD storage for the OS disk (not premium SSD). VM size shouldn't matter. Tested on WS22, but any Windows version should work.
2. From elevated PowerShell:

Set-Location -Path $env:SystemDrive\
Set-ExecutionPolicy Bypass -Force
(New-Object Net.Webclient).DownloadFile('https://raw.githubusercontent.com/craiglandis/misc/main/New-File.ps1', "$env:SystemDrive\New-File.ps1")
.\New-File.ps1

In my testing it took rdfc.exe ~90 minutes to create a 20GB file with random data in it on a Standard_LRS HDD OS disk WS22 Standard_F4s Azure VM. So ~4MB/sec.

Run VM Inspector
#>
$ErrorActionPreference = 'Stop'
$startTime = Get-Date

$machineConfigPath = 'C:\Windows\Microsoft.NET\Framework\v4.0.30319\Config\machine.config'
$largeFilePath = 'C:\Windows\Microsoft.NET\Framework\v4.0.30319\Config\largeFile'
$rdfcZipUrl = 'http://www.bertel.de/software/rdfc/rdfc.zip'
$rdfcZipPath = "$env:TEMP\rdfc.zip"
$rdfcZipExtractedPath = Split-Path -Path $rdfcZipPath
$rdfcFilePath = "$rdfcZipExtractedPath\rdfc.exe"

if ((Test-Path -Path $rdfcZipPath -PathType Leaf) -eq $false)
{
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072
    (New-Object Net.Webclient).DownloadFile($rdfcZipUrl, $rdfcZipPath)
}

if ((Test-Path -Path $rdfcFilePath -PathType Leaf) -eq $false)
{
    Expand-Archive -Path $rdfcZipPath -DestinationPath $rdfcZipExtractedPath
}

if (Test-Path -Path $rdfcFilePath -PathType Leaf)
{
    & $rdfcFilePath $largeFilePath 20 GB overwrite
}
else
{
    Write-Host "File not found: $rdfcFilePath"
    exit 2
}

if (Test-Path -Path $machineConfigPath -PathType Leaf)
{
    Rename-Item -Path $machineConfigPath -NewName "$machineConfigPath.$(Get-Date -Format yyyyMMddHHmmss)"
}
Rename-Item -Path $largeFilePath -NewName $machineConfigPath

if (Test-Path -Path $machineConfigPath -PathType Leaf)
{
    Get-Item -Path $machineConfigPath | Select-Object FullName, @{Name = 'GB'; Expression={[System.Math]::Round($_.Length/1GB, 2)}}
}
$duration = '{0:hh}:{0:mm}:{0:ss}.{0:ff}' -f (New-TimeSpan -Start $startTime -End (Get-Date))
Write-Host $duration
