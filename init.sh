#!/bin/bash

if [ "$1" == "bash" ]; then
    exec $@
fi

if [ ! -f "/config/slapd.conf" ] && [ ! "$(ls -A /config/slapd.d)" ] ; then
    echo "no config files found."
    exit 1
fi

if [ ! "$(ls -A /ssl)" ]; then
   echo "No SSL certificates found,"
   echo -e "dont forget to run:\nchown 76:70 private.pem\nchmod 'og=-rwx' private.pem"
   exit 1
fi

if [ ! -f "/db/id2entry.bdb" ] && [ "$ROLE" == "master"  ] ; then
    echo "No existing database found. Trying to create one from backup"
    if [ ! -f "/db/DB_CONFIG" ]; then
        echo "WARNING no DB_CONFIG file found!"
    fi

    if [ -f "$LDAP_BACKUP" ]; then
        slapadd -l "$LDAP_BACKUP"
    else
        echo ".ldif file $LDAP_BACKUP not found or var LDAP_BACKUP not set porperly."
    fi

fi

chown -R ldap:ldap /var/lib/ldap/
chown -R ldap:ldap /etc/openldap/slapd.d
/usr/lib/openldap/slapd -f /etc/openldap/slapd.conf -F /etc/openldap/slapd.d -u ldap -g ldap -h ldaps:/// -d "$LOGLEVEL"
