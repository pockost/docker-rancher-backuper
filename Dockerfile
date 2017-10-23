FROM alpine

RUN apk update && apk add docker duplicity lftp

COPY backup_mysql.sh /usr/local/bin
COPY backup_to_ftp.sh /usr/local/bin
COPY backup_to_ftp_incr.sh /usr/local/bin
COPY backup_purge_old_to_ftp.sh /usr/local/bin
COPY crontabs /etc/crontabs/root

CMD [ "crond", "-f" ]
