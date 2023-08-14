Set-ExecutionPolicy Bypass -Force
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072
$url = 'https://github.com/PowerShell/Win32-OpenSSH/releases/download/v9.2.2.0p1-Beta/OpenSSH-Win32.zip'
$filePath = 'C:\OpenSSH-Win32.zip'
(New-Object Net.Webclient).DownloadFile($url, $filePath)
#'Expand-Archive -Path c:\OpenSSH-Win64.zip -DestinationPath c:\ -Force'

$folderPath = 'C:\OpenSSH'
if ((Test-Path -Path $folderPath -PathType Container) -ne $true)
{
    New-Item -Path $folderPath -ItemType Directory -ErrorAction Stop
}

(New-Object -COM Shell.Application).Namespace($folderPath).CopyHere((New-Object -COM Shell.Application).Namespace($filePath).Items(), 16)
do
{
    Start-Sleep -Milliseconds 100
} until (Test-Path -Path $folderPath\OpenSSH-Win32\install-sshd.ps1)
Move-Item -Path $folderPath\OpenSSH-Win32\* $folderPath\
if (Test-Path -Path $folderPath\install-sshd.ps1 -PathType Leaf)
{
    & "$folderPath\install-sshd.ps1"
    if (Get-Service -Name sshd -ErrorAction SilentlyContinue)
    {
        Start-Service -Name sshd
        Set-Service -Name sshd -StartupType Automatic
        New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction 'Inbound' -Protocol 'TCP' -Action 'Allow' -LocalPort 22 -ErrorAction SilentlyContinue
    }
}
