#!/usr/bin/env bash

echo "Install the base tools"

apt-get update
apt-get install -y \
 curl vim wget htop unzip gnupg2 netcat-traditional \
 bash-completion openssh-server perl

## Run pre-install scripts
sh /mnt/setup-ca.sh

#echo "Next, install Postfix (or Sendmail) to send notification emails"
#apt-get install -y postfix

## Add the GitLab CE Repository
apt-get install -y debian-archive-keyring \
 lsb-release software-properties-common

## Add the official GitLab apt repository for the community edition
curl -sS https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | sudo bash

## The repository contents are added to:
cat /etc/apt/sources.list.d/gitlab_gitlab-ce.list

## Intended URL
export EXTERNAL_URL="https://telephus.k-space.ee/gitlab"

## Disable the automatic SSL certificate creation
export LETSENCRYPT="false"

## Install GitLab CE
apt-get install -y gitlab-ce

echo "Continue with manual install from here."
