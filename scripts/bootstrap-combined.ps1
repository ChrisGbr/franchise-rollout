# bootstrap-combined.ps1

$logPath = "C:\ou-setup.log"
function Log($msg) {
    Add-Content -Path $logPath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [BOOTSTRAP] - $msg"
}

Log "Lade Skripte herunter..."
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ChrisGbr/franchise-rollout/feature/terraform-extension-ad/scripts/setup-domain.ps1" -OutFile "C:\setup-domain.ps1"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ChrisGbr/franchise-rollout/feature/terraform-extension-ad/scripts/configure-ou.ps1" -OutFile "C:\configure-ou.ps1"
Log "Skripte heruntergeladen."

Log "Starte setup-domain.ps1"
Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File C:\setup-domain.ps1" -Wait

Log "Warte auf AD (90 Sek.)..."
Start-Sleep -Seconds 90

Log "Starte configure-ou.ps1"
Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File C:\configure-ou.ps1" -Wait

Log "Bootstrap abgeschlossen."
