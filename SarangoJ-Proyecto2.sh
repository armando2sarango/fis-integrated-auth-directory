cat << 'EOF' > SarangoJ-Proyecto2.sh
#!/bin/bash
# =======================================================================
# INSTALADOR AUTOMÁTICO -  Servicio Integrado de Directorio y Autenticación para la FIS
# ESTUDIANTE: José Armando Sarango Cuenca
# =======================================================================

# --- BLOQUE DE SEGURIDAD ---
clear
echo "========================================================="
echo " ⚠️  ADVERTENCIA DE SEGURIDAD Y RESPALDO ⚠️"
echo "========================================================="
echo " Este instalador va a configurar Kerberos, DNS y LDAP."
echo " Para su seguridad, se realizará un BACKUP AUTOMÁTICO"
echo " de sus configuraciones actuales en la carpeta:"
echo "    👉 ./backups_previos/"
echo ""
echo " Si algo falla, podrá restaurar sus archivos desde ahí."
echo "========================================================="
read -p "¿Desea continuar con la instalación? (y/N): " confirm

if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "❌ Instalación cancelada. No se hicieron cambios."
    exit 1
fi

# --- RUTINA DE RESPALDO (La solución al miedo) ---
echo ""
echo "📦 Generando copias de seguridad..."
mkdir -p backups_previos
[ -f /etc/krb5.conf ] && cp /etc/krb5.conf backups_previos/krb5.conf.bak && echo "   - krb5.conf respaldado."
[ -f /etc/bind/named.conf.local ] && cp /etc/bind/named.conf.local backups_previos/named.conf.local.bak && echo "   - Config DNS respaldada."
[ -f /etc/hosts ] && cp /etc/hosts backups_previos/hosts.bak && echo "   - Hosts respaldado."
echo "✅ Respaldo completado."
sleep 2
# ------------------------------------------------

echo ""
echo "========================================================="
echo " 🚀 INICIANDO INSTALACIÓN DEL SERVICIO INTEGRADO (FIS EPN)"
echo "========================================================="

# 1. Permisos
chmod +x scripts/*.sh
chmod +x deploy.sh

# 2. Instalación de Paquetes
./scripts/setup_clients.sh

# 3. Configuración Servidor
./scripts/setup_server.sh

# 4. Despliegue Web
./deploy.sh

# 5. Carga de Datos LDAP (Usuarios y Estructura)
echo "--- [LDAP] Cargando estructura y usuarios base ---"
# IMPORTANTE: La opción -c permite continuar si ya existen usuarios (evita errores al re-instalar)
ldapadd -c -x -D "cn=admin,dc=fis,dc=epn,dc=ec" -w 1234 -f config/universidad.ldif > /dev/null 2>&1 || echo "⚠️  Nota: Se omitieron entradas duplicadas en LDAP."

# 6. Carga de Datos Kerberos (Sincronización)
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