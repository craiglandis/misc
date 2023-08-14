param(
    [string]$manifestName,
    [string]$outputPath = 'c:\logs',
    [switch]$copy,
    [switch]$show,
    [switch]$linux,
    [switch]$windows
)

function Out-Log
{
    param(
        [string]$text,
        [switch]$verboseOnly,
        [string]$prefix,
        [switch]$raw,
        [switch]$logonly,
        [ValidateSet('Black', 'DarkBlue', 'DarkGreen', 'DarkCyan', 'DarkRed', 'DarkMagenta', 'DarkYellow', 'Gray', 'DarkGray', 'Blue', 'Green', 'Cyan', 'Red', 'Magenta', 'Yellow', 'White')]
        [string]$color = 'White'
    )

    if ($verboseOnly)
    {
        if ($verbose)
        {
            $outputNeeded = $true
            $foreGroundColor = 'Yellow'
        }
        else
        {
            $outputNeeded = $false
        }
    }
    else
    {
        $outputNeeded = $true
        $foreGroundColor = 'White'
    }

    if ($outputNeeded)
    {
        if ($raw)
        {
            if ($logonly)
            {
                if ($logFilePath)
                {
                    $text | Out-File $logFilePath -Append
                }
            }
            else
            {
                Write-Host $text -ForegroundColor $color
                if ($logFilePath)
                {
                    $text | Out-File $logFilePath -Append
                }
            }
        }
        else
        {
            if ($prefix -eq 'timespan' -and $global:scriptStartTime)
            {
                $timespan = New-TimeSpan -Start $global:scriptStartTime -End (Get-Date)
                $prefixString = '{0:hh}:{0:mm}:{0:ss}.{0:ff}' -f $timespan
            }
            elseif ($prefix -eq 'both' -and $global:scriptStartTime)
            {
                $timestamp = Get-Date -Format 'yyyy-MM-dd hh:mm:ss'
                $timespan = New-TimeSpan -Start $global:scriptStartTime -End (Get-Date)
                $prefixString = "$($timestamp) $('{0:hh}:{0:mm}:{0:ss}.{0:ff}' -f $timespan)"
            }
            else
            {
                $prefixString = Get-Date -Format 'yyyy-MM-dd hh:mm:ss'
            }

            if ($logonly)
            {
                if ($logFilePath)
                {
                    "$prefixString $text" | Out-File $logFilePath -Append
                }
            }
            else
            {
                Write-Host $prefixString -NoNewline -ForegroundColor Cyan
                Write-Host " $text" -ForegroundColor $color
                if ($logFilePath)
                {
                    "$prefixString $text" | Out-File $logFilePath -Append
                }
            }
        }
    }
}

function Invoke-ExpressionWithLogging
{
    param(
        [string]$command,
        [switch]$verboseOnly
    )

    if ($verboseOnly)
    {
        if ($verbose)
        {
            Out-Log $command -verboseOnly
        }
    }
    else
    {
        Out-Log $command
    }

    try
    {
        Invoke-Expression -Command $command
    }
    catch
    {
        $global:errorRecordObject = $PSItem
        Out-Log "`n$command`n" -raw -color Red
        Out-Log "$global:errorRecordObject" -raw -color Red
        if ($LASTEXITCODE)
        {
            Out-Log "`$LASTEXITCODE: $LASTEXITCODE`n" -raw -color Red
        }
    }
}

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

if (!$manifestName)
{
    # https://github.com/Azure/azure-diskinspect-service/blob/master/manifests/windows/diagnostic
    $apiUrl = 'https://api.github.com/repos/Azure/azure-diskinspect-service/git/trees/master?recursive=1'
    $response = Invoke-RestMethod -Uri $apiUrl -Headers @{'User-Agent' = 'Mozilla/5.0'}
    $files = $response.tree | Where-Object { $_.type -eq 'blob' }
    if ($linux)
    {
        $files = $files.path | Where-Object {$_.StartsWith('manifests/linux')}
    }
    elseif ($windows)
    {
        $files = $files.path | Where-Object {$_.StartsWith('manifests/windows')}
    }
    else
    {
        $files = $files.path | Where-Object {$_.StartsWith('manifests/windows')}
    }
    $manifests = $files | ForEach-Object {$_.Split('/')[-1]}
    $manifestCount = $manifests | Measure-Object | Select-Object -ExpandProperty Count
    $i = 1
    $manifests | ForEach-Object {
        $manifestName = $_.Split('/')[-1]
        Write-Host "$i.$manifestName" -ForegroundColor Cyan
        $i++
    }
    $manifestNumber = Read-Host "`nSelect manifest 1-$manifestCount"
    $manifestName = $manifests[$manifestNumber - 1]
}
$manifestUrl = "https://raw.githubusercontent.com/Azure/azure-diskinspect-service/master/manifests/windows/$manifestName"

if ((Test-Path -Path $outputPath) -eq $false)
{
    New-Item -Path $outputPath -ItemType Directory -Force | Out-Null
}

$manifestPath = "$outputPath\$manifestName.txt"
$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest $manifestUrl -OutFile $manifestPath
$global:manifest = Get-Content -Path $manifestPath

if ($show)
{
    $global:manifest
    Invoke-Item -Path $manifestPath
}
elseif ($copy)
{
    $chocoExePath = 'C:\ProgramData\chocolatey\bin\choco.exe'
    $chocolateyInstalled = Test-Path -Path $chocoExePath -PathType Leaf
    if ($chocolateyInstalled -eq $false)
    {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    }

    $7zExePortablePath = "C:\ProgramData\chocolatey\lib\7zip.portable\tools\7z.exe"
    $7zExeInstallPath = "C:\Program Files\7-zip\7z.exe"

    $7zExePath = Get-Item -Path $7zPortableExePath -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName -ErrorAction SilentlyContinue
    if (!$7zExePath)
    {
        $7zExePath = Get-Item -Path $7zExeInstallPath -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName -ErrorAction SilentlyContinue
    }
    if ($7zExePath)
    {
        Out-Log "Found 7z.exe: $7zExePath"
    }
    else
    {
        Write-PSFMessage "Installing 7z.exe portable"
        &$chocoExePath install 7zip.portable -y
    }

    $destinationRoot = "$outputPath\$($env:computername)_$(Get-Date -Format yyyyMMddHHmmss)"
    if ((Test-Path -Path $destinationRoot -PathType Container) -eq $false)
    {
        New-Item -Path $destinationRoot -ItemType Directory | Out-Null
    }

    foreach ($line in $manifest)
    {
        if ($line.StartsWith('copy'))
        {
            # copy,/WindowsAzure/Logs/Plugins/*/*/CommandExecution.log
            $line = $line.Split(',')[-1]
            $line = $line.Replace('/','\')
            $line = "C:$line"
            $sourceFiles = Invoke-ExpressionWithLogging "Get-Childitem -Path $line -ErrorAction SilentlyContinue"
            foreach ($sourceFile in $sourceFiles)
            {
                $sourceFilePath = $sourceFile.FullName
                $relativePath = $sourceFilePath.Substring(2)
                $destinationPath = Join-Path -Path $destinationRoot -ChildPath $relativePath
                $destinationDir = Split-Path -Path $destinationPath -Parent
                New-Item -Path $destinationDir -ItemType Directory -Force | Out-Null
                Copy-Item -Path $sourceFilePath -Destination $destinationPath
            }
        }
    }

    if ($7zExePath)
    {
        Invoke-ExpressionWithLogging "&$7zExePath -bd a $destinationRoot.7z $destinationRoot\*" #| Out-Null
    }
    elseif (Get-Command -Name Compress-Archive -ErrorAction SilentlyContinue)
    {
        Invoke-ExpressionWithLogging "Compress-Archive -Path '$destinationRoot\*' -DestinationPath '$destinationRoot.zip'"
    }
    else
    {
        $folderPath = $destinationRoot
        $zipFilePath = "$destinationRoot.zip"

        # Create a blank zip file
        Set-Content -Path $zipFilePath -Value ("PK" + [char]5 + [char]6 + ("$([char]0)" * 18))

        # Use Shell.Application to compress the folder
        $shellApplication = New-Object -ComObject Shell.Application
        $zipPackage = $shellApplication.NameSpace($zipFilePath)
        $filesToCompress = $shellApplication.NameSpace($folderPath).Items()
        $zipPackage.CopyHere($filesToCompress)

        # Wait for compression to complete
        $sourceCount = $filesToCompress.Count
        while ($zipPackage.Items().Count -lt $sourceCount) {
            Start-Sleep -Milliseconds 100
        }

        Write-Output "Folder compressed to $zipFilePath"
    }
}
else
{
    Invoke-Item -Path $manifestPath
    $global:manifest
}