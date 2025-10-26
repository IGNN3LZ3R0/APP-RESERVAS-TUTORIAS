import 'package:flutter/material.dart';
import '../../servicios/docente_service.dart';

class CrearDocenteScreen extends StatefulWidget {
  const CrearDocenteScreen({super.key});

  @override
  State<CrearDocenteScreen> createState() => _CrearDocenteScreenState();
}

class _CrearDocenteScreenState extends State<CrearDocenteScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores
  final _nombreController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _emailController = TextEditingController();
  final _celularController = TextEditingController();
  final _oficinaController = TextEditingController();
  final _emailAlternativoController = TextEditingController();
  
  bool _isLoading = false;
  DateTime? _fechaNacimiento;
  DateTime? _fechaIngreso;

  @override
  void dispose() {
    _nombreController.dispose();
    _cedulaController.dispose();
    _emailController.dispose();
    _celularController.dispose();
    _oficinaController.dispose();
    _emailAlternativoController.dispose();
    super.dispose();
  }

  String? _validarRequerido(String? value, String campo) {
    if (value == null || value.isEmpty) {
      return '$campo es obligatorio';
    }
    return null;
  }

  String? _validarEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El email es obligatorio';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Ingresa un email válido';
    }
    return null;
  }

  String? _validarCedula(String? value) {
    if (value == null || value.isEmpty) {
      return 'La cédula es obligatoria';
    }
    if (value.length != 10) {
      return 'La cédula debe tener 10 dígitos';
    }
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'La cédula solo debe contener números';
    }
    return null;
  }

  String? _validarTelefono(String? value) {
    if (value == null || value.isEmpty) {
      return 'El celular es obligatorio';
    }
    if (value.length < 10) {
      return 'El celular debe tener al menos 10 dígitos';
    }
    return null;
  }

  Future<void> _seleccionarFecha(BuildContext context, bool esNacimiento) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1565C0),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        if (esNacimiento) {
          _fechaNacimiento = picked;
        } else {
          _fechaIngreso = picked;
        }
      });
    }
  }

  Future<void> _registrarDocente() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_fechaNacimiento == null) {
      _mostrarError('Por favor selecciona la fecha de nacimiento');
      return;
    }

    // ⭐ NUEVO: Validar edad mínima (18 años) y año mínimo (1960)
    final fechaActual = DateTime.now();
    final edad = fechaActual.year - _fechaNacimiento!.year;
    final mesActual = fechaActual.month;
    final diaActual = fechaActual.day;

    // Ajustar edad si aún no ha cumplido años este año
    int edadReal = edad;
    if (mesActual < _fechaNacimiento!.month ||
        (mesActual == _fechaNacimiento!.month && diaActual < _fechaNacimiento!.day)) {
      edadReal = edad - 1;
    }

    // Validar año mínimo
    if (_fechaNacimiento!.year < 1960) {
      _mostrarError('El año de nacimiento debe ser 1960 o posterior');
      return;
    }

    // Validar edad mínima
    if (edadReal < 18) {
      _mostrarError('El docente debe tener al menos 18 años');
      return;
    }
    // ⭐ FIN NUEVO

    if (_fechaIngreso == null) {
      _mostrarError('Por favor selecciona la fecha de ingreso');
      return;
    }

    setState(() => _isLoading = true);

    final resultado = await DocenteService.registrarDocente(
      nombreDocente: _nombreController.text.trim(),
      cedulaDocente: _cedulaController.text.trim(),
      emailDocente: _emailController.text.trim(),
      celularDocente: _celularController.text.trim(),
      oficinaDocente: _oficinaController.text.trim(),
      emailAlternativoDocente: _emailAlternativoController.text.trim(),
      fechaNacimientoDocente: _fechaNacimiento!.toIso8601String().split('T')[0],
      fechaIngresoDocente: _fechaIngreso!.toIso8601String().split('T')[0],
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (resultado != null && resultado.containsKey('error')) {
      _mostrarError(resultado['error']);
    } else {
      _mostrarExito('Docente registrado exitosamente. Se envió un correo con las credenciales.');
      
      await Future.delayed(const Duration(seconds: 2));
      
      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Docente'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Información
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'El sistema generará automáticamente una contraseña y la enviará por correo al docente.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Nombre
            TextFormField(
              controller: _nombreController,
              decoration: InputDecoration(
                labelText: 'Nombre Completo',
                prefixIcon: const Icon(Icons.person),
                hintText: 'Dr. Juan Pérez',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) => _validarRequerido(value, 'El nombre'),
            ),
            const SizedBox(height: 16),

            // Cédula
            TextFormField(
              controller: _cedulaController,
              keyboardType: TextInputType.number,
              maxLength: 10,
              decoration: InputDecoration(
                labelText: 'Cédula',
                prefixIcon: const Icon(Icons.badge),
                hintText: '1234567890',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: _validarCedula,
            ),
            const SizedBox(height: 16),

            // Email institucional
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Correo Institucional',
                prefixIcon: const Icon(Icons.email),
                hintText: 'docente@epn.edu.ec',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: _validarEmail,
            ),
            const SizedBox(height: 16),

            // Email alternativo
            TextFormField(
              controller: _emailAlternativoController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Correo Alternativo',
                prefixIcon: const Icon(Icons.alternate_email),
                hintText: 'docente@gmail.com',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: _validarEmail,
            ),
            const SizedBox(height: 16),

            // Celular
            TextFormField(
              controller: _celularController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Celular',
                prefixIcon: const Icon(Icons.phone),
                hintText: '0987654321',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: _validarTelefono,
            ),
            const SizedBox(height: 16),

            // Oficina
            TextFormField(
              controller: _oficinaController,
              decoration: InputDecoration(
                labelText: 'Oficina',
                prefixIcon: const Icon(Icons.meeting_room),
                hintText: 'Edificio A - Oficina 101',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) => _validarRequerido(value, 'La oficina'),
            ),
            const SizedBox(height: 16),

            // Fecha de nacimiento
            InkWell(
              onTap: () => _seleccionarFecha(context, true),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Fecha de Nacimiento',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _fechaNacimiento == null
                      ? 'Seleccionar fecha'
                      : '${_fechaNacimiento!.day}/${_fechaNacimiento!.month}/${_fechaNacimiento!.year}',
                  style: TextStyle(
                    color: _fechaNacimiento == null ? Colors.grey : Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Fecha de ingreso
            InkWell(
              onTap: () => _seleccionarFecha(context, false),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Fecha de Ingreso',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _fechaIngreso == null
                      ? 'Seleccionar fecha'
                      : '${_fechaIngreso!.day}/${_fechaIngreso!.month}/${_fechaIngreso!.year}',
                  style: TextStyle(
                    color: _fechaIngreso == null ? Colors.grey : Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Botón registrar
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _registrarDocente,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Registrar Docente',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}