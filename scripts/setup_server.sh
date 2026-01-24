#!/bin/bash
echo "--- Iniciando Configuracion SarangoJ ---"
# 1. Detectar IP actual (WSL)
MYIP=$(hostname -I | awk '{print $1}')
echo "Tu IP detectada es: $MYIP"

# 2. Configurar DNS (Bind9)
echo "Configurando Bind9..."
cat <<EOF | sudo tee /etc/bind/named.conf.local
zone "fis.epn.ec" {
    type master;
    file "/etc/bind/db.fis.epn.ec";
};
EOF

cat <<EOF | sudo tee /etc/bind/db.fis.epn.ec
;
; BIND data file for FIS.EPN.EC
;
\$TTL    604800
@       IN      SOA     krb5.fis.epn.ec. admin.fis.epn.ec. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      krb5.fis.epn.ec.
@       IN      A       $MYIP
krb5    IN      A       $MYIP
EOF

# 3. Configurar Kerberos (krb5.conf) CON RUTAS EXPLÍCITAS
echo "Configurando krb5.conf..."
cat <<EOF | sudo tee /etc/krb5.conf
[libdefaults]
    default_realm = FIS.EPN.EC
    dns_lookup_realm = false
    dns_lookup_kdc = true

[realms]
    FIS.EPN.EC = {
        kdc = krb5.fis.epn.ec
        admin_server = krb5.fis.epn.ec
        database_name = /var/lib/krb5kdc/principal
        admin_keytab = FILE:/etc/krb5kdc/kadm5.keytab
        acl_file = /etc/krb5kdc/kadm5.acl
        key_stash_file = /etc/krb5kdc/stash
        kdc_ports = 88
        max_life = 10h 0m 0s
        max_renewable_life = 7d 0h 0m 0s
    }

[domain_realm]
    .fis.epn.ec = FIS.EPN.EC
    fis.epn.ec = FIS.EPN.EC
EOF

# 4. Crear archivo ACL de Kerberos
echo "Configurando ACL de Kerberos..."
sudo mkdir -p /etc/krb5kdc
cat <<EOF | sudo tee /etc/krb5kdc/kadm5.acl
*/admin@FIS.EPN.EC    *
EOF

# 5. Configurar kdc.conf
echo "Configurando kdc.conf..."
cat <<EOF | sudo tee /etc/krb5kdc/kdc.conf
[kdcdefaults]
    kdc_ports = 88

[realms]
    FIS.EPN.EC = {
        database_name = /var/lib/krb5kdc/principal
        admin_keytab = FILE:/etc/krb5kdc/kadm5.keytab
        acl_file = /etc/krb5kdc/kadm5.acl
        key_stash_file = /etc/krb5kdc/stash
        kdc_ports = 88
        max_life = 10h 0m 0s
        max_renewable_life = 7d 0h 0m 0s
        default_principal_flags = +preauth
    }
EOF

# 6. Reiniciar servicio de red
sudo systemctl restart bind9
echo "--- Archivos Creados Exitosamente ---"
