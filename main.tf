locals {
  docker_image_name = "tel-${var.env}-gitlab"
  container_name    = "container-${var.env}-gitlab"
  fqdn              = "gitlab.docker.${var.env}.acme.corp"
  external_address  = "https://telephus.k-space.ee/gitlab"

  omnibus_template = <<-EOT
    gitlab_rails['gitlab_shell_ssh_port'] = 2233;
    nginx['enable'] = true;
    nginx['ssl_certificate'] = '/etc/gitlab/ssl/certs/server-chain.crt';
    nginx['ssl_certificate_key'] = '/etc/gitlab/ssl/private/server.key';
    letsencrypt['enable'] = false;
    external_url '${local.external_address}';
  EOT

  //  env_template = <<EOT
  //    %{if var.bootstrappable}
  //    BOOTSTRAPPABLE=${var.bootstrappable}
  //    %{~endif~}
  //  EOT
}

resource "docker_image" "gitlab" {
  name         = local.docker_image_name
  keep_locally = false
  build {
    context = path.module
    build_args = {
      _SERVER_KEY_PASSPHRASE = module.bw_gitlab_pk_passphrase.data.password
    }
  }
  triggers = {
    dir_sha1 = sha1(join("", [
      filesha1("${path.module}/Dockerfile")
    ]))
  }
}

resource "docker_volume" "gitlab_data" {
  name = "volume-${var.env}-gitlab-data"
}

resource "docker_volume" "gitlab_config" {
  name = "volume-${var.env}-gitlab-config"
}

resource "docker_volume" "gitlab_logs" {
  name = "volume-${var.env}-gitlab-logs"
}

resource "docker_container" "gitlab" {
  name  = local.container_name
  image = docker_image.gitlab.image_id
  //  restart    = "on-failure"
  //  must_run   = true
  restart  = "unless-stopped"
  hostname = local.container_name
  privileged = true
  shm_size = 1024

//  ulimit {
//    name = "core"
//    soft = 0
//    hard = 0
//  }
//
//  ulimit {
//    name = "nproc"
//    soft = 3101
//    hard = 3101
//  }
//
//  ulimit {
//    name = "nofile"
//    hard = 65536
//    soft = 65536
//  }
//
//  ulimit {
//    name = "sigpending"
//    hard = 65536
//    soft = 65536
//  }
//
//  ulimit {
//    name = "cpu"
//    soft = 2
//    hard = 3
//  }
//  ulimit {
//    name = "memlock"
//    soft = 32768
//    hard = 32768
//  }
//
//  sysctls = {
//    "net.core.somaxconn"         = "1024"
//    "kernel.shmall" = "4194304"
//    "kernel.shmmax" = "17179869184"
//    "kernel.sem"     = "250 32000 32 262"
//  }

  networks_advanced {
    name         = "${var.env}-docker"
    ipv4_address = "10.10.0.121"
  }

  env = [
    "GITLAB_OMNIBUS_CONFIG=${local.omnibus_template}"
  ]

  ports {
    internal = 22
    external = 2233
  }

  healthcheck {
    interval     = "1m0s"
    retries      = 5
    start_period = "0s"
    test = [
      "CMD-SHELL",
      "/opt/gitlab/bin/gitlab-healthcheck --fail --max-time 10",
    ]
    timeout = "30s"
  }

  volumes {
    volume_name    = docker_volume.gitlab_config.name
    container_path = "/etc/gitlab"
    read_only      = false
  }

  volumes {
    volume_name    = docker_volume.gitlab_logs.name
    container_path = "/var/log/gitlab"
    read_only      = false
  }

  volumes {
    volume_name    = docker_volume.gitlab_data.name
    container_path = "/var/opt/gitlab"
    read_only      = false
  }
}
