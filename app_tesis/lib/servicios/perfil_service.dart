// ✅ FUNCIÓN CORREGIDA - actualizarPerfilDocente
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../modelos/usuario.dart';
import '../servicios/auth_service.dart';

class PerfilService {
  // ========== ACTUALIZAR PERFIL ADMINISTRADOR ==========
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

      request.headers.addAll(ApiConfig.getMultipartHeaders(token: token));

      if (nombre != null && nombre.isNotEmpty) {
        request.fields['nombreAdministrador'] = nombre;
      }
      if (email != null && email.isNotEmpty) {
        request.fields['email'] = email;
      }

      if (imagen != null) {
        request.files.add(
          await http.MultipartFile.fromPath('imagen', imagen.path),
        );
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

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

  // ========== ✅ ACTUALIZAR PERFIL DOCENTE (CORREGIDO) ==========
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

      // ✅ URL correcta
      final url = '${ApiConfig.baseUrl}/docente/perfil/$id';
      print('🔗 URL de actualización: $url');

      var request = http.MultipartRequest('PUT', Uri.parse(url));

      // ✅ Header con token
      request.headers['Authorization'] = 'Bearer $token';
      print('📋 Headers configurados con Authorization');

      // ==========================================
      // ✅ CAMPOS BÁSICOS
      // ==========================================
      if (nombre != null && nombre.isNotEmpty) {
        request.fields['nombreDocente'] = nombre;
        print('📝 Campo agregado: nombreDocente = $nombre');
      }

      if (cedula != null && cedula.isNotEmpty) {
        request.fields['cedulaDocente'] = cedula;
        print('📝 Campo agregado: cedulaDocente = $cedula');
      }

      if (fechaNacimiento != null && fechaNacimiento.isNotEmpty) {
        request.fields['fechaNacimientoDocente'] = fechaNacimiento;
      }

      if (oficina != null && oficina.isNotEmpty) {
        request.fields['oficinaDocente'] = oficina;
        print('📝 Campo agregado: oficinaDocente = $oficina');
      }

      if (emailAlternativo != null && emailAlternativo.isNotEmpty) {
        request.fields['emailAlternativoDocente'] = emailAlternativo;
        print('📝 Campo agregado: emailAlternativoDocente = $emailAlternativo');
      }

      if (celular != null && celular.isNotEmpty) {
        request.fields['celularDocente'] = celular;
        print('📝 Campo agregado: celularDocente = $celular');
      }

      // ==========================================
      // ✅ SEMESTRE
      // ==========================================
      if (semestreAsignado != null && semestreAsignado.isNotEmpty) {
        request.fields['semestreAsignado'] = semestreAsignado;
        print('📝 Campo agregado: semestreAsignado = $semestreAsignado');
      }

      // ==========================================
      // ✅ ASIGNATURAS (CRÍTICO)
      // ==========================================
      if (asignaturas != null) {
        // ✅ ENVIAR COMO JSON STRING (el backend espera esto)
        final asignaturasJson = jsonEncode(asignaturas);
        request.fields['asignaturas'] = asignaturasJson;

        print('📝 Campo agregado: asignaturas');
        print('   Cantidad: ${asignaturas.length} materias');
        print('   Materias: ${asignaturas.join(", ")}');
        print('   JSON enviado: $asignaturasJson');
      }

      // ==========================================
      // ✅ IMAGEN
      // ==========================================
      if (imagen != null) {
        request.files.add(
          await http.MultipartFile.fromPath('imagen', imagen.path),
        );
        print('📸 Imagen agregada al request');
      }

      // ==========================================
      // ✅ EJECUTAR REQUEST
      // ==========================================
      print('🚀 Enviando request...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📬 Status: ${response.statusCode}');
      print('📄 Body: ${response.body}');

      // ==========================================
      // ✅ RESPUESTA EXITOSA
      // ==========================================
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['docente'] != null) {
          final usuarioActualizado = Usuario.fromJson(
            data['docente'],
            'Docente',
          );
          await AuthService.actualizarUsuario(usuarioActualizado);

          print('✅ Usuario en SharedPreferences actualizado');
          print('   Semestre: ${usuarioActualizado.semestreAsignado}');
          print('   Asignaturas: ${usuarioActualizado.asignaturas}');
        }

        return data;
      }
      // ==========================================
      // ✅ ERRORES 401 / 403
      // ==========================================
      else if (response.statusCode == 401 || response.statusCode == 403) {
        final error = jsonDecode(response.body);
        print('❌ Error de autorización: ${error['msg']}');
        return {
          'error': 'Acceso denegado. Por favor inicia sesión nuevamente.',
        };
      }
      // ==========================================
      // ✅ OTRO ERROR DEL BACKEND
      // ==========================================
      else {
        final error = jsonDecode(response.body);
        print('❌ Error en servidor: ${error['msg']}');
        return {'error': error['msg'] ?? 'Error al actualizar perfil'};
      }
    } catch (e) {
      print('❌ Error en actualizarPerfilDocente: $e');
      return {'error': 'Error de conexión: $e'};
    }
  }

  // ========== ACTUALIZAR PERFIL ESTUDIANTE ==========
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

      if (nombre != null && nombre.isNotEmpty) {
        request.fields['nombreEstudiante'] = nombre;
      }
      if (telefono != null && telefono.isNotEmpty) {
        request.fields['telefono'] = telefono;
      }
      if (email != null && email.isNotEmpty) {
        request.fields['emailEstudiante'] = email;
      }

      if (imagen != null) {
        request.files.add(
          await http.MultipartFile.fromPath('imagen', imagen.path),
        );
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      print('📡 Status Code: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        print('✅ Respuesta del backend:');
        print('   Keys: ${data.keys.join(", ")}');
        print('   success: ${data['success']}');
        print('   msg: ${data['msg']}');

        if (data['estudiante'] != null) {
          print('📦 Datos del estudiante recibidos:');
          print('   _id: ${data['estudiante']['_id']}');
          print(
            '   nombreEstudiante: ${data['estudiante']['nombreEstudiante']}',
          );
          print('   emailEstudiante: ${data['estudiante']['emailEstudiante']}');
          print('   telefono: ${data['estudiante']['telefono']}');
          print('   fotoPerfil: ${data['estudiante']['fotoPerfil']}');

          final usuarioActualizado = Usuario.fromJson(
            data['estudiante'],
            'Estudiante',
          );

          print('🔄 Usuario actualizado creado:');
          print('   ID: ${usuarioActualizado.id}');
          print('   Nombre: ${usuarioActualizado.nombre}');
          print('   Email: ${usuarioActualizado.email}');
          print('   Foto: ${usuarioActualizado.fotoPerfil}');

          await AuthService.actualizarUsuario(usuarioActualizado);
          print('💾 Usuario guardado en SharedPreferences');
        } else {
          print('⚠️ ADVERTENCIA: data["estudiante"] es null');
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

  // ========== CAMBIAR CONTRASEÑA ADMIN / DOCENTE / ESTUDIANTE ==========
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
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        return {'error': error['msg'] ?? 'Error al cambiar contraseña'};
      }
    } catch (e) {
      print('Error en cambiarPasswordAdministrador: $e');
      return {'error': 'Error de conexión: $e'};
    }
  }

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
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        return {'error': error['msg'] ?? 'Error al cambiar contraseña'};
      }
    } catch (e) {
      print('Error en cambiarPasswordDocente: $e');
      return {'error': 'Error de conexión: $e'};
    }
  }

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
        return jsonDecode(response.body);
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
