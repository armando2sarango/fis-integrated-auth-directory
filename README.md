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

- [Descripción](#-descripción-del-proyecto)
- [Características](#-características-principales)
- [Arquitectura](#-arquitectura-y-justificación-técnica)
- [Requisitos](#-requisitos-previos)
- [Instalación](#-instalación)
- [Configuración del Cliente](#-configuración-del-cliente-windows)
- [Uso](#-uso-del-sistema)
- [Verificación](#-verificación-y-pruebas)
- [Estructura del Proyecto](#-estructura-del-proyecto)
- [Solución de Problemas](#-solución-de-problemas)
- [Contribuciones](#-contribuciones)
- [Licencia](#-licencia)

---

## 📖 Descripción del Proyecto

Este sistema simula una infraestructura de red empresarial real que implementa **Single Sign-On (SSO)** para gestión de identidades corporativas. Permite que usuarios de diferentes perfiles (Profesores, Estudiantes y Administrativos) accedan a servicios web utilizando una única contraseña, visualizando información personalizada según su rol.

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

#### 1. **Sincronización de Tiempo** (`ntpdate`)
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

1. Abra **Bloc de Notas** como Administrador
2. Edite: `C:\Windows\System32\drivers\etc\hosts`
3. Agregue la siguiente línea al final:

```plaintext
127.0.0.1    krb5.fis.epn.ec
```

### B. Instalación del Cliente MIT Kerberos

1. Descargue [MIT Kerberos for Windows (64-bit)](https://web.mit.edu/kerberos/dist/)
2. Ejecute el instalador y seleccione instalación **Typical**
3. Verifique la instalación en: `C:\Program Files\MIT\Kerberos\bin\gssapi64.dll`

### C. Obtención de Tickets (Opcional)

1. Abra **MIT Kerberos Ticket Manager**
2. Haga clic en **Get Ticket**
3. Ingrese credenciales:
   - **Principal:** `luis.mafla` (o cualquier usuario del sistema)
   - **Password:** `password123`

### D. Configuración de Zonas de Seguridad de Windows

1. Abra **Panel de Control** → **Opciones de Internet**
2. Vaya a la pestaña **Seguridad**
3. Seleccione **Intranet local**
4. Haga clic en **Sitios**
5. Haga clic en **Opciones avanzadas**
6. Agregue el dominio: `http://krb5.fis.epn.ec`
7. Haga clic en **Agregar** y luego en **Cerrar**

> **Nota:** Este paso es crucial para que Windows confíe en el dominio y permita la autenticación automática.

### E. Configuración de Mozilla Firefox

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

## 🎯 Uso del Sistema

### Acceso al Sistema

Navegue a: **http://krb5.fis.epn.ec**

### Credenciales de Prueba

**Contraseña universal:** `password123`

| Perfil | Usuario | Información Visible |
|--------|---------|---------------------|
| **Profesor** | `luis.mafla` | Títulos académicos, Oficina 211, Depto. Ciencias de la Computación |
| **Estudiante** | `jose.sarango` | Edad, Carrera, Matrícula, Semestre |
| **Administrativo** | `carlos.soporte` | Cargo TI, Ubicación de servidores |

### Funcionalidades Disponibles

- **Visualizar Perfil:** Información personalizada según rol
- **Cambiar Foto:** Cargar nueva imagen de perfil (almacenada en LDAP)
- **Cerrar Sesión:** Invalidar tickets de autenticación

---

## ✅ Verificación y Pruebas

### 1. Auditoría del Sistema

Ejecute el script de verificación para validar la correcta creación de usuarios:

```bash
./verificar_todo.sh
```

**Resultado esperado:** Todos los usuarios deben mostrar estado `✅ OK` en LDAP y Kerberos.

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
sudo ntpdate pool.ntp.org
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

---

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Por favor:

1. Fork el proyecto
2. Cree una rama para su feature (`git checkout -b feature/NuevaCaracteristica`)
3. Commit sus cambios (`git commit -m 'Agregar nueva característica'`)
4. Push a la rama (`git push origin feature/NuevaCaracteristica`)
5. Abra un Pull Request

---

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Consulte el archivo `LICENSE` para más detalles.

---

## 👨‍💻 Autor

**Jose Sarango**  
Estudiante de Administración de Sistemas  
Escuela Politécnica Nacional

---

## 📞 Soporte

Para reportar problemas o solicitar ayuda:
- Abra un [Issue](https://github.com/armando2sarango/fis-integrated-auth-directory/issues)

---

**⭐ Si este proyecto te fue útil, considera darle una estrella en GitHub**