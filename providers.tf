provider "azurerm" {
  features {}

  # azurerm v4+ requires the subscription to be set explicitly.
  # In Cloud Shell you can omit this and instead export ARM_SUBSCRIPTION_ID,
  # but passing it as a variable keeps the config self-contained.
  subscription_id = var.subscription_id
}
