# Active Directory-Rolle installieren
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Domäne einrichten (automatischer Reboot)
Install-ADDSForest `
  -DomainName "franchise.local" `
  -DomainNetbiosName "FRANCHISE" `
  -SafeModeAdministratorPassword (ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force) `
  -Force

# Nach dem Reboot: Task zur OU-Konfiguration erstellen (falls Datei vorhanden)
$ouScript = "C:\configure-ou.ps1"

if (Test-Path $ouScript) {
    $taskName = "Run-Franchise-OU-Setup"
    
    # Task-Aktion definieren
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Unrestricted -File `"$ouScript`""

    # Trigger: Beim Systemstart, einmalig
    $trigger = New-ScheduledTaskTrigger -AtStartup

    # Zusätzliche Einstellungen
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

    # Task registrieren
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -RunLevel Highest -User "SYSTEM"
}
