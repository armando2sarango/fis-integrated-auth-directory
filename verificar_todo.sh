#!/bin/bash
# Lista de usuarios esperados
USUARIOS=("luis.mafla" "carlos.soporte" "darlin.anacicha" "leandro.bravo" "erick.carcelen" "alexis.chacon" "michael.enriquez" "juan.flores" "anthony.goyes" "mark.hernandez" "francisco.hernandez" "wilson.inga" "yasid.jimenez" "andres.jimenez" "mateo.macas" "anthony.reinoso" "lenin.reyes" "jose.sarango" "danny.tipan" "sergio.vite" "bryan.yunga" "martin.zambonino")

echo "========================================"
echo "   AUDITORÍA DEL SISTEMA (LDAP + KRB5)"
echo "========================================"
printf "%-20s | %-10s | %-10s\n" "USUARIO" "LDAP" "KERBEROS"
echo "----------------------------------------"

for u in "${USUARIOS[@]}"; do
    # 1. Chequear LDAP (Corregido: buscamos si devuelve algún resultado)
    if ldapsearch -x -b "dc=fis,dc=epn,dc=ec" "(uid=$u)" uid 2>/dev/null | grep -q "uid:"; then
        LDAP_STATUS="✅ OK"
    else
        LDAP_STATUS="❌ FALTA"
    fi

    # 2. Chequear Kerberos
    if sudo kadmin.local -q "getprinc $u" 2>/dev/null | grep -q "Principal: $u@FIS.EPN.EC"; then
        KRB_STATUS="✅ OK"
    else
        KRB_STATUS="❌ FALTA"
    fi

    printf "%-20s | %-10s | %-10s\n" "$u" "$LDAP_STATUS" "$KRB_STATUS"
done
echo "========================================"
