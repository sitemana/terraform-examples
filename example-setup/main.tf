###
### SYS11 Terraform Example
### Terraform reproduction of https://github.com/syseleven/heattemplates-examples/tree/master/example-setup
###

################################################################################
# Input variables
################################################################################

variable "number_appservers" {
  type    = "string"
  default = "4"
}

variable "number_dbservers" {
  type    = "string"
  default = "3"
}

variable "number_servicehosts" {
  type    = "string"
  default = "1"
}

variable "public_network" {
  type = "string"
}

variable "flavor_lb" {
  type    = "string"
  default = "m1.micro"
}

variable "flavor_appserver" {
  type    = "string"
  default = "m1.micro"
}

variable "flavor_dbserver" {
  type    = "string"
  default = "m1.micro"
}

variable "flavor_servicehost" {
  type    = "string"
  default = "m1.micro"
}

variable "image" {
  type = "string"
}

variable "consul_mastertoken_length" {
  type    = "string"
  default = "30"
}

variable "consul_agenttoken_length" {
  type    = "string"
  default = "30"
}

variable "ssh_keys" {
  type = "list"
}

################################################################################
# Data we get from OpenStack
################################################################################

data "openstack_networking_network_v2" "public_network" {
  name = "${var.public_network}"
}

################################################################################
# Data we generate ourselves
################################################################################

resource "random_string" "consul_mastertoken" {
  length  = "${var.consul_mastertoken_length}"
  special = false
}

resource "random_string" "consul_agenttoken" {
  length  = "${var.consul_agenttoken_length}"
  special = false
}

################################################################################
# Base network configuration
################################################################################

resource "openstack_networking_network_v2" "syseleven_net" {
  name           = "syseleven_net"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "syseleven_subnet" {
  name            = "syseleven_subnet"
  network_id      = "${openstack_networking_network_v2.syseleven_net.id}"
  cidr            = "192.168.2.0/24"
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
  ip_version      = 4

  allocation_pools = [{
    start = "192.168.2.10"

    end = "192.168.2.250"
  }]
}

resource "openstack_networking_router_v2" "syseleven_router" {
  name                = "syseleven_router"
  admin_state_up      = true
  external_network_id = "${data.openstack_networking_network_v2.public_network.id}"
}

resource "openstack_networking_router_interface_v2" "router_subnet_connect" {
  router_id = "${openstack_networking_router_v2.syseleven_router.id}"
  subnet_id = "${openstack_networking_subnet_v2.syseleven_subnet.id}"
}

################################################################################
# Bring up the machines using appropriate modules
################################################################################

module "servicehost_group" {
  count  = "${var.number_servicehosts}"
  source = "modules/servicehost"

  metadata = {
    "consul_main"        = "127.0.0.1"
    "consul_mastertoken" = "${random_string.consul_mastertoken.result}"
    "consul_agenttoken"  = "${random_string.consul_agenttoken.result}"
  }

  name           = "servicehost"
  flavor         = "${var.flavor_servicehost}"
  image          = "${var.image}"
  syseleven_net  = "${openstack_networking_network_v2.syseleven_net.name}"
  public_network = "${var.public_network}"
  ssh_keys       = "${var.ssh_keys}"
}

module "lb_group" {
  source = "modules/lb"

  metadata = {
    "consul_main"        = "${join(",", module.servicehost_group.instance_ip)}"
    "consul_mastertoken" = "${random_string.consul_mastertoken.result}"
    "consul_agenttoken"  = "${random_string.consul_agenttoken.result}"
  }

  name           = "lb"
  flavor         = "${var.flavor_lb}"
  image          = "${var.image}"
  syseleven_net  = "${openstack_networking_network_v2.syseleven_net.name}"
  public_network = "${var.public_network}"
  ssh_keys       = "${var.ssh_keys}"
}

module "dbserver_group" {
  count  = "${var.number_dbservers}"
  source = "modules/dbserver"

  metadata = {
    "consul_main"        = "${join(",", module.servicehost_group.instance_ip)}"
    "consul_mastertoken" = "${random_string.consul_mastertoken.result}"
    "consul_agenttoken"  = "${random_string.consul_agenttoken.result}"
  }

  name          = "db"
  flavor        = "${var.flavor_dbserver}"
  image         = "${var.image}"
  syseleven_net = "${openstack_networking_network_v2.syseleven_net.name}"
  ssh_keys      = "${var.ssh_keys}"
}

module "appserver_group" {
  count  = "${var.number_appservers}"
  source = "modules/server"

  metadata = {
    "consul_main"        = "${join(",", module.servicehost_group.instance_ip)}"
    "consul_mastertoken" = "${random_string.consul_mastertoken.result}"
    "consul_agenttoken"  = "${random_string.consul_agenttoken.result}"
  }

  name          = "app"
  flavor        = "${var.flavor_appserver}"
  image         = "${var.image}"
  syseleven_net = "${openstack_networking_network_v2.syseleven_net.name}"
  ssh_keys      = "${var.ssh_keys}"
}

################################################################################
# Output locally generated values
################################################################################

output "consul_mastertoken" {
  value = "${random_string.consul_mastertoken.result}"
}

output "consul_agenttoken" {
  value = "${random_string.consul_agenttoken.result}"
}
