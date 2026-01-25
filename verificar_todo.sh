#!/bin/bash
USUARIOS=("enrrique.mafla" "carlos.soporte" "darlin.anacicha" "leandro.bravo" "erick.carcelen" "alexis.chacon" "michael.enriquez" "juan.flores" "anthony.goyes" "mark.hernandez" "francisco.hernandez" "wilson.inga" "yasid.jimenez" "andres.jimenez" "mateo.macas" "anthony.reinoso" "lenin.reyes" "jose.sarango" "danny.tipan" "sergio.vite" "bryan.yunga" "martin.zambonino")
# Credenciales LDAP
LDAP_ADMIN="cn=admin,dc=fis,dc=epn,dc=ec"
LDAP_PASS="Sistemas2026"

echo "========================================"
echo "   AUDITORÍA DEL SISTEMA (LDAP + KRB5)"
echo "========================================"
printf "%-20s | %-10s | %-10s\n" "USUARIO" "LDAP" "KERBEROS"
echo "----------------------------------------"

for u in "${USUARIOS[@]}"; do
    if ldapsearch -x -D "$LDAP_ADMIN" -w "$LDAP_PASS" \
        -b "dc=fis,dc=epn,dc=ec" "(uid=$u)" uid 2>/dev/null | grep -q "uid: $u"; then
        LDAP_STATUS="✅ OK"
    else
        LDAP_STATUS="❌ FALTA"
    fi
    if sudo kadmin.local -q "getprinc $u" 2>/dev/null | grep -q "Principal: $u@FIS.EPN.EC"; then
        KRB_STATUS="✅ OK"
    else
        KRB_STATUS="❌ FALTA"
    fi

    printf "%-20s | %-10s | %-10s\n" "$u" "$LDAP_STATUS" "$KRB_STATUS"
done
echo "========================================"