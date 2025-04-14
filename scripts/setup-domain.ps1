$log = "C:\ou-setup.log"
function Log($msg) {
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Add-Content -Path $log -Value "$timestamp [SETUP] $msg"
}

# AD-Domänenrolleninstallation
try {
    Log "Starte AD-Rolleninstallation..."
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools -ErrorAction Stop | Out-Null
    Log "AD-Rolle installiert."
} catch {
    Log "Fehler bei der Installation der AD-Domain-Services: $_"
    exit 1
}

$log = "C:\ou-setup.log"
function Log($msg) {
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Add-Content -Path $log -Value "$timestamp [SETUP] $msg"
}

# === Scheduled Task für die OU-Konfiguration erstellen ===
Log "Erstelle Scheduled Task für die OU-Konfiguration..."

$taskName = "ConfigureOU"
$scriptPath = "C:\configure-ou.ps1"

# Überprüfe, ob der Task bereits existiert
$taskExists = schtasks.exe /Query /TN $taskName 2>$null
if (-not $taskExists) {
    # Aktion: PowerShell ausführen, um das OU-Konfigurations-Skript zu starten
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`""
    # Trigger: Beim Systemstart mit einer zufälligen Verzögerung von 5 Minuten (sorgt dafür, dass das AD vollständig hochgefahren ist)
    $trigger = New-ScheduledTaskTrigger -AtStartup -RandomDelay "00:05:00"
    # Task erstellen mit höchsten Rechten
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -RunLevel Highest -Force
    Log "Scheduled Task '$taskName' wurde erstellt."
} else {
    Log "Scheduled Task '$taskName' existiert bereits."
}

# === Fortsetzung: AD-Rolleninstallation und ADDSForest ===

# AD-Rolleninstallation
try {
    Log "Starte AD-Rolleninstallation..."
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools -ErrorAction Stop | Out-Null
    Log "AD-Rolle installiert."
} catch {
    Log "Fehler bei der Installation der AD-Domain-Services: $_"
    exit 1
}

# Forest-Setup: Nach erfolgreicher Ausführung wird in der Regel ein Neustart eingeleitet
try {
    Log "Starte Forest-Setup..."
    Install-ADDSForest `
      -DomainName "franchise.local" `
      -DomainNetbiosName "FRANCHISE" `
      -SafeModeAdministratorPassword (ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force) `
      -Force -ErrorAction Stop
    Log "Forest eingerichtet. Reboot wird automatisch durchgeführt."
} catch {
    Log "Fehler beim Forest-Setup: $_"
    exit 1
}
