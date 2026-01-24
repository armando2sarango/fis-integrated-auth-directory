#!/bin/bash
echo "--- INSTALANDO PROYECTO ---"

# 1. Limpiar servidor web
sudo rm -rf /var/www/html/*

# 2. Vincular código fuente
DIR_PROYECTO=$(pwd)/src
sudo ln -s $DIR_PROYECTO/* /var/www/html/

# 3. Crear carpetas de sistema necesarias
sudo mkdir -p /var/www/html/img/usuarios
sudo chmod -R 777 $DIR_PROYECTO/img/usuarios

# 4. DETECTAR VERSIÓN DE PHP INSTALADA
echo "🔍 Detectando versión de PHP..."
PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null)

if [ -z "$PHP_VERSION" ]; then
    echo "❌ PHP no está instalado. Instalando PHP..."
    sudo apt update
    sudo apt install -y php libapache2-mod-php php-ldap
    PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
fi

echo "✅ PHP $PHP_VERSION detectado"

# 5. INSTALAR MÓDULOS NECESARIOS
echo "📦 Instalando módulos de PHP y Apache..."
sudo apt install -y \
    php${PHP_VERSION}-ldap \
    libapache2-mod-php${PHP_VERSION} \
    libapache2-mod-auth-gssapi \
    apache2

# 6. CONFIGURAR APACHE PARA KERBEROS + PHP
echo "🔧 Configurando Apache con autenticación Kerberos..."

# Crear keytab para Apache
sudo kadmin.local -q "addprinc -randkey HTTP/krb5.fis.epn.ec@FIS.EPN.EC" 2>/dev/null
sudo kadmin.local -q "ktadd -k /etc/apache2/http.keytab HTTP/krb5.fis.epn.ec@FIS.EPN.EC" 2>/dev/null
sudo chown www-data:www-data /etc/apache2/http.keytab
sudo chmod 640 /etc/apache2/http.keytab

# Crear configuración del sitio con autenticación Kerberos
cat <<'APACHECONF' | sudo tee /etc/apache2/sites-available/fis-auth.conf > /dev/null
<VirtualHost *:80>
    ServerName krb5.fis.epn.ec
    DocumentRoot /var/www/html

    <Directory /var/www/html>
        # Autenticación Kerberos OBLIGATORIA
        AuthType GSSAPI
        AuthName "FIS - Autenticación Kerberos Requerida"
        GssapiCredStore keytab:/etc/apache2/http.keytab
        GssapiLocalName On
        Require valid-user
        
        # CRÍTICO: Configuración PHP
        Options -Indexes +FollowSymLinks
        AllowOverride All
        DirectoryIndex index.php index.html
        
        # Forzar procesamiento de PHP
        AddType application/x-httpd-php .php
        AddHandler application/x-httpd-php .php
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/fis_error.log
    CustomLog ${APACHE_LOG_DIR}/fis_access.log combined
</VirtualHost>
APACHECONF

# 7. HABILITAR MÓDULOS DE APACHE (Compatibilidad Multi-versión)
echo "🔌 Habilitando módulos de Apache..."

# Deshabilitar sitio default
sudo a2dissite 000-default.conf 2>/dev/null
# --- FIX CRÍTICO: CAMBIO DE MOTOR (MPM) ---
echo "⚙️  Ajustando motor MPM para compatibilidad con PHP..."
sudo a2dismod mpm_event 2>/dev/null
sudo a2dismod mpm_worker 2>/dev/null
sudo a2enmod mpm_prefork 2>/dev/null
# Habilitar módulos necesarios
sudo a2enmod rewrite
sudo a2enmod auth_gssapi

# Habilitar módulo PHP (intentar ambas formas para compatibilidad)
if [ -f "/etc/apache2/mods-available/php${PHP_VERSION}.load" ]; then
    sudo a2enmod php${PHP_VERSION}
    echo "✅ Módulo php${PHP_VERSION} habilitado"
else
    # Fallback para versiones que usan nombres diferentes
    sudo a2enmod php 2>/dev/null || true
fi

# Habilitar sitio
sudo a2ensite fis-auth.conf

# 8. VERIFICAR Y ARREGLAR PERMISOS
echo "🔐 Configurando permisos..."
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html
sudo chmod -R 777 $DIR_PROYECTO/img/usuarios

# 9. REINICIAR APACHE
echo "🔄 Reiniciando Apache..."
sudo systemctl restart apache2

# 10. DIAGNÓSTICO
echo ""
echo "═══════════════════════════════════════════"
echo "          DIAGNÓSTICO DEL SISTEMA"
echo "═══════════════════════════════════════════"

if sudo systemctl is-active --quiet apache2; then
    echo "✅ Apache: ACTIVO"
else
    echo "❌ Apache: INACTIVO - Revisa los logs:"
    sudo systemctl status apache2 --no-pager -l
    exit 1
fi

# Verificar módulo PHP
if apache2ctl -M 2>/dev/null | grep -q php; then
    echo "✅ Módulo PHP: CARGADO"
else
    echo "⚠️  Módulo PHP: NO DETECTADO"
    echo "   Módulos activos:"
    apache2ctl -M 2>/dev/null | grep php || echo "   (ninguno con 'php' en el nombre)"
fi

# Verificar módulo Kerberos
if apache2ctl -M 2>/dev/null | grep -q gssapi; then
    echo "✅ Módulo GSSAPI: CARGADO"
else
    echo "❌ Módulo GSSAPI: NO CARGADO"
fi

echo ""
echo "📋 Información del sistema:"
echo "   - Ubuntu: $(lsb_release -rs 2>/dev/null || echo 'Desconocida')"
echo "   - PHP: $PHP_VERSION"
echo "   - Apache: $(apache2 -v 2>/dev/null | head -n1 | cut -d'/' -f2 | cut -d' ' -f1)"
echo ""
echo "═══════════════════════════════════════════"
echo ""

# 11. TEST RÁPIDO DE PHP
echo "🧪 Creando archivo de prueba PHP..."
echo '<?php phpinfo(); ?>' | sudo tee /var/www/html/test.php > /dev/null

echo ""
echo "✅ Instalación completada."
echo ""
echo "📍 PASOS SIGUIENTES:"
echo "   1. Verifica que tienes ticket Kerberos: klist"
echo "   2. Accede a: http://krb5.fis.epn.ec/test.php"
echo "   3. Si ves la página de phpinfo(), PHP funciona ✓"
echo "   4. Luego accede a: http://krb5.fis.epn.ec/index.php"
echo ""
echo "   Si test.php muestra código en lugar de ejecutarse:"
echo "   - Revisa: sudo tail -f /var/log/apache2/fis_error.log"
echo ""