locals {
  docker_image_name = "tel-${var.env}-gitlab"
  container_name    = "container-${var.env}-gitlab"
  fqdn              = "gitlab.docker.${var.env}.acme.corp"
  external_address  = "https://telephus.k-space.ee/gitlab"

  omnibus_template = <<-EOT
    gitlab_rails['gitlab_shell_ssh_port'] = 22;
    nginx['enable'] = true;
    nginx['ssl_certificate'] = '/etc/gitlab/ssl/certs/server-chain.crt';
    nginx['ssl_certificate_key'] = '/etc/gitlab/private/server.key';
    letsencrypt['enable'] = false;
    external_url '${local.external_address}';
    gitlab_rails['initial_root_password'] = '${module.bw_platform_gitlab_initial.data.password}';
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
}

resource "docker_volume" "gitlab_data" {
  name = "volume-${var.env}-gitlab-data"
}

resource "docker_volume" "gitlab_config" {
  name = "volume-${var.env}-gitlab-config"
}

resource "docker_volume" "gitlab_logs" {
  name = "volume-${var.env}-minio-logs"
}

resource "docker_container" "gitlab" {
  name     = local.container_name
  image    = docker_image.gitlab.image_id
  restart  = "on-failure"
  must_run = true
  hostname = local.container_name

  networks_advanced {
    name         = "${var.env}-docker"
    ipv4_address = "10.10.0.121"
  }

  env = [
    "GITLAB_OMNIBUS_CONFIG=${local.omnibus_template}"
  ]

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
