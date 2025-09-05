packer {
  required_plugins {
    qemu = {
      version = "~> 1"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

variable "username" {
  type = string
  default = "dev"
}


variable "cpu" {
  type    = string
  default = "4"
}

variable "ram" {
  type    = string
  default = "4096"
}




source "qemu" "rocky-amd64" {
  iso_url           = "https://rockylinux.mirrorservice.org/pub/rocky/10.0/isos/x86_64/Rocky-10.0-x86_64-minimal.iso"
  # iso_url           = "https://dl.rockylinux.org/pub/rocky/10/isos/x86_64/Rocky-10.0-x86_64-minimal.iso"
  iso_checksum      = "sha256:de75c2f7cc566ea964017a1e94883913f066c4ebeb1d356964e398ed76cadd12"
  output_directory  = "artifacts"
  shutdown_command  = "sudo shutdown -P now"
  disk_size         = "8192M"
  format            = "qcow2"
  # if `accelerator` isn't specified; packer will try `kvm` followed by `tcg`
  ssh_username      = "${var.username}"
  ssh_timeout       = "20m"
  vm_name           = "rocky"
  net_device        = "virtio-net"
  boot_wait         = "1s" # 0s - https://github.com/hashicorp/packer/pull/9022
  headless          = false
  disk_compression  = true
  cpu_model = "Broadwell-v1"
  http_directory = "./http"
  boot_command = [
    "<esc><wait><up>e<wait><down><down><down><left> inst.text inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/rocky-install.ks PACKER_USER=${var.username} PACKER_AUTHORIZED_KEY={{ .SSHPublicKey | urlquery }}<wait><leftCtrlOn>x<leftCtrlOff>"
  ]
  boot_key_interval = "20ms"
  qemuargs = [ # kernel panics if not set...
    ["-machine", "type=q35,accel=hvf:kvm:whpx:tcg:none"],
    ["-m", "${var.ram}M"],
    ["-smp", "${var.cpu}"],
    ["-display", "none"]
  ]
}

build {
  sources = ["source.qemu.rocky-amd64"]

  provisioner "shell" {
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    scripts = ["scripts/10-base-packages.sh", "scripts/11-kernel.sh", "scripts/12-cloud-init.sh"]
  }
}
