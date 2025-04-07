# setup-domain.ps1

# Active Directory-Rolle installieren
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Neue Domäne einrichten (automatischer Reboot folgt)
Install-ADDSForest `
  -DomainName "franchise.local" `
  -DomainNetbiosName "FRANCHISE" `
  -SafeModeAdministratorPassword (ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force) `
  -Force

# Nach dem Reboot wird dieser Teil NICHT mehr ausgeführt
# Deshalb Scheduled Task einrichten, um configure-ou.ps1 auszuführen

$scriptPath = "C:\configure-ou.ps1"

if (Test-Path $scriptPath) {
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Unrestricted -File `"$scriptPath`""
    $trigger = New-ScheduledTaskTrigger -AtStartup
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -StartWhenAvailable
    Register-ScheduledTask -TaskName "Run-FranchiseOU" -Action $action -Trigger $trigger -Settings $settings -RunLevel Highest -User "SYSTEM"
}
