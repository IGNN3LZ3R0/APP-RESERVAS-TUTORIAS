class ApiConfig {
  // ========== CONFIGURACIÓN BASE ==========
  // ✅ Para emulador de Android Studio
  static const String baseUrl = 'http://10.0.2.2:3000/api';
  
  // ========== ENDPOINTS DE AUTENTICACIÓN ==========
  
  // Login por rol
  static const String loginAdministrador = '$baseUrl/login';
  static const String loginDocente = '$baseUrl/docente/login';
  static const String loginEstudiante = '$baseUrl/estudiante/login';
  
  // Registro
  static const String registroEstudiante = '$baseUrl/estudiante/registro';
  
  // ========== CONFIRMAR EMAIL ==========
  
  // Confirmar email (solo estudiantes)
  static String confirmarEmail(String token) => '$baseUrl/confirmar/$token';
  
  // ========== RECUPERAR CONTRASEÑA - POR ROL ==========
  
  // ESTUDIANTE
  static const String recuperarPasswordEstudiante = '$baseUrl/estudiante/recuperarpassword';
  static String comprobarTokenEstudiante(String token) => '$baseUrl/estudiante/recuperarpassword/$token';
  static String nuevoPasswordEstudiante(String token) => '$baseUrl/estudiante/nuevopassword/$token';
  
  // DOCENTE
  static const String recuperarPasswordDocente = '$baseUrl/docente/recuperarpassword';
  static String comprobarTokenDocente(String token) => '$baseUrl/docente/recuperarpassword/$token';
  static String nuevoPasswordDocente(String token) => '$baseUrl/docente/nuevopassword/$token';
  
  // ADMINISTRADOR
  static const String recuperarPasswordAdmin = '$baseUrl/administrador/recuperarpassword';
  static String comprobarTokenAdmin(String token) => '$baseUrl/administrador/recuperarpassword/$token';
  static String nuevoPasswordAdmin(String token) => '$baseUrl/administrador/nuevopassword/$token';
  
  // ========== CAMBIO DE CONTRASEÑA OBLIGATORIO ==========
  
  // ⭐ NUEVO: Para docentes recién creados con contraseña temporal
  static const String cambiarPasswordObligatorioDocente = '$baseUrl/docente/cambiar-password-obligatorio';
  
  // ========== ENDPOINTS DE PERFIL ==========
  
  static const String perfilAdministrador = '$baseUrl/perfil';
  static const String perfilDocente = '$baseUrl/docente/perfil';
  static const String perfilEstudiante = '$baseUrl/estudiante/perfil';
  
  // Actualizar perfil
  static String actualizarPerfilAdmin(String id) => '$baseUrl/administrador/$id';
  static String actualizarPerfilDocente(String id) => '$baseUrl/docente/perfil/$id';
  static String actualizarPerfilEstudiante(String id) => '$baseUrl/estudiante/$id';
  
  // Actualizar contraseña
  static String actualizarPasswordAdmin(String id) => '$baseUrl/administrador/administrador/actualizarpassword/$id';
  static String actualizarPasswordDocente(String id) => '$baseUrl/docente/actualizarpassword/$id';
  static String actualizarPasswordEstudiante(String id) => '$baseUrl/estudiante/actualizarpassword/$id';
  
  // ========== ENDPOINTS DE DOCENTES ==========
  
  static const String registrarDocente = '$baseUrl/docente/registro';
  static const String listarDocentes = '$baseUrl/docentes';
  static String detalleDocente(String id) => '$baseUrl/docente/$id';
  static String eliminarDocente(String id) => '$baseUrl/docente/eliminar/$id';
  
  // ========== ENDPOINTS DE TUTORÍAS ==========
  
  static const String registrarTutoria = '$baseUrl/tutoria/registro';
  static const String listarTutorias = '$baseUrl/tutorias';
  static String actualizarTutoria(String id) => '$baseUrl/tutoria/actualizar/$id';
  static String cancelarTutoria(String id) => '$baseUrl/tutoria/cancelar/$id';
  static String registrarAsistencia(String id) => '$baseUrl/tutoria/registrar-asistencia/$id';
  
  // ========== ENDPOINTS DE DISPONIBILIDAD ==========
  
  static const String registrarDisponibilidad = '$baseUrl/tutorias/registrar-disponibilidad';
  static String verDisponibilidad(String docenteId) => '$baseUrl/ver-disponibilidad-docente/$docenteId';
  static String bloquesOcupados(String docenteId) => '$baseUrl/tutorias-ocupadas/$docenteId';
  
  // ========== MÉTODOS DE UTILIDAD ==========
  
  /// Headers para peticiones JSON
  static Map<String, String> getHeaders({String? token}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }
  
  /// Headers para multipart (subir archivos)
  static Map<String, String> getMultipartHeaders({String? token}) {
    final headers = <String, String>{};
    
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }
  
  /// Obtiene el endpoint de login según el rol
  static String getLoginEndpoint(String rol) {
    switch (rol.toLowerCase()) {
      case 'administrador':
        return loginAdministrador;
      case 'docente':
        return loginDocente;
      case 'estudiante':
      default:
        return loginEstudiante;
    }
  }
  
  /// Obtiene el endpoint de perfil según el rol
  static String getPerfilEndpoint(String rol) {
    switch (rol.toLowerCase()) {
      case 'administrador':
        return perfilAdministrador;
      case 'docente':
        return perfilDocente;
      case 'estudiante':
      default:
        return perfilEstudiante;
    }
  }
  
  // ========== MÉTODOS PARA RECUPERACIÓN DE CONTRASEÑA ==========
  
  /// Obtiene el endpoint de recuperación de contraseña según el rol
  /// @deprecated Usa los endpoints específicos por rol
  static String getRecuperarPasswordEndpoint(String rol) {
    switch (rol.toLowerCase()) {
      case 'administrador':
        return recuperarPasswordAdmin;
      case 'docente':
        return recuperarPasswordDocente;
      case 'estudiante':
      default:
        return recuperarPasswordEstudiante;
    }
  }
  
  /// Obtiene el endpoint de comprobación de token según el rol
  /// @deprecated Usa los endpoints específicos por rol
  static String getComprobarTokenEndpoint(String rol, String token) {
    switch (rol.toLowerCase()) {
      case 'administrador':
        return comprobarTokenAdmin(token);
      case 'docente':
        return comprobarTokenDocente(token);
      case 'estudiante':
      default:
        return comprobarTokenEstudiante(token);
    }
  }
  
  /// Obtiene el endpoint de nueva contraseña según el rol
  /// @deprecated Usa los endpoints específicos por rol
  static String getNuevoPasswordEndpoint(String rol, String token) {
    switch (rol.toLowerCase()) {
      case 'administrador':
        return nuevoPasswordAdmin(token);
      case 'docente':
        return nuevoPasswordDocente(token);
      case 'estudiante':
      default:
        return nuevoPasswordEstudiante(token);
    }
  }
  
  /// Detecta el rol basándose en el formato del email
  /// Emails @epn.edu.ec = institucionales (docente/admin)
  /// Otros emails = estudiante
  static String detectarRolPorEmail(String email) {
    final emailLower = email.toLowerCase().trim();
    
    if (emailLower.endsWith('@epn.edu.ec')) {
      // Email institucional - por defecto docente
      // El backend intentará primero docente, luego admin
      return 'docente';
    } else {
      // Email normal - estudiante
      return 'estudiante';
    }
  }
  
  /// Obtiene el nombre del campo de email según el rol para el body de las peticiones
  static String getCampoEmailPorRol(String rol) {
    switch (rol.toLowerCase()) {
      case 'administrador':
        return 'email';
      case 'docente':
        return 'emailDocente';
      case 'estudiante':
      default:
        return 'emailEstudiante';
    }
  }
}