resource "azurerm_virtual_machine_extension" "bootstrap_ad_hamburg" {
  name                 = "bootstrap-ad-hamburg"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm_hamburg.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SETTINGS
  {
    "commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted -File setup-domain.ps1"
  }
  SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
  {
    "fileUris": [
      "https://raw.githubusercontent.com/ChrisGbr/franchise-rollout/feature/terraform-extension-ad/scripts/setup-domain.ps1"
    ]
  }
  PROTECTED_SETTINGS
}

resource "azurerm_virtual_machine_extension" "configure_ou_hamburg" {
  name                 = "configure-ou-hamburg"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm_hamburg.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SETTINGS
  {
    "commandToExecute": "powershell.exe -ExecutionPolicy Bypass -File configure-ou.ps1"
  }
  SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
  {
    "fileUris": [
      "https://raw.githubusercontent.com/ChrisGbr/franchise-rollout/feature/terraform-extension-ad/scripts/configure-ou.ps1"
    ]
  }
  PROTECTED_SETTINGS

  depends_on = [azurerm_virtual_machine_extension.bootstrap_ad_hamburg]
}
