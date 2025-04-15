# setup-domain.ps1
$log = "C:\ou-setup.log"
function Log($msg) {
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Add-Content -Path $log -Value "$timestamp [SETUP] $msg"
}

Log "Erstelle Scheduled Task für die OU-Konfiguration..."

$taskName = "ConfigureOU"
$persistentScriptPath = "C:\Scripts\configure-ou.ps1"
$remoteScriptUrl = "https://raw.githubusercontent.com/ChrisGbr/franchise-rollout/feature/terraform-extension-ad/scripts/configure-ou.ps1"  # Passe diese URL falls nötig an!

# Stelle sicher, dass der Ordner "C:\Scripts" existiert, andernfalls erstellen
if (-not (Test-Path "C:\Scripts")) {
    New-Item -Path "C:\" -Name "Scripts" -ItemType "Directory" | Out-Null
    Log "Ordner C:\Scripts wurde erstellt."
}

# Sicherstellen, dass configure-ou.ps1 vorhanden ist
$localScriptPath = "C:\configure-ou.ps1"
if (-not (Test-Path $localScriptPath)) {
    Log "Datei $localScriptPath existiert nicht. Versuche, sie von $remoteScriptUrl herunterzuladen..."
    try {
        Invoke-WebRequest -Uri $remoteScriptUrl -OutFile $localScriptPath -ErrorAction Stop
        Log "Datei $localScriptPath wurde erfolgreich heruntergeladen."
    } catch {
        Log ("Fehler beim Herunterladen von " + $remoteScriptUrl + ": " + $_.Exception.Message)
    }
}

# Kopiere die configure-ou.ps1 in den persistente Ordner, damit sie nach dem Neustart erhalten bleibt.
if (Test-Path $localScriptPath) {
    Copy-Item -Path $localScriptPath -Destination $persistentScriptPath -Force
    Log "configure-ou.ps1 wurde nach $persistentScriptPath kopiert."
} else {
    Log "Warnung: Datei $localScriptPath existiert immer noch nicht. Bitte sicherstellen, dass das Skript verfügbar ist."
}

# Überprüfe, ob der Scheduled Task bereits existiert
$taskExists = schtasks.exe /Query /TN $taskName 2>$null
if (-not $taskExists) {
    # Aktion: Führe das OU-Konfigurationsskript mit powershell.exe aus
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -NoProfile -File `"$persistentScriptPath`""
    # Trigger: Beim Systemstart mit einer fixen Verzögerung von 10 Minuten,
    # damit alle AD-Dienste vollständig hochgefahren sind.
    $trigger = New-ScheduledTaskTrigger -AtStartup -Delay "00:10:00"
    # Registriere den Scheduled Task mit höchsten Rechten
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -RunLevel Highest -Force
    Log "Scheduled Task '$taskName' wurde erstellt und läuft mit höchsten Rechten."
} else {
    Log "Scheduled Task '$taskName' existiert bereits."
}

# === AD-Rolleninstallation ===
try {
    Log "Starte AD-Rolleninstallation..."
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools -ErrorAction Stop | Out-Null
    Log "AD-Rolle installiert."
} catch {
    Log "Fehler bei der Installation der AD-Domain-Services: $_"
    exit 1
}

# === Forest-Setup ===
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
