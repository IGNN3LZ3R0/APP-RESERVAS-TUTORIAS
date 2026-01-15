// lib/servicios/notification_service.dart
import 'dart:async';
import '../modelos/usuario.dart';

/// Servicio global para notificar cambios entre pantallas
class NotificationService {
  // Singleton
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Stream controllers para diferentes eventos
  final _materiasActualizadasController = StreamController<void>.broadcast();
  final _horariosActualizadosController = StreamController<void>.broadcast();
  final _usuarioActualizadoController = StreamController<Usuario>.broadcast();

  // Streams públicos
  Stream<void> get materiasActualizadas =>
      _materiasActualizadasController.stream;
  Stream<void> get horariosActualizados =>
      _horariosActualizadosController.stream;
  Stream<Usuario> get usuarioActualizado =>
      _usuarioActualizadoController.stream;

  // Métodos para notificar eventos
  void notificarMateriasActualizadas() {
    print('🔔 NotificationService: Materias actualizadas');
    if (!_materiasActualizadasController.isClosed) {
      _materiasActualizadasController.add(null);
    }
  }

  void notificarHorariosActualizados() {
    print('🔔 NotificationService: Horarios actualizados');
    if (!_horariosActualizadosController.isClosed) {
      _horariosActualizadosController.add(null);
    }
  }

  void notificarActualizacionUsuario(Usuario usuario) {
    print('🔔 NotificationService: Usuario actualizado - ${usuario.nombre}');
    if (!_usuarioActualizadoController.isClosed) {
      _usuarioActualizadoController.add(usuario);
    }
  }

  // Cleanup
  void dispose() {
    _materiasActualizadasController.close();
    _horariosActualizadosController.close();
    _usuarioActualizadoController.close();
  }
}

// Instancia global
final notificationService = NotificationService();
