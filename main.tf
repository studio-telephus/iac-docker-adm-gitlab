module "container_adm_gitlab" {
  source    = "github.com/studio-telephus/tel-iac-modules-lxd.git//container?ref=develop"
  name      = "container-adm-gitlab"
  profiles  = ["limits", "fs-dir", "nw-adm", "privileged"]
  autostart = true
  nic = {
    name = "eth0"
    properties = {
      nictype        = "bridged"
      parent         = "adm-network"
      "ipv4.address" = "10.0.10.121"
    }
  }
  mount_dirs = [
    "${path.cwd}/filesystem-shared-ca-certificates",
    "${path.cwd}/filesystem",
  ]
  exec_enabled = true
  exec         = "/mnt/install.sh"
  environment = {
    RANDOM_STRING = "d1b52079-581c-4ec8-b678-eb79aa39cdc4"
  }
}
