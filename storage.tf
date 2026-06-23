# Random suffix so the globally-unique storage account name doesn't collide.
resource "random_string" "sa_suffix" {
  length  = 6
  upper   = false
  special = false
}

# ---------------------------------------------------------------------------
# Storage account with the public endpoint switched OFF.
# This is the core data-security control: the account is unreachable from
# the internet and can only be hit through the private endpoint below.
# ---------------------------------------------------------------------------
resource "azurerm_storage_account" "sa" {
  name                     = "st${var.prefix}${random_string.sa_suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  # --- Defence-in-depth controls ---
  public_network_access_enabled     = false # no internet-facing endpoint
  allow_nested_items_to_be_public   = false # disable blob anonymous access
  shared_access_key_enabled         = false # force Entra ID (RBAC) auth, no account keys
  infrastructure_encryption_enabled = true  # double encryption at rest (set at creation only)

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Private DNS zone for blob storage, linked to BOTH VNets so that any
# resource in the hub or spoke resolves the storage FQDN to its private IP.
# ---------------------------------------------------------------------------
resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "hub" {
  name                  = "dnslink-hub"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "spoke" {
  name                  = "dnslink-spoke"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = azurerm_virtual_network.spoke.id
  registration_enabled  = false
  tags                  = var.tags
}

# ---------------------------------------------------------------------------
# Private endpoint for the blob service, placed in the dedicated PE subnet.
# The private_dns_zone_group wires the endpoint's IP into the DNS zone
# automatically, so name resolution "just works" from inside the VNets.
# ---------------------------------------------------------------------------
resource "azurerm_private_endpoint" "blob" {
  name                = "pe-${var.prefix}-blob"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.spoke_privateendpoints.id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-blob"
    private_connection_resource_id = azurerm_storage_account.sa.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdzg-blob"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob.id]
  }
}
