import 'package:flutter/material.dart';
import '../../servicios/docente_service.dart';

class EditarDocenteScreen extends StatefulWidget {
  final Map<String, dynamic> docente;

  const EditarDocenteScreen({super.key, required this.docente});

  @override
  State<EditarDocenteScreen> createState() => _EditarDocenteScreenState();
}

class _EditarDocenteScreenState extends State<EditarDocenteScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nombreController;
  late TextEditingController _cedulaController;
  late TextEditingController _emailController;
  late TextEditingController _celularController;
  late TextEditingController _oficinaController;
  late TextEditingController _emailAlternativoController;
  
  bool _isLoading = false;
  DateTime? _fechaNacimiento;
  DateTime? _fechaIngreso;

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  void _cargarDatosIniciales() {
    _nombreController = TextEditingController(text: widget.docente['nombreDocente']);
    _cedulaController = TextEditingController(text: widget.docente['cedulaDocente']);
    _emailController = TextEditingController(text: widget.docente['emailDocente']);
    _celularController = TextEditingController(text: widget.docente['celularDocente']);
    _oficinaController = TextEditingController(text: widget.docente['oficinaDocente']);
    _emailAlternativoController = TextEditingController(text: widget.docente['emailAlternativoDocente']);

    // Parsear fechas
    if (widget.docente['fechaNacimientoDocente'] != null) {
      try {
        _fechaNacimiento = DateTime.parse(widget.docente['fechaNacimientoDocente']);
      } catch (e) {
        _fechaNacimiento = null;
      }
    }

    if (widget.docente['fechaIngresoDocente'] != null) {
      try {
        _fechaIngreso = DateTime.parse(widget.docente['fechaIngresoDocente']);
      } catch (e) {
        _fechaIngreso = null;
      }
    }
  }

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
      initialDate: esNacimiento 
          ? (_fechaNacimiento ?? DateTime.now().subtract(const Duration(days: 365 * 25)))
          : (_fechaIngreso ?? DateTime.now()),
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

  Future<void> _actualizarDocente() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_fechaNacimiento == null) {
      _mostrarError('Por favor selecciona la fecha de nacimiento');
      return;
    }

    // Validar edad mínima (18 años) y año mínimo (1960)
    final fechaActual = DateTime.now();
    final edad = fechaActual.year - _fechaNacimiento!.year;
    final mesActual = fechaActual.month;
    final diaActual = fechaActual.day;

    int edadReal = edad;
    if (mesActual < _fechaNacimiento!.month ||
        (mesActual == _fechaNacimiento!.month && diaActual < _fechaNacimiento!.day)) {
      edadReal = edad - 1;
    }

    if (_fechaNacimiento!.year < 1960) {
      _mostrarError('El año de nacimiento debe ser 1960 o posterior');
      return;
    }

    if (edadReal < 18) {
      _mostrarError('El docente debe tener al menos 18 años');
      return;
    }

    if (_fechaIngreso == null) {
      _mostrarError('Por favor selecciona la fecha de ingreso');
      return;
    }

    setState(() => _isLoading = true);

    final resultado = await DocenteService.actualizarDocente(
      id: widget.docente['_id'],
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
      _mostrarExito('Docente actualizado exitosamente');
      
      await Future.delayed(const Duration(seconds: 1));
      
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
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Docente'),
        elevation: 0,
        backgroundColor: const Color(0xFF1565C0),
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
                        'Actualiza la información del docente.',
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: _validarCedula,
            ),
            const SizedBox(height: 16),

            // Email institucional (solo lectura)
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Correo Institucional',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                helperText: 'No se puede modificar el email institucional',
              ),
            ),
            const SizedBox(height: 16),

            // Email alternativo
            TextFormField(
              controller: _emailAlternativoController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Correo Alternativo',
                prefixIcon: const Icon(Icons.alternate_email),
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

            // Botón actualizar
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _actualizarDocente,
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
                        'Actualizar Docente',
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