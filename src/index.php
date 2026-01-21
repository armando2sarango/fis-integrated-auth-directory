<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Acceso Seguro FIS - Perfil</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; background-color: #f4f7f6; display: flex; justify-content: center; align-items: center; min-height: 100vh; margin: 0; }
        .card { background: white; width: 450px; padding: 30px; border-radius: 15px; box-shadow: 0 10px 25px rgba(0,0,0,0.1); text-align: center; margin: 20px; }
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
        .info-row { display: flex; justify-content: space-between; border-bottom: 1px solid #eee; padding: 6px 0; }
        .info-row:last-child { border-bottom: none; }
        .label { font-weight: bold; color: #555; }
        .value { color: #333; text-align: right; max-width: 220px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
        
        .upload-form { margin-bottom: 15px; }
        .custom-file-upload {
            border: 1px solid #ccc; display: inline-block; padding: 6px 12px; cursor: pointer;
            border-radius: 5px; background: #007bff; color: white; font-size: 0.8em; transition: 0.3s;
        }
        .custom-file-upload:hover { background: #0056b3; }
        .clock { font-family: 'Courier New', monospace; font-weight: bold; color: #333; }
        a { text-decoration: none; color: #007bff; }
        a:hover { text-decoration: underline; }
    </style>
</head>
<body>

<?php
// --- 1. CONFIGURACIÓN INICIAL ---
$full_user = $_SERVER['REMOTE_USER'] ?? 'invitado';
$uid = explode("@", $full_user)[0];
$base_dir = "img/usuarios/" . $uid;

// --- 2. LOGICA SUBIDA FOTO ---
if ($_SERVER['REQUEST_METHOD'] == 'POST' && isset($_FILES['foto'])) {
    $check = getimagesize($_FILES["foto"]["tmp_name"]);
    if($check !== false) {
        $ds = ldap_connect("ldap://localhost");
        ldap_set_option($ds, LDAP_OPT_PROTOCOL_VERSION, 3);
        
        // ¡CAMBIA LA CONTRASEÑA!
        $ldap_admin_user = "cn=admin,dc=fis,dc=epn,dc=ec";
        $ldap_admin_pass = "1234"; 

        if ($ds && ldap_bind($ds, $ldap_admin_user, $ldap_admin_pass)) {
            $search = ldap_search($ds, "dc=fis,dc=epn,dc=ec", "(uid=$uid)");
            $info_user = ldap_get_entries($ds, $search);
            if ($info_user["count"] > 0) {
                $user_dn = $info_user[0]["dn"];
                $foto_binaria = file_get_contents($_FILES['foto']['tmp_name']);
                ldap_mod_replace($ds, $user_dn, ["jpegPhoto" => $foto_binaria]);
                ldap_close($ds);
                header("Location: " . $_SERVER['PHP_SELF']); exit;
            }
        }
        ldap_close($ds);
    }
}

// --- 3. LECTURA DE DATOS ---
$nombre = $uid; $rol_etiqueta = "Usuario"; $dato_extra = ""; 
$foto_html = '<img src="img/default_user.png" class="profile-img">';

// Array donde guardaremos solo los campos que queremos mostrar
$campos_visibles = [];

$ds = ldap_connect("ldap://localhost");
ldap_set_option($ds, LDAP_OPT_PROTOCOL_VERSION, 3);

if ($ds) {
    $r = ldap_bind($ds);
    $search = ldap_search($ds, "dc=fis,dc=epn,dc=ec", "(uid=$uid)");
    $info = ldap_get_entries($ds, $search);

    if ($info["count"] > 0) {
        // Datos comunes
        $nombre = $info[0]["displayname"][0] ?? $info[0]["cn"][0] ?? $uid;
        // $correo = $info[0]["mail"][0] ?? "No registrado";
        // Si LDAP tiene correo, úsalo. Si no, ¡invéntalo usando el UID!
$dominio = "fis.epn.ec"; // Tu dominio
$correo_ldap = $info[0]["mail"][0] ?? "";

if ($correo_ldap != "") {
    $correo = $correo_ldap;
} else {
    // Construimos el correo uniendo usuario + dominio
    $correo = $uid . "@" . $dominio; 
}

        
        // Detección de Rol y Configuración de Campos
        $dn = $info[0]["dn"];
        
        // CASO 1: ESTUDIANTES
        if (strpos($dn, "ou=Estudiantes") !== false) {
            $rol_etiqueta = "Estudiante 🎓";
            $carrera = $info[0]["departmentnumber"][0] ?? "Sin carrera";
            $matricula = $info[0]["employeenumber"][0] ?? "--";
            $dato_extra = $carrera;

            // Definimos qué ve un estudiante
            $campos_visibles = [
                "ID Matrícula" => $matricula,
                "Usuario"      => $uid,
                "Correo"       => "<a href='mailto:$correo'>$correo</a>",
                "Carrera"      => $carrera
            ];
        } 
        // CASO 2: PROFESORES
        elseif (strpos($dn, "ou=Profesores") !== false) {
            $rol_etiqueta = "Docente 👨‍🏫";
            $titulo = $info[0]["title"][0] ?? "Profesor";
            $oficina = $info[0]["roomnumber"][0] ?? "--";
            $movil = $info[0]["mobile"][0] ?? "--";
            $dato_extra = $titulo;

            // Definimos qué ve un profesor
            $campos_visibles = [
                "Título"    => $titulo,
                "Usuario"   => $uid,
                "Correo"    => "<a href='mailto:$correo'>$correo</a>",
                "Oficina"   => $oficina,
                "Móvil"     => $movil
            ];
        } 
        // CASO 3: ADMINISTRATIVOS
        elseif (strpos($dn, "ou=Administrativos") !== false) {
            $rol_etiqueta = "Administrativo 💼";
            $cargo = $info[0]["title"][0] ?? "Personal";
            $ext = $info[0]["telephonenumber"][0] ?? "--";
            $ubicacion = $info[0]["roomnumber"][0] ?? "--";
            $dato_extra = $cargo;

            // Definimos qué ve un admin
            $campos_visibles = [
                "Cargo"     => $cargo,
                "Usuario"   => $uid,
                "Correo"    => "<a href='mailto:$correo'>$correo</a>",
                "Extensión" => $ext,
                "Ubicación" => $ubicacion
            ];
        }

        // FOTO (Prioridad LDAP)
        if (isset($info[0]["jpegphoto"][0])) {
            $data = base64_encode($info[0]["jpegphoto"][0]);
            $foto_html = '<img src="data:image/jpeg;base64,'.$data.'" class="profile-img">';
        } elseif (file_exists($base_dir . "/perfil.jpg")) {
            $foto_html = '<img src="'.$base_dir.'/perfil.jpg?v='.time().'" class="profile-img">';
        }
    }
    ldap_close($ds);
}
?>

    <div class="card">
        <div class="success-header">¡Identidad Verificada!</div>
        
        <?php echo $foto_html; ?>

        <div class="upload-form">
            <form action="" method="POST" enctype="multipart/form-data">
                <label for="file-upload" class="custom-file-upload">📷 Actualizar Foto</label>
                <input id="file-upload" type="file" name="foto" style="display:none;" onchange="this.form.submit()"/>
            </form>
        </div>

        <div class="user-name"><?php echo $nombre; ?></div>
        <div class="user-role"><?php echo $rol_etiqueta; ?></div>
        <div class="user-detail"><?php echo $dato_extra; ?></div>

        <div class="info-box">
            <?php foreach ($campos_visibles as $label => $valor): ?>
                <div class="info-row">
                    <span class="label"><?php echo $label; ?>:</span> 
                    <span class="value"><?php echo $valor; ?></span>
                </div>
            <?php endforeach; ?>
            
            <div class="info-row">
                <span class="label">Hora:</span> 
                <span id="reloj" class="clock">--:--:--</span>
            </div>
        </div>
    </div>

    <script>
        function actualizarReloj() {
            const ahora = new Date();
            document.getElementById('reloj').innerText = ahora.toLocaleTimeString();
        }
        setInterval(actualizarReloj, 1000);
        actualizarReloj();
    </script>

</body>
</html>