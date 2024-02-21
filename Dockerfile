FROM gitlab/gitlab-ce:16.8.3-ce.0

COPY ./filesystem /.
COPY ./filesystem-shared-ca-certificates /.

ARG _SERVER_KEY_PASSPHRASE

RUN openssl rsa \
  -in /etc/gitlab/ssl/private/server-encrypted.key \
  -out /etc/gitlab/ssl/private/server.key \
  -passin "pass:${_SERVER_KEY_PASSPHRASE}"

RUN bash /mnt/setup-ca.sh

EXPOSE 22 80 443
