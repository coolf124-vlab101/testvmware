##Provider

provider "vsphere" {
  user           = var.vsphere_user
  password       = var.vsphere_pass
  vsphere_server = var.vsphere_server

  # If you have a self-signed cert
  allow_unverified_ssl = true
}


##Data

data "vsphere_datacenter" "dc" {
  name = var.vsphere_datacenter
}

data "vsphere_datastore" "datastore" {
  name          = var.vsphere_datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.vsphere_cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = var.vsphere_network
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = var.vsphere_template
  datacenter_id = data.vsphere_datacenter.dc.id
}

##vSphere VMs

resource "vsphere_virtual_machine" "vm01" {
  name             = "vm01"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id

  num_cpus = 2
  memory   = 2048
  firmware  = "efi"
  efi_secure_boot_enabled = true
  guest_id = data.vsphere_virtual_machine.template.guest_id

  scsi_type = data.vsphere_virtual_machine.template.scsi_type

  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  disk {
    label            = "disk0"
    size             = data.vsphere_virtual_machine.template.disks.0.size
    eagerly_scrub    = data.vsphere_virtual_machine.template.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
  }


  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    
  }

 connection {
    type     = "ssh"
    user     = "root"
    password = var.root_pass
    host     = vsphere_virtual_machine.vm01.default_ip_address
 }

 provisioner "remote-exec" {
   inline = [
    "sleep 60",
      "echo 'hello world'"
      
    ]
 }

 }

 ##Output

output "ip" {
value = vsphere_virtual_machine.vm01.default_ip_address

}
