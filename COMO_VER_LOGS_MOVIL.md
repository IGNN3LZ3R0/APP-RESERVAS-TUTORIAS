# 📱 Cómo Ver Logs de Flutter en Dispositivo Móvil

## Opción 1: Conectar por USB (Recomendado)

### Android
1. **Habilita depuración USB** en tu dispositivo:
   - Ve a `Ajustes` → `Acerca del teléfono`
   - Toca 7 veces en "Número de compilación"
   - Regresa a `Ajustes` → `Opciones de desarrollador`
   - Activa "Depuración USB"

2. **Conecta tu teléfono por USB** a tu computadora

3. **Abre PowerShell** en la carpeta del proyecto:
   ```powershell
   cd C:\Users\ignne\Desktop\app_tesis_final\app_tesis
   ```

4. **Verifica la conexión**:
   ```powershell
   flutter devices
   ```
   Deberías ver tu dispositivo listado.

5. **Ver logs en tiempo real**:
   ```powershell
   flutter logs
   ```
   O con más detalle:
   ```powershell
   flutter logs --verbose
   ```

6. **Ver logs del sistema Android**:
   ```powershell
   adb logcat | Select-String "flutter"
   ```

### Filtrar logs específicos
```powershell
# Solo logs que contienen "Estudiante" o "Usuario"
flutter logs | Select-String "Estudiante|Usuario|📦|✅|❌|🔄|💾"

# Guardar logs en un archivo
flutter logs > logs_app.txt
```

## Opción 2: Sin Cable (Apps de Logging)

### Usar Logcat Reader
1. Instala la app **Logcat Reader** desde Play Store
2. Dale permisos de lectura de logs
3. Filtra por "flutter" o por tu paquete

### Usar DevTools remotamente
1. En tu computadora, ejecuta:
   ```powershell
   flutter pub global activate devtools
   flutter pub global run devtools
   ```
2. Conecta tu dispositivo a la misma red WiFi
3. Accede desde el navegador

## Opción 3: Implementar Logging en la App

### 1. Agregar logger package
En `pubspec.yaml`:
```yaml
dependencies:
  logger: ^2.0.2+1
```

### 2. Crear un servicio de logs
```dart
// lib/servicios/log_service.dart
import 'package:logger/logger.dart';

class LogService {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printEmojis: true,
    ),
  );

  static void info(String message) => _logger.i(message);
  static void error(String message, [dynamic error]) => _logger.e(message, error: error);
  static void debug(String message) => _logger.d(message);
  static void warning(String message) => _logger.w(message);
}
```

### 3. Ver logs en producción con Firebase Crashlytics
```yaml
dependencies:
  firebase_crashlytics: ^3.4.9
```

```dart
// En main.dart
await FirebaseCrashlytics.instance.log('Usuario actualizado: $nombre');
```

## 🎯 Para Este Problema Específico

### Conecta tu teléfono por USB y ejecuta:
```powershell
cd C:\Users\ignne\Desktop\app_tesis_final\app_tesis
flutter logs | Select-String "Usuario|Estudiante|nombre|email|📦|✅|🔄|💾|Respuesta del backend|Datos del estudiante"
```

Esto te mostrará **todos los logs relevantes** para depurar el problema del nombre que no aparece.

### Capturar logs durante la actualización
1. Conecta el teléfono por USB
2. Ejecuta `flutter logs` en PowerShell
3. En la app, ve a **Editar Perfil**
4. Cambia el nombre
5. Guarda
6. **Observa los logs** en la consola
7. Busca los mensajes que agregamos con emojis (✅, 📦, 🔄, etc.)

Si ves el log `✅ Respuesta del backend` pero no ves `📦 Datos del estudiante recibidos`, entonces **el problema está en la estructura de la respuesta del backend**.

## 🔍 Debugging sin USB

Si no puedes conectar por USB, agrega logs visuales temporales en la app:

```dart
// En editar_perfil_screen.dart, después de guardar:
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Debug Info'),
    content: SingleChildScrollView(
      child: Text('Resultado: ${resultado.toString()}'),
    ),
  ),
);
```

Esto te mostrará la respuesta completa en un diálogo.
