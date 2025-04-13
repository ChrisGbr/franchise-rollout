$log = "C:\ou-setup.log"
function Log($msg) {
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Add-Content -Path $log -Value "$timestamp [OU] $msg"
}

Log "Starte OU-Konfiguration..."

# Kurze Wartezeit, um sicherzustellen, dass AD-Dienste voll verfügbar sind
Start-Sleep -Seconds 30

try {
    Import-Module ActiveDirectory -ErrorAction Stop
} catch {
    Log "Fehler: ActiveDirectory Modul konnte nicht geladen werden: $_"
    exit 1
}

try {
    $hostname = $env:COMPUTERNAME
    # Entferne den Präfix "vm-ad-" und extrahiere den alphabetischen Standortnamen
    $standort = $hostname -replace '^vm-ad-', ''
    if ($standort -match "([a-zA-Z]+)") {
        $ouName = $matches[1].Substring(0,1).ToUpper() + $matches[1].Substring(1)
    } else {
        $ouName = $standort
    }

    # Erstelle OU, wenn sie noch nicht existiert
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$ouName'" -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name $ouName -Path "DC=franchise,DC=local" -ErrorAction Stop
        Log "OU $ouName erstellt."
    } else {
        Log "OU $ouName existiert bereits."
    }

    # Erstelle Gruppen
    $gruppen = @("Admins_$ouName", "Mitarbeiter_$ouName")
    foreach ($gruppe in $gruppen) {
        if (-not (Get-ADGroup -Filter "Name -eq '$gruppe'" -ErrorAction SilentlyContinue)) {
            New-ADGroup -Name $gruppe -GroupScope Global -Path "OU=$ouName,DC=franchise,DC=local" -ErrorAction Stop
            Log "Gruppe $gruppe erstellt."
        } else {
            Log "Gruppe $gruppe existiert bereits."
        }
    }

    # Erstelle Benutzer anhand des Standorts
    $userName = switch -Wildcard ($standort) {
        "*berlin*"  { "anna.mitarbeiter"; break }
        "*hamburg*" { "hans.mitarbeiter"; break }
        default     { "standard.user" }
    }

    if (-not (Get-ADUser -Filter "SamAccountName -eq '$userName'" -ErrorAction SilentlyContinue)) {
        New-ADUser -Name $userName `
            -SamAccountName $userName `
            -UserPrincipalName "$userName@franchise.local" `
            -Path "OU=$ouName,DC=franchise,DC=local" `
            -AccountPassword (ConvertTo-SecureString "P@ssw0rd123" -AsPlainText -Force) `
            -Enabled $true -ErrorAction Stop
        Log "Benutzer $userName erstellt."
    } else {
        Log "Benutzer $userName existiert bereits."
    }
} catch {
    Log "Fehler bei der OU-Konfiguration: $_"
    exit 1
}
