// lib/pantallas/admin/gestion_usuarios_screen.dart
import 'package:flutter/material.dart';
import '../../modelos/usuario.dart';
import '../../servicios/docente_service.dart';
import 'crear_docente_screen.dart';
import 'detalle_docente_screen.dart';  
import 'editar_docente_screen.dart';   

class GestionUsuariosScreen extends StatefulWidget {
  final Usuario usuario;

  const GestionUsuariosScreen({super.key, required this.usuario});

  @override
  State<GestionUsuariosScreen> createState() => _GestionUsuariosScreenState();
}

class _GestionUsuariosScreenState extends State<GestionUsuariosScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _docentes = [];
  List<Map<String, dynamic>> _docentesFiltrados = [];
  final _searchController = TextEditingController();
  String _filtroEstado = 'Todos'; // 'Todos', 'Activos', 'Inactivos'

  @override
  void initState() {
    super.initState();
    _cargarDocentes();
    _searchController.addListener(_filtrarDocentes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarDocentes() async {
    setState(() => _isLoading = true);

    try {
      final docentes = await DocenteService.listarDocentes();
      setState(() {
        _docentes = docentes;
        _aplicarFiltros();
      });
    } catch (e) {
      if (mounted) {
        _mostrarError('Error al cargar docentes: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filtrarDocentes() {
    _aplicarFiltros();
  }

  void _aplicarFiltros() {
    final query = _searchController.text.toLowerCase().trim();
    
    setState(() {
      _docentesFiltrados = _docentes.where((docente) {
        // Filtro por búsqueda
        final nombreMatch = (docente['nombreDocente'] ?? '')
            .toString()
            .toLowerCase()
            .contains(query);
        final emailMatch = (docente['emailDocente'] ?? '')
            .toString()
            .toLowerCase()
            .contains(query);
        
        final cumpleBusqueda = query.isEmpty || nombreMatch || emailMatch;
        
        // Filtro por estado
        final estadoDocente = docente['estadoDocente'] ?? true;
        final cumpleEstado = _filtroEstado == 'Todos' ||
            (_filtroEstado == 'Activos' && estadoDocente) ||
            (_filtroEstado == 'Inactivos' && !estadoDocente);
        
        return cumpleBusqueda && cumpleEstado;
      }).toList();
    });
  }

  void _cambiarFiltroEstado(String nuevoFiltro) {
    setState(() {
      _filtroEstado = nuevoFiltro;
      _aplicarFiltros();
    });
  }

  Future<void> _deshabilitarDocente(Map<String, dynamic> docente) async {
    final fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      locale: const Locale('es', 'ES'),
      helpText: 'Selecciona fecha de salida',
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

    if (fechaSeleccionada == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Deshabilitar docente?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de deshabilitar a ${docente['nombreDocente']}?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              '⚠️ El docente no podrá acceder al sistema después de esta acción.',
              style: TextStyle(color: Colors.orange),
            ),
            const SizedBox(height: 12),
            Text(
              'Fecha de salida: ${fechaSeleccionada.day}/${fechaSeleccionada.month}/${fechaSeleccionada.year}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Deshabilitar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _isLoading = true);

    final resultado = await DocenteService.eliminarDocente(
      id: docente['_id'],
      salidaDocente: fechaSeleccionada.toIso8601String().split('T')[0],
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (resultado != null && resultado.containsKey('error')) {
      _mostrarError(resultado['error']);
    } else {
      _mostrarExito('Docente deshabilitado exitosamente');
      _cargarDocentes();
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
        title: const Text('Gestión de Docentes'),
        backgroundColor: const Color(0xFF1565C0),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDocentes,
            tooltip: 'Recargar lista',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargarDocentes,
        child: Column(
          children: [
            // Buscador
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre o email',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            // Filtros por estado
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _FiltroChip(
                    label: 'Todos',
                    isSelected: _filtroEstado == 'Todos',
                    onTap: () => _cambiarFiltroEstado('Todos'),
                  ),
                  const SizedBox(width: 8),
                  _FiltroChip(
                    label: 'Activos',
                    isSelected: _filtroEstado == 'Activos',
                    onTap: () => _cambiarFiltroEstado('Activos'),
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _FiltroChip(
                    label: 'Inactivos',
                    isSelected: _filtroEstado == 'Inactivos',
                    onTap: () => _cambiarFiltroEstado('Inactivos'),
                    color: Colors.grey,
                  ),
                ],
              ),
            ),

            // Lista de docentes
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _docentesFiltrados.isEmpty
                      ? _buildEstadoVacio()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _docentesFiltrados.length,
                          itemBuilder: (context, index) {
                            final docente = _docentesFiltrados[index];
                            return _DocenteCard(
                              docente: docente,
                              onDesabilitar: () =>
                                  _deshabilitarDocente(docente),
                              onVerDetalle: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetalleDocenteScreen(
                                      docenteId: docente['_id'],
                                    ),
                                  ),
                                );
                              },
                              onEditar: () async {
                                final resultado = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditarDocenteScreen(
                                      docente: docente,
                                    ),
                                  ),
                                );

                                if (resultado == true && mounted) {
                                  _cargarDocentes();
                                }
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final resultado = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => const CrearDocenteScreen(),
            ),
          );

          if (resultado == true && mounted) {
            _cargarDocentes();
          }
        },
        backgroundColor: const Color(0xFF1565C0),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildEstadoVacio() {
    if (_docentes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay docentes registrados',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Presiona el botón + para crear uno',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No se encontraron docentes',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta con otro criterio de búsqueda',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }
  }
}

// Widget para la tarjeta de docente
class _DocenteCard extends StatelessWidget {
  final Map<String, dynamic> docente;
  final VoidCallback onDesabilitar;
  final VoidCallback onVerDetalle;
  final VoidCallback onEditar;

  const _DocenteCard({
    required this.docente,
    required this.onDesabilitar,
    required this.onVerDetalle,
    required this.onEditar,
  });

  @override
  Widget build(BuildContext context) {
    final estadoDocente = docente['estadoDocente'] ?? true;
    final avatarUrl = docente['avatarDocente'] ??
        'https://cdn-icons-png.flaticon.com/512/4715/4715329.png';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 30,
          backgroundImage: NetworkImage(avatarUrl),
          backgroundColor: Colors.grey[300],
        ),
        title: Text(
          docente['nombreDocente'] ?? 'Sin nombre',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              docente['emailDocente'] ?? 'Sin email',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text(
                estadoDocente ? 'Activo' : 'Inactivo',
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
              backgroundColor: estadoDocente ? Colors.green : Colors.grey,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'detalle':
                onVerDetalle();
                break;
              case 'editar':
                onEditar();
                break;
              case 'deshabilitar':
                onDesabilitar();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'detalle',
              child: Row(
                children: [
                  Icon(Icons.info, size: 20),
                  SizedBox(width: 12),
                  Text('Ver detalle'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'editar',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 12),
                  Text('Editar'),
                ],
              ),
            ),
            if (estadoDocente)
              const PopupMenuItem(
                value: 'deshabilitar',
                child: Row(
                  children: [
                    Icon(Icons.block, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Deshabilitar', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Widget para los chips de filtro
class _FiltroChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FiltroChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? const Color(0xFF1565C0);

    return GestureDetector(
      onTap: onTap,
      child: Chip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : chipColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        backgroundColor: isSelected ? chipColor : chipColor.withOpacity(0.1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}