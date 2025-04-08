# configure-ou.ps1

$logPath = "C:\ou-setup.log"
function Log($msg) {
    Add-Content -Path $logPath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [OU] - $msg"
}

Start-Sleep -Seconds 60
Log "OU-Konfiguration gestartet."

$hostname = $env:COMPUTERNAME
$standort = $hostname -replace '^vm-ad-', ''
$ouName = $standort.Substring(0,1).ToUpper() + $standort.Substring(1)

$userName = switch -Wildcard ($standort) {
    "*berlin*"  { "anna.mitarbeiter"; break }
    "*hamburg*" { "hans.mitarbeiter"; break }
    default     { "standard.user" }
}

Import-Module ActiveDirectory
Log "Standort erkannt: $ouName"

if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$ouName'")) {
    New-ADOrganizationalUnit -Name $ouName -Path "DC=franchise,DC=local"
    Log "OU '$ouName' erstellt."
} else {
    Log "OU '$ouName' existiert bereits."
}

$gruppen = @("Admins_$ouName", "Mitarbeiter_$ouName")
foreach ($gruppe in $gruppen) {
    if (-not (Get-ADGroup -Filter "Name -eq '$gruppe'")) {
        New-ADGroup -Name $gruppe -GroupScope Global -Path "OU=$ouName,DC=franchise,DC=local"
        Log "Gruppe '$gruppe' erstellt."
    } else {
        Log "Gruppe '$gruppe' existiert bereits."
    }
}

if (-not (Get-ADUser -Filter "SamAccountName -eq '$userName'")) {
    New-ADUser -Name "$userName" `
        -SamAccountName $userName `
        -UserPrincipalName "$userName@franchise.local" `
        -Path "OU=$ouName,DC=franchise,DC=local" `
        -AccountPassword (ConvertTo-SecureString "P@ssw0rd123" -AsPlainText -Force) `
        -Enabled $true
    Log "Benutzer '$userName' erstellt."
} else {
    Log "Benutzer '$userName' existiert bereits."
}

Log "OU-Konfiguration abgeschlossen."
