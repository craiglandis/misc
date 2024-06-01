Set-ExecutionPolicy -ExecutionPolicy Bypass -Force
Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private
Enable-PSRemoting -SkipNetworkProfileCheck -Force
winrm quickconfig -q
winrm quickconfig -transport:http
winrm set winrm/config '@{MaxTimeoutms="1800000"}'
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="800"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/client/auth '@{Basic="true"}'
winrm set winrm/config/listener?Address=*+Transport=HTTP '@{Port="5985"}'
netsh advfirewall firewall set rule group="Windows Remote Administration" new enable=yes
netsh advfirewall firewall set rule name="Windows Remote Management (HTTP-In)" new enable=yes action=allow remoteip=any
# Set-Item WSMan:\localhost\Client\TrustedHosts 192.168.50.107 -Concatenate -Force
# netsh advfirewall firewall add rule name="Port 5985" dir=in action=allow protocol=TCP localport=5985
# sc config winrm start= disabled
# reg add HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce /v StartWinRM /t REG_SZ /f /d "cmd.exe /c 'sc config winrm start= auto & sc start winrm'"
Restart-Service winrm

<#
winrm set winrm/config '@{MaxTimeoutms=\`"1800000\`"}'
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB=\`"800\`"}'
winrm set winrm/config/service '@{AllowUnencrypted=\`"true\`"}'
winrm set winrm/config/service/auth '@{Basic=\`"true\`"}'
winrm set winrm/config/client/auth '@{Basic=\`"true\`"}'
winrm set winrm/config/listener?Address=*+Transport=HTTP '@{Port=\`"5985\`"}'
winrm set winrm/config/client '@{TrustedHosts=\`"*\`"}'

# Enable-WSManCredSSP -Role "Client" -DelegateComputer $CAServer -Force
# Invoke-Command -ComputerName $CAServer -ScriptBlock { Enable-WSManCredSSP Server -Force }
#>
