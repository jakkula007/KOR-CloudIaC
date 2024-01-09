#This section configures the Azure provider for Terraform. 
#It sets up the necessary credentials (client ID, client secret, subscription ID, and tenant ID) 
#to authenticate with Azure.

provider "azurerm" {
  features {}
  client_id       = var.client_id
  client_secret   = var.client_secret
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}


#This retrieves information about an existing Azure resource group named "AUE-KOR-ResourceGroup-TRN01" 
#using the azurerm_resource_group data source.

data "azurerm_resource_group" "existing" {
  name = "AUE-KOR-ResourceGroup-TRN01"
}

#This resource block creates an Azure Virtual Network named "jack-network" with the address space "10.0.0.0/16" 
#in the specified resource group and location.

resource "azurerm_virtual_network" "example" {
  name                = "virtual_network_name"
  resource_group_name = data.azurerm_resource_group.existing.name
  location            = data.azurerm_resource_group.existing.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "public_subnet" {
  count                = 1
  name                 = "public-subnet-${count.index + 1}"
  resource_group_name  = data.azurerm_resource_group.existing.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.${count.index + 1}.0/24"]
}

resource "azurerm_subnet" "private_subnet" {
  count                = 1
  name                 = "private-subnet"
  resource_group_name  = data.azurerm_resource_group.existing.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.${count.index + 4}.0/24"]
}


#This local variable creates a list of public IP IDs from the azurerm_public_ip resource block
#storing them for later use.




#This resource block creates an Azure network interface for each virtual machine. 
#It is associated with a specific subnet and gets a dynamic private IP address.
# It also links to a public IP from the list created earlier.

resource "azurerm_network_interface" "example" {
  count               = 1
  name                = "jack-nic"
  resource_group_name = data.azurerm_resource_group.existing.name
  location            = data.azurerm_resource_group.existing.location

  ip_configuration {
    name      = "jack-ip-config"
    subnet_id = azurerm_subnet.private_subnet[count.index % length(azurerm_subnet.private_subnet)].id

    private_ip_address_allocation = "Dynamic"
    
  }
}


#This resource block creates Azure public IP addresses for each virtual machine with dynamic allocation.

# Create Public IP addresses
resource "azurerm_public_ip" "example" {
  count               = 1
  name                = "example-public-ip"
  resource_group_name = data.azurerm_resource_group.existing.name
  location            = data.azurerm_resource_group.existing.location
  allocation_method   = "Dynamic"
}

# Create Network Security Group
#This resource block defines a Network Security Group (NSG) in Azure.

resource "azurerm_network_security_group" "example_nsg" {
  name                = "nsg_name"
  resource_group_name = data.azurerm_resource_group.existing.name
  location            = data.azurerm_resource_group.existing.location
}

# Define NSG rules for inbound traffic
#This resource block defines an inbound rule in the NSG to allow all traffic.

resource "azurerm_network_security_rule" "example_inbound_rule" {
  name                        = "inbound-rule"
  resource_group_name         = data.azurerm_resource_group.existing.name
  network_security_group_name = azurerm_network_security_group.example_nsg.name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

# Define NSG rules for outbound traffic
#This resource block defines an outbound rule in the NSG to allow all outbound traffic.


resource "azurerm_network_security_rule" "example_outbound_rule" {
  name                        = "outbound-rule"
  resource_group_name         = data.azurerm_resource_group.existing.name
  network_security_group_name = azurerm_network_security_group.example_nsg.name
  priority                    = 110
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

# Attach NSG to the network interface
#This resource block associates the NSG with the network interface of each virtual machine.

resource "azurerm_network_interface_security_group_association" "example_nic_nsg_association" {
  count = 1

  network_interface_id      = azurerm_network_interface.example[count.index % length(azurerm_network_interface.example)].id
  network_security_group_id = azurerm_network_security_group.example_nsg.id
}


#These resource blocks define specific rules in the NSG for allowing RDP (Remote Desktop Protocol) 
#traffic to Windows machines and SSH traffic to Linux machines.

# Define NSG rules for inbound traffic for RDP (Windows)
resource "azurerm_network_security_rule" "example_rdp_rule" {
  resource_group_name         = data.azurerm_resource_group.existing.name
  network_security_group_name = azurerm_network_security_group.example_nsg.name
  
  name                        = "rdp-rule"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}




#This resource block creates an Azure virtual machine for each specified count.
# It associates the VM with the previously created network interface, 
#sets the VM size based on user input or predefined values, and uses the specified OS type.


resource "azurerm_virtual_machine" "example" {

  count                 = 1
  name                  = "jack-virtual_machine_name"
  vm_size               = "Standard_D2_v2"
  resource_group_name   = data.azurerm_resource_group.existing.name
  location              = data.azurerm_resource_group.existing.location
  network_interface_ids = [azurerm_network_interface.example[count.index].id]
  
    
  





  #This specifies the image reference for the virtual machine, 
  #determining the OS image to use based on the OS type specified.


  /* publisher:
For Windows OS, it sets the publisher to "MicrosoftWindowsServer."
For Linux OS, it sets the publisher to "Canonical."
The publisher represents the entity that created the OS image.


offer:
For Windows OS, it sets the offer to "WindowsServer."
For Linux OS, it sets the offer to "UbuntuServer."
The offer is a specific edition or version of the OS.


sku:
For Windows OS, it sets the SKU (stock keeping unit) to "2019-Datacenter."
For Linux OS, it sets the SKU to "18.04-LTS."
The SKU specifies the particular variant of the OS.

version:
It sets the version to "latest," indicating that the latest available version of the specified OS should be used.*/

   storage_image_reference {
	publisher = "MicrosoftWindowsServer"
	offer     = "WindowsServer"
	sku       = "2019-Datacenter"
	version   = "latest"
}

   os_profile {
    computer_name  = "jackcomp"
    admin_username = "jackuser"
    admin_password = "Password123"
}


  os_profile_windows_config {
    provision_vm_agent = true
  }

  #This defines the OS disk for the virtual machine, specifying details like name, caching, 
  #creation options, managed disk type, disk size, and OS type.

  storage_os_disk {
    name              = "CentOS121-os-disk-vm"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    disk_size_gb      = 128

    

  }

  tags = {
    environment = "dev"
  }
}