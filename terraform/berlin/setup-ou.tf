resource "azurerm_virtual_machine_extension" "ou_config_berlin" {
  name                 = "ou-config-berlin"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm_berlin.id
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

  depends_on = [azurerm_virtual_machine_extension.setup_ad_berlin]
}
