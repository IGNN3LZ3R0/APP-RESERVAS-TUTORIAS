import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../modelos/usuario.dart';
import '../servicios/perfil_service.dart';
import '../servicios/auth_service.dart';

class EditarPerfilScreen extends StatefulWidget {
  final Usuario usuario;

  const EditarPerfilScreen({Key? key, required this.usuario}) : super(key: key);

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _oficinaController = TextEditingController();
  final _celularController = TextEditingController();
  final _emailAlternativoController = TextEditingController();
  
  File? _imagenSeleccionada;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  void _cargarDatos() {
    _nombreController.text = widget.usuario.nombre;
    _emailController.text = widget.usuario.email;
    
    if (widget.usuario.esEstudiante) {
      _apellidoController.text = widget.usuario.apellido ?? '';
      _telefonoController.text = widget.usuario.telefono ?? '';
    } else if (widget.usuario.esDocente) {
      _cedulaController.text = widget.usuario.cedula ?? '';
      _oficinaController.text = widget.usuario.oficina ?? '';
      _celularController.text = widget.usuario.celular ?? '';
      _emailAlternativoController.text = widget.usuario.emailAlternativo ?? '';
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _cedulaController.dispose();
    _oficinaController.dispose();
    _celularController.dispose();
    _emailAlternativoController.dispose();
    super.dispose();
  }

  // Mostrar opciones para seleccionar imagen
  Future<void> _mostrarOpcionesImagen() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Seleccionar foto',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF1565C0)),
                title: const Text('Tomar foto'),
                onTap: () {
                  Navigator.pop(context);
                  _seleccionarImagen(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF1565C0)),
                title: const Text('Elegir de galería'),
                onTap: () {
                  Navigator.pop(context);
                  _seleccionarImagen(ImageSource.gallery);
                },
              ),
              if (_imagenSeleccionada != null || widget.usuario.fotoPerfil != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Eliminar foto'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _imagenSeleccionada = null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Seleccionar imagen desde cámara o galería
  Future<void> _seleccionarImagen(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imagenSeleccionada = File(pickedFile.path);
        });
      }
    } catch (e) {
      _mostrarError('Error al seleccionar imagen: $e');
    }
  }

  // Guardar cambios
  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    Map<String, dynamic>? resultado;

    try {
      if (widget.usuario.esAdministrador) {
        resultado = await PerfilService.actualizarPerfilAdministrador(
          id: widget.usuario.id,
          nombre: _nombreController.text.trim(),
          email: _emailController.text.trim(),
          imagen: _imagenSeleccionada,
        );
      } else if (widget.usuario.esDocente) {
        resultado = await PerfilService.actualizarPerfilDocente(
          id: widget.usuario.id,
          nombre: _nombreController.text.trim(),
          cedula: _cedulaController.text.trim(),
          oficina: _oficinaController.text.trim(),
          email: _emailController.text.trim(),
          emailAlternativo: _emailAlternativoController.text.trim(),
          celular: _celularController.text.trim(),
          imagen: _imagenSeleccionada,
        );
      } else if (widget.usuario.esEstudiante) {
        // Para estudiante solo se puede actualizar la foto
        if (_imagenSeleccionada != null) {
          resultado = await PerfilService.actualizarPerfilEstudiante(
            id: widget.usuario.id,
            imagen: _imagenSeleccionada!,
          );
        } else {
          resultado = {'msg': 'No hay cambios para guardar'};
        }
      }
    } catch (e) {
      resultado = {'error': 'Error inesperado: $e'};
    }

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (resultado != null && resultado.containsKey('error')) {
      _mostrarError(resultado['error']);
    } else {
      _mostrarExito('Perfil actualizado correctamente');
      
      // Obtener usuario actualizado
      final usuarioActualizado = await AuthService.getUsuarioActual();
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return;
      Navigator.pop(context, usuarioActualizado);
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _guardarCambios,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Foto de perfil
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: _imagenSeleccionada != null
                        ? FileImage(_imagenSeleccionada!)
                        : NetworkImage(widget.usuario.fotoPerfilUrl) as ImageProvider,
                    backgroundColor: Colors.grey[300],
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _mostrarOpcionesImagen,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Campos según el rol
            if (widget.usuario.esAdministrador) ...[
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa tu nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa tu correo';
                  }
                  if (!value.contains('@')) {
                    return 'Ingresa un correo válido';
                  }
                  return null;
                },
              ),
            ] else if (widget.usuario.esDocente) ...[
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa tu nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cedulaController,
                decoration: const InputDecoration(
                  labelText: 'Cédula',
                  prefixIcon: Icon(Icons.badge),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo institucional',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailAlternativoController,
                decoration: const InputDecoration(
                  labelText: 'Correo alternativo',
                  prefixIcon: Icon(Icons.alternate_email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _celularController,
                decoration: const InputDecoration(
                  labelText: 'Celular',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _oficinaController,
                decoration: const InputDecoration(
                  labelText: 'Oficina',
                  prefixIcon: Icon(Icons.meeting_room),
                ),
              ),
            ] else if (widget.usuario.esEstudiante) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Información Personal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: const Text('Nombre'),
                        subtitle: Text(widget.usuario.nombre),
                      ),
                      ListTile(
                        leading: const Icon(Icons.email),
                        title: const Text('Correo'),
                        subtitle: Text(widget.usuario.email),
                      ),
                      if (widget.usuario.telefono != null)
                        ListTile(
                          leading: const Icon(Icons.phone),
                          title: const Text('Teléfono'),
                          subtitle: Text(widget.usuario.telefono!),
                        ),
                      const Divider(),
                      const Text(
                        'Para estudiantes solo se puede cambiar la foto de perfil.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Botón guardar
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _guardarCambios,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Guardar Cambios',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}