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
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
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
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
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
  /// Backend devuelve: { token, rol, nombre, apellido, telefono, _id, emailEstudiante, fotoPerfil }
  /// NOTA: Tu backend tiene 'nombre' y 'apellido' separados, pero en tu modelo es 'nombreEstudiante'
  static Future<Map<String, dynamic>?> loginEstudiante({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.loginEstudiante),
        headers: ApiConfig.getHeaders(),
        body: jsonEncode({
          'emailEstudiante': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Combinar nombre y apellido si vienen separados
        String nombreCompleto = data['nombre'] ?? '';
        if (data['apellido'] != null && data['apellido'].isNotEmpty) {
          nombreCompleto += ' ${data['apellido']}';
        }
        
        // Guardar datos en SharedPreferences
        await _guardarSesion(
          token: data['token'],
          rol: 'Estudiante',
          usuarioJson: {
            '_id': data['_id'],
            'nombreEstudiante': nombreCompleto,
            'emailEstudiante': data['emailEstudiante'],
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
  
  // ========== RECUPERAR CONTRASEÑA ==========
  
  /// Solicitar recuperación de contraseña
  static Future<Map<String, dynamic>?> recuperarPassword({
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.recuperarPassword),
        headers: ApiConfig.getHeaders(),
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final error = jsonDecode(response.body);
        return {'error': error['msg'] ?? 'Error al solicitar recuperación'};
      }
    } catch (e) {
      print('Error en recuperarPassword: $e');
      return {'error': 'Error de conexión.'};
    }
  }
  
  /// Crear nueva contraseña
  static Future<Map<String, dynamic>?> crearNuevoPassword({
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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final error = jsonDecode(response.body);
        return {'error': error['msg'] ?? 'Error al cambiar contraseña'};
      }
    } catch (e) {
      print('Error en crearNuevoPassword: $e');
      return {'error': 'Error de conexión.'};
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
}