resource "azurerm_virtual_machine_extension" "bootstrap_ad_berlin" {
  name                 = "bootstrap-ad-berlin"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm_berlin.id
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
