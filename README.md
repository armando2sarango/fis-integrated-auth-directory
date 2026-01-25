# Servicio Integrado de Autenticación y Directorio (FIS EPN)

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04%2B-orange.svg)](https://ubuntu.com/)
[![Kerberos](https://img.shields.io/badge/Kerberos-MIT-red.svg)](https://web.mit.edu/kerberos/)

**Proyecto:** Servicio Integrado de Directorio y Autenticación para la FIS  
**Estudiante:** Jose Sarango  
**Materia:** Computación Distribuida  
**Docente:** Enrique Mafla Gallegos  
**Institución:** Escuela Politécnica Nacional

---

## 📋 Tabla de Contenidos
- [Quick Start](#-quick-start) 
- [Descripción](#-descripción-del-proyecto)
- [Características](#-características-principales)
- [Arquitectura](#-arquitectura-y-justificación-técnica)
- [Requisitos](#-requisitos-previos)
- [Instalación](#-instalación)
- [Configuración del Cliente](#-configuración-del-cliente-windows)
- [Credenciales del Sistema](#-credenciales-del-sistema)
- [Uso](#-uso-del-sistema)
- [Verificación](#-verificación-y-pruebas)
- [Estructura del Proyecto](#-estructura-del-proyecto)
- [Solución de Problemas](#-solución-de-problemas)
- [Contribuciones](#-contribuciones)
- [Licencia](#-licencia)

---

## 📖 Descripción del Proyecto

Este sistema simula una infraestructura de red empresarial real que implementa **Single Sign-On (SSO)** para gestión de identidades corporativas. Permite que usuarios de diferentes perfiles (Profesores, Estudiantes y Administrativos) accedan a servicios web utilizando una única contraseña, visualizando información personalizada según su rol.
## 🚀 Quick Start (Para Usuarios Experimentados)
```bash
# 1. Clonar e instalar
git clone https://github.com/armando2sarango/fis-integrated-auth-directory.git
cd fis-integrated-auth-directory
chmod +x *.sh scripts/*.sh
sudo ./SarangoJ-Proyecto2.sh

# 2. Verificar instalación
./verificar_todo.sh

# 3. Acceder desde Windows
# - Editar C:\Windows\System32\drivers\etc\hosts (agregar: <IP_DE_WSL>    krb5.fis.epn.ec)
# - Instalar MIT Kerberos for Windows
# - Configurar Firefox (ver sección detallada)
# - Navegar a http://krb5.fis.epn.ec
```

Para instrucciones detalladas, continúa leyendo...
### Tecnologías Integradas

El proyecto combina dos estándares industriales de identidad y acceso:

1. **Kerberos (MIT)** - Autenticación segura mediante tickets criptográficos
2. **OpenLDAP** - Directorio centralizado para información organizacional

---

## ✨ Características Principales

- 🔐 **Single Sign-On (SSO)** - Una sola autenticación para múltiples servicios
- 👥 **Gestión de Perfiles** - Soporte para Profesores, Estudiantes y Administrativos
- 📸 **Gestión de Avatares** - Carga y almacenamiento de fotos de perfil en LDAP
- 🏢 **Directorio Organizacional** - Estructura jerárquica con OUs personalizadas
- 🔒 **Seguridad Empresarial** - Autenticación basada en tickets Kerberos
- 🌐 **Interfaz Web Moderna** - Dashboard intuitivo con información personalizada

---

## 🏗️ Arquitectura y Justificación Técnica

### Componentes del Sistema

#### 1. **Sincronización de Tiempo** (`ntp`)
**Propósito:** Prevención de ataques de repetición (Replay Attacks)

Kerberos requiere sincronización temporal estricta (tolerancia < 5 minutos) entre servidor y cliente. NTP garantiza la coherencia temporal necesaria para la validez de los tickets.

#### 2. **Servidor DNS** (`bind9`)
**Propósito:** Resolución de nombres de dominio

Kerberos depende exclusivamente de FQDNs (Fully Qualified Domain Names). BIND9 actúa como servidor autoritativo para la zona `fis.epn.ec`, resolviendo nombres como `krb5.fis.epn.ec` a direcciones IP locales.

#### 3. **Key Distribution Center** (`krb5-kdc`, `krb5-admin-server`)
**Propósito:** Núcleo de autenticación

- **KDC:** Emite Ticket Granting Tickets (TGT) tras validación de credenciales
- **Admin Server:** Gestión de principales y políticas de seguridad

#### 4. **Directorio LDAP** (`slapd`, `ldap-utils`)
**Propósito:** Base de datos organizacional

Almacena atributos extendidos no manejados por Kerberos:
- Fotografías en formato base64
- Información de contacto
- Datos organizacionales (departamentos, oficinas, títulos)
- Estructura jerárquica (OUs)

#### 5. **Frontend Web** (`apache2`, `php`, `libapache2-mod-auth-gssapi`)
**Propósito:** Interfaz de usuario y demostración de SSO

- **Apache2:** Servidor HTTP
- **mod-auth-gssapi:** Módulo de autenticación Kerberos/GSSAPI
- **PHP-LDAP:** Binding para consultas LDAP desde la aplicación web

---

## 📦 Requisitos Previos

### Servidor (Linux)
- **SO:** Ubuntu 20.04+ / Debian 11+ / WSL2
- **RAM:** Mínimo 2GB
- **Privilegios:** Acceso root/sudo
- **Conectividad:** Puerto 80 (HTTP) disponible

### Cliente (Windows)
- **SO:** Windows 10/11
- **Navegador:** Mozilla Firefox 90+
- **Software:** MIT Kerberos for Windows
- **Privilegios:** Acceso administrativo para configuración

---
### Red
- **Conectividad:** Cliente y servidor en la misma red local o WSL2 accesible desde Windows
- **Puertos:** 88 (Kerberos), 389 (LDAP), 80 (HTTP)
- **Firewall:** Permitir tráfico entre cliente Windows y WSL/servidor Linux

## 🚀 Instalación

### Paso 1: Clonar el Repositorio

```bash
git clone https://github.com/armando2sarango/fis-integrated-auth-directory.git
cd fis-integrated-auth-directory
```

### Paso 2: Asignar Permisos de Ejecución

```bash
chmod +x SarangoJ-Proyecto2.sh deploy.sh scripts/*.sh verificar_todo.sh
```

### Paso 3: Ejecutar Despliegue Automático

```bash
sudo ./SarangoJ-Proyecto2.sh
```

### 🛡️ Nota de Seguridad

El script detectará si existen configuraciones previas y solicitará confirmación. Si acepta, se realizará un **Backup Automático** de sus archivos en la carpeta `./backups_previos/` antes de realizar cambios.

### ⚠️ Interacción Durante la Instalación

Durante la instalación de Kerberos, configure los siguientes valores **exactamente**:

| Parámetro | Valor |
|-----------|-------|
| **Realm** | `FIS.EPN.EC` |
| **Kerberos Servers** | `krb5.fis.epn.ec` |
| **Administrative Server** | `krb5.fis.epn.ec` |

---

## ⚙️ Configuración del Cliente (Windows)

### A. Configuración del Archivo Hosts

> ⚠️ **IMPORTANTE:** Necesitas obtener la IP de tu WSL primero.

#### Paso 1: Obtener la IP de WSL

Abre tu terminal **WSL** y ejecuta:
```bash
hostname -I | awk '{print $1}'
```

**Ejemplo de salida:**
```
172.28.144.233
```

Copia esta IP, la necesitarás en el siguiente paso.

#### Paso 2: Editar el archivo hosts en Windows

1. Abra **Bloc de Notas** como Administrador
2. Edite: `C:\Windows\System32\drivers\etc\hosts`
3. Agregue la siguiente línea al final (reemplazando `<IP_WSL>` con la IP que obtuviste):
```plaintext
<IP_WSL>    krb5.fis.epn.ec
```

**Ejemplo con IP real:**
```plaintext
172.28.144.233    krb5.fis.epn.ec
```

4. Guarde el archivo (Ctrl+S)

#### Paso 3: Verificar la configuración

Abre **PowerShell** en Windows y ejecuta:
```powershell
ping krb5.fis.epn.ec
```

**Salida esperada:**
```
Haciendo ping a krb5.fis.epn.ec [172.28.144.233] con 32 bytes de datos:
Respuesta desde 172.28.144.233: bytes=32 tiempo<1ms TTL=64
```

> 💡 **Nota sobre IP Dinámica:** La IP de WSL puede cambiar al reiniciar Windows. Si después de un reinicio no puedes acceder al servidor, repite estos pasos para actualizar la IP.



### B. Instalación del Cliente MIT Kerberos

1. Descargue [MIT Kerberos for Windows (64-bit)](https://web.mit.edu/kerberos/dist/)
2. Ejecute el instalador y seleccione instalación **Typical**
3. Verifique la instalación en: `C:\Program Files\MIT\Kerberos\bin\gssapi64.dll`

### C. Configuración del archivo krb5.ini


Para que el cliente de Windows sepa cómo comunicarse con el reino FIS.EPN.EC, necesita un archivo de configuración. En lugar de escribirlo a mano, puede obtener la configuración exacta ejecutando este comando en su terminal de WSL
1. Cree el archivo  C:\ProgramData\MIT\Kerberos5\krb5.ini.
2. En su WSL ejecute "cat /etc/krb5.conf"
3. Copie todo lo que tiene ese archivo en el .init de windows(recuerde ingresar como administrador para que le permita guardar los cambios)

### D. Obtención de Tickets (Primera Prueba)

1. Abra **MIT Kerberos Ticket Manager**
2. Haga clic en **Get Ticket**
3. Ingrese credenciales:
   - **Principal:** `enrrique.mafla@EPN.FIS.EC` (o cualquier usuario del sistema)
   - **Password:** `password123`

### E. Configuración de Zonas de Seguridad de Windows

1. Abra **Panel de Control** → **Opciones de Internet**
2. Vaya a la pestaña **Seguridad**
3. Seleccione **Intranet local**
4. Haga clic en **Sitios**
5. Haga clic en **Opciones avanzadas**
6. Agregue el dominio: `http://krb5.fis.epn.ec`
7. Haga clic en **Agregar** y luego en **Cerrar**

> **Nota:** Este paso es crucial para que Windows confíe en el dominio y permita la autenticación automática.
> ⚠️ **IMPORTANTE:** Cierre completamente Firefox antes de realizar estos cambios (incluyendo procesos en segundo plano).
### F. Configuración de Mozilla Firefox

1. Escriba en la barra de direcciones: `about:config`
2. Acepte el aviso de riesgo
3. Configure las siguientes variables:

| Variable | Valor | Descripción |
|----------|-------|-------------|
| `network.negotiate-auth.trusted-uris` | `fis.epn.ec` | Autoriza el dominio para SSO |
| `network.negotiate-auth.gsslib` | `C:\Program Files\MIT\Kerberos\bin\gssapi64.dll` | Ruta a librería GSSAPI |
| `network.auth.use-sspi` | `false` | Desactiva autenticación Windows |
| `network.negotiate-auth.use-sspi` | `false` | Fuerza uso de GSSAPI |
| `network.negotiate-auth.allow-non-fqdn` | `true` | Permite nombres de host cortos |

---
🔐 Credenciales del Sistema
Credenciales Administrativas
Servidor LDAP (OpenLDAP)

DN Administrativo: cn=admin,dc=fis,dc=epn,dc=ec
Contraseña: Sistemas2026
Uso: Gestión del directorio LDAP, creación/modificación de entradas
Ejemplo de uso:
# Búsqueda en LDAP
ldapsearch -x -D "cn=admin,dc=fis,dc=epn,dc=ec" -w Sistemas2026 \
  -b "dc=fis,dc=epn,dc=ec" "(objectClass=*)"

# Modificar entrada LDAP
ldapmodify -x -D "cn=admin,dc=fis,dc=epn,dc=ec" -w Sistemas2026 -f modificacion.ldif
Servidor Kerberos (KDC Admin)

Principal Administrativo: admin/admin@FIS.EPN.EC
Contraseña: Sistemas2026
Uso: Gestión de principales Kerberos, políticas de seguridad
Ejemplo de uso:
# Acceso a kadmin
kadmin -p admin/admin@FIS.EPN.EC
# Ingresar contraseña: Sistemas2026

# O con kadmin.local (requiere sudo, no solicita contraseña)
sudo kadmin.local
### Credenciales de Usuarios

#### Usuarios del Sistema (Kerberos y LDAP)
- **Contraseña predeterminada:** `password123`
- **Aplica a:** Todos los usuarios creados automáticamente por los scripts
- **Alcance:** Autenticación Kerberos y acceso web SSO

#### Usuarios de Prueba Precargados

| Rol | Usuario | Contraseña | Realm Completo |
|-----|---------|------------|----------------|
| 👨‍🏫 **Profesor** | `luis.mafla` | `password123` | `luis.mafla@FIS.EPN.EC` |
| 👨‍🎓 **Estudiante** | `jose.sarango` | `password123` | `jose.sarango@FIS.EPN.EC` |
| 👨‍💼 **Administrativo** | `carlos.soporte` | `password123` | `carlos.soporte@FIS.EPN.EC` |

### 🔑 Cambio de Contraseñas

#### Cambiar contraseña de usuario en Kerberos:
```bash
# Desde el cliente (usuario cambia su propia contraseña)
kpasswd usuario@FIS.EPN.EC

# Desde el servidor (como administrador)
sudo kadmin.local
kadmin.local: cpw usuario@FIS.EPN.EC
# Ingresar nueva contraseña cuando se solicite
```

#### Cambiar contraseña del administrador LDAP:
```bash
# Generar hash de nueva contraseña
slappasswd
# Copiar el hash generado (ejemplo: {SSHA}xK8V6qkMOGGZr...)

# Editar configuración
sudo ldapmodify -Y EXTERNAL -H ldapi:///
# Ingresar:
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcRootPW
olcRootPW: {SSHA}xK8V6qkMOGGZr...
# Presionar Ctrl+D para finalizar
```

### ⚠️ Notas de Seguridad

> **🔒 IMPORTANTE - Entorno de Producción:**
> - Las contraseñas predeterminadas (`Sistemas2026` y `password123`) son **SOLO para entornos de prueba/desarrollo**
> - En producción, utilice contraseñas robustas (mínimo 16 caracteres, mezcla de mayúsculas, minúsculas, números y símbolos)
> - Implemente políticas de rotación de contraseñas cada 90 días
> - Habilite autenticación de dos factores (2FA) cuando sea posible
> - Revise logs de autenticación regularmente: `/var/log/krb5kdc.log` y `/var/log/slapd.log`

---
## 🎯 Uso del Sistema

### Acceso al Sistema

Navegue a: **http://krb5.fis.epn.ec**

### 👤 Creación Rápida de Usuarios (LDAP + Kerberos)

Para agregar nuevos usuarios al sistema de forma automatizada, utilice el script `crear_usuario.sh`:
```bash
sudo ./scripts/crear_usuario.sh
```

#### Ejemplo de Creación de un Profesor
```plaintext
=== CREADOR DE USUARIOS AVANZADO (KERBEROS + LDAP) ===
Usuario (ej: joel.quilumba): juan.perez
Primer Nombre: Juan
Segundo Nombre (opcional, presiona Enter para omitir): Carlos
Apellido: Pérez
Contraseña: ********
------------------------------------------------
Seleccione el ROL del usuario:
1) Estudiante
2) Profesor
3) Administrativo
Opción (1-3): 2
Título Académico (ej: PhD en Purdue University): PhD en Machine Learning
Departamento (ej: Informática y Ciencias de la Computación): Inteligencia Artificial
Número de Oficina (ej: 211): 305
Teléfono (ej: 022-976-300): 022-333-444
Descripción/Trayectoria: Investigador en IA | 15 años experiencia

>> [1/2] Creando principal en Kerberos...
✅ Principal creado

>> [2/2] Generando entrada LDAP para Profesores...
✅ Usuario juan.perez creado exitosamente en Profesores
   DN: uid=juan.perez,ou=Profesores,dc=fis,dc=epn,dc=ec
   UID Number: 10025
   GID Number: 10001
------------------------------------------------
```

#### Ejemplo de Creación de un Estudiante
```plaintext
=== CREADOR DE USUARIOS AVANZADO (KERBEROS + LDAP) ===
Usuario (ej: joel.quilumba): maria.lopez
Primer Nombre: María
Segundo Nombre (opcional, presiona Enter para omitir): 
Apellido: López
Contraseña: ********
------------------------------------------------
Seleccione el ROL del usuario:
1) Estudiante
2) Profesor
3) Administrativo
Opción (1-3): 1
Carrera (ej: Ciencias de la Computación): Ingeniería en Sistemas
Edad: 21

>> [1/2] Creando principal en Kerberos...
✅ Principal creado

>> [2/2] Generando entrada LDAP para Estudiantes...
✅ Usuario maria.lopez creado exitosamente en Estudiantes
   DN: uid=maria.lopez,ou=Estudiantes,dc=fis,dc=epn,dc=ec
   UID Number: 10026
   GID Number: 10000
------------------------------------------------
```

#### Campos Requeridos por Rol

| Rol | Campos Adicionales |
|-----|-------------------|
| **Estudiante** | • Carrera<br>• Edad |
| **Profesor** | • Título Académico<br>• Departamento<br>• Número de Oficina<br>• Teléfono<br>• Descripción/Trayectoria |
| **Administrativo** | • Cargo<br>• Ubicación/Oficina<br>• Descripción del puesto |

#### Verificación del Usuario Creado

Para verificar que el usuario fue creado correctamente:
```bash
# Verificar en LDAP
ldapsearch -x -D "cn=admin,dc=fis,dc=epn,dc=ec" -w Sistemas2026 \
  -b "ou=Profesores,dc=fis,dc=epn,dc=ec" "(uid=juan.perez)"

# Verificar en Kerberos
sudo kadmin.local -q "getprinc juan.perez"
```

#### Prueba de Autenticación
```bash
# Obtener ticket Kerberos
kinit juan.perez
# Ingrese la contraseña cuando se solicite

# Verificar ticket
klist

# Debería mostrar:
# Ticket cache: FILE:/tmp/krb5cc_1000
# Default principal: juan.perez@FIS.EPN.EC
```

### 🔑 Credenciales de Prueba

> **Contraseña para todos los usuarios:** `password123`

| Rol | Usuario | Descripción |
|-----|---------|-------------|
| 👨‍🏫 **Profesor** | `luis.mafla` | Títulos académicos, Oficina 211, Depto. CC |
| 👨‍🎓 **Estudiante** | `jose.sarango` | Edad, Carrera, Matrícula |
| 👨‍💼 **Administrativo** | `carlos.soporte` | Cargo TI, Ubicación |

### Funcionalidades Disponibles

- **Visualizar Perfil:** Información personalizada según rol
- **Cambiar Foto:** Cargar nueva imagen de perfil (almacenada en LDAP)
- **Cerrar Sesión:** Invalidar tickets de autenticación
- **Crear Usuarios:** Agregar nuevos usuarios con el script automatizado


---

## ✅ Verificación y Pruebas

### 1. Auditoría del Sistema
```bash
./verificar_todo.sh
```

**✅ Output esperado:**
```
[LDAP] luis.mafla ✅ OK
[KRB5] luis.mafla ✅ OK
[LDAP] jose.sarango ✅ OK
[KRB5] jose.sarango ✅ OK
...
✅ Sistema verificado correctamente
```

**❌ Si ves errores:**
```bash
# Revisar logs de Kerberos
sudo tail -f /var/log/krb5kdc.log

# Revisar logs de LDAP
sudo journalctl -u slapd -f
```
### 2. Prueba de Autenticación SSO

1. Acceda a: http://krb5.fis.epn.ec
2. Ingrese con usuario `luis.mafla` y contraseña `password123`
3. Verifique que aparezca el dashboard sin solicitar credenciales adicionales

### 3. Prueba de Gestión de Fotos

1. Inicie sesión con cualquier usuario
2. Haga clic en **"📷 Cambiar Foto"**
3. Seleccione una imagen (PNG/JPG, máx. 2MB)
4. Verifique que la foto se actualice inmediatamente

---

## 📁 Estructura del Proyecto

```
fis-integrated-auth-directory/
├── SarangoJ-Proyecto2.sh       # Script maestro de instalación y seguridad
├── deploy.sh                   # Script de despliegue web
├── verificar_todo.sh           # Script de auditoría
├── scripts/
│   ├── setup_server.sh         # Configuración DNS (Bind9) y KDC
│   ├── setup_clients.sh        # Instalación de dependencias
│   ├── cargar_demo.sh          # Sincronización LDAP-Kerberos
│   └── crear_usuario.sh        # Asistente para crear usuarios manuales
├── config/
│   ├── universidad.ldif        # Datos masivos de usuarios y estructura
│   └── mafla.ldif              # Archivo de prueba específico
└── src/
    ├── index.php               # Dashboard principal (Lógica SSO)
    └── img/                    # Directorio de imágenes de perfil
```

---

## 🔧 Solución de Problemas

### Error: "Clock skew too great"
**Causa:** Desincronización temporal entre cliente y servidor

**Solución:**
```bash
sudo ntp pool.ntp.org
sudo systemctl restart krb5-kdc
```

### Error: "Cannot resolve krb5.fis.epn.ec"
**Causa:** DNS no configurado correctamente

**Solución:**
1. Verifique el archivo hosts en Windows
2. Confirme que BIND9 esté corriendo: `sudo systemctl status bind9`

### Error: "Authentication failed" en Firefox
**Causa:** Configuración incorrecta de GSSAPI

**Solución:**
1. Verifique la ruta de `gssapi64.dll` en `about:config`
2. Confirme que `network.negotiate-auth.use-sspi` esté en `false`
3. Reinicie Firefox completamente
### Error: "El navegador muestra código PHP (texto) en lugar de la web"
**Causa:** Apache está usando el módulo mpm_event en lugar de mpm_prefork. 
**Solución:**Ejecute los siguientes comandos
sudo a2dismod mpm_event
sudo a2enmod mpm_prefork
sudo a2enmod php8.3  # (o la versión detectada)
sudo systemctl restart apache2

---

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Por favor:

1. Fork el proyecto
2. Cree una rama para su feature (`git checkout -b feature/NuevaCaracteristica`)
3. Commit sus cambios (`git commit -m 'Agregar nueva característica'`)
4. Push a la rama (`git push origin feature/NuevaCaracteristica`)
5. Abra un Pull Request

---

## 👨‍💻 Autor

**Jose Sarango**  
Estudiante de Ciencias de la Computación
Escuela Politécnica Nacional

---

**⭐ Si este proyecto te fue útil, considera darle una estrella en GitHub**