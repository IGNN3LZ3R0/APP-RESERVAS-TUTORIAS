import 'package:flutter/material.dart';
import '../../servicios/tutoria_service.dart';
import '../../servicios/horario_service.dart';
import '../../config/responsive_helper.dart';

class ReagendarTutoriaDialog extends StatefulWidget {
  final Map<String, dynamic> tutoria;
  final String nombreDocente;

  const ReagendarTutoriaDialog({
    super.key,
    required this.tutoria,
    required this.nombreDocente,
  });

  @override
  State<ReagendarTutoriaDialog> createState() => _ReagendarTutoriaDialogState();
}

class _ReagendarTutoriaDialogState extends State<ReagendarTutoriaDialog>
    with SingleTickerProviderStateMixin {
  DateTime? _fechaSeleccionada;
  String? _horaInicio;
  String? _horaFin;
  final _motivoController = TextEditingController();
  bool _isLoading = false;

  bool _cargandoDisponibilidad = false;
  List<Map<String, dynamic>> _bloquesDisponibles = [];
  String? _error;

  Set<int> _diasDisponiblesDocente = {};
  bool _cargandoDias = true;

  String? _materiaOriginal;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();

    DateTime fechaTutoria;
    try {
      fechaTutoria = DateTime.parse(widget.tutoria['fecha']);
    } catch (e) {
      fechaTutoria = DateTime.now().add(const Duration(days: 1));
    }

    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    // 🔧 Normalizar fechaTutoria a solo fecha (sin hora) para comparación correcta
    final fechaTutoriaNormalizada = DateTime(
      fechaTutoria.year,
      fechaTutoria.month,
      fechaTutoria.day,
    );

    if (fechaTutoriaNormalizada.isBefore(hoy)) {
      _fechaSeleccionada = null;
      print('⚠️ Tutoría pasada detectada. Se buscará próximo día disponible.');
    } else {
      _fechaSeleccionada = fechaTutoriaNormalizada;
    }

    _horaInicio = widget.tutoria['horaInicio'];
    _horaFin = widget.tutoria['horaFin'];

    _cargarDiasDisponiblesDocente();
  }

  @override
  void dispose() {
    _motivoController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  DateTime _buscarProximoDiaDisponible() {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);

    for (int i = 1; i <= 90; i++) {
      final fecha = hoy.add(Duration(days: i));
      final diaSemana = fecha.weekday;

      if (_diasDisponiblesDocente.contains(diaSemana)) {
        return fecha;
      }
    }

    return hoy.add(const Duration(days: 1));
  }

  String? _identificarMateriaOriginal(
    Map<String, List<Map<String, dynamic>>> disponibilidad,
  ) {
    if (widget.tutoria['bloqueDocenteId'] != null) {
      final bloqueId = widget.tutoria['bloqueDocenteId'];

      for (var entrada in disponibilidad.entries) {
        final materia = entrada.key;
        final bloques = entrada.value;

        for (var bloque in bloques) {
          if (bloque['_id'] == bloqueId) {
            print('✅ Materia encontrada por bloqueDocenteId: $materia');
            return materia;
          }
        }
      }
    }

    final fechaOriginal = DateTime.parse(widget.tutoria['fecha']);
    final diaOriginal = _obtenerDiaSemana(fechaOriginal);
    final horaInicioOriginal = widget.tutoria['horaInicio'];
    final horaFinOriginal = widget.tutoria['horaFin'];

    print('🔍 Buscando materia por horario:');
    print('   Día: $diaOriginal');
    print('   Hora: $horaInicioOriginal - $horaFinOriginal');

    List<String> materiasCoincidentes = [];

    for (var entrada in disponibilidad.entries) {
      final materia = entrada.key;
      final bloques = entrada.value;

      for (var bloque in bloques) {
        if (bloque['dia'] == diaOriginal) {
          final bloqueInicio = _convertirAMinutos(bloque['horaInicio']);
          final bloqueFin = _convertirAMinutos(bloque['horaFin']);
          final tutoriaInicio = _convertirAMinutos(horaInicioOriginal);
          final tutoriaFin = _convertirAMinutos(horaFinOriginal);

          if (tutoriaInicio >= bloqueInicio && tutoriaFin <= bloqueFin) {
            materiasCoincidentes.add(materia);
          }
        }
      }
    }

    if (materiasCoincidentes.isEmpty) {
      print('❌ No se encontró ninguna materia coincidente');
      return null;
    }

    if (materiasCoincidentes.length > 1) {
      print(
        '⚠️ Múltiples materias coincidentes: ${materiasCoincidentes.join(", ")}',
      );
      if (widget.tutoria['materia'] != null) {
        final materiaTutoria = widget.tutoria['materia'];
        if (materiasCoincidentes.contains(materiaTutoria)) {
          print('✅ Usando materia del registro de tutoría: $materiaTutoria');
          return materiaTutoria;
        }
      }
    }

    print('✅ Materia identificada: ${materiasCoincidentes.first}');
    return materiasCoincidentes.first;
  }

  Future<void> _cargarDiasDisponiblesDocente() async {
    setState(() => _cargandoDias = true);

    try {
      // Comprobación nula del docente y recolección segura del id
      final docenteObj = widget.tutoria['docente'];
      String? docenteId;
      if (docenteObj is Map &&
          docenteObj['_id'] != null &&
          docenteObj['_id'].toString().isNotEmpty) {
        docenteId = docenteObj['_id'].toString();
      } else {
        // Soporte para distintos esquemas de objeto
        docenteId =
            widget.tutoria['docenteId'] ??
            widget.tutoria['docente_id'] ??
            widget.tutoria['docenteId'];
      }

      if (docenteId == null || docenteId.isEmpty) {
        if (mounted) {
          setState(() {
            _cargandoDias = false;
            _error = 'No se pudo determinar el docente de esta tutoría';
          });
        }
        return;
      }

      print('📅 Cargando días disponibles del docente: $docenteId');

      final disponibilidad = await HorarioService.obtenerDisponibilidadCompleta(
        docenteId: docenteId,
      );

      if (disponibilidad == null || disponibilidad.isEmpty) {
        if (mounted) {
          setState(() {
            _cargandoDias = false;
            _error = 'El docente no tiene disponibilidad registrada';
          });
        }
        return;
      }

      print('📚 Materias disponibles: ${disponibilidad.keys.join(", ")}');

      _materiaOriginal = _identificarMateriaOriginal(disponibilidad);

      if (_materiaOriginal == null) {
        if (mounted) {
          setState(() {
            _cargandoDias = false;
            _error =
                'No se pudo determinar la materia de esta tutoría. '
                'Por favor, contacta al docente para reagendar.';
          });
        }
        return;
      }

      print('✅ Materia original de la tutoría: $_materiaOriginal');

      final bloquesMateria = disponibilidad[_materiaOriginal] ?? [];

      if (bloquesMateria.isEmpty) {
        if (mounted) {
          setState(() {
            _cargandoDias = false;
            _error =
                'El docente no tiene disponibilidad para la materia "$_materiaOriginal"';
          });
        }
        return;
      }

      Set<String> diasDisponibles = {};

      for (var bloque in bloquesMateria) {
        diasDisponibles.add(bloque['dia']);
      }

      print(
        '📅 Días disponibles para "$_materiaOriginal": ${diasDisponibles.join(", ")}',
      );

      final mapaDias = {
        'Lunes': 1,
        'Martes': 2,
        'Miércoles': 3,
        'Jueves': 4,
        'Viernes': 5,
        'Sábado': 6,
        'Domingo': 7,
      };

      Set<int> diasNumericos = {};
      for (var dia in diasDisponibles) {
        if (mapaDias.containsKey(dia)) {
          diasNumericos.add(mapaDias[dia]!);
        }
      }

      if (mounted) {
        setState(() {
          _diasDisponiblesDocente = diasNumericos;
          _cargandoDias = false;
        });

        // 🔧 Normalizar comparación con hoy para evitar problemas de hora
        final ahora = DateTime.now();
        final hoy = DateTime(ahora.year, ahora.month, ahora.day);

        if (_fechaSeleccionada == null ||
            _fechaSeleccionada!.isBefore(hoy) ||
            !_diasDisponiblesDocente.contains(_fechaSeleccionada!.weekday)) {
          _fechaSeleccionada = _buscarProximoDiaDisponible();
          print('📅 Usando próximo día disponible: $_fechaSeleccionada');
        }

        _cargarDisponibilidadDelDia();
      }
    } catch (e) {
      print('❌ Error cargando días disponibles: $e');
      if (mounted) {
        setState(() {
          _cargandoDias = false;
          _error = 'Error al cargar disponibilidad: $e';
        });
      }
    }
  }

  int _convertirAMinutos(String hora) {
    try {
      final partes = hora.split(':');
      final horas = int.parse(partes[0]);
      final minutos = int.parse(partes[1]);
      return horas * 60 + minutos;
    } catch (e) {
      print('⚠️ Error convirtiendo hora: $hora');
      return 0;
    }
  }

  String _obtenerDiaSemana(DateTime fecha) {
    const dias = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    return dias[fecha.weekday - 1];
  }

  List<Map<String, dynamic>> _generarTurnos20Min(String inicio, String fin) {
    // 🔧 Definir la función de conversión DENTRO de este método
    int convertirAMinutos(String hora) {
      try {
        final partes = hora.split(':');
        final horas = int.parse(partes[0]);
        final minutos = int.parse(partes[1]);
        return horas * 60 + minutos;
      } catch (e) {
        print('⚠️ Error convirtiendo hora en _generarTurnos20Min: $hora');
        return 0;
      }
    }

    final minutosInicio = convertirAMinutos(inicio);
    final minutosFin = convertirAMinutos(fin);
    const duracionTurno = 20;

    List<Map<String, dynamic>> turnos = [];
    int actual = minutosInicio;

    while (actual + duracionTurno <= minutosFin) {
      final hInicio = (actual ~/ 60).toString().padLeft(2, '0');
      final mInicio = (actual % 60).toString().padLeft(2, '0');
      final inicioTurno = '$hInicio:$mInicio';

      final siguienteMinuto = actual + duracionTurno;
      final hFin = (siguienteMinuto ~/ 60).toString().padLeft(2, '0');
      final mFin = (siguienteMinuto % 60).toString().padLeft(2, '0');
      final finTurno = '$hFin:$mFin';

      turnos.add({'horaInicio': inicioTurno, 'horaFin': finTurno});

      actual += duracionTurno;
    }

    return turnos;
  }

  Future<void> _cargarDisponibilidadDelDia() async {
    if (_fechaSeleccionada == null || _materiaOriginal == null) return;

    setState(() {
      _cargandoDisponibilidad = true;
      _error = null;
      _bloquesDisponibles = [];
    });

    try {
      // Recolección segura del id del docente
      final docenteObj = widget.tutoria['docente'];
      String? docenteId;
      if (docenteObj is Map &&
          docenteObj['_id'] != null &&
          docenteObj['_id'].toString().isNotEmpty) {
        docenteId = docenteObj['_id'].toString();
      } else {
        docenteId =
            widget.tutoria['docenteId'] ??
            widget.tutoria['docente_id'] ??
            widget.tutoria['docenteId'];
      }

      if (docenteId == null || docenteId.isEmpty) {
        if (mounted) {
          setState(() {
            _cargandoDisponibilidad = false;
            _error = 'No se pudo determinar el docente de esta tutoría';
          });
        }
        return;
      }

      const dias = [
        'Lunes',
        'Martes',
        'Miércoles',
        'Jueves',
        'Viernes',
        'Sábado',
        'Domingo',
      ];
      final diaSemana = dias[_fechaSeleccionada!.weekday - 1];

      print(
        '🔍 Buscando disponibilidad para: $diaSemana en materia $_materiaOriginal',
      );

      final disponibilidad = await HorarioService.obtenerDisponibilidadCompleta(
        docenteId: docenteId,
      );

      if (disponibilidad == null || disponibilidad.isEmpty) {
        setState(() {
          _cargandoDisponibilidad = false;
          _error = 'El docente no tiene disponibilidad registrada';
        });
        return;
      }

      final bloquesMateria = disponibilidad[_materiaOriginal] ?? [];
      List<Map<String, dynamic>> bloquesDelDia = [];

      for (var bloque in bloquesMateria) {
        if (bloque['dia'] == diaSemana) {
          bloquesDelDia.add(bloque);
        }
      }

      print(
        '📦 Bloques encontrados para $_materiaOriginal en $diaSemana: ${bloquesDelDia.length}',
      );

      if (bloquesDelDia.isEmpty) {
        setState(() {
          _cargandoDisponibilidad = false;
          _bloquesDisponibles = [];
        });
        return;
      }

      final fechaStr = _fechaSeleccionada!.toIso8601String().split('T')[0];
      final bloquesOcupados = await TutoriaService.listarTutorias(
        incluirCanceladas: false,
      );

      final ocupadosEnFecha = bloquesOcupados.where((t) {
        final tDoc = t['docente'];
        final tDocId = (tDoc is Map && tDoc['_id'] != null)
            ? tDoc['_id']
            : (t['docenteId'] ?? t['docente_id']);

        return tDocId == docenteId &&
            t['fecha'] == fechaStr &&
            t['_id'] != widget.tutoria['_id'] &&
            (t['estado'] == 'pendiente' || t['estado'] == 'confirmada');
      }).toList();

      List<Map<String, dynamic>> turnosDisponibles = [];

      for (var bloque in bloquesDelDia) {
        final turnos = _generarTurnos20Min(
          bloque['horaInicio'],
          bloque['horaFin'],
        );

        for (var turno in turnos) {
          // 🔧 Convertir a minutos para comparación
          final turnoInicio = _convertirAMinutos(turno['horaInicio']);
          final turnoFin = _convertirAMinutos(turno['horaFin']);

          final ocupado = ocupadosEnFecha.any((tutoria) {
            final tutoriaInicio = _convertirAMinutos(tutoria['horaInicio']);
            final tutoriaFin = _convertirAMinutos(tutoria['horaFin']);

            // Verificar solapamiento usando números
            return !(turnoFin <= tutoriaInicio || turnoInicio >= tutoriaFin);
          });

          if (!ocupado) {
            turnosDisponibles.add(turno);
          }
        }
      }

      setState(() {
        _bloquesDisponibles = turnosDisponibles;
        _cargandoDisponibilidad = false;

        final horarioActualDisponible = turnosDisponibles.any(
          (t) => t['horaInicio'] == _horaInicio && t['horaFin'] == _horaFin,
        );

        if (!horarioActualDisponible) {
          _horaInicio = null;
          _horaFin = null;
        }
      });

      print('✅ Turnos disponibles para reagendar: ${turnosDisponibles.length}');
    } catch (e) {
      print('❌ Error en _cargarDisponibilidadDelDia: $e');
      setState(() {
        _cargandoDisponibilidad = false;
        _error = 'Error al cargar disponibilidad: $e';
      });
    }
  }

  Future<void> _seleccionarFecha() async {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);

    DateTime fechaInicial;
    if (_fechaSeleccionada != null && !_fechaSeleccionada!.isBefore(hoy)) {
      fechaInicial = _fechaSeleccionada!;
    } else {
      fechaInicial = hoy.add(const Duration(days: 1));
    }

    final fecha = await showDatePicker(
      context: context,
      initialDate: fechaInicial,
      firstDate: hoy,
      lastDate: DateTime.now().add(const Duration(days: 90)),
      locale: const Locale('es', 'ES'),
      selectableDayPredicate: (DateTime date) {
        final diaSemana = date.weekday;
        return _diasDisponiblesDocente.contains(diaSemana);
      },
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1565C0),
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
            dialogTheme: DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );

    if (fecha != null && mounted) {
      setState(() {
        _fechaSeleccionada = fecha;
        _horaInicio = null;
        _horaFin = null;
      });

      _cargarDisponibilidadDelDia();
    }
  }

  Future<void> _reagendar() async {
    if (_fechaSeleccionada == null) {
      _mostrarError('Selecciona una fecha');
      return;
    }

    if (_horaInicio == null || _horaFin == null) {
      _mostrarError('Selecciona un turno disponible');
      return;
    }

    final turnoValido = _bloquesDisponibles.any(
      (t) => t['horaInicio'] == _horaInicio && t['horaFin'] == _horaFin,
    );

    if (!turnoValido) {
      _mostrarError('El turno seleccionado ya no está disponible');
      return;
    }

    final fechaHoraNueva = DateTime(
      _fechaSeleccionada!.year,
      _fechaSeleccionada!.month,
      _fechaSeleccionada!.day,
      int.parse(_horaInicio!.split(':')[0]),
      int.parse(_horaInicio!.split(':')[1]),
    );

    final ahora = DateTime.now();
    final diferencia = fechaHoraNueva.difference(ahora);
    final horasAnticipacion = diferencia.inMinutes / 60.0;

    print('⏰ Validación de anticipación:');
    print('   Hora actual: ${ahora}');
    print('   Nueva hora: ${fechaHoraNueva}');
    print('   Horas de anticipación: ${horasAnticipacion.toStringAsFixed(2)}');

    if (horasAnticipacion < 2) {
      _mostrarError(
        'Debes reagendar con al menos 2 horas de anticipación. '
        'Tiempo disponible: ${horasAnticipacion.toStringAsFixed(1)} horas',
      );
      return;
    }

    setState(() => _isLoading = true);

    final fechaFormateada = _fechaSeleccionada!.toIso8601String().split('T')[0];

    final resultado = await TutoriaService.reagendarTutoria(
      tutoriaId: widget.tutoria['_id'],
      nuevaFecha: fechaFormateada,
      nuevaHoraInicio: _horaInicio!,
      nuevaHoraFin: _horaFin!,
      motivo: _motivoController.text.isEmpty
          ? 'Reagendada por el estudiante'
          : _motivoController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (resultado != null && resultado.containsKey('error')) {
      _mostrarError(resultado['error']);
    } else {
      Navigator.pop(context, {'success': true});
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    const dias = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    final dia = dias[fecha.weekday - 1];
    return '$dia ${fecha.day}/${fecha.month}/${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    // Responsiveness helpers
    final isMobile = context.isMobile;
    final isDesktop = context.isDesktop;
    final contentPadding = context.responsivePadding;
    final spacing = context.responsiveSpacing;
    final dialogRadius = ResponsiveHelper.getBorderRadius(context);
    final dialogWidth = isDesktop
        ? 650.0
        : (isMobile ? MediaQuery.of(context).size.width * 0.95 : 560.0);
    final dialogMaxHeight = MediaQuery.of(context).size.height * 0.86;
    final buttonHeight = ResponsiveHelper.getButtonHeight(context);

    if (_cargandoDias) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(dialogRadius),
        ),
        child: Container(
          padding: EdgeInsets.all(contentPadding * 1.25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(contentPadding * 0.8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  shape: BoxShape.circle,
                ),
                child: SizedBox(
                  height: context.responsiveIconSize(36),
                  width: context.responsiveIconSize(36),
                  child: const CircularProgressIndicator(strokeWidth: 3),
                ),
              ),
              SizedBox(height: spacing * 1.5),
              Text(
                'Verificando disponibilidad del docente...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: context.responsiveFontSize(16),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null && _diasDisponiblesDocente.isEmpty) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(dialogRadius),
        ),
        child: Container(
          padding: EdgeInsets.all(contentPadding * 1.1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(contentPadding * 0.9),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: context.responsiveIconSize(48),
                  color: Colors.red[700],
                ),
              ),
              SizedBox(height: spacing),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: context.responsiveFontSize(15),
                  height: 1.4,
                ),
              ),
              SizedBox(height: spacing * 1.5),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: contentPadding * 0.7,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(dialogRadius * 0.5),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Cerrar',
                    style: TextStyle(fontSize: context.responsiveFontSize(15)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(dialogRadius),
        ),
        elevation: 8,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: dialogWidth,
            maxHeight: dialogMaxHeight,
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(contentPadding),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(dialogRadius),
                    topRight: Radius.circular(dialogRadius),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(contentPadding * 0.6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(dialogRadius * 0.5),
                      ),
                      child: Icon(
                        Icons.event_repeat,
                        color: Colors.white,
                        size: context.responsiveIconSize(24),
                      ),
                    ),
                    SizedBox(width: spacing),
                    Expanded(
                      child: Text(
                        'Reagendar Tutoría',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: context.responsiveFontSize(20),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: context.responsiveIconSize(20),
                      ),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.all(isMobile ? 8 : 12),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(contentPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(contentPadding),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.orange[50]!, Colors.orange[100]!],
                          ),
                          borderRadius: BorderRadius.circular(
                            dialogRadius * 0.6,
                          ),
                          border: Border.all(
                            color: Colors.orange[300]!,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(contentPadding * 0.4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(
                                      dialogRadius * 0.4,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.info_outline,
                                    color: Colors.white,
                                    size: context.responsiveIconSize(18),
                                  ),
                                ),
                                SizedBox(width: spacing),
                                Text(
                                  'Horario Actual',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[900],
                                    fontSize: context.responsiveFontSize(16),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: spacing),
                            if (_materiaOriginal != null) ...[
                              Container(
                                padding: EdgeInsets.all(contentPadding * 0.75),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    dialogRadius * 0.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.book,
                                      size: context.responsiveIconSize(18),
                                      color: Colors.orange[700],
                                    ),
                                    SizedBox(width: spacing * 0.5),
                                    Expanded(
                                      child: Text(
                                        'Materia: $_materiaOriginal',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: context.responsiveFontSize(
                                            14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: spacing * 0.6),
                            ],

                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: context.responsiveIconSize(16),
                                  color: Colors.orange[800],
                                ),
                                SizedBox(width: spacing * 0.5),
                                Text(
                                  widget.tutoria['fecha'] != null
                                      ? _formatearFecha(
                                          DateTime.parse(
                                            widget.tutoria['fecha'],
                                          ),
                                        )
                                      : 'Fecha no disponible',
                                  style: TextStyle(
                                    fontSize: context.responsiveFontSize(14),
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: spacing * 0.5),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: context.responsiveIconSize(16),
                                  color: Colors.orange[800],
                                ),
                                SizedBox(width: spacing * 0.5),
                                Text(
                                  '${widget.tutoria['horaInicio'] ?? '--:--'} - ${widget.tutoria['horaFin'] ?? '--:--'}',
                                  style: TextStyle(
                                    fontSize: context.responsiveFontSize(14),
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),

                            if (widget.tutoria['fecha'] != null) ...[
                              // 🔧 Normalizar fecha para comparación correcta
                              Builder(
                                builder: (context) {
                                  final fechaTutParsed = DateTime.parse(
                                    widget.tutoria['fecha'],
                                  );
                                  final fechaTutNorm = DateTime(
                                    fechaTutParsed.year,
                                    fechaTutParsed.month,
                                    fechaTutParsed.day,
                                  );
                                  final ahora = DateTime.now();
                                  final hoy = DateTime(
                                    ahora.year,
                                    ahora.month,
                                    ahora.day,
                                  );

                                  if (fechaTutNorm.isBefore(hoy)) {
                                    return SizedBox(
                                      width: double.infinity,
                                      child: Column(
                                        children: [
                                          SizedBox(height: spacing),
                                          Container(
                                            padding: EdgeInsets.all(
                                              contentPadding * 0.6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.red[100],
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    dialogRadius * 0.5,
                                                  ),
                                              border: Border.all(
                                                color: Colors.red[300]!,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.warning,
                                                  color: Colors.red[700],
                                                  size: context
                                                      .responsiveIconSize(16),
                                                ),
                                                SizedBox(width: spacing * 0.5),
                                                Expanded(
                                                  child: Text(
                                                    'Esta fecha ya pasó. Selecciona una fecha futura.',
                                                    style: TextStyle(
                                                      fontSize: context
                                                          .responsiveFontSize(
                                                            12,
                                                          ),
                                                      color: Colors.red[900],
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                  return SizedBox.shrink();
                                },
                              ),
                            ],
                          ],
                        ),
                      ),

                      SizedBox(height: spacing * 1.5),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(contentPadding * 0.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1565C0).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                dialogRadius * 0.4,
                              ),
                            ),
                            child: Icon(
                              Icons.edit_calendar,
                              size: context.responsiveIconSize(20),
                              color: const Color(0xFF1565C0),
                            ),
                          ),
                          SizedBox(width: spacing),
                          Text(
                            'Nuevo Horario',
                            style: TextStyle(
                              fontSize: context.responsiveFontSize(18),
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1565C0),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: spacing),

                      InkWell(
                        onTap: _seleccionarFecha,
                        borderRadius: BorderRadius.circular(dialogRadius * 0.5),
                        child: Container(
                          padding: EdgeInsets.all(contentPadding),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(
                              dialogRadius * 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(contentPadding * 0.6),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF1565C0,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                    dialogRadius * 0.4,
                                  ),
                                ),
                                child: Icon(
                                  Icons.calendar_today,
                                  color: const Color(0xFF1565C0),
                                  size: context.responsiveIconSize(20),
                                ),
                              ),
                              SizedBox(width: spacing),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Fecha',
                                      style: TextStyle(
                                        fontSize: context.responsiveFontSize(
                                          12,
                                        ),
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: spacing * 0.2),
                                    Text(
                                      _fechaSeleccionada != null
                                          ? _formatearFecha(_fechaSeleccionada!)
                                          : 'Seleccionar fecha',
                                      style: TextStyle(
                                        fontSize: context.responsiveFontSize(
                                          16,
                                        ),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: context.responsiveIconSize(16),
                                color: Colors.grey[600],
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: spacing),

                      if (_cargandoDisponibilidad)
                        Container(
                          padding: EdgeInsets.all(contentPadding * 1.2),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(
                              dialogRadius * 0.5,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                SizedBox(
                                  height: context.responsiveIconSize(32),
                                  width: context.responsiveIconSize(32),
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 3,
                                  ),
                                ),
                                SizedBox(height: spacing),
                                Text(
                                  'Cargando turnos...',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: context.responsiveFontSize(14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (_error != null)
                        Container(
                          padding: EdgeInsets.all(contentPadding * 0.9),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(
                              dialogRadius * 0.5,
                            ),
                            border: Border.all(color: Colors.red[300]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red[700],
                                size: context.responsiveIconSize(18),
                              ),
                              SizedBox(width: spacing),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: TextStyle(
                                    color: Colors.red[900],
                                    fontSize: context.responsiveFontSize(14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (_bloquesDisponibles.isEmpty)
                        Container(
                          padding: EdgeInsets.all(contentPadding),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(
                              dialogRadius * 0.5,
                            ),
                            border: Border.all(color: Colors.orange[300]!),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.warning_amber,
                                color: Colors.orange[700],
                                size: context.responsiveIconSize(48),
                              ),
                              SizedBox(height: spacing),
                              Text(
                                'No hay turnos disponibles para ${_formatearFecha(_fechaSeleccionada!)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: context.responsiveFontSize(15),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: spacing * 0.5),
                              Text(
                                'El docente no tiene horarios libres en este día para la materia "$_materiaOriginal".',
                                style: TextStyle(
                                  fontSize: context.responsiveFontSize(13),
                                  color: Colors.grey[700],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: spacing),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _seleccionarFecha,
                                  icon: Icon(
                                    Icons.calendar_today,
                                    size: context.responsiveIconSize(18),
                                  ),
                                  label: Text(
                                    'Elegir otro día',
                                    style: TextStyle(
                                      fontSize: context.responsiveFontSize(15),
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange[600],
                                    foregroundColor: Colors.white,
                                    minimumSize: Size.fromHeight(
                                      buttonHeight * 0.85,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        dialogRadius * 0.45,
                                      ),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.all(contentPadding * 0.8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.blue[50]!, Colors.blue[100]!],
                                ),
                                borderRadius: BorderRadius.circular(
                                  dialogRadius * 0.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(
                                      contentPadding * 0.4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(
                                        dialogRadius * 0.4,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.schedule,
                                      size: context.responsiveIconSize(18),
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                  SizedBox(width: spacing * 0.8),
                                  Expanded(
                                    child: Text(
                                      'Turnos Disponibles (${_bloquesDisponibles.length})',
                                      style: TextStyle(
                                        fontSize: context.responsiveFontSize(
                                          14,
                                        ),
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[900],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: contentPadding * 0.6,
                                      vertical: contentPadding * 0.25,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1565C0),
                                      borderRadius: BorderRadius.circular(
                                        dialogRadius * 0.4,
                                      ),
                                    ),
                                    child: Text(
                                      _materiaOriginal ?? 'Materia',
                                      style: TextStyle(
                                        fontSize: context.responsiveFontSize(
                                          11,
                                        ),
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: spacing),
                            ..._bloquesDisponibles.map((turno) {
                              final isSelected =
                                  _horaInicio == turno['horaInicio'] &&
                                  _horaFin == turno['horaFin'];

                              return Padding(
                                padding: EdgeInsets.only(bottom: spacing * 0.6),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _horaInicio = turno['horaInicio'];
                                      _horaFin = turno['horaFin'];
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(
                                    dialogRadius * 0.45,
                                  ),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: EdgeInsets.all(
                                      contentPadding * 0.6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(
                                              0xFF1565C0,
                                            ).withOpacity(0.15)
                                          : Colors.grey[50],
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF1565C0)
                                            : Colors.grey[300]!,
                                        width: isSelected ? 2 : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        dialogRadius * 0.45,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: const Color(
                                                  0xFF1565C0,
                                                ).withOpacity(0.2),
                                                blurRadius: 8,
                                                spreadRadius: 1,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(
                                            contentPadding * 0.4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? const Color(0xFF1565C0)
                                                : Colors.green.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              dialogRadius * 0.35,
                                            ),
                                          ),
                                          child: Icon(
                                            isSelected
                                                ? Icons.check_circle
                                                : Icons.schedule,
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.green[700],
                                            size: context.responsiveIconSize(
                                              20,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: spacing),
                                        Expanded(
                                          child: Text(
                                            '${turno['horaInicio']} - ${turno['horaFin']}',
                                            style: TextStyle(
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.w600,
                                              color: isSelected
                                                  ? const Color(0xFF1565C0)
                                                  : Colors.black87,
                                              fontSize: context
                                                  .responsiveFontSize(15),
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            size: context.responsiveIconSize(
                                              16,
                                            ),
                                            color: const Color(0xFF1565C0),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),

                      SizedBox(height: spacing),

                      TextField(
                        controller: _motivoController,
                        decoration: InputDecoration(
                          labelText: 'Motivo (opcional)',
                          hintText: 'Ejemplo: Tengo un compromiso académico',
                          prefixIcon: Icon(
                            Icons.comment,
                            color: Colors.blue[700],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              dialogRadius * 0.45,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              dialogRadius * 0.45,
                            ),
                            borderSide: const BorderSide(
                              color: Color(0xFF1565C0),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),

              Container(
                padding: EdgeInsets.all(contentPadding),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: buttonHeight,
                  child: ElevatedButton(
                    onPressed:
                        (_isLoading ||
                            _cargandoDisponibilidad ||
                            _horaInicio == null)
                        ? null
                        : _reagendar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      disabledBackgroundColor: Colors.grey[300],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(dialogRadius * 0.5),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: context.responsiveIconSize(20),
                            width: context.responsiveIconSize(20),
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              // Usamos Wrap para que el icono y el texto puedan ajustarse sin causar overflow
                              return ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: constraints.maxWidth,
                                ),
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: spacing * 0.6,
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      size: context.responsiveIconSize(20),
                                    ),
                                    SizedBox(
                                      // Reservamos parte del ancho para el texto y permitimos truncamiento si es necesario
                                      width:
                                          constraints.maxWidth *
                                          (isMobile ? 0.65 : 0.6),
                                      child: Text(
                                        _horaInicio == null
                                            ? 'Selecciona un horario'
                                            : 'Confirmar Reagendamiento',
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: TextStyle(
                                          fontSize: context.responsiveFontSize(
                                            16,
                                          ),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
