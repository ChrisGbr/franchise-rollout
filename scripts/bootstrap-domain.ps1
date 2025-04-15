# bootstrap-domain.ps1

# Schritt 1: AD-Domain-Services installieren
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Schritt 2: Neue AD-Domäne erstellen (inkl. automatischem Reboot)
Install-ADDSForest `
  -DomainName "franchise.local" `
  -DomainNetbiosName "FRANCHISE" `
  -SafeModeAdministratorPassword (ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force) `
  -Force

# Schritt 3: Scheduled Task vorbereiten – OU-Skript wird nach Neustart automatisch ausgeführt
$scriptPath = "C:\configure-ou.ps1"
if (Test-Path $scriptPath) {
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Unrestricted -File `"$scriptPath`""
    $trigger = New-ScheduledTaskTrigger -AtStartup
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -StartWhenAvailable
    Register-ScheduledTask -TaskName "Run-FranchiseOU" -Action $action -Trigger $trigger -Settings $settings -RunLevel Highest -User "SYSTEM"
}
