# This parameter file is configured to be used with a 30 Core / 120 GB RAM quota provided by SysEleven GmbH.

public_network = "ext-net"

image = "Ubuntu 16.04 LTS sys11 optimized 2018.03.21"

# Used resources can be configures with the following parameters
number_appservers = "4"

number_dbservers = "3"

number_servicehosts = "1"

flavor_lb = "m1.tiny"

flavor_appserver = "m1.tiny"

flavor_dbserver = "m1.tiny"

flavor_servicehost = "m1.tiny"

consul_mastertoken_length = "30"

consul_agenttoken_length = "30"

# Please exchange the ssh public keys below with yours 
ssh_keys = [
  "ssh-rsa AAAAB3Nz [...] ABAAACAC62Lw== user1@host",
  "ssh-rsa AAAAT1MT [...] CDBAACDB66Iz== user2@host",
]
