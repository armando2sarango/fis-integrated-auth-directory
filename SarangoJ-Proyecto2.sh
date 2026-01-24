#!/bin/bash
# =======================================================================
# INSTALADOR AUTOMÁTICO - PROYECTO 2
# ESTUDIANTE: Sarango J.
# =======================================================================

# 1. Permisos
chmod +x scripts/*.sh
chmod +x deploy.sh

echo "========================================================="
echo " INICIANDO INSTALACIÓN DEL SERVICIO INTEGRADO (FIS EPN)"
echo "========================================================="

# 2. Instalación de Paquetes
./scripts/setup_clients.sh

# 3. Configuración Servidor
./scripts/setup_server.sh

# 4. Despliegue Web
./deploy.sh

# 5. Carga de Datos LDAP (Usuarios y Estructura)
echo "--- [LDAP] Cargando estructura y usuarios base ---"
ldapadd -x -D "cn=admin,dc=fis,dc=epn,dc=ec" -w 1234 -f config/universidad.ldif || echo "⚠️  Advertencia: Hubo un error cargando el LDIF (¿Quizás ya existen los datos?)"

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
