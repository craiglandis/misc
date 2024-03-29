[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$manifestName,
    [string]$outputPath = 'C:\logs',
    [switch]$copy,
    [switch]$show,
    [switch]$linux,
    [switch]$windows,
    [switch]$checkHandles
)

function Out-Log
{
    param(
        [string]$text,
        [switch]$verboseOnly,
        [switch]$sameline,
        [ValidateSet('timespan', 'both')]
        [string]$prefix = 'both',
        [ValidateSet('hours', 'minutes', 'seconds')]
        [string]$timespanFormat = 'minutes',
        [switch]$dateCondensed = $true,
        [switch]$milliseconds,
        [switch]$raw,
        [switch]$logonly,
        # [ValidateSet('Black', 'DarkBlue', 'DarkGreen', 'DarkCyan', 'DarkRed', 'DarkMagenta', 'DarkYellow', 'Gray', 'DarkGray', 'Blue', 'Green', 'Cyan', 'Red', 'Magenta', 'Yellow', 'White')]
        [string]$color = 'White'
    )

    if ($dateCondensed)
    {
        $dateFormat = 'ddhhmmss'
    }
    else
    {
        $dateFormat = 'yyyy-MM-dd hh:mm:ss'
    }

    if ($verboseOnly)
    {
        $global:callstack = Get-PSCallStack
        $caller = $callstack | select-object -first 1 -skip 1
        $caller = $caller.InvocationInfo.MyCommand.Name
        if ($caller -eq 'Invoke-ExpressionWithLogging')
        {
            $caller = $callstack | select-object -first 1 -skip 2
            $caller = $caller.InvocationInfo.MyCommand.Name
        }
        $caller = "$yellow$caller$reset"
        # Write-Host "$scriptName `$verboseOnly: $verboseOnly `$global:verbose: $global:verbose" -ForegroundColor Magenta
        if ($global:verbose)
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
            if (!$global:scriptStartTime)
            {
                $global:scriptStartTime = Get-Date
            }
            # if ($prefix -eq 'timespan' -and $global:scriptStartTime)
            if ($prefix -eq 'timespan' -and $global:scriptStartTime)
            {
                $timespan = New-TimeSpan -Start $global:scriptStartTime -End (Get-Date)
                if ($timespanFormat -eq 'hours')
                {
                    $format = '{0:hh}:{0:mm}:{0:ss}'
                    #$prefixString = '{0:hh}:{0:mm}:{0:ss}.{0:ff}' -f $timespan
                }
                elseif ($timespanFormat -eq 'minutes')
                {
                    $format = '{0:mm}:{0:ss}'
                    #$prefixString = '{0:mm}:{0:ss}.{0:ff}' -f $timespan
                }
                elseif ($timespanFormat -eq 'seconds')
                {
                    $format = '{0:ss}'
                    #$prefixString = '{0:ss}.{0:ff}' -f $timespan
                }
                if ($milliseconds)
                {
                    $format = "$($format).{0:ff}"
                }
                $prefixString = $format -f $timespan
                # $prefixString = "[$prefixString]"
                $prefixString = $prefixString
            }
            # elseif ($prefix -eq 'both' -and $global:scriptStartTime)
            elseif ($prefix -eq 'both' -and $global:scriptStartTime)
            {
                $timestamp = Get-Date -Format $dateFormat
                # $timespan = New-TimeSpan -Start $global:scriptStartTime -End (Get-Date)
                $timespan = New-TimeSpan -Start $global:scriptStartTime -End (Get-Date)

                if ($timespanFormat -eq 'hours')
                {
                    $format = '{0:hh}:{0:mm}:{0:ss}'
                    #$prefixString = '{0:hh}:{0:mm}:{0:ss}.{0:ff}' -f $timespan
                }
                elseif ($timespanFormat -eq 'minutes')
                {
                    $format = '{0:mm}:{0:ss}'
                    #$prefixString = '{0:mm}:{0:ss}.{0:ff}' -f $timespan
                }
                elseif ($timespanFormat -eq 'seconds')
                {
                    $format = '{0:ss}'
                    #$prefixString = '{0:ss}.{0:ff}' -f $timespan
                }
                if ($milliseconds)
                {
                    $format = "$($format).{0:ff}"
                }
                $prefixString = $format -f $timespan
                $prefixString = "$cyan$timestamp$reset $blue$prefixString$reset"
            }
            else
            {
                $prefixString = Get-Date -Format $dateFormat
            }

            if ($logonly -or $global:quiet)
            {
                if ($logFilePath)
                {
                    # $prefixString = $prefixString.Replace("$cyan", '').Replace("$blue", '').Replace("$reset", '')
                    "$prefixString $text" | Out-File $logFilePath -Append
                }
            }
            else
            {
                #<#
                switch ($color)
                {
                    'Gray' {$color = $gray}
                    'Red' {$color = $red}
                    'Green' {$color = $green}
                    'Yellow' {$color = $yellow}
                    'Blue' {$color = $blue}
                    'Magenta' {$color = $magenta}
                    'Cyan' {$color = $cyan}
                    'White' {$color = $white}
                    Default {$white}
                }
                #>

                if ($verboseOnly)
                {
                    $prefixString = "$prefixString [$caller]"
                }

                if ($sameline)
                {
                    $script:lastCallWasSameLine = $true
                    Write-Host "`r$cyan$prefixString$reset $text" -NoNewline
                    #Write-Host "`r$prefixString $cyan$text$reset" -NoNewline
                    #Write-Host "`r$prefixString" -NoNewline -ForegroundColor Cyan
                    #Write-Host "`r $text" -ForegroundColor $color -NoNewline
                }
                else
                {
                    if ($script:lastCallWasSameLine)
                    {
                        Write-Host ''
                        $script:lastCallWasSameLine = $null
                    }
                    Write-Host $prefixString -NoNewline -ForegroundColor Gray
                    Write-Host " $text"  #-ForegroundColor $color
                    # Write-Host "$cyan$prefixString$reset $color$text$reset"
                }

                if ($logFilePath)
                {
                    # $prefixString = $prefixString.Replace("$cyan", '').Replace("$blue", '').Replace("$reset", '')
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

    # $command = $command.Replace($green, '').Replace($reset, '')

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

$global:verbose = [bool]$PSBoundParameters['verbose']
$global:debug = [bool]$PSBoundParameters['debug']

$global:scriptStartTime = Get-Date
$scriptStartTimeString = Get-Date -Date $scriptStartTime -Format yyyyMMddHHmmss
$scriptFullName = $MyInvocation.MyCommand.Path
$scriptFolderPath = Split-Path -Path $scriptFullName
$scriptName = Split-Path -Path $scriptFullName -Leaf
$scriptBaseName = $scriptName.Split('.')[0]
$host.UI.RawUI.WindowTitle = "$($scriptBaseName.ToUpper())"

$logFolderParentPath = "C:\Logs"
$logFolderPath = "$logFolderParentPath\$scriptBaseName"
$global:logFilePath = "$logFolderPath\$($scriptBaseName)_$(Get-Date -Format yyyyMMddhhmmss).log"
if ((Test-Path -Path $global:logFilePath -PathType Container) -eq $false)
{
    New-Item -Path $global:logFilePath -ItemType File -Force | Out-Null
}
Out-Log "Log file: $cyan$global:logFilePath$reset" -verboseOnly

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
    $7zExePath = 'C:\Program Files\7-zip\7z.exe'
    if ((Test-Path -Path $7zExePath -PathType Leaf) -eq $false)
    {
        $7zUrl = 'https://www.7-zip.org/a/7z2301-x64.exe'
        $7zDownloadPath = 'C:\7z2301-x64.exe'
        $result = Invoke-ExpressionWithLogging "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; (New-Object Net.Webclient).DownloadFile('$7zUrl', '$7zDownloadPath'); C:\7z2301-x64.exe /S"
        $result = Invoke-ExpressionWithLogging "Remove-Item -Path $7zDownloadPath -ErrorAction SilentlyContinue"
    }

    if ($checkHandles)
    {
        $handleUrl = 'https://download.sysinternals.com/files/Handle.zip'
        $handleDownloadPath = 'C:\Handle.zip'
        $handleFolderPath = 'C:\Handle'
        $handleExePath = "$handleFolderPath\handle64.exe"
        $handleOutputFile = "$handleFolderPath\handle.txt"

        $result = Invoke-ExpressionWithLogging "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; (New-Object Net.Webclient).DownloadFile('$handleUrl','$handleDownloadPath')"
        $result = Invoke-ExpressionWithLogging "& '$7zExePath' x '$handleDownloadPath' -o'$handleFolderPath' -aoa -r"
        $result = Invoke-ExpressionWithLogging "Remove-Item -Path $handleDownloadPath -ErrorAction SilentlyContinue"
        $result = Invoke-ExpressionWithLogging "$handleExePath dataStore.edb -accepteula -nobanner > $handleOutputFile; Get-Content -Path $handleOutputFile -ErrorAction SilentlyContinue"
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
            # copy,/Boot/BCD,noscan
            # https://raw.githubusercontent.com/Azure/azure-diskinspect-service/master/manifests/windows/windowsupdate
            $line = $line.Replace(',noscan','')
            $line = $line.Split(',')[-1]
            $line = $line.Replace('/','\')
            $line = "C:$line"
            if ($line -eq 'C:\Windows\System32\config\SOFTWARE')
            {
                $line = 'C:\Windows\System32\config\SOFTWARE.hiv'
                $result = Invoke-ExpressionWithLogging "reg save HKLM\SOFTWARE $line /y"
            }
            if ($line -eq 'C:\Windows\System32\config\SYSTEM')
            {
                $line = 'C:\Windows\System32\config\SYSTEM.hiv'
                $result = Invoke-ExpressionWithLogging "reg save HKLM\SYSTEM $line /y"
            }
            if ($line -eq 'C:\Windows\SoftwareDistribution\datastore\DataStore.edb')
            {
                # DataStore.edb sometimes can't be copied unless wuauserv is stopped first
                # But this was messing with my guest patching tests, so commenting out for now
                # Invoke-ExpressionWithLogging "Stop-Service -Name 'wuauserv' -ErrorAction SilentlyContinue"
                $line = 'C:\FileThatDoesNotExist'
            }
            $sourceFiles = Invoke-ExpressionWithLogging "Get-Childitem -Path '$line' -ErrorAction SilentlyContinue" -verboseOnly
            foreach ($sourceFile in $sourceFiles)
            {
                $sourceFilePath = $sourceFile.FullName
                $relativePath = $sourceFilePath.Substring(2)
                $destinationPath = Join-Path -Path $destinationRoot -ChildPath $relativePath
                $destinationDir = Split-Path -Path $destinationPath -Parent
                New-Item -Path $destinationDir -ItemType Directory -Force | Out-Null
                Invoke-ExpressionWithLogging "Copy-Item -Path '$sourceFilePath' -Destination '$destinationPath' -ErrorAction SilentlyContinue" -verboseOnly
            }
            <#
            $wuauservStatus = Get-Service -Name 'wuauserv' | Select-Object -ExpandProperty Status
            if ($wuauservStatus -eq 'Stopped')
            {
                Invoke-ExpressionWithLogging "Start-Service -Name 'wuauserv' -ErrorAction SilentlyContinue"
            }
            #>
        }
    }

    if ($7zExePath)
    {
        $result = Invoke-ExpressionWithLogging "& '$7zExePath' -bd a $destinationRoot.7z $destinationRoot\*" #| Out-Null
        #& "`"$7zExePath`" -bd a $destinationRoot.7z $destinationRoot\*"
    }
    elseif (Get-Command -Name Compress-Archive -ErrorAction SilentlyContinue)
    {
        Invoke-ExpressionWithLogging "Compress-Archive -Path '$destinationRoot\*' -DestinationPath '$destinationRoot.zip'"
    }
    else
    {
        $folderPath = $destinationRoot
        $zipFilePath = "$destinationRoot.zip"
        Set-Content -Path $zipFilePath -Value ("PK" + [char]5 + [char]6 + ("$([char]0)" * 18))
        $shellApplication = New-Object -ComObject Shell.Application
        $zipPackage = $shellApplication.NameSpace($zipFilePath)
        $filesToCompress = $shellApplication.NameSpace($folderPath).Items()
        $zipPackage.CopyHere($filesToCompress)
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

    <#
    # Simpler just to install 7-Zip only instead of installing Chocolatey to then install 7-Zip
    # since chocolatey is only being used in the script to install that one thing
    # Also, on WS12, installing Chocolatey installs Netfx 4.8 which requires a reboot
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

    $7zExePath = Get-Item -Path $7zExePortablePath -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName -ErrorAction SilentlyContinue
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
        Out-Log "Installing 7z.exe portable"
        &$chocoExePath install 7zip.portable -y
    }
    #>
