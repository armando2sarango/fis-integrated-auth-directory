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
read -s -p "Contraseña: " PASSWORD
echo ""
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
CN_COMPLETO=""

# Construir nombre completo
if [ -z "$SEGUNDO_NOMBRE" ]; then
    CN_COMPLETO="$NOMBRE $APELLIDO"
else
    CN_COMPLETO="$NOMBRE $SEGUNDO_NOMBRE $APELLIDO"
fi

case $OPCION in
    1)
        OU="Estudiantes"
        GID=10000
        read -p "Carrera (ej: Ciencias de la Computación): " CARRERA
        read -p "Edad: " EDAD
        EXTRA_ATTR="departmentNumber: $CARRERA"$'\n'"description: Edad: $EDAD"
        ;;
    2)
        OU="Profesores"
        GID=10001
        read -p "Título Académico (ej: PhD en Purdue University): " TITULO
        read -p "Departamento (ej: Informática y Ciencias de la Computación): " DEPTO
        read -p "Número de Oficina (ej: 211): " OFICINA
        read -p "Teléfono (ej: 022-976-300): " TELEFONO
        read -p "Descripción/Trayectoria: " DESC
        
        EXTRA_ATTR="title: $TITULO"$'\n'
        EXTRA_ATTR+="departmentNumber: $DEPTO"$'\n'
        EXTRA_ATTR+="roomNumber: $OFICINA"$'\n'
        EXTRA_ATTR+="telephoneNumber: $TELEFONO"$'\n'
        EXTRA_ATTR+="description: $DESC"
        ;;
    3)
        OU="Administrativos"
        GID=10002
        read -p "Cargo (ej: Jefe de Infraestructura TI): " CARGO
        read -p "Ubicación/Oficina (ej: Planta Baja - Server Room): " UBICACION
        read -p "Descripción del puesto: " DESC
        
        EXTRA_ATTR="title: $CARGO"$'\n'
        EXTRA_ATTR+="roomNumber: $UBICACION"$'\n'
        EXTRA_ATTR+="description: $DESC"
        ;;
    *)
        echo "Opción no válida. Saliendo."
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
cn: $CN_COMPLETO
sn: $APELLIDO
givenName: $GIVEN_NAME
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