#!/bin/bash
# =======================================================================
# INSTALADOR AUTOMÁTICO - Servicio Integrado de Directorio y Autenticación para la FIS
# ESTUDIANTE: José Armando Sarango Cuenca
# =======================================================================

# --- BLOQUE 0: SANITIZACIÓN PROFUNDA (MATAR ZOMBIES) ---
echo "🧹 Ejecutando limpieza profunda de Kerberos..."

# Detener servicios primero
sudo systemctl stop krb5-kdc 2>/dev/null
sudo systemctl stop krb5-admin-server 2>/dev/null

# Eliminar binarios compilados manualmente
sudo rm -rf /usr/local/sbin/kdb5_util
sudo rm -rf /usr/local/sbin/krb5kdc
sudo rm -rf /usr/local/sbin/kadmind
sudo rm -rf /usr/local/bin/krb5-config
sudo rm -rf /usr/local/var/krb5kdc

# CRÍTICO: Eliminar librerías que causan symbol lookup error
sudo rm -rf /usr/local/lib/libkrb5*
sudo rm -rf /usr/local/lib/libgssapi*
sudo rm -rf /usr/local/lib/libkadm5*
sudo rm -rf /usr/local/include/krb5*

# Actualizar cache de librerías del sistema
sudo ldconfig

echo "✨ Limpieza profunda completada."
sleep 1

# --- BLOQUE 1: DETECCIÓN INTELIGENTE Y LIMPIEZA ---
clear
echo "========================================================="
echo " 🕵️  VERIFICACIÓN DE ENTORNO PREVIO"
echo "========================================================="

if dpkg -l | grep -q "krb5-kdc"; then
    echo "🚨 ATENCIÓN: Se ha detectado una instalación previa."
    read -p "♻️  ¿Desea realizar una LIMPIEZA TOTAL y reinstalar? (y/n): " limpiar
    
    if [[ "$limpiar" == "y" || "$limpiar" == "Y" ]]; then
        echo "🧹 Ejecutando Protocolo de Limpieza de Paquetes..."
        sudo systemctl stop krb5-kdc 2>/dev/null
        sudo systemctl stop krb5-admin-server 2>/dev/null
        sudo systemctl stop slapd 2>/dev/null
        sudo systemctl stop bind9 2>/dev/null
        sudo systemctl stop apache2 2>/dev/null
        
        # Purga completa
        sudo apt purge krb5-kdc krb5-admin-server krb5-config slapd ldap-utils bind9 bind9utils apache2 libapache2-mod-auth-gssapi -y > /dev/null 2>&1
        sudo apt autoremove --purge -y > /dev/null 2>&1
        
        # Borrado profundo de configuraciones
        sudo rm -rf /etc/krb5.conf /var/lib/krb5kdc /etc/krb5kdc
        sudo rm -rf /etc/ldap /var/lib/ldap
        sudo rm -rf /etc/bind/db.fis.epn.ec /etc/bind/named.conf.local
        sudo rm -rf /var/www/html/*
        
        echo "✨ Sistema limpio."
        sleep 2
    else
        echo "⚠️  Continuando sobre instalación existente..."
    fi
else
    echo "✅ Entorno limpio detectado."
fi

# --- BLOQUE DE SEGURIDAD Y RESPALDO ---
echo "========================================================="
echo " ⚠️  ADVERTENCIA DE SEGURIDAD Y RESPALDO ⚠️"
echo "========================================================="
echo " Este instalador va a configurar Kerberos (FIS.EPN.EC), DNS y LDAP."
echo " Se realizará un BACKUP en: ./backups_previos/"
echo "========================================================="
read -p "¿Desea continuar con la instalación? (y/N): " confirm

if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "❌ Instalación cancelada."
    exit 1
fi

mkdir -p backups_previos
[ -f /etc/krb5.conf ] && cp /etc/krb5.conf backups_previos/krb5.conf.bak
[ -f /etc/bind/named.conf.local ] && cp /etc/bind/named.conf.local backups_previos/named.conf.local.bak
[ -f /etc/hosts ] && cp /etc/hosts backups_previos/hosts.bak
echo "✅ Respaldo completado."

# --- BLOQUE 2: INSTALACIÓN EXPLÍCITA ---
echo ""
echo "========================================================="
echo " 🚀 INICIANDO INSTALACIÓN DE PAQUETES"
echo "========================================================="
echo "ATENTO A LAS PANTALLAS AZULES:"
echo "👉 Realm: FIS.EPN.EC"
echo "👉 Servers: krb5.fis.epn.ec"
echo "👉 Admin Password: Sistemas2026"
echo "---------------------------------------------------------"
sleep 2
echo "🔐 Verificando bloqueo de APT..."

echo "🛑 Deteniendo actualizaciones automáticas..."
sudo systemctl stop unattended-upgrades 2>/dev/null
sudo systemctl disable unattended-upgrades 2>/dev/null

echo "🔐 Verificando bloqueo de APT..."
while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
    echo "⏳ APT está ocupado. Esperando..."
    sleep 5
done


echo "✅ APT disponible."

# --- SOLUCIÓN 1: PRE-CONFIGURACIÓN ---
echo "🔐 Pre-configurando contraseña de LDAP..."
LDAP_ADMIN_PASS="Sistemas2026"
sudo debconf-set-selections <<< "slapd slapd/internal/generated_adminpw password $LDAP_ADMIN_PASS"
sudo debconf-set-selections <<< "slapd slapd/internal/adminpw password $LDAP_ADMIN_PASS"
sudo debconf-set-selections <<< "slapd slapd/password2 password $LDAP_ADMIN_PASS"
sudo debconf-set-selections <<< "slapd slapd/password1 password $LDAP_ADMIN_PASS"
sudo debconf-set-selections <<< "slapd slapd/domain string fis.epn.ec"
sudo debconf-set-selections <<< "slapd shared/organization string FIS EPN"
sudo debconf-set-selections <<< "slapd slapd/backend string MDB"
sudo debconf-set-selections <<< "slapd slapd/purge_database boolean true"
sudo debconf-set-selections <<< "slapd slapd/move_old_database boolean true"
sudo debconf-set-selections <<< "slapd slapd/allow_ldap_v2 boolean false"
sudo debconf-set-selections <<< "slapd slapd/no_configuration boolean false"
echo "✅ LDAP pre-configurado."

sudo apt update -y
sudo apt install ntp krb5-kdc krb5-admin-server krb5-config slapd ldap-utils bind9 bind9utils bind9-doc apache2 libapache2-mod-auth-gssapi php libapache2-mod-php php-ldap -y

# --- SOLUCIÓN 2: POST-VERIFICACIÓN ---
echo "🔧 Verificando contraseña de LDAP..."
if ! ldapsearch -x -D "cn=admin,dc=fis,dc=epn,dc=ec" -w "$LDAP_ADMIN_PASS" \
     -b "dc=fis,dc=epn,dc=ec" "(objectClass=*)" > /dev/null 2>&1; then
    
    echo "⚠️  Corrigiendo contraseña..."
    NEW_HASH=$(sudo slappasswd -s "$LDAP_ADMIN_PASS")
    cat > /tmp/fix_ldap.ldif << EOF
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcRootPW
olcRootPW: $NEW_HASH
EOF
    sudo ldapmodify -Y EXTERNAL -H ldapi:/// -f /tmp/fix_ldap.ldif
    sudo systemctl restart slapd
    rm /tmp/fix_ldap.ldif
    echo "✅ Contraseña corregida."
fi

# --- BLOQUE 3: CONFIGURACIÓN ---
echo ""
echo "========================================================="
echo " ⚙️  CONFIGURANDO SERVICIOS"
echo "========================================================="
# 1. Asegurar permisos de los scripts secundarios
chmod +x scripts/*.sh deploy.sh
# --- NUEVO: ASEGURAR SINCRONIZACIÓN DE TIEMPO (CRÍTICO) ---
echo "🕰️  Configurando sincronización horaria (NTP)..."
# Habilitar el servicio para que inicie siempre con el sistema
sudo systemctl enable ntp 2>/dev/null
# Reiniciar para forzar la sincronización inmediata con los servidores de Ubuntu
sudo systemctl restart ntp
sleep 2
echo "✅ Reloj sincronizado."
# ---------------------------------------------------------
# 2.Configuración Servidor
./scripts/setup_server.sh
echo "⏳ Esperando LDAP..."

until systemctl is-active --quiet slapd; do
    sleep 2
done

echo "✅ LDAP activo"

# --- BLINDAJE DE SEGURIDAD LDAP ---
echo "🔒 Blindando servidor LDAP..."
cat <<LDAPCONF > disable_anon.ldif


dn: cn=config
changetype: modify
add: olcDisallows
olcDisallows: bind_anon

dn: cn=config
changetype: modify
add: olcRequires
olcRequires: authc

dn: olcDatabase={-1}frontend,cn=config
changetype: modify
add: olcRequires
olcRequires: authc
LDAPCONF

sudo ldapadd -Y EXTERNAL -H ldapi:/// -f disable_anon.ldif > /dev/null 2>&1
echo "✅ Acceso anónimo bloqueado."

# --- FIX CRÍTICO KERBEROS (ELIMINANDO CONFLICTOS) ---
echo "🔧 Inicializando Base de Datos Maestra de Kerberos..."

# Asegurar que existan los directorios correctos
sudo mkdir -p /var/lib/krb5kdc
sudo mkdir -p /etc/krb5kdc
sudo chmod 700 /var/lib/krb5kdc

# Detener servicios antes de inicializar
sudo systemctl stop krb5-kdc 2>/dev/null
sudo systemctl stop krb5-admin-server 2>/dev/null

if [ ! -f /var/lib/krb5kdc/principal ]; then
    sudo rm -rf /var/lib/krb5kdc/*
    
    # FORZAMOS EL USO DEL BINARIO CORRECTO DEL SISTEMA
    sudo /usr/sbin/kdb5_util create -r FIS.EPN.EC -s -P password123
    
    # Esperar a que se cree el archivo
    sleep 2
    
    # Verificar que se creó correctamente
    if [ -f /var/lib/krb5kdc/principal ]; then
        echo "✅ Base de datos Kerberos inicializada correctamente."
    else
        echo "❌ ERROR: No se pudo crear la base de datos Kerberos."
        exit 1
    fi
    
    # Ahora sí reiniciar servicios
    sudo systemctl restart krb5-kdc
    sudo systemctl restart krb5-admin-server
    sleep 3
    
    # Verificar que los servicios estén activos
    if sudo systemctl is-active --quiet krb5-kdc; then
        echo "✅ Servicio KDC iniciado correctamente."
    else
        echo "⚠️  Advertencia: KDC no pudo iniciarse. Verifica los logs con: journalctl -xeu krb5-kdc.service"
    fi
else
    echo "⚠️  Base de datos Kerberos ya existe, omitiendo creación..."
    sudo systemctl restart krb5-kdc
    sudo systemctl restart krb5-admin-server
fi

# 4. Despliegue Web
./deploy.sh

# 5. Carga de Datos LDAP
echo "--- [LDAP] Esperando servicio antes de carga ---"

until systemctl is-active --quiet slapd; do
    sleep 2
done

echo "✅ LDAP listo para carga"

echo "--- [LDAP] Cargando estructura y usuarios ---"

ldapadd -x -D "cn=admin,dc=fis,dc=epn,dc=ec" -w Sistemas2026 \
-f config/universidad.ldif || {

echo "❌ ERROR cargando datos LDAP"
exit 1

}

# 6. Carga de Datos Kerberos
./scripts/cargar_demo.sh

echo ""
echo "========================================================="
echo " ✅ INSTALACIÓN FINALIZADA EXITOSAMENTE"
echo "========================================================="
echo "URL: http://krb5.fis.epn.ec"
echo "Admin LDAP: Sistemas2026"
echo "Usuario Web: jose.sarango / password123"
echo "========================================================="

# Verificación automática post-instalación
echo ""
echo "========================================================="
echo " 🔍 VERIFICACIÓN DEL SISTEMA"
echo "========================================================="
echo "Estado del KDC:"
sudo systemctl status krb5-kdc --no-pager -l | grep "Active:"
echo ""
echo "Estado del Admin Server:"
sudo systemctl status krb5-admin-server --no-pager -l | grep "Active:"
echo "========================================================="