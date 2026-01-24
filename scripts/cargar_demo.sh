#!/bin/bash
echo "---------------------------------------------------------"
echo " CREANDO USUARIOS REALES EN KERBEROS"
echo "---------------------------------------------------------"

crear_krb() {
    USER=$1
    if ! sudo kadmin.local -q "getprinc $USER" > /dev/null 2>&1; then
        sudo kadmin.local -q "addprinc -pw password123 $USER"
        echo "✅ + $USER"
    else
        echo "ℹ️  Ya existe: $USER"
    fi
}

# 1. Profesor y Admin
crear_krb "luis.mafla"
crear_krb "carlos.soporte"

# 2. Estudiantes
crear_krb "darlin.anacicha"
crear_krb "leandro.bravo"
crear_krb "erick.carcelen"
crear_krb "alexis.chacon"
crear_krb "michael.enriquez"
crear_krb "juan.flores"
crear_krb "anthony.goyes"
crear_krb "mark.hernandez"
crear_krb "francisco.hernandez"
crear_krb "wilson.inga"
crear_krb "yasid.jimenez"
crear_krb "andres.jimenez"
crear_krb "mateo.macas"
crear_krb "anthony.reinoso"
crear_krb "lenin.reyes"
crear_krb "jose.sarango"
crear_krb "danny.tipan"
crear_krb "sergio.vite"
crear_krb "bryan.yunga"
crear_krb "martin.zambonino"

echo "---------------------------------------------------------"
echo "¡Todos los usuarios listos! Clave: password123"
echo "---------------------------------------------------------"
