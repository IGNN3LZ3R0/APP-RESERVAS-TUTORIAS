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
  
  // Confirmar email
  static String confirmarEmail(String token) => '$baseUrl/confirmar/$token';
  
  // Recuperar contraseña
  static const String recuperarPassword = '$baseUrl/recuperarpassword';
  static String comprobarToken(String token) => '$baseUrl/recuperarpassword/$token';
  static String nuevoPassword(String token) => '$baseUrl/nuevopassword/$token';
  
  // ========== ENDPOINTS DE PERFIL ==========
  
  static const String perfilAdministrador = '$baseUrl/perfil';
  static const String perfilDocente = '$baseUrl/docente/perfil';
  static const String perfilEstudiante = '$baseUrl/estudiante/perfil';
  
  // Actualizar perfil
  static String actualizarPerfilAdmin(String id) => '$baseUrl/administrador/$id';
  static String actualizarPerfilDocente(String id) => '$baseUrl/docente/actualizar/$id';
  static String actualizarPerfilEstudiante(String id) => '$baseUrl/estudiante/$id';
  
  // Actualizar contraseña
  static String actualizarPasswordAdmin(String id) => '$baseUrl/administrador/actualizarpassword/$id';
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
}