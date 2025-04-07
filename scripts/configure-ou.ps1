# configure-ou.ps1

Write-Host "Starte AD-Konfiguration für OU Berlin01"

# OU anlegen
New-ADOrganizationalUnit -Name "Berlin01" -Path "DC=franchise,DC=local"

# Gruppen
New-ADGroup -Name "Admins_Berlin01" -GroupScope Global -Path "OU=Berlin01,DC=franchise,DC=local"
New-ADGroup -Name "Mitarbeiter_Berlin01" -GroupScope Global -Path "OU=Berlin01,DC=franchise,DC=local"

# Benutzer
New-ADUser -Name "Anna Mitarbeiter" `
  -SamAccountName "anna.mitarbeiter" `
  -UserPrincipalName "anna.mitarbeiter@franchise.local" `
  -Path "OU=Berlin01,DC=franchise,DC=local" `
  -AccountPassword (ConvertTo-SecureString "P@ssw0rd123" -AsPlainText -Force) `
  -Enabled $true

# Optional: Task wieder löschen, um ihn nur einmal auszuführen
Unregister-ScheduledTask -TaskName "Run-FranchiseOU" -Confirm:$false

Write-Host "OU & Benutzerkonfiguration abgeschlossen."
