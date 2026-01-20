#!/bin/bash
# ================================================================
# PROYECTO: SERVICIO INTEGRADO DE AUTENTICACION (FIS)
# ESTUDIANTE: SARANGO J
# ================================================================

echo "--- [1/5] Iniciando Instalacion Limpia para SarangoJ ---"

# 1. Preparativos del Sistema
sudo hostnamectl set-hostname krb5.fis.epn.ec
sudo apt-get update -y

# 2. Instalacion de Sincronizacion de Tiempo (Vital)
echo "--- [2/5] Instalando NTP ---"
sudo apt-get install ntpdate -y
sudo ntpdate -u pool.ntp.org

# 3. Instalacion de DNS (Bind9)
echo "--- [3/5] Instalando Bind9 (DNS) ---"
sudo apt-get install bind9 bind9utils bind9-doc -y

# 4. Instalacion de Kerberos (KDC)
# NOTA: TE PEDIRA PANTALLAS AZULES/ROSADAS. REVISA EL CHAT PARA SABER QUE PONER.
echo "--- [4/5] Instalando Kerberos ---"
sudo apt-get install krb5-kdc krb5-admin-server -y

# 5. Instalacion de LDAP y Apache (Web)
echo "--- [5/5] Instalando LDAP y Apache ---"
sudo apt-get install slapd ldap-utils -y
sudo apt-get install apache2 libapache2-mod-auth-gssapi php libapache2-mod-php -y

echo "--- INSTALACION DE PAQUETES COMPLETADA ---"
echo "Ahora procedemos a la configuracion..."
