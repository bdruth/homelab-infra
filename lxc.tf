resource "proxmox_lxc" "lxc-test" {
    features {
        nesting = true
    }
    hostname = "terraform-new-container"
    network {
        name = "eth0"
        bridge = "vmbr0"
        ip = "192.168.7.75/24"
        gw = "192.168.7.1"
        ip6 = "auto"
    }
    ostemplate = "f39ac8b4-7319-42ec-b12e-dd3d4d98a85f:vztmpl/debian-12-standard_12.2-1_amd64.tar.zst"
    password = "***REMOVED***"
    ssh_public_keys = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDDksBMkSWfRLuTAS30E/ZtzY74laZMxa7F6RGyDEJfObQaAyuf1FAmIdTEVgwDJ8gDqtUTy7tDv6reSqGyXNKmEgoNOBdJ4RXPAobZSXX6X2PsgNXd/mrZqHcc/RN4wkJpHmgLoj2ZJuE30Ld0/csP98GeusGREznCEhzuQ3a8N/YVkUtz1lgYKW7yWf5XKD1s/IQBwGmI4eA4I7EkljXtEFIqlEXF4zXNPRpSh+iND++zKdSFZ+ve7ZxWlTlwUCyn5wMRLYNWc+jk84ViX/mQr++dPihC/PVg58UwYK74w1pMfqrrZaHGPuKC64x3x3P1ytblEd752r82iAHTNL8R"
    start = true
    pool = "terraform-prov-pool"
    target_node = "proxmox-main"
    unprivileged = true
}

resource "null_resource" "run_ansible_playbook" {
    provisioner "local-exec" {
        command     = "until nc -zv ${split("/",proxmox_lxc.lxc-test.network[0].ip)[0]} 22; do echo 'Waiting for SSH to be available...'; sleep 5; done"
        working_dir = path.module
    }
    provisioner "local-exec" {
        command     = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i '${split("/",proxmox_lxc.lxc-test.network[0].ip)[0]},' -u root --private-key ./id_rsa ./ansible/pihole/main.yml"
        working_dir = path.module
    }
}

output "lxc_test_ip" {
    value = split("/",proxmox_lxc.lxc-test.network[0].ip)[0]
}