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

# Forest-Setup
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
