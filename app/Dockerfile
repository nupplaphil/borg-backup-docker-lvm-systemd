FROM alpine:latest
MAINTAINER "Philipp Holzer" <admin@philipp.info>

ENV GID=666 \
    UID=666 \
    TZ=Europe/Vienna

ENV BORG_BACKUP_DIR=/borg/data
ENV BORG_PRUNE=1
ENV KEEP_DAILY="14" \
    KEEP_WEEKLY="8" \
    KEEP_MONTHLY="6" \
    KEEP_YEARLY="0"

WORKDIR /borg/scripts

RUN apk update && apk upgrade \
      && apk -U add borgbackup openssh-keygen openssh-client \ 
      && rm -fr /var/cache/apk/*

LABEL description "Borg Backup Helper Script" \
      borg "Borg Cron v${PKG_VER}"

VOLUME /borg/data /borg/cache /borg/config /borg/config/keys /var/log/borg

COPY docker-entrypoint.sh /usr/local/bin/
RUN ln -s /usr/local/bin/docker-entrypoint.sh /
ENTRYPOINT [ "docker-entrypoint.sh"]

CMD [ "create" ]
