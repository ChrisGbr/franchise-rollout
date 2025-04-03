Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

Install-ADDSForest `
  -DomainName "franchise.local" `
  -DomainNetbiosName "FRANCHISE" `
  -SafeModeAdministratorPassword (ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force) `
  -Force

# Warten bis nach Neustart, danach:
Start-Sleep -Seconds 60

New-ADOrganizationalUnit -Name "Berlin01" -Path "DC=franchise,DC=local"

New-ADGroup -Name "Admins_Berlin01" -GroupScope Global -Path "OU=Berlin01,DC=franchise,DC=local"
New-ADGroup -Name "Mitarbeiter_Berlin01" -GroupScope Global -Path "OU=Berlin01,DC=franchise,DC=local"

New-ADUser -Name "Anna Mitarbeiter" `
  -SamAccountName "anna.mitarbeiter" `
  -UserPrincipalName "anna.mitarbeiter@franchise.local" `
  -Path "OU=Berlin01,DC=franchise,DC=local" `
  -AccountPassword (ConvertTo-SecureString "P@ssw0rd123" -AsPlainText -Force) `
  -Enabled $true
+
