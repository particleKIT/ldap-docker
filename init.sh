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

if [ ! -f "/db/id2entry.bdb" ]; then
    echo "No existing database found."
    if [ "$ROLE" == "master"  ] ; then
        echo "... Trying to create one from backup"
        if [ ! -f "/db/DB_CONFIG" ]; then
            echo "WARNING: no DB_CONFIG file found!"
        fi

        echo "$LDAP_BACKUP"
        if [ -z "$LDAP_BACKUP" ]; then
            LDAP_BACKUP="/backup/$(ls /backup -c1|head -1)"
        fi
        if [ -f "$LDAP_BACKUP" ]; then
            echo "migrating $LDAP_BACKUP"
            slapadd -l "$LDAP_BACKUP"
        else
            echo "FATAL: $LDAP_BACKUP backup file not found or var LDAP_BACKUP not set porperly."
            exit 1
        fi
    fi
fi

echo "starting slapd..."
chown -R ldap:ldap /var/lib/ldap/
chown -R ldap:ldap /etc/openldap/slapd.d
/usr/lib/openldap/slapd -f /etc/openldap/slapd.conf -F /etc/openldap/slapd.d -u ldap -g ldap -h ldaps:/// -d "$LOGLEVEL"
