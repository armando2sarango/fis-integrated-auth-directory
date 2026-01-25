#!/bin/bash

# --- CONFIGURACION ---
LDAP_BASE="dc=fis,dc=epn,dc=ec"
LDAP_ADMIN="cn=admin,dc=fis,dc=epn,dc=ec"
LDAP_PASS="Sistemas2026"  # ⚠️ Actualizada según tus búsquedas

echo "=== CREADOR DE USUARIOS AVANZADO (KERBEROS + LDAP) ==="
read -p "Usuario (ej: joel.quilumba): " USUARIO
read -p "Primer Nombre: " NOMBRE
read -p "Segundo Nombre (opcional, presiona Enter para omitir): " SEGUNDO_NOMBRE
read -p "Apellido: " APELLIDO
read -p "Segundo Apellido (opcional): " SEGUNDO_APELLIDO
read -s -p "Contraseña: " PASSWORD
echo ""
# --- 1. LÓGICA DE NOMBRES ---
# Apellido Completo
if [ -z "$SEGUNDO_APELLIDO" ]; then
    SN_LDAP="$APELLIDO"
else
    SN_LDAP="$APELLIDO $SEGUNDO_APELLIDO"
fi

# Nombre de Pila Completo
if [ -z "$SEGUNDO_NOMBRE" ]; then
    GIVEN_LDAP="$NOMBRE"
else
    GIVEN_LDAP="$NOMBRE $SEGUNDO_NOMBRE"
fi

# Nombre Completo (lo que lee la Web)
CN_LDAP="$GIVEN_LDAP $SN_LDAP"

echo "------------------------------------------------"
echo "Seleccione el ROL del usuario:"
echo "1) Estudiante"
echo "2) Profesor"
echo "3) Administrativo"
read -p "Opción (1-3): " OPCION

# Variables por defecto
OU="Estudiantes"
GID=10000
EXTRA_ATTR=""

case $OPCION in
    1)
        OU="Estudiantes"
        GID=10000
        read -p "Carrera: " CARRERA
        read -p "Edad: " EDAD
        EXTRA_ATTR="departmentNumber: $CARRERA"$'\n'"description: Edad: $EDAD"
        ;;
    2)
        OU="Profesores"
        GID=10001
        read -p "Título Académico: " TITULO
        read -p "Departamento: " DEPTO
        read -p "Número de Oficina: " OFICINA
        read -p "Teléfono (opcional): " TEL
        read -p "Descripción/Trayectoria: " DESC
        
        EXTRA_ATTR="title: $TITULO"$'\n'
        EXTRA_ATTR+="departmentNumber: $DEPTO"$'\n'
        EXTRA_ATTR+="roomNumber: $OFICINA"$'\n'
        [ -n "$TEL" ] && EXTRA_ATTR+="telephoneNumber: $TEL"$'\n'
        EXTRA_ATTR+="description: $DESC"
        ;;
    3)
        OU="Administrativos"
        GID=10002
        read -p "Cargo: " CARGO
        read -p "Ubicación/Oficina: " UBICACION
        read -p "Descripción: " DESC
        
        EXTRA_ATTR="title: $CARGO"$'\n'
        EXTRA_ATTR+="roomNumber: $UBICACION"$'\n'
        EXTRA_ATTR+="description: $DESC"
        ;;
    *)
        echo "Opción no válida."
        exit 1
        ;;
esac

echo ""
# 1. KERBEROS
echo ">> [1/2] Creando principal en Kerberos..."
sudo kadmin.local -q "addprinc -pw $PASSWORD $USUARIO"

# 2. LDAP
echo ">> [2/2] Generando entrada LDAP para $OU..."
UID_NUM=$(shuf -i 10023-50000 -n 1)  # Comenzar desde 10023 (después del último estudiante)
LDIF="/tmp/${USUARIO}.ldif"

# Construir givenName
if [ -z "$SEGUNDO_NOMBRE" ]; then
    GIVEN_NAME="$NOMBRE"
else
    GIVEN_NAME="$NOMBRE $SEGUNDO_NOMBRE"
fi

cat <<LDIF_CONTENT > $LDIF
dn: uid=$USUARIO,ou=$OU,$LDAP_BASE
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
cn: $CN_LDAP
sn: $SN_LDAP
givenName: $GIVEN_LDAP
uid: $USUARIO
uidNumber: $UID_NUM
gidNumber: $GID
homeDirectory: /home/$USUARIO
loginShell: /bin/bash
userPassword: $PASSWORD
$EXTRA_ATTR
LDIF_CONTENT

ldapadd -x -D "$LDAP_ADMIN" -w "$LDAP_PASS" -f $LDIF
rm $LDIF

echo "------------------------------------------------"
echo "✅ Usuario $USUARIO creado exitosamente en $OU"
echo "   DN: uid=$USUARIO,ou=$OU,$LDAP_BASE"
echo "   UID Number: $UID_NUM"
echo "   GID Number: $GID"
echo "------------------------------------------------"