import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../modelos/usuario.dart';
import '../servicios/auth_service.dart';

class PerfilService {
  // ========== ACTUALIZAR PERFIL ==========

  /// Actualizar perfil de Administrador
  static Future<Map<String, dynamic>?> actualizarPerfilAdministrador({
    required String id,
    String? nombre,
    String? email,
    File? imagen,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return {'error': 'No hay sesión activa'};

      var request = http.MultipartRequest(
        'PUT',
        Uri.parse(ApiConfig.actualizarPerfilAdmin(id)),
      );

      // Agregar headers
      request.headers.addAll(ApiConfig.getMultipartHeaders(token: token));

      // Agregar campos - SIEMPRE enviar los campos aunque no cambien
      if (nombre != null && nombre.isNotEmpty) {
        request.fields['nombreAdministrador'] = nombre;
      }
      if (email != null && email.isNotEmpty) {
        request.fields['email'] = email;
      }

      // Agregar imagen si existe
      if (imagen != null) {
        request.files.add(
          await http.MultipartFile.fromPath('imagen', imagen.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Actualizar usuario en SharedPreferences
        if (data['administrador'] != null) {
          final usuarioActualizado = Usuario.fromJson(
            data['administrador'],
            'Administrador',
          );
          await AuthService.actualizarUsuario(usuarioActualizado);
        }

        return data;
      } else {
        final error = jsonDecode(response.body);
        return {'error': error['msg'] ?? 'Error al actualizar perfil'};
      }
    } catch (e) {
      print('Error en actualizarPerfilAdministrador: $e');
      return {'error': 'Error de conexión: $e'};
    }
  }

  /// Actualizar perfil de Docente
  static Future<Map<String, dynamic>?> actualizarPerfilDocente({
    required String id,
    String? nombre,
    String? cedula,
    String? fechaNacimiento,
    String? oficina,
    String? email,
    String? emailAlternativo,
    String? celular,
    String? semestreAsignado,
    List<String>? asignaturas,
    File? imagen,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return {'error': 'No hay sesión activa'};

      print('🔑 Token obtenido: ${token.substring(0, 20)}...');
      print('🆔 Actualizando perfil del docente ID: $id');

      // ✅ USAR LA URL CORRECTA - /docente/perfil/:id
      final url = '${ApiConfig.baseUrl}/docente/perfil/$id';
      print('🔗 URL de actualización: $url');

      var request = http.MultipartRequest('PUT', Uri.parse(url));

      // ✅ HEADERS CON TOKEN
      request.headers['Authorization'] = 'Bearer $token';
      print('📋 Headers configurados con Authorization');

      // Agregar campos básicos del docente
      if (nombre != null && nombre.isNotEmpty) {
        request.fields['nombreDocente'] = nombre;
        print('📝 Campo agregado: nombreDocente = $nombre');
      }
      if (cedula != null && cedula.isNotEmpty) {
        request.fields['cedulaDocente'] = cedula;
      }
      if (fechaNacimiento != null && fechaNacimiento.isNotEmpty) {
        request.fields['fechaNacimientoDocente'] = fechaNacimiento;
      }
      if (oficina != null && oficina.isNotEmpty) {
        request.fields['oficinaDocente'] = oficina;
      }
      if (emailAlternativo != null && emailAlternativo.isNotEmpty) {
        request.fields['emailAlternativoDocente'] = emailAlternativo;
      }
      if (celular != null && celular.isNotEmpty) {
        request.fields['celularDocente'] = celular;
      }

      // Nuevos campos para gestión de materias
      if (semestreAsignado != null && semestreAsignado.isNotEmpty) {
        request.fields['semestreAsignado'] = semestreAsignado;
      }
      if (asignaturas != null && asignaturas.isNotEmpty) {
        request.fields['asignaturas'] = jsonEncode(asignaturas);
      }

      // Agregar imagen si existe
      if (imagen != null) {
        request.files.add(
          await http.MultipartFile.fromPath('imagen', imagen.path),
        );
      }

      print('🚀 Enviando request...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📬 Status code: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Actualizar usuario en SharedPreferences
        if (data['docente'] != null) {
          final usuarioActualizado = Usuario.fromJson(
            data['docente'],
            'Docente',
          );
          await AuthService.actualizarUsuario(usuarioActualizado);
        }

        return data;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Error de autenticación/autorización
        final error = jsonDecode(response.body);
        print('❌ Error de autorización: ${error['msg']}');
        return {'error': 'Acceso denegado. Por favor inicia sesión nuevamente.'};
      } else {
        final error = jsonDecode(response.body);
        print('❌ Error del servidor: ${error['msg']}');
        return {'error': error['msg'] ?? 'Error al actualizar perfil'};
      }
    } catch (e) {
      print('❌ Error en actualizarPerfilDocente: $e');
      return {'error': 'Error de conexión: $e'};
    }
  }

  /// Actualizar perfil de Estudiante
  static Future<Map<String, dynamic>?> actualizarPerfilEstudiante({
    required String id,
    String? nombre,
    String? telefono,
    String? email,
    File? imagen,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return {'error': 'No hay sesión activa'};

      final url = ApiConfig.actualizarPerfilEstudiante(id);
      print('🔗 URL de actualización: $url');

      var request = http.MultipartRequest('PUT', Uri.parse(url));

      request.headers.addAll(ApiConfig.getMultipartHeaders(token: token));

      // Agregar campos editables
      if (nombre != null && nombre.isNotEmpty) {
        request.fields['nombreEstudiante'] = nombre;
        print('📝 Enviando nombre: $nombre');
      }
      if (telefono != null && telefono.isNotEmpty) {
        request.fields['telefono'] = telefono;
        print('📞 Enviando teléfono: $telefono');
      }
      if (email != null && email.isNotEmpty) {
        request.fields['emailEstudiante'] = email;
        print('📧 Enviando email: $email');
      }

      // Agregar imagen si existe
      if (imagen != null) {
        request.files.add(
          await http.MultipartFile.fromPath('imagen', imagen.path),
        );
        print('📸 Enviando imagen');
      }

      print('🚀 Enviando request...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📬 Status code: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Actualizar usuario en SharedPreferences
        if (data['estudiante'] != null) {
          final usuarioActualizado = Usuario.fromJson(
            data['estudiante'],
            'Estudiante',
          );
          await AuthService.actualizarUsuario(usuarioActualizado);
          print('✅ Usuario actualizado en cache');
        }

        return data;
      } else {
        final error = jsonDecode(response.body);
        print('❌ Error del servidor: ${error['msg']}');
        return {'error': error['msg'] ?? 'Error al actualizar perfil'};
      }
    } catch (e) {
      print('❌ Error en actualizarPerfilEstudiante: $e');
      return {'error': 'Error de conexión: $e'};
    }
  }

  // ========== CAMBIAR CONTRASEÑA ==========

  /// Cambiar contraseña de Administrador
  static Future<Map<String, dynamic>?> cambiarPasswordAdministrador({
    required String id,
    required String passwordActual,
    required String passwordNuevo,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return {'error': 'No hay sesión activa'};

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/administrador/actualizarpassword/$id'),
        headers: ApiConfig.getHeaders(token: token),
        body: jsonEncode({
          'passwordactual': passwordActual,
          'passwordnuevo': passwordNuevo,
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
      print('Error en cambiarPasswordAdministrador: $e');
      return {'error': 'Error de conexión: $e'};
    }
  }

  /// Cambiar contraseña de Docente
  static Future<Map<String, dynamic>?> cambiarPasswordDocente({
    required String id,
    required String passwordActual,
    required String passwordNuevo,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return {'error': 'No hay sesión activa'};

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/docente/actualizarpassword/$id'),
        headers: ApiConfig.getHeaders(token: token),
        body: jsonEncode({
          'passwordactual': passwordActual,
          'passwordnuevo': passwordNuevo,
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
      print('Error en cambiarPasswordDocente: $e');
      return {'error': 'Error de conexión: $e'};
    }
  }

  /// Cambiar contraseña de Estudiante
  static Future<Map<String, dynamic>?> cambiarPasswordEstudiante({
    required String id,
    required String passwordActual,
    required String passwordNuevo,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return {'error': 'No hay sesión activa'};

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/estudiante/actualizarpassword/$id'),
        headers: ApiConfig.getHeaders(token: token),
        body: jsonEncode({
          'passwordactual': passwordActual,
          'passwordnuevo': passwordNuevo,
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
      print('Error en cambiarPasswordEstudiante: $e');
      return {'error': 'Error de conexión: $e'};
    }
  }
}