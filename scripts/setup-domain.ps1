# Full Code for setup-domain.ps1

$log = "C:\ou-setup.log"
function Log($msg) {
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Add-Content -Path $log -Value "$timestamp [SETUP] $msg"
}

# --- Scheduled Task für die OU-Konfiguration einrichten ---
Log "Erstelle Scheduled Task für die OU-Konfiguration..."

$taskName = "ConfigureOU"
$persistentScriptPath = "C:\Scripts\configure-ou.ps1"

# Sicherstellen, dass der persistente Ordner existiert
if (-not (Test-Path "C:\Scripts")) {
    New-Item -Path "C:\" -Name "Scripts" -ItemType "Directory" | Out-Null
    Log "Ordner C:\Scripts wurde erstellt."
}

# Falls die OU-Konfiguration als Script an einem temporären Ort liegt, kopiere es in den persistenten Ordner
if (Test-Path "C:\configure-ou.ps1") {
    Copy-Item -Path "C:\configure-ou.ps1" -Destination $persistentScriptPath -Force
    Log "configure-ou.ps1 wurde nach $persistentScriptPath kopiert."
} else {
    Log "Warnung: Datei C:\configure-ou.ps1 existiert nicht. Bitte sicherstellen, dass das Script vorhanden ist."
}

# Überprüfen, ob der Scheduled Task bereits existiert
$taskExists = schtasks.exe /Query /TN $taskName 2>$null
if (-not $taskExists) {
    # Erstelle die Aktion: Starte PowerShell, um das Script auszuführen (ohne Profil, mit Bypass der ExecutionPolicy)
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -NoProfile -File `"$persistentScriptPath`""
    # Erstelle einen Trigger: Beim Systemstart mit fester Verzögerung von 10 Minuten
    $trigger = New-ScheduledTaskTrigger -AtStartup -Delay "00:10:00"
    # Registriere den Task mit höchsten Rechten
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -RunLevel Highest -Force
    Log "Scheduled Task '$taskName' wurde erstellt und läuft mit höchsten Rechten."
} else {
    Log "Scheduled Task '$taskName' existiert bereits."
}

# --- Fortsetzung: AD-Rolleninstallation und Forest-Setup ---

try {
    Log "Starte AD-Rolleninstallation..."
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools -ErrorAction Stop | Out-Null
    Log "AD-Rolle installiert."
} catch {
    Log "Fehler bei der Installation der AD-Domain-Services: $_"
    exit 1
}

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
