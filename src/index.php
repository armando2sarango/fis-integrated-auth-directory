<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Acceso Seguro FIS - Perfil</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; background-color: #f4f7f6; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
        .card { background: white; width: 450px; padding: 30px; border-radius: 15px; box-shadow: 0 10px 25px rgba(0,0,0,0.1); text-align: center; }
        .success-header { color: #28a745; font-size: 1.2em; margin-bottom: 20px; font-weight: bold; }
        .profile-img {
            width: 140px; height: 140px;
            border-radius: 50%; object-fit: cover;
            border: 4px solid #e8f5e9; margin-bottom: 15px;
            background-color: #eee;
        }
        .user-name { font-size: 1.5em; color: #333; margin: 5px 0; font-weight: bold; }
        .user-role { color: #007bff; font-weight: bold; font-size: 0.9em; margin-bottom: 5px; text-transform: uppercase; letter-spacing: 1px; }
        .user-detail { color: #666; font-size: 0.95em; margin-bottom: 20px; font-style: italic; }
        
        .info-box { background-color: #f8f9fa; padding: 15px; border-radius: 10px; text-align: left; font-size: 0.9em; line-height: 1.6; }
        .info-row { display: flex; justify-content: space-between; border-bottom: 1px solid #eee; padding: 5px 0; }
        .info-row:last-child { border-bottom: none; }
        .label { font-weight: bold; color: #555; }
        
        /* Botón de carga */
        .upload-form { margin-bottom: 15px; }
        .custom-file-upload {
            border: 1px solid #ccc; display: inline-block; padding: 6px 12px; cursor: pointer;
            border-radius: 5px; background: #007bff; color: white; font-size: 0.8em; transition: 0.3s;
        }
        .custom-file-upload:hover { background: #0056b3; }
        .clock { font-family: 'Courier New', monospace; font-weight: bold; color: #333; }
    </style>
</head>
<body>

<?php
// 1. INICIALIZAR VARIABLES
$full_user = $_SERVER['REMOTE_USER'] ?? 'invitado';
$uid = explode("@", $full_user)[0];
$base_dir = "img/usuarios/" . $uid;
$mensaje = "";

// 2. LOGICA SUBIDA FOTO
if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_FILES['foto'])) {
    if (!file_exists($base_dir)) { mkdir($base_dir, 0777, true); }
    $destino = $base_dir . "/perfil.jpg";
    if (move_uploaded_file($_FILES['foto']['tmp_name'], $destino)) {
        chmod($destino, 0644);
        header("Location: " . $_SERVER['PHP_SELF']); exit;
    }
}

// 3. DATOS LDAP
$nombre = $uid; $rol = "Usuario"; $dato_extra = ""; $desc = "Sin datos";
$foto_html = '<img src="img/default_user.png" class="profile-img">';

$ds = ldap_connect("ldap://localhost");
ldap_set_option($ds, LDAP_OPT_PROTOCOL_VERSION, 3);

if ($ds) {
    $r = ldap_bind($ds);
    $search = ldap_search($ds, "dc=fis,dc=epn,dc=ec", "(uid=$uid)");
    $info = ldap_get_entries($ds, $search);

    if ($info["count"] > 0) {
        $nombre = $info[0]["cn"][0] ?? $uid;
        $desc = $info[0]["description"][0] ?? "Miembro activo";
        
        // RECUPERAR DATOS EXTRA (Carrera o Título)
        $carrera = $info[0]["departmentnumber"][0] ?? ""; // Para estudiantes
        $titulo_prof = $info[0]["title"][0] ?? "";        // Para profes/admin

        // DETECCION DE ROL
        $dn = $info[0]["dn"];
        if (strpos($dn, "ou=Estudiantes") !== false) {
            $rol = "Estudiante 🎓";
            $dato_extra = $carrera ? "Carrera: " . $carrera : "";
        } elseif (strpos($dn, "ou=Profesores") !== false) {
            $rol = "Profesor 👨‍🏫";
            $dato_extra = $titulo_prof;
        } elseif (strpos($dn, "ou=Administrativos") !== false) {
            $rol = "Administrativo 💼";
            $dato_extra = $titulo_prof; // Cargo
        }

        // FOTO
        if (file_exists($base_dir . "/perfil.jpg")) {
            $foto_html = '<img src="'.$base_dir.'/perfil.jpg?v='.time().'" class="profile-img">';
        } elseif (isset($info[0]["jpegphoto"][0])) {
            $data = base64_encode($info[0]["jpegphoto"][0]);
            $foto_html = '<img src="data:image/jpeg;base64,'.$data.'" class="profile-img">';
        }
    }
    ldap_close($ds);
}
?>

    <div class="card">
        <div class="success-header">¡Autenticación Exitosa!</div>
        
        <?php echo $foto_html; ?>

        <div class="upload-form">
            <form action="" method="POST" enctype="multipart/form-data">
                <label for="file-upload" class="custom-file-upload">📷 Cambiar Foto</label>
                <input id="file-upload" type="file" name="foto" style="display:none;" onchange="this.form.submit()"/>
            </form>
        </div>

        <div class="user-name"><?php echo $nombre; ?></div>
        <div class="user-role"><?php echo $rol; ?></div>
        <div class="user-detail"><?php echo $dato_extra; ?></div>

        <div class="info-box">
            <div class="info-row"><span class="label">Usuario:</span> <span><?php echo $uid; ?></span></div>
            <div class="info-row"><span class="label">IP:</span> <span><?php echo $_SERVER['REMOTE_ADDR']; ?></span></div>
            <div class="info-row"><span class="label">Descripción:</span> <span><?php echo $desc; ?></span></div>
            <div class="info-row"><span class="label">Hora:</span> <span id="reloj" class="clock">--:--:--</span></div>
        </div>
    </div>

    <script>
        function actualizarReloj() {
            const ahora = new Date();
            const hora = ahora.toLocaleTimeString();
            document.getElementById('reloj').innerText = hora;
        }
        setInterval(actualizarReloj, 1000); // Actualizar cada 1000ms (1 seg)
        actualizarReloj(); // Ejecutar inmediatamente al cargar
    </script>

</body>
</html>
