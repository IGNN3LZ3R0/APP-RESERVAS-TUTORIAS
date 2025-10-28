import 'package:flutter/material.dart';
import '../modelos/usuario.dart';
import '../servicios/auth_service.dart';
import '../config/routes.dart';
import 'perfil/editar_perfil_screen.dart';
import 'auth/cambiar_password_screen.dart';
import 'admin/gestion_usuarios_screen.dart';
import 'docente/gestion_materias_screen.dart';

class HomeScreen extends StatefulWidget {
  final Usuario usuario;

  const HomeScreen({super.key, required this.usuario});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late Usuario _usuario;

  @override
  void initState() {
    super.initState();
    _usuario = widget.usuario;
    debugPrint(
      'HomeScreen init usuario: ${_usuario.id} | ${_usuario.nombre} | rol=${_usuario.rol}',
    );
  }

  // ✅ MÉTODO CORREGIDO: Actualiza el usuario en toda la app
  void _onUserUpdated(Usuario usuarioActualizado) {
    debugPrint(
      'HomeScreen onUserUpdated: ${usuarioActualizado.id} | ${usuarioActualizado.nombre}',
    );
    setState(() {
      _usuario = usuarioActualizado;
    });
  }

  // Obtener las pantallas según el rol
  List<Widget> _getScreens() {
    switch (_usuario.rol) {
      case 'Administrador':
        return [
          _DashboardAdministrador(usuario: _usuario),
          _PlaceholderScreen(titulo: 'Gestión de Usuarios'),
          _PlaceholderScreen(titulo: 'Reportes'),
          _PerfilScreen(usuario: _usuario, onUserUpdated: _onUserUpdated),
        ];
      case 'Docente':
        return [
          _DashboardDocente(usuario: _usuario),
          _PlaceholderScreen(titulo: 'Mi Disponibilidad'),
          _PlaceholderScreen(titulo: 'Mis Tutorías'),
          _PerfilScreen(usuario: _usuario, onUserUpdated: _onUserUpdated),
        ];
      case 'Estudiante':
      default:
        return [
          _DashboardEstudiante(usuario: _usuario),
          _PlaceholderScreen(titulo: 'Docentes Disponibles'),
          _PlaceholderScreen(titulo: 'Mis Citas'),
          _PerfilScreen(usuario: _usuario, onUserUpdated: _onUserUpdated),
        ];
    }
  }

  // Obtener los items del bottom navigation según el rol
  List<BottomNavigationBarItem> _getNavItems() {
    switch (_usuario.rol) {
      case 'Administrador':
        return const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Usuarios'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Reportes'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ];
      case 'Docente':
        return const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Horario'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Tutorías'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ];
      case 'Estudiante':
      default:
        return const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Docentes'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Mis Citas'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = _getScreens();

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1565C0),
        items: _getNavItems(),
      ),
    );
  }
}

// ========== DASHBOARDS POR ROL ==========

// Dashboard para Estudiantes
class _DashboardEstudiante extends StatelessWidget {
  final Usuario usuario;

  const _DashboardEstudiante({required this.usuario});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notificaciones próximamente')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta de bienvenida
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundImage: NetworkImage(usuario.fotoPerfilUrl),
                      backgroundColor: Colors.grey[300],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¡Hola, ${usuario.nombreCompleto}!',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Estudiante',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Acciones rápidas
            const Text(
              'Acciones rápidas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _QuickActionCard(
                  icon: Icons.add_circle,
                  title: 'Agendar Tutoría',
                  color: Colors.blue,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Próximamente')),
                    );
                  },
                ),
                _QuickActionCard(
                  icon: Icons.event,
                  title: 'Mis Citas',
                  color: Colors.green,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Próximamente')),
                    );
                  },
                ),
                _QuickActionCard(
                  icon: Icons.history,
                  title: 'Historial',
                  color: Colors.orange,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Próximamente')),
                    );
                  },
                ),
                _QuickActionCard(
                  icon: Icons.help,
                  title: 'Ayuda',
                  color: Colors.purple,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Próximamente')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Próximas tutorías
            const Text(
              'Próximas tutorías',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No tienes tutorías próximas',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Dashboard para Docentes
class _DashboardDocente extends StatelessWidget {
  final Usuario usuario;

  const _DashboardDocente({required this.usuario});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notificaciones próximamente')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bienvenido, ${usuario.nombre}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Docente',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Pendientes',
                    value: '0',
                    icon: Icons.pending,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    title: 'Hoy',
                    value: '0',
                    icon: Icons.today,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ⭐ SECCIÓN NUEVA: Acciones rápidas
            const Text(
              'Acciones rápidas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // ⭐ Tarjeta de Gestión de Materias
            Card(
              elevation: 2,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GestionMateriasScreen(usuario: usuario),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.book,
                          size: 32,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mis Materias',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Gestionar materias y horarios',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // ⭐ FIN DE SECCIÓN NUEVA

            const Text(
              'Solicitudes pendientes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No hay solicitudes pendientes',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Dashboard para Administradores
class _DashboardAdministrador extends StatelessWidget {
  final Usuario usuario;

  const _DashboardAdministrador({required this.usuario});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel de Administración')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bienvenido, ${usuario.nombre}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Acciones rápidas
            const Text(
              'Acciones rápidas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Tarjeta de Gestión de Usuarios
            Card(
              elevation: 2,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GestionUsuariosScreen(usuario: usuario),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.people,
                          size: 32,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gestión de Usuarios',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Administrar docentes del sistema',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _StatCard(
                  title: 'Usuarios',
                  value: '0',
                  icon: Icons.people,
                  color: Colors.blue,
                ),
                _StatCard(
                  title: 'Tutorías',
                  value: '0',
                  icon: Icons.book,
                  color: Colors.green,
                ),
                _StatCard(
                  title: 'Docentes',
                  value: '0',
                  icon: Icons.school,
                  color: Colors.orange,
                ),
                _StatCard(
                  title: 'Estudiantes',
                  value: '0',
                  icon: Icons.person,
                  color: Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Pantalla de Perfil
class _PerfilScreen extends StatefulWidget {
  final Usuario usuario;
  final ValueChanged<Usuario>? onUserUpdated;

  const _PerfilScreen({required this.usuario, this.onUserUpdated});

  @override
  State<_PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<_PerfilScreen> {
  late Usuario _usuario;

  @override
  void initState() {
    super.initState();
    _usuario = widget.usuario;
  }

  // ✅ MÉTODO CORREGIDO: Navega y actualiza el perfil
  Future<void> _navegarAEditarPerfil() async {
    // ✅ VALIDAR QUE EL USUARIO TIENE ID
    if (_usuario.id.isEmpty) {
      print('❌ ERROR: Usuario sin ID válido');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Sesión inválida. Inicia sesión nuevamente.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    print('🔹 Navegando a editar perfil con usuario:');
    print('   ID: ${_usuario.id}');
    print('   Nombre: ${_usuario.nombre}');
    print('   Email: ${_usuario.email}');
    print('   Rol: ${_usuario.rol}');
    
    final usuarioActualizado = await Navigator.push<Usuario>(
      context,
      MaterialPageRoute(
        builder: (context) => EditarPerfilScreen(usuario: _usuario),
      ),
    );

    if (usuarioActualizado != null && mounted) {
      print('✅ Usuario actualizado recibido: ${usuarioActualizado.nombre}');
      setState(() {
        _usuario = usuarioActualizado;
      });
      
      // ✅ ESTA LÍNEA ES LA CLAVE - Notifica al HomeScreen
      widget.onUserUpdated?.call(usuarioActualizado);
    } else {
      print('⚠️ No se recibió usuario actualizado');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(_usuario.fotoPerfilUrl),
              backgroundColor: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            _usuario.nombre,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Text(
            _usuario.email,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),

          Center(
            child: Chip(
              label: Text(_usuario.rol),
              backgroundColor: const Color(0xFF1565C0).withOpacity(0.1),
              labelStyle: const TextStyle(
                color: Color(0xFF1565C0),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 32),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Editar Perfil'),
            subtitle: const Text('Actualiza tu información personal'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _navegarAEditarPerfil,
          ),

          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Cambiar Contraseña'),
            subtitle: const Text('Actualiza tu contraseña'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CambiarPasswordScreen(usuario: _usuario),
                ),
              );
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              final confirmar = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Cerrar Sesión'),
                  content: const Text(
                    '¿Estás seguro de que deseas cerrar sesión?',
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
                      child: const Text('Cerrar Sesión'),
                    ),
                  ],
                ),
              );

              if (confirmar == true && context.mounted) {
                await AuthService.logout();
                AppRoutes.navigateToLogin(context);
              }
            },
          ),
        ],
      ),
    );
  }
}

// ========== WIDGETS AUXILIARES ==========

// Tarjeta de acción rápida
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Tarjeta de estadística
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

// Pantalla placeholder
class _PlaceholderScreen extends StatelessWidget {
  final String titulo;

  const _PlaceholderScreen({required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              'Pantalla en construcción',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              titulo,
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}