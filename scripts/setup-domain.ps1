# setup-domain.ps1

$logPath = "C:\ou-setup.log"
function Log($msg) {
    Add-Content -Path $logPath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [SETUP] - $msg"
}

Log "Start: Active Directory wird installiert."

Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools | Out-Null
Log "AD-Rolle installiert."

Install-ADDSForest `
  -DomainName "franchise.local" `
  -DomainNetbiosName "FRANCHISE" `
  -SafeModeAdministratorPassword (ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force) `
  -Force

Log "AD-Forest eingerichtet. Reboot erfolgt automatisch durch AD-Setup."
