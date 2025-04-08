# configure-ou.ps1

$logPath = "C:\ou-setup.log"
function Log($msg) {
    Add-Content -Path $logPath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [OU] - $msg"
}

Start-Sleep -Seconds 10
Log "🚀 OU-Konfiguration startet..."

# Standortname dynamisch bestimmen
$hostname = $env:COMPUTERNAME
$standort = $hostname -replace '^vm-ad-', ''
$ouName = $standort.Substring(0,1).ToUpper() + $standort.Substring(1)

# Benutzername anhand des Standorts
$userName = switch -Wildcard ($standort) {
    "*berlin*"  { "anna.mitarbeiter"; break }
    "*hamburg*" { "hans.mitarbeiter"; break }
    default     { "standard.user" }
}

Import-Module ActiveDirectory
Log "📡 Standort erkannt: $ouName"

# OU anlegen (falls nicht vorhanden)
if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$ouName'")) {
    New-ADOrganizationalUnit -Name $ouName -Path "DC=franchise,DC=local"
    Log "✅ OU '$ouName' erstellt."
} else {
    Log "ℹ️ OU '$ouName' existiert bereits."
}

# Standard-Gruppen anlegen
$gruppen = @("Admins_$ouName", "Mitarbeiter_$ouName")
foreach ($gruppe in $gruppen) {
    if (-not (Get-ADGroup -Filter "Name -eq '$gruppe'")) {
        New-ADGroup -Name $gruppe -GroupScope Global -Path "OU=$ouName,DC=franchise,DC=local"
        Log "✅ Gruppe '$gruppe' erstellt."
    } else {
        Log "ℹ️ Gruppe '$gruppe' existiert bereits."
    }
}

# Benutzer anlegen
if (-not (Get-ADUser -Filter "SamAccountName -eq '$userName'")) {
    New-ADUser -Name "$userName" `
        -SamAccountName $userName `
        -UserPrincipalName "$userName@franchise.local" `
        -Path "OU=$ouName,DC=franchise,DC=local" `
        -AccountPassword (ConvertTo-SecureString "P@ssw0rd123" -AsPlainText -Force) `
        -Enabled $true
    Log "✅ Benutzer '$userName' erstellt."
} else {
    Log "ℹ️ Benutzer '$userName' existiert bereits."
}

# Scheduled Task entfernen (Self-Cleanup)
Unregister-ScheduledTask -TaskName "FranchiseOU" -Confirm:$false
Log "🧹 Scheduled Task 'FranchiseOU' gelöscht."
Log "✅ OU-Konfiguration abgeschlossen."
