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

echo "✅ Web desplegada. Usa ./scripts/crear_usuario.sh para añadir gente."
