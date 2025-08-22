resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-voteapp-dev-frcentral"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "aks-voteapp-dev"

  default_node_pool {
    name    = "default"
    vm_size = "standard_d2s_v3"
    vnet_subnet_id = azurerm_subnet.aks_subnet.id
  
    enable_auto_scaling = true
    min_count            = 1
    max_count            = 3
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "Overlay"

    service_cidr   = "10.1.0.0/16"
    dns_service_ip = "10.1.0.10"

    pod_cidr = "10.2.0.0/16"

    network_policy = "calico"
  }

  tags = {
    Propietario = "Ivelin"
    Proyecto    = "Kubernetes"
    Entorno     = "Desarrollo"
  }
}