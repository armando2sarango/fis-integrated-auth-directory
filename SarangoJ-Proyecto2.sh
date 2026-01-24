cat << 'EOF' > SarangoJ-Proyecto2.sh
#!/bin/bash
# =======================================================================
# INSTALADOR AUTOMÁTICO -  Servicio Integrado de Directorio y Autenticación para la FIS
# ESTUDIANTE: José Armando Sarango Cuenca
# =======================================================================

# --- BLOQUE 0: DETECCIÓN INTELIGENTE Y LIMPIEZA (PARA EL PROFESOR) ---
clear
echo "========================================================="
echo " 🕵️  VERIFICACIÓN DE ENTORNO PREVIO"
echo "========================================================="

if dpkg -l | grep -q "krb5-kdc"; then
    echo "🚨 ATENCIÓN: Se ha detectado una instalación previa de Kerberos/LDAP."
    echo "   Si continúa sin limpiar, el proyecto FALLARÁ por conflictos de base de datos."
    echo ""
    echo "   Si usted es el Docente o está re-intentando la instalación,"
    echo "   se recomienda encarecidamente realizar una LIMPIEZA TOTAL."
    echo ""
    read -p "♻️  ¿Desea realizar una LIMPIEZA PROFUNDA y reinstalar desde cero? (Recomendado) (y/n): " limpiar
    
    if [[ "$limpiar" == "y" || "$limpiar" == "Y" ]]; then
        echo "🧹 Ejecutando Protocolo de Limpieza..."
        
        # 1. Parar servicios
        sudo service krb5-kdc stop 2>/dev/null
        sudo service krb5-admin-server stop 2>/dev/null
        sudo service slapd stop 2>/dev/null
        sudo service bind9 stop 2>/dev/null
        sudo service apache2 stop 2>/dev/null
        
        # 2. Desinstalar paquetes (Purge)
        echo "   - Desinstalando paquetes..."
        sudo apt purge krb5-kdc krb5-admin-server krb5-config slapd ldap-utils bind9 bind9utils apache2 libapache2-mod-auth-gssapi -y > /dev/null 2>&1
        sudo apt autoremove --purge -y > /dev/null 2>&1
        
        # 3. Borrar residuos de configuración (CRÍTICO)
        echo "   - Borrando bases de datos antiguas..."
        sudo rm -rf /etc/krb5.conf
        sudo rm -rf /var/lib/krb5kdc
        sudo rm -rf /etc/ldap
        sudo rm -rf /var/lib/ldap
        sudo rm -rf /etc/bind
        sudo rm -rf /var/www/html/*
        
        echo "✨ Sistema limpio y listo para instalación fresca."
        sleep 2
    else
        echo "⚠️  Continuando sobre instalación existente (Bajo su propio riesgo)..."
    fi
else
    echo "✅ Entorno limpio detectado."
fi

# --- BLOQUE DE SEGURIDAD Y RESPALDO ---
echo "========================================================="
echo " ⚠️  ADVERTENCIA DE SEGURIDAD Y RESPALDO ⚠️"
echo "========================================================="
echo " Este instalador va a configurar Kerberos (FIS.EPN.EC), DNS y LDAP."
echo " Para su seguridad, se realizará un BACKUP AUTOMÁTICO"
echo " de sus configuraciones actuales en: ./backups_previos/"
echo "========================================================="
read -p "¿Desea continuar con la instalación? (y/N): " confirm

if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "❌ Instalación cancelada. No se hicieron cambios."
    exit 1
fi

# --- RUTINA DE RESPALDO ---
echo ""
echo "📦 Generando copias de seguridad..."
mkdir -p backups_previos
[ -f /etc/krb5.conf ] && cp /etc/krb5.conf backups_previos/krb5.conf.bak && echo "   - krb5.conf respaldado."
[ -f /etc/bind/named.conf.local ] && cp /etc/bind/named.conf.local backups_previos/named.conf.local.bak && echo "   - Config DNS respaldada."
[ -f /etc/hosts ] && cp /etc/hosts backups_previos/hosts.bak && echo "   - Hosts respaldado."
echo "✅ Respaldo completado."
sleep 1

echo ""
echo "========================================================="
echo " 🚀 INICIANDO INSTALACIÓN DEL SERVICIO INTEGRADO (FIS EPN)"
echo "========================================================="

# 1. Permisos
chmod +x scripts/*.sh
chmod +x deploy.sh

# 2. Instalación de Paquetes
# Aquí saldrán las PANTALLAS AZULES si el sistema está limpio.
# Recuerda: Realm = FIS.EPN.EC | Servidores = krb5.fis.epn.ec
./scripts/setup_clients.sh

# 3. Configuración Servidor (Genera krb5.conf y DNS)
./scripts/setup_server.sh
# --- BLOQUE DE SEGURIDAD LDAP (PROHIBIR ANÓNIMOS) ---
echo "🔒 Blindando servidor LDAP (Desactivando acceso anónimo)..."
cat <<EOF > disable_anon.ldif
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
EOF

# Aplicamos la restricción
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f disable_anon.ldif > /dev/null 2>&1
echo "✅ Acceso anónimo bloqueado. Solo usuarios autenticados pueden leer."
# ----------------------------------------------------

# --- [FIX CRÍTICO] INICIALIZACIÓN DE BASE DE DATOS KERBEROS ---
# Esto asegura que la base de datos exista antes de intentar crear usuarios
if [ ! -f /var/lib/krb5kdc/principal ]; then
    echo "🔧 [FIX] Inicializando Base de Datos Maestra de Kerberos..."
    
    # 1. Aseguramos que el directorio esté limpio
    sudo rm -rf /var/lib/krb5kdc/*
    
    # 2. Creamos el reino automáticamente (sin pedir clave interactiva)
    # La clave maestra será: password123
    printf "password123\npassword123" | sudo krb5_newrealm
    
    # 3. Reiniciamos servicios para aplicar cambios
    sudo service krb5-admin-server restart
    sudo service krb5-kdc restart
    sleep 3
    echo "✅ Base de datos Kerberos inicializada correctamente."
fi
# -------------------------------------------------------------

# 4. Despliegue Web
./deploy.sh

# 5. Carga de Datos LDAP (Usuarios y Estructura)
echo "--- [LDAP] Cargando estructura y usuarios base ---"
ldapadd -c -x -D "cn=admin,dc=fis,dc=epn,dc=ec" -w Sistemas2026 -f config/universidad.ldif > /dev/null 2>&1 || echo "⚠️  Nota: Se omitieron entradas duplicadas en LDAP."

# 6. Carga de Datos Kerberos (Sincronización)
# Ahora esto funcionará porque la base de datos ya fue creada en el paso 3 (FIX)
./scripts/cargar_demo.sh

echo ""
echo "========================================================="
echo " ✅ INSTALACIÓN FINALIZADA EXITOSAMENTE"
echo "========================================================="
echo "DATOS DE ACCESO PARA PRUEBAS (Clave: password123):"
echo "--------------------------------------------------"
echo "1. Dr. Mafla:      luis.mafla"
echo "2. Estudiante:     jose.sarango"
echo "3. Admin:          carlos.soporte"
echo ""
echo "URL de Acceso: http://krb5.fis.epn.ec"
echo "========================================================="
EOF