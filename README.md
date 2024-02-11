# iac-docker-adm-gitlab

1. Deploy this IaC to create the Gitlab Docker container.
2. Get the temporary root password from `/etc/gitlab/initial_root_password`.
3. Log in and change the temporary root password to the one saved in Bitwarden.
4. Create a PAT for the root user and save it to Bitwarden under `platform_gitlab_api_key`
5. Save the runner registration key to Bitwarden under `platform_gitlab_runner_registration_key`
6. Deploy `iac-gitlab-config` to create the base configuration.
7. Each group will then have their own repository to administer the group.

## Helpers

    docker inspect container-adm-gitlab | grep -i shm

## Pre-flight

Before GitLab could be installed the *host* requires some preparation.
Add the followings to /etc/sysctl.conf

cat <<-EOF >> /etc/sysctl.conf
## For Gitlab
kernel.shmall = 4194304
kernel.sem = 250 32000 32 262
net.core.somaxconn = 1024
kernel.shmmax = 17179869184
EOF

## LXC server

Run the Github workflow to install the Terraform resources to remote host server.

## Inside container-gitlab

    apt install vim curl wget htop openssh-server git

Self-signed certificate

    openssl rsa -in 1.key -out 1-after.key

Pre-install

    export EXTERNAL_URL="https://telephus.k-space.ee/gitlab"

### E-mail setup

Configure gitlab settings in /etc/gitlab/gitlab.rb

    ### GitLab email server settings
    ###! Docs: https://docs.gitlab.com/omnibus/settings/smtp.html
    ###! **Use smtp instead of sendmail/postfix.**
    
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.gmail.com"
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = "studio.telephus@gmail.com"
gitlab_rails['smtp_password'] = "changeit"
gitlab_rails['smtp_domain'] = "smtp.gmail.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = false
    
    ###! **Can be: 'none', 'peer', 'client_once', 'fail_if_no_peer_cert'**
    ###! Docs: http://api.rubyonrails.org/classes/ActionMailer/Base.html
    gitlab_rails['smtp_openssl_verify_mode'] = 'peer'
    
    # gitlab_rails['smtp_ca_path'] = "/etc/ssl/certs"
    # gitlab_rails['smtp_ca_file'] = "/etc/ssl/certs/ca-certificates.crt"
    
### Email Settings

gitlab_rails['gitlab_email_enabled'] = true

##! If your SMTP server does not like the default 'From: gitlab@gitlab.example.com'
##! can change the 'From' with this setting.
gitlab_rails['gitlab_email_from'] = 'gitlab@gitlab.docker.adm.acme.corp'
gitlab_rails['gitlab_email_display_name'] = 'Gitlab'
gitlab_rails['gitlab_email_reply_to'] = 'noreply@gitlab.docker.adm.acme.corp'
gitlab_rails['gitlab_email_subject_suffix'] = '[GITLAB]'
# gitlab_rails['gitlab_email_smime_enabled'] = false
# gitlab_rails['gitlab_email_smime_key_file'] = '/etc/gitlab/ssl/gitlab_smime.key'
# gitlab_rails['gitlab_email_smime_cert_file'] = '/etc/gitlab/ssl/gitlab_smime.crt'
# gitlab_rails['gitlab_email_smime_ca_certs_file'] = '/etc/gitlab/ssl/gitlab_smime_cas.crt'

Test

    gitlab-rails console

Then

    Notify.test_email('studio.telephus@gmail.com', 'Message Subject', 'Message Body').deliver_now

## Verify

Test curl

    curl --cacert /opt/acme-pki.git/self-signed/franciumca.cer \
        'https://gitlab.docker.adm.acme.corp/gitlab' -v

    curl --insecure \
        'https://gitlab.docker.adm.acme.corp/gitlab' -v

## Upgrade

    https://docs.gitlab.com/ee/update/package

## Manual conf

Admin Area -> CI/CD -> Variables

    GITLAB_ORIGIN=https://gitlab.docker.adm.acme.corp/gitlab
    NEXUS_ORIGIN=https://nexus.adm.acme.corp/nexus
    SONAR_ORIGIN=https://sonarqube.adm.acme.corp/sonarqube
    CI_NEXUS_MAVEN_URL=$NEXUS_ORIGIN/repository/maven-releases
    CI_NEXUS_DOCKER_URL=nexus.adm.acme.corp:18443
    SONAR_ANALYZE_TOKEN=changeit (mask)

## Project "iam"

### CI/CD Settings -> Variables

    CI_NEXUS_MAVEN_PUBLISH_USERNAME=nx-common-publish (protect)
    CI_NEXUS_MAVEN_PUBLISH_PASSWORD=changeit (protect, mask)   
    CI_NEXUS_DOCKER_PUBLISH_USER=nx-docker-private-publish (protect)
    CI_NEXUS_DOCKER_PUBLISH_PASSWORD=changeit (protect, mask)  

### Links

- https://docs.gitlab.com/ee/install/docker.html
