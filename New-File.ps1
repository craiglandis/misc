<#
This script creates a 20GB file with random data in order to create a reproducible timeout with VM Inspector with a Windows VM
https://learn.microsoft.com/en-us/troubleshoot/azure/virtual-machines/vm-inspector-azure-virtual-machines

The script should only be used on a test VM as it replaces C:\Windows\Microsoft.NET\Framework\v4.0.30319\Config\machine.config in order to reproduce the timeout.

1. Create a a Windows VM with Standard_LRS HDD storage for the OS disk (not premium SSD). VM size shouldn't matter. Tested on WS22, but any Windows version should work.
2. 


10.00 GB written to 'C:\Windows\Microsoft.NET\Framework\v4.0.30319\Config\largeFile' in 2265 sec. (ca. 4.52 MB/sec.)
00:37:45.82

10GB took IID 6.48 min
17:29:08  Copying Step [26.1] File: /Windows/Microsoft.NET/Framework/v4.0.30319/Config/machine.config SUCCEEDED.  [Operation duration: 329 seconds]
[Execution duration: 389 seconds]

20.00 GB written to 'C:\Windows\Microsoft.NET\Framework\v4.0.30319\Config\largeFile' in 5056 sec. (ca. 4.05 MB/sec.)
01:24:15.27 - so ~90 min. to create 20GB file with random data in it.

Set-ExecutionPolicy Bypass -Force; (New-Object Net.Webclient).DownloadFile('https://raw.githubusercontent.com/craiglandis/bootstrap/main/bootstrap.ps1', "$env:SystemDrive\bootstrap.ps1");.\bootstrap.ps1 -group HV
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

<#


$file1Path = 'c:\file1.bin'
$file2Path = 'c:\file2.bin'
$file3Path = 'c:\file3.bin'
reg save hklm\software $file1Path
Copy-Item -path $file1Path -Destination $file2Path
do {
    #get-content -path $file1Path -Encoding Byte -Read 512 | set-content -path $file2Path -Encoding Byte
    cmd /c copy /b $file1path + $file2path $file3Path | out-null
    $file3 = get-item -path $file3Path
    $file3Length = $file3.Length
    Write-Host "$file3Path $([Math]::Round($file3Length/1GB,2))GB"
    if ($file3Length -le 10GB)
    {
        remove-item -path $file2Path
        Rename-Item -Path $file3Path -NewName $file2Path
    }
} until ($file3Length -gt 10GB)
if (Test-Path -Path $machineConfigPath -PathType Leaf)
{
    Rename-Item -Path $machineConfigPath -NewName "$machineConfigPath.$(Get-Date -Format yyyyMMddHHmmss)"
}
Copy-Item -path $file3Path -Destination $machineConfigPath
$duration = '{0:hh}:{0:mm}:{0:ss}.{0:ff}' -f (New-TimeSpan -Start $startTime -End (Get-Date))
Write-Host $duration
#>
