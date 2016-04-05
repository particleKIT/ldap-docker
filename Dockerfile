FROM opensuse:leap
MAINTAINER TTP/ITP <admin@particle.kit.edu>

RUN zypper --gpg-auto-import-keys --non-interactive ref && \
    zypper --gpg-auto-import-keys --non-interactive up && \
    zypper --gpg-auto-import-keys --non-interactive in -l \
    openldap2 pam_ldap openldap2-client openssl ca-certificates cron

# setup a clean ldap environment
# enforce tls 
RUN echo "" > /etc/openldap/ldap.conf &&\
    rm -rf /var/lib/ldap/* /etc/openldap/slapd.* &&\
    sed -i 's/^OPENLDAP_START_LDAP=.*$/OPENLDAP_START_LDAP="no"/g' /etc/sysconfig/openldap &&\
    sed -i 's/^OPENLDAP_START_LDAPS=.*$/OPENLDAP_START_LDAPS="yes"/g' /etc/sysconfig/openldap &&\
    mkdir /etc/openldap/ssl &&\
    mkdir /backup &&\
    ln -s /etc/openldap /config &&\
    ln -s /var/lib/ldap /db 

VOLUME /config
VOLUME /db
VOLUME /backup

EXPOSE 389
EXPOSE 636

ADD init.sh /init.sh
ADD ldap-backup /usr/local/sbin/ldap-backup

# ROLE=master/slave

ENV ROLE=master \
    LOGLEVEL=stats \
    LDAP_BACKUP_DIR="/backup"
    LDAP_BACKUP_FILE=""
    LDAP_BACKUP_CRON="@hourly"  

ENTRYPOINT ["/init.sh"]
