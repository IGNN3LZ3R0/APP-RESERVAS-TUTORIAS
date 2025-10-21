import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../servicios/auth_service.dart';

class DocenteService {
  /// Registrar un nuevo docente (solo Admin)
  static Future<Map<String, dynamic>?> registrarDocente({
    required String nombreDocente,
    required String cedulaDocente,
    required String emailDocente,
    required String celularDocente,
    required String oficinaDocente,
    required String emailAlternativoDocente,
    required String fechaNacimientoDocente,
    required String fechaIngresoDocente,
    required String semestreAsignado,
    required List<String> asignaturas,
  }) async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        return {'error': 'No hay sesión activa'};
      }

      final response = await http.post(
        Uri.parse(ApiConfig.registrarDocente),
        headers: ApiConfig.getHeaders(token: token),
        body: jsonEncode({
          'nombreDocente': nombreDocente,
          'cedulaDocente': cedulaDocente,
          'emailDocente': emailDocente,
          'celularDocente': celularDocente,
          'oficinaDocente': oficinaDocente,
          'emailAlternativoDocente': emailAlternativoDocente,
          'fechaNacimientoDocente': fechaNacimientoDocente,
          'fechaIngresoDocente': fechaIngresoDocente,
          'semestreAsignado': semestreAsignado,
          'asignaturas': asignaturas,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final error = jsonDecode(response.body);
        return {'error': error['msg'] ?? 'Error al registrar docente'};
      }
    } catch (e) {
      print('Error en registrarDocente: $e');
      return {'error': 'Error de conexión. Verifica tu internet.'};
    }
  }

  /// Listar todos los docentes
  static Future<List<Map<String, dynamic>>> listarDocentes() async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        return [];
      }

      final response = await http.get(
        Uri.parse(ApiConfig.listarDocentes),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> docentes = data['docentes'] ?? [];
        return docentes.map((doc) => doc as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      print('Error en listarDocentes: $e');
      return [];
    }
  }

  /// Obtener detalle de un docente
  static Future<Map<String, dynamic>?> detalleDocente(String id) async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        return {'error': 'No hay sesión activa'};
      }

      final response = await http.get(
        Uri.parse(ApiConfig.detalleDocente(id)),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final error = jsonDecode(response.body);
        return {'error': error['msg'] ?? 'Error al obtener docente'};
      }
    } catch (e) {
      print('Error en detalleDocente: $e');
      return {'error': 'Error de conexión.'};
    }
  }

  /// Eliminar docente (deshabilitar)
  static Future<Map<String, dynamic>?> eliminarDocente({
    required String id,
    required String salidaDocente,
  }) async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        return {'error': 'No hay sesión activa'};
      }

      final response = await http.delete(
        Uri.parse(ApiConfig.eliminarDocente(id)),
        headers: ApiConfig.getHeaders(token: token),
        body: jsonEncode({
          'salidaDocente': salidaDocente,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final error = jsonDecode(response.body);
        return {'error': error['msg'] ?? 'Error al eliminar docente'};
      }
    } catch (e) {
      print('Error en eliminarDocente: $e');
      return {'error': 'Error de conexión.'};
    }
  }

  /// Actualizar docente
  static Future<Map<String, dynamic>?> actualizarDocente({
    required String id,
    required String nombreDocente,
    required String cedulaDocente,
    required String emailDocente,
    required String celularDocente,
    required String oficinaDocente,
    required String emailAlternativoDocente,
    required String fechaNacimientoDocente,
    required String fechaIngresoDocente,
    required String semestreAsignado,
    required List<String> asignaturas,
  }) async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        return {'error': 'No hay sesión activa'};
      }

      final response = await http.put(
        Uri.parse(ApiConfig.actualizarPerfilDocente(id)),
        headers: ApiConfig.getHeaders(token: token),
        body: jsonEncode({
          'nombreDocente': nombreDocente,
          'cedulaDocente': cedulaDocente,
          'emailDocente': emailDocente,
          'celularDocente': celularDocente,
          'oficinaDocente': oficinaDocente,
          'emailAlternativoDocente': emailAlternativoDocente,
          'fechaNacimientoDocente': fechaNacimientoDocente,
          'fechaIngresoDocente': fechaIngresoDocente,
          'semestreAsignado': semestreAsignado,
          'asignaturas': asignaturas,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final error = jsonDecode(response.body);
        return {'error': error['msg'] ?? 'Error al actualizar docente'};
      }
    } catch (e) {
      print('Error en actualizarDocente: $e');
      return {'error': 'Error de conexión.'};
    }
  }
}