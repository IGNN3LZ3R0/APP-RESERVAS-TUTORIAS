import 'package:flutter/material.dart';
import '../../servicios/docente_service.dart';

class DetalleDocenteScreen extends StatefulWidget {
  final String docenteId;

  const DetalleDocenteScreen({super.key, required this.docenteId});

  @override
  State<DetalleDocenteScreen> createState() => _DetalleDocenteScreenState();
}

class _DetalleDocenteScreenState extends State<DetalleDocenteScreen> {
  Map<String, dynamic>? _docente;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDetalle();
  }

  Future<void> _cargarDetalle() async {
    setState(() => _isLoading = true);
    
    final resultado = await DocenteService.detalleDocente(widget.docenteId);
    
    setState(() {
      _docente = resultado;
      _isLoading = false;
    });

    if (resultado != null && resultado.containsKey('error')) {
      _mostrarError(resultado['error']);
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

  String _formatearFecha(String? fecha) {
    if (fecha == null) return 'No especificado';
    try {
      final date = DateTime.parse(fecha);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return fecha;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Docente'),
        backgroundColor: const Color(0xFF1565C0),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _docente == null || _docente!.containsKey('error')
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 80, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _docente?['error'] ?? 'Error al cargar datos',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _cargarDetalle,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarDetalle,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Foto de perfil
                      Center(
                        child: CircleAvatar(
                          radius: 60,
                          backgroundImage: NetworkImage(
                            _docente!['avatarDocente'] ??
                                'https://cdn-icons-png.flaticon.com/512/4715/4715329.png',
                          ),
                          backgroundColor: Colors.grey[300],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Nombre
                      Text(
                        _docente!['nombreDocente'] ?? 'Sin nombre',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Estado
                      Center(
                        child: Chip(
                          label: Text(
                            _docente!['estadoDocente'] == true ? 'Activo' : 'Inactivo',
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: _docente!['estadoDocente'] == true
                              ? Colors.green
                              : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Información personal
                      _buildSeccion('Información Personal', [
                        _buildItem('Cédula', _docente!['cedulaDocente']),
                        _buildItem('Fecha de Nacimiento', _formatearFecha(_docente!['fechaNacimientoDocente'])),
                        _buildItem('Fecha de Ingreso', _formatearFecha(_docente!['fechaIngresoDocente'])),
                        if (_docente!['salidaDocente'] != null)
                          _buildItem('Fecha de Salida', _formatearFecha(_docente!['salidaDocente'])),
                      ]),
                      const SizedBox(height: 16),

                      // Información de contacto
                      _buildSeccion('Información de Contacto', [
                        _buildItem('Email Institucional', _docente!['emailDocente']),
                        _buildItem('Email Alternativo', _docente!['emailAlternativoDocente']),
                        _buildItem('Celular', _docente!['celularDocente']),
                        _buildItem('Oficina', _docente!['oficinaDocente']),
                      ]),
                      const SizedBox(height: 16),

                      // Información académica
                      _buildSeccion('Información Académica', [
                        _buildItem('Semestre Asignado', _docente!['semestreAsignado']),
                        _buildAsignaturas(_docente!['asignaturas']),
                      ]),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSeccion(String titulo, List<Widget> items) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0),
              ),
            ),
            const SizedBox(height: 12),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildItem(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'No especificado',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAsignaturas(dynamic asignaturas) {
    List<String> materias = [];
    
    if (asignaturas is List) {
      materias = asignaturas.map((e) => e.toString()).toList();
    } else if (asignaturas is String) {
      try {
        materias = asignaturas.split(',').map((e) => e.trim()).toList();
      } catch (e) {
        materias = [asignaturas];
      }
    }

    if (materias.isEmpty) {
      return _buildItem('Asignaturas', 'Ninguna asignada');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Asignaturas:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: materias
                .map((materia) => Chip(
                      label: Text(materia),
                      backgroundColor: Colors.blue[50],
                      labelStyle: const TextStyle(fontSize: 12),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}