<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Perfil FIS - EPN</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; background-color: #f4f7f6; display: flex; justify-content: center; align-items: center; min-height: 100vh; margin: 0; }
        .card { background: white; width: 500px; padding: 40px; border-radius: 15px; box-shadow: 0 10px 25px rgba(0,0,0,0.1); text-align: center; }
        .success-header { color: #28a745; font-size: 1.2em; margin-bottom: 20px; font-weight: bold; text-transform: uppercase; letter-spacing: 1px; }
        .profile-img { width: 150px; height: 150px; border-radius: 50%; object-fit: cover; border: 5px solid #e8f5e9; margin-bottom: 15px; background-color: #eee; }
        .user-name { font-size: 1.6em; color: #333; margin: 10px 0; font-weight: 800; }
        .user-role { color: #0056b3; font-weight: bold; font-size: 0.9em; margin-bottom: 5px; text-transform: uppercase; letter-spacing: 2px; }
        .user-detail { color: #666; font-size: 1em; margin-bottom: 25px; font-style: italic; }
        
        .info-box { background-color: #f8f9fa; padding: 20px; border-radius: 10px; text-align: left; font-size: 0.95em; line-height: 1.6; border: 1px solid #e9ecef; }
        .info-row { display: flex; justify-content: space-between; border-bottom: 1px solid #eee; padding: 8px 0; }
        .info-row:last-child { border-bottom: none; }
        .label { font-weight: bold; color: #495057; }
        .value { color: #212529; text-align: right; max-width: 300px; }
        
        .upload-form { margin-bottom: 20px; }
        .custom-file-upload { border: 1px solid #ced4da; display: inline-block; padding: 8px 16px; cursor: pointer; border-radius: 5px; background: #fff; color: #495057; font-size: 0.85em; transition: 0.2s; }
        .custom-file-upload:hover { background: #e2e6ea; }
        .clock { font-family: 'Courier New', monospace; font-weight: bold; color: #dc3545; }
        a { text-decoration: none; color: #007bff; }
    </style>
</head>
<body>

<?php
// CONFIGURACION
$full_user = $_SERVER['REMOTE_USER'] ?? 'invitado';
$uid = explode("@", $full_user)[0];
$dominio = "fis.epn.ec";

// 1. LOGICA SUBIDA FOTO (Con Autenticación Segura)
if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_FILES['foto'])) {
    if($check = getimagesize($_FILES["foto"]["tmp_name"])) {
        $ds = ldap_connect("ldap://localhost");
        ldap_set_option($ds, LDAP_OPT_PROTOCOL_VERSION, 3);
        
        // ⚠️ CORRECCIÓN AQUÍ: Usamos la nueva clave segura
        if ($ds && ldap_bind($ds, "cn=admin,dc=fis,dc=epn,dc=ec", "SistemasSeguro2026")) {
            $search = ldap_search($ds, "dc=fis,dc=epn,dc=ec", "(uid=$uid)");
            $info = ldap_get_entries($ds, $search);
            if ($info["count"] > 0) {
                $foto_bin = file_get_contents($_FILES['foto']['tmp_name']);
                ldap_mod_replace($ds, $info[0]["dn"], ["jpegPhoto" => $foto_bin]);
                header("Location: " . $_SERVER['PHP_SELF']); exit;
            }
        }
    }
}

// 2. LECTURA DE DATOS (Con Autenticación Segura - Anónimo Bloqueado)
$nombre = $uid; $rol = "Usuario"; $subtitulo = ""; $foto_html = '<img src="img/default_user.png" class="profile-img">';
$datos = [];

$ds = ldap_connect("ldap://localhost");
ldap_set_option($ds, LDAP_OPT_PROTOCOL_VERSION, 3);

if ($ds) {
    // ⚠️ Autenticación OBLIGATORIA para leer (Blindaje de seguridad)
    $bind = ldap_bind($ds, "cn=admin,dc=fis,dc=epn,dc=ec", "SistemasSeguro2026");

    if ($bind) {
        $search = ldap_search($ds, "dc=fis,dc=epn,dc=ec", "(uid=$uid)");
        $info = ldap_get_entries($ds, $search);

        if ($info["count"] > 0) {
            $u = $info[0];
            $nombre = $u["cn"][0] ?? $uid;
            $correo = $uid . "@" . $dominio;
            
            // FOTO
            if (isset($u["jpegphoto"][0])) {
                $foto_html = '<img src="data:image/jpeg;base64,'.base64_encode($u["jpegphoto"][0]).'" class="profile-img">';
            }

            // LOGICA DE ROLES
            $dn = $u["dn"];
            
            if (strpos($dn, "ou=Profesores") !== false) {
                $rol = "Docente 👨‍🏫";
                $subtitulo = $u["title"][0] ?? "Profesor";
                $datos = [
                    "Departamento" => $u["departmentnumber"][0] ?? "--",
                    "Oficina" => $u["roomnumber"][0] ?? "--",
                    "Estudios" => $u["description"][0] ?? "--",
                    "Teléfono" => $u["telephonenumber"][0] ?? "IP-400"
                ];
            } elseif (strpos($dn, "ou=Estudiantes") !== false) {
                $rol = "Estudiante 🎓";
                $subtitulo = $u["departmentnumber"][0] ?? "Estudiante"; // Carrera
                $datos = [
                    "Matrícula ID" => $u["uidnumber"][0],
                    "Información" => $u["description"][0] ?? "Estudiante Activo", // Edad
                    "Correo Inst." => "<a href='#'>$correo</a>"
                ];
            } else {
                $rol = "Administrativo 💼";
                $subtitulo = $u["title"][0] ?? "Personal";
                $datos = [
                    "Ubicación" => $u["roomnumber"][0] ?? "--",
                    "Función" => $u["description"][0] ?? "Administrativo"
                ];
            }
        }
    }
}
?>

    <div class="card">
        <div class="success-header">Identidad Verificada</div>
        <?php echo $foto_html; ?>
        
        <div class="upload-form">
            <form action="" method="POST" enctype="multipart/form-data">
                <label for="f" class="custom-file-upload">📷 Cambiar Foto</label>
                <input id="f" type="file" name="foto" style="display:none;" onchange="this.form.submit()"/>
            </form>
        </div>

        <div class="user-name"><?php echo $nombre; ?></div>
        <div class="user-role"><?php echo $rol; ?></div>
        <div class="user-detail"><?php echo $subtitulo; ?></div>

        <div class="info-box">
            <div class="info-row"><span class="label">Usuario:</span> <span class="value"><?php echo $uid; ?></span></div>
            <?php foreach ($datos as $k => $v): ?>
                <div class="info-row"><span class="label"><?php echo $k; ?>:</span> <span class="value"><?php echo $v; ?></span></div>
            <?php endforeach; ?>
            <div class="info-row"><span class="label">Hora:</span> <span id="clock" class="clock">--:--:--</span></div>
        </div>
    </div>

    <script>
        setInterval(() => {
            document.getElementById('clock').innerText = new Date().toLocaleTimeString();
        }, 1000);
    </script>
</body>
</html>