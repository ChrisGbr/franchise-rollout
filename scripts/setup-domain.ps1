# setup-domain.ps1

$logPath = "C:\ou-setup.log"
function Log($msg) {
    Add-Content -Path $logPath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [SETUP] - $msg"
}

Log "🛠️ Start: Active Directory wird installiert."

# Installiere AD-Rolle + Tools
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools | Out-Null

Log "📦 Rolle 'AD-Domain-Services' installiert."

# Installiere neuen AD-Forest
Install-ADDSForest `
  -DomainName "franchise.local" `
  -DomainNetbiosName "FRANCHISE" `
  -SafeModeAdministratorPassword (ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force) `
  -Force

Log "🌲 AD-Forest 'franchise.local' installiert. Reboot folgt automatisch."

# Scheduled Task zur OU-Konfiguration nach dem Reboot registrieren
$scriptPath = "C:\configure-ou.ps1"

if (Test-Path $scriptPath) {
    Log "📝 OU-Konfigurationsskript gefunden. Scheduled Task wird eingerichtet."

    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`""
    $trigger = New-ScheduledTaskTrigger -AtStartup
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -StartWhenAvailable -Hidden
    Register-ScheduledTask -TaskName "FranchiseOU" -Action $action -Trigger $trigger -Settings $settings -RunLevel Highest -User "SYSTEM"

    Log "✅ Scheduled Task 'FranchiseOU' erfolgreich erstellt."
} else {
    Log "❌ WARNUNG: 'configure-ou.ps1' nicht gefunden. OU-Konfiguration wird beim nächsten Start nicht ausgeführt!"
}
