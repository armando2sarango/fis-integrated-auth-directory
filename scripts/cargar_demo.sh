#!/bin/bash
echo "---------------------------------------------------------"
echo " 🔨 REPARANDO USUARIOS KERBEROS (MODO FORZADO)"
echo "---------------------------------------------------------"

reset_krb() {
    USER=$1
    # 1. Borrarlo a la fuerza (silenciosamente) para eliminar versiones corruptas
    sudo kadmin.local -q "delprinc -force $USER" > /dev/null 2>&1
    
    # 2. Crearlo de nuevo asegurando la contraseña
    if sudo kadmin.local -q "addprinc -pw password123 $USER" > /dev/null 2>&1; then
        echo "✅ $USER -> Re-creado correctamente (@FIS.EPN.EC)"
    else
        echo "⚠️  Error creando $USER (Revisa los logs)"
    fi
}

# 1. Profesor y Admin
reset_krb "luis.mafla"
reset_krb "carlos.soporte"

# 2. Estudiantes
reset_krb "darlin.anacicha"
reset_krb "leandro.bravo"
reset_krb "erick.carcelen"
reset_krb "alexis.chacon"
reset_krb "michael.enriquez"
reset_krb "juan.flores"
reset_krb "anthony.goyes"
reset_krb "mark.hernandez"
reset_krb "francisco.hernandez"
reset_krb "wilson.inga"
reset_krb "yasid.jimenez"
reset_krb "andres.jimenez"
reset_krb "mateo.macas"
reset_krb "anthony.reinoso"
reset_krb "lenin.reyes"
reset_krb "jose.sarango"
reset_krb "danny.tipan"
reset_krb "sergio.vite"
reset_krb "bryan.yunga"
reset_krb "martin.zambonino"

echo "---------------------------------------------------------"
echo "¡Reparación completa! Todos tienen clave: password123"
echo "---------------------------------------------------------"
