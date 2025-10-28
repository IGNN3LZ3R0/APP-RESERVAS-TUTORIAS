import 'package:flutter/material.dart';
import '../../modelos/usuario.dart';
import '../../servicios/perfil_service.dart';
import '../../servicios/auth_service.dart';

class GestionMateriasScreen extends StatefulWidget {
  final Usuario usuario;

  const GestionMateriasScreen({super.key, required this.usuario});

  @override
  State<GestionMateriasScreen> createState() => _GestionMateriasScreenState();
}

class _GestionMateriasScreenState extends State<GestionMateriasScreen> {
  // Materias disponibles por semestre
  final Map<String, List<String>> _materiasPorSemestre = {
    'Nivelacion': [
      'Matemática Básica',
      'Física Básica',
      'Química Básica',
      'Introducción a la Programación',
      'Metodología de Estudio',
      'Comunicación Oral y Escrita',
    ],
    'Primer Semestre': [
      'Cálculo I',
      'Álgebra Lineal',
      'Física I',
      'Programación I',
      'Introducción a la Ingeniería',
      'Comunicación Técnica',
      'Fundamentos de Computación',
    ],
  };

  String _semestreSeleccionado = 'Nivelacion';
  List<String> _materiasSeleccionadas = [];
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _cargarMateriasActuales();
  }

  void _cargarMateriasActuales() {
    // Cargar materias y semestre del docente
    if (widget.usuario.semestreAsignado != null) {
      _semestreSeleccionado = widget.usuario.semestreAsignado!;
    }
    
    if (widget.usuario.asignaturas != null) {
      _materiasSeleccionadas = List.from(widget.usuario.asignaturas!);
    }
  }

  void _toggleMateria(String materia) {
    setState(() {
      if (_materiasSeleccionadas.contains(materia)) {
        _materiasSeleccionadas.remove(materia);
      } else {
        _materiasSeleccionadas.add(materia);
      }
      _hasChanges = true;
    });
  }

  void _cambiarSemestre(String? nuevoSemestre) {
    if (nuevoSemestre == null) return;
    
    setState(() {
      _semestreSeleccionado = nuevoSemestre;
      // Limpiar materias seleccionadas al cambiar de semestre
      _materiasSeleccionadas.clear();
      _hasChanges = true;
    });
  }

  Future<void> _guardarCambios() async {
    if (_materiasSeleccionadas.isEmpty) {
      _mostrarError('Debes seleccionar al menos una materia');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final resultado = await PerfilService.actualizarPerfilDocente(
        id: widget.usuario.id,
        semestreAsignado: _semestreSeleccionado,
        asignaturas: _materiasSeleccionadas,
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (resultado != null && resultado.containsKey('error')) {
        _mostrarError(resultado['error']);
      } else {
        _mostrarExito('Materias actualizadas correctamente');
        
        // Actualizar el usuario en SharedPreferences
        await AuthService.obtenerPerfil();
        
        setState(() => _hasChanges = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarError('Error al guardar: $e');
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
    final materiasDisponibles = _materiasPorSemestre[_semestreSeleccionado] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Materias'),
        backgroundColor: const Color(0xFF1565C0),
        actions: [
          if (_hasChanges && !_isLoading)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _guardarCambios,
              tooltip: 'Guardar cambios',
            ),
        ],
      ),
      body: Column(
        children: [
          // Selector de semestre
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Semestre Asignado',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _semestreSeleccionado,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1565C0)),
                      items: _materiasPorSemestre.keys.map((semestre) {
                        return DropdownMenuItem(
                          value: semestre,
                          child: Text(semestre),
                        );
                      }).toList(),
                      onChanged: _cambiarSemestre,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lista de materias
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Selecciona las materias que impartes (${_materiasSeleccionadas.length} seleccionadas)',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),

                if (materiasDisponibles.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No hay materias disponibles para este semestre',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ...materiasDisponibles.map((materia) {
                    final isSelected = _materiasSeleccionadas.contains(materia);
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: CheckboxListTile(
                        title: Text(
                          materia,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        value: isSelected,
                        activeColor: const Color(0xFF1565C0),
                        onChanged: (value) => _toggleMateria(materia),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    );
                  }),
              ],
            ),
          ),

          // Botón guardar (solo visible si hay cambios)
          if (_hasChanges)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _guardarCambios,
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
                          'Guardar Cambios',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}