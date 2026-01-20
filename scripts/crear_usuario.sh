#!/bin/bash
# --- CONFIGURACION ---
LDAP_BASE="dc=fis,dc=epn,dc=ec"
LDAP_ADMIN="cn=admin,dc=fis,dc=epn,dc=ec"
# ¡OJO! Asegúrate que esta sea tu contraseña real de LDAP
LDAP_PASS="1234" 

echo "=== CREADOR DE USUARIOS AVANZADO (KERBEROS + LDAP) ==="
read -p "Usuario (ej: joel.quilumba): " USUARIO
read -p "Primer Nombre: " NOMBRE
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
GID=10002
EXTRA_ATTR=""

case $OPCION in
    1)
        OU="Estudiantes"
        GID=10002
        read -p "Ingrese la Carrera (ej: Sistemas): " CARRERA
        # Usamos departmentNumber para la carrera
        EXTRA_ATTR="departmentNumber: $CARRERA"
        ;;
    2)
        OU="Profesores"
        GID=10003
        read -p "Ingrese Título Académico (ej: PhD en IA): " TITULO
        EXTRA_ATTR="title: $TITULO"
        ;;
    3)
        OU="Administrativos"
        GID=10004
        read -p "Ingrese el Cargo (ej: Secretaria): " CARGO
        read -p "Descripción (ej: Planta Central): " DESC
        EXTRA_ATTR="title: $CARGO"$'\n'"description: $DESC"
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
UID_NUM=$(shuf -i 20000-50000 -n 1)
LDIF="/tmp/${USUARIO}.ldif"

cat <<LDIF_CONTENT > $LDIF
dn: uid=$USUARIO,ou=$OU,$LDAP_BASE
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
cn: $NOMBRE $APELLIDO
sn: $APELLIDO
givenName: $NOMBRE
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
echo "------------------------------------------------"
