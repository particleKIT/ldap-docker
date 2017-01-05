#!/bin/bash

if [ "$1" == "bash" ]; then
    exec $@
fi

if [ ! -f "/config/slapd.conf" ] && [ ! "$(ls -A /config/slapd.d)" ] ; then
    echo "no config files found."
    exit 1
fi

if [ ! "$(ls -A /config/ssl)" ]; then
   echo "No SSL certificates found,"
   echo -e "dont forget to run:\nchown 76:70 private.pem\nchmod 'og=-rwx' private.pem"
   exit 1
else
    echo "copy public keys to /etc/pki/trust/anchors/ and update trusted certificates"
    cp /config/ssl/*public* /etc/pki/trust/anchors/
    /usr/sbin/update-ca-certificates -f -v
fi

if [ "$ROLE" == "master"  ] ; then
    if [ ! -f "/db/data.mdb" ]  ; then
        echo "No existing database found."
        echo "... Trying to create one from backup"
        if [ ! -f "/db/DB_CONFIG" ]; then
            echo "WARNING: no DB_CONFIG file found!"
        fi

        LDAP_BACKUP_FILE="/backup/$(ls /backup -c1|head -n1)"
        if [ -f "$LDAP_BACKUP_FILE" ]; then
            echo "extracting $LDAP_BACKUP_FILE"
            gunzip "$LDAP_BACKUP_FILE"
            LDAP_BACKUP_FILE="${LDAP_BACKUP_FILE%.gz}"
            echo "migrating $LDAP_BACKUP_FILE"
            slapadd -l "$LDAP_BACKUP_FILE"
        else
            echo "FATAL: $LDAP_BACKUP_FILE backup file not found in /backup."
            exit 1
        fi

    fi
    if [ "$BACKUP_CRON" != "" ]; then
        echo "setting ldap-backup-cron to $BACKUP_CRON"
        echo "$BACKUP_CRON    root    /usr/local/sbin/ldap-backup" > /etc/cron.d/ldap-backup
        /usr/sbin/cron
    fi
fi

echo "starting slapd..."
chown -R ldap:ldap /var/lib/ldap/
chown -R ldap:ldap /etc/openldap/slapd.d
/usr/sbin/slapd -f /etc/openldap/slapd.conf -F /etc/openldap/slapd.d -u ldap -g ldap -h ldaps:/// -d "$LOGLEVEL"
