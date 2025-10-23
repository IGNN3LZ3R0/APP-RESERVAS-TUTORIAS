import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../modelos/usuario.dart';

class AuthService {
  // ========== CONSTANTES PARA SHAREDPREFERENCES ==========
  static const String _keyToken = 'token';
  static const String _keyUsuario = 'usuario';
  static const String _keyRol = 'rol';

  // ========== LOGIN ==========

  /// Login para Administrador
  /// Backend devuelve: { token, rol, nombreAdministrador, _id, email, fotoPerfilAdmin }
  static Future<Map<String, dynamic>?> loginAdministrador({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.loginAdministrador),
        headers: ApiConfig.getHeaders(),
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Guardar datos en SharedPreferences
        await _guardarSesion(
          token: data['token'],
          rol: 'Administrador',
          usuarioJson: {
            '_id': data['_id'],
            'nombreAdministrador': data['nombreAdministrador'],
            'email': data['email'],
            'fotoPerfilAdmin': data['fotoPerfilAdmin'],
            'rol': data['rol'],
            'status': true,
            'confirmEmail': true,
            'isOAuth': false,
          },
        );

        return data;
      } else {
        final error = jsonDecode(response.body);
        return {'error': error['msg'] ?? 'Error al iniciar sesión'};
      }
    } catch (e) {
      print('Error en loginAdministrador: $e');
      return {'error': 'Error de conexión. Verifica tu internet.'};
    }
  }

  /// Login para Docente
  /// Backend devuelve: { token, rol, _id, avatarDocente }
  /// NOTA: El backend solo devuelve estos 4 campos, necesitamos obtener el perfil completo después
  static Future<Map<String, dynamic>?> loginDocente({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.loginDocente),
        headers: ApiConfig.getHeaders(),
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Guardar token temporalmente
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyToken, data['token']);
        await prefs.setString(_keyRol, 'Docente');

        // Obtener perfil completo del docente
        final perfilResponse = await http.get(
          Uri.parse(ApiConfig.perfilDocente),
          headers: ApiConfig.getHeaders(token: data['token']),
        );

        if (perfilResponse.statusCode == 200) {
          final perfilData = jsonDecode(perfilResponse.body);

          // Guardar sesión completa
          await _guardarSesion(
            token: data['token'],
            rol: 'Docente',
            usuarioJson: {
              '_id': perfilData['_id'],
              'nombreDocente': perfilData['nombreDocente'],
              'emailDocente': perfilData['emailDocente'],
              'cedulaDocente': perfilData['cedulaDocente'],
              'celularDocente': perfilData['celularDocente'],
              'oficinaDocente': perfilData['oficinaDocente'],
              'emailAlternativoDocente': perfilData['emailAlternativoDocente'],
              'avatarDocente': perfilData['avatarDocente'],
              'asignaturas': perfilData['asignaturas'],
              'semestreAsignado': perfilData['semestreAsignado'],
              'fechaNacimientoDocente': perfilData['fechaNacimientoDocente'],
              'fechaIngresoDocente': perfilData['fechaIngresoDocente'],
              'rol': data['rol'],
              'estadoDocente': true,
              'confirmEmail': true,
              'isOAuth': false,
            },
          );

          return data;
        }

        return data;
      } else {
        final error = jsonDecode(response.body);
        return {'error': error['msg'] ?? 'Error al iniciar sesión'};
      }
    } catch (e) {
      print('Error en loginDocente: $e');
      return {'error': 'Error de conexión. Verifica tu internet.'};
    }
  }

  /// Login para Estudiante
  /// Backend devuelve: { token, rol, nombreEstudiante, telefono, _id, emailEstudiante, fotoPerfil }
  static Future<Map<String, dynamic>?> loginEstudiante({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.loginEstudiante),
        headers: ApiConfig.getHeaders(),
        body: jsonEncode({'emailEstudiante': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Guardar datos en SharedPreferences
        await _guardarSesion(
          token: data['token'],
          rol: 'Estudiante',
          usuarioJson: {
            '_id': data['_id'],
            'nombreEstudiante': data['nombreEstudiante'] ?? '',
            'emailEstudiante': data['emailEstudiante'] ?? email,
            'telefono': data['telefono'],
            'fotoPerfil': data['fotoPerfil'],
            'rol': data['rol'],
            'status': true,
            'confirmEmail': true,
            'isOAuth': false,
          },
        );

        return data;
      } else {
        final error = jsonDecode(response.body);
        return {'error': error['msg'] ?? 'Error al iniciar sesión'};
      }
    } catch (e) {
      print('Error en loginEstudiante: $e');
      return {'error': 'Error de conexión. Verifica tu internet.'};
    }
  }

  // ========== REGISTRO ==========

  /// Registro de estudiante
  static Future<Map<String, dynamic>?> registrarEstudiante({
    required String nombre,
    required String email,
    required String password,
    String? telefono,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.registroEstudiante),
        headers: ApiConfig.getHeaders(),
        body: jsonEncode({
          'nombreEstudiante': nombre,
          'emailEstudiante': email,
          'password': password,
          'telefono': telefono ?? '',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final error = jsonDecode(response.body);
        return {'error': error['msg'] ?? 'Error al registrar'};
      }
    } catch (e) {
      print('Error en registrarEstudiante: $e');
      return {'error': 'Error de conexión. Verifica tu internet.'};
    }
  }

  // ========== SESIÓN ==========

  /// Guarda la sesión del usuario
  static Future<void> _guardarSesion({
    required String token,
    required String rol,
    required Map<String, dynamic> usuarioJson,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyRol, rol);
    await prefs.setString(_keyUsuario, jsonEncode(usuarioJson));
  }

  /// Obtiene el token guardado
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  /// Obtiene el rol guardado
  static Future<String?> getRol() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRol);
  }

  /// Obtiene el usuario actual desde SharedPreferences
  static Future<Usuario?> getUsuarioActual() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usuarioJson = prefs.getString(_keyUsuario);
      final rol = prefs.getString(_keyRol);

      if (usuarioJson != null && rol != null) {
        final Map<String, dynamic> data = jsonDecode(usuarioJson);
        return Usuario.fromJson(data, rol);
      }
      return null;
    } catch (e) {
      print('Error en getUsuarioActual: $e');
      return null;
    }
  }

  /// Verifica si hay una sesión activa
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Cierra la sesión del usuario
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUsuario);
    await prefs.remove(_keyRol);
    await prefs.clear();
  }

  /// Actualiza la información del usuario en SharedPreferences
  static Future<void> actualizarUsuario(Usuario usuario) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsuario, jsonEncode(usuario.toJson()));
  }

  // ========== OBTENER PERFIL DESDE EL SERVIDOR ==========

  /// Obtiene el perfil completo del usuario desde el servidor
  static Future<Usuario?> obtenerPerfil() async {
    try {
      final token = await getToken();
      final rol = await getRol();

      if (token == null || rol == null) return null;

      final endpoint = ApiConfig.getPerfilEndpoint(rol);

      final response = await http.get(
        Uri.parse(endpoint),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final usuario = Usuario.fromJson(data, rol);

        // Actualizar en SharedPreferences
        await actualizarUsuario(usuario);

        return usuario;
      }
      return null;
    } catch (e) {
      print('Error en obtenerPerfil: $e');
      return null;
    }
  }

  // ========== CONFIRMAR EMAIL ==========

  /// Confirma el email del estudiante con el token recibido por deep link
  static Future<Map<String, dynamic>?> confirmarEmail(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.confirmarEmail(token)),
        headers: ApiConfig.getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        print('✅ Cuenta confirmada exitosamente');
        return data;
      } else {
        print('❌ Error confirmando cuenta: ${data['msg']}');
        return {'error': data['msg'] ?? 'Error al confirmar cuenta'};
      }
    } catch (e) {
      print('❌ Error en confirmarEmail: $e');
      return {'error': 'Error de conexión. Verifica tu internet.'};
    }
  }

  // ========== COMPROBAR TOKEN DE RECUPERACIÓN ==========

  /// Verifica si el token de recuperación de contraseña es válido
  static Future<Map<String, dynamic>?> comprobarTokenPassword(
    String token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.comprobarToken(token)),
        headers: ApiConfig.getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        print('✅ Token válido');
        return data;
      } else {
        print('❌ Token inválido: ${data['msg']}');
        return {'error': data['msg'] ?? 'Token inválido o expirado'};
      }
    } catch (e) {
      print('❌ Error en comprobarTokenPassword: $e');
      return {'error': 'Error de conexión'};
    }
  }

  // ========== CREAR NUEVA CONTRASEÑA ==========

  /// Crea una nueva contraseña usando el token de recuperación
  static Future<Map<String, dynamic>?> crearNuevaPassword({
    required String token,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.nuevoPassword(token)),
        headers: ApiConfig.getHeaders(),
        body: jsonEncode({
          'password': password,
          'confirmpassword': confirmPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        print('✅ Contraseña actualizada');
        return data;
      } else {
        print('❌ Error actualizando contraseña: ${data['msg']}');
        return {'error': data['msg'] ?? 'Error al actualizar contraseña'};
      }
    } catch (e) {
      print('❌ Error en crearNuevaPassword: $e');
      return {'error': 'Error de conexión'};
    }
  }

  // ========== RECUPERAR CONTRASEÑA ==========

  /// Solicita un enlace de recuperación de contraseña
  static Future<Map<String, dynamic>?> recuperarPassword({
    required String email,
  }) async {
    try {
      print('📧 Enviando solicitud de recuperación para: $email');

      final response = await http.post(
        Uri.parse(ApiConfig.recuperarPassword),
        headers: ApiConfig.getHeaders(),
        body: jsonEncode({'emailEstudiante': email}),
      );

      print('📬 Código de estado: ${response.statusCode}');
      print('📝 Respuesta: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data['success'] == true || !data.containsKey('success')) {
          print('✅ ${data['msg']}');
          return {'msg': data['msg']};
        } else {
          print('⚠️ Respuesta con success=false: ${data['msg']}');
          return {'error': data['msg']};
        }
      } else {
        print('❌ Error en recuperación: ${data['msg']}');
        return {'error': data['msg'] ?? 'Error al procesar la solicitud'};
      }
    } catch (e) {
      print('❌ Error en recuperarPassword: $e');
      return {'error': 'Error de conexión. Verifica tu internet.'};
    }
  }
}
