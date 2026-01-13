import Tutoria from '../models/tutorias.js';
import disponibilidadDocente from '../models/disponibilidadDocente.js';
import Docente from '../models/docente.js';
import moment from 'moment';
const { 
  sendMailCancelacionParaDocente,
  sendMailCancelacionParaEstudiante 
} = await import('../config/sendgrid_mailer.js');

// =====================================================
// ✅ NUEVA FUNCIÓN: Calcular turnos disponibles de 20 minutos
// =====================================================
const calcularTurnosDisponibles = (horaInicio, horaFin) => {
  const convertirAMinutos = (hora) => {
    const [h, m] = hora.split(':').map(Number);
    return h * 60 + m;
  };

  const minutosInicio = convertirAMinutos(horaInicio);
  const minutosFin = convertirAMinutos(horaFin);
  const duracionTurno = 20; // minutos

  const turnos = [];
  let actual = minutosInicio;

  while (actual + duracionTurno <= minutosFin) {
    const inicioTurno = `${String(Math.floor(actual / 60)).padStart(2, '0')}:${String(actual % 60).padStart(2, '0')}`;
    const finTurno = `${String(Math.floor((actual + duracionTurno) / 60)).padStart(2, '0')}:${String((actual + duracionTurno) % 60).padStart(2, '0')}`;
    
    turnos.push({
      horaInicio: inicioTurno,
      horaFin: finTurno
    });

    actual += duracionTurno;
  }

  return turnos;
};

// =====================================================
// ✅ NUEVA FUNCIÓN: Obtener turnos disponibles de un bloque
// =====================================================
const obtenerTurnosDisponibles = async (req, res) => {
  try {
    const { docenteId, fecha, horaInicio, horaFin } = req.query;

    if (!docenteId || !fecha || !horaInicio || !horaFin) {
      return res.status(400).json({
        success: false,
        msg: "Faltan parámetros: docenteId, fecha, horaInicio, horaFin"
      });
    }

    console.log(`🔍 Calculando turnos para: ${fecha} ${horaInicio}-${horaFin}`);

    // 1. Calcular todos los turnos posibles de 20 min
    const todosLosTurnos = calcularTurnosDisponibles(horaInicio, horaFin);
    console.log(`   Total turnos calculados: ${todosLosTurnos.length}`);

    // 2. Buscar tutorías ya agendadas en ese bloque
    const tutoriasAgendadas = await Tutoria.find({
      docente: docenteId,
      fecha: fecha,
      estado: { $in: ['pendiente', 'confirmada'] }
    }).select('horaInicio horaFin');

    console.log(`   Tutorías agendadas: ${tutoriasAgendadas.length}`);

    // 3. Filtrar turnos disponibles (sin solapamiento)
    const turnosDisponibles = todosLosTurnos.filter(turno => {
      const turnoOcupado = tutoriasAgendadas.some(tutoria => {
        return !(
          turno.horaFin <= tutoria.horaInicio || 
          turno.horaInicio >= tutoria.horaFin
        );
      });
      return !turnoOcupado;
    });

    console.log(`   Turnos disponibles: ${turnosDisponibles.length}`);

    res.status(200).json({
      success: true,
      bloqueCompleto: {
        horaInicio,
        horaFin
      },
      turnos: {
        total: todosLosTurnos.length,
        disponibles: turnosDisponibles.length,
        ocupados: todosLosTurnos.length - turnosDisponibles.length,
        lista: turnosDisponibles
      }
    });

  } catch (error) {
    console.error("❌ Error calculando turnos:", error);
    res.status(500).json({
      success: false,
      msg: "Error al calcular turnos disponibles",
      error: error.message
    });
  }
};

// =====================================================
// ✅ NUEVA FUNCIÓN: Registrar Tutoría con Sistema de Turnos
// =====================================================
const registrarTutoriaConTurnos = async (req, res) => {
  try {
    const { docente, fecha, horaInicio, horaFin } = req.body;
    const estudiante = req.estudianteBDD?._id;

    if (!estudiante) {
      return res.status(401).json({ msg: "Estudiante no autenticado" });
    }

    // ✅ VALIDACIÓN 1: Duración máxima de 20 minutos
    const convertirAMinutos = (hora) => {
      const [h, m] = hora.split(':').map(Number);
      return h * 60 + m;
    };

    const minutosInicio = convertirAMinutos(horaInicio);
    const minutosFin = convertirAMinutos(horaFin);
    const duracion = minutosFin - minutosInicio;

    if (duracion > 20) {
      return res.status(400).json({
        success: false,
        msg: "La duración del turno no puede exceder 20 minutos"
      });
    }

    if (duracion <= 0) {
      return res.status(400).json({
        success: false,
        msg: "La hora de fin debe ser posterior a la hora de inicio"
      });
    }

    console.log(`📝 Agendando turno: ${horaInicio}-${horaFin} (${duracion} min)`);

    // ✅ VALIDACIÓN 2: Verificar solapamiento EXACTO
    const turnoOcupado = await Tutoria.findOne({
      docente,
      fecha,
      estado: { $in: ['pendiente', 'confirmada'] },
      $or: [
        {
          $and: [
            { horaInicio: { $lt: horaFin } },
            { horaFin: { $gt: horaInicio } }
          ]
        }
      ]
    });

    if (turnoOcupado) {
      console.log(`❌ Turno ocupado: ${turnoOcupado.horaInicio}-${turnoOcupado.horaFin}`);
      return res.status(400).json({ 
        success: false,
        msg: "Este turno ya está ocupado. Por favor, elige otro horario.",
        turnoOcupado: {
          horaInicio: turnoOcupado.horaInicio,
          horaFin: turnoOcupado.horaFin
        }
      });
    }

    // ✅ VALIDACIÓN 3: Verificar que el turno esté dentro de un bloque disponible
    const fechaUTC = new Date(fecha + 'T05:00:00Z');
    const diaSemana = fechaUTC.toLocaleDateString('es-EC', { weekday: 'long' }).toLowerCase();

    const bloquesDisponibles = await disponibilidadDocente.find({ 
      docente, 
      diaSemana 
    });

    if (bloquesDisponibles.length === 0) {
      return res.status(400).json({ 
        success: false,
        msg: "El docente no tiene disponibilidad registrada para ese día." 
      });
    }

    // Verificar que el turno esté dentro de algún bloque
    let bloqueValido = null;
    
    for (const disponibilidad of bloquesDisponibles) {
      for (const bloque of disponibilidad.bloques) {
        const bloqueInicio = convertirAMinutos(bloque.horaInicio);
        const bloqueFin = convertirAMinutos(bloque.horaFin);

        if (minutosInicio >= bloqueInicio && minutosFin <= bloqueFin) {
          bloqueValido = disponibilidad._id;
          break;
        }
      }
      if (bloqueValido) break;
    }

    if (!bloqueValido) {
      return res.status(400).json({ 
        success: false,
        msg: "El turno seleccionado no está dentro del horario disponible del docente." 
      });
    }

    // ✅ VALIDACIÓN 4: No permitir agendar en el pasado
    const hoy = moment().startOf('day');
    const fechaTutoria = moment(fecha, 'YYYY-MM-DD').startOf('day');

    if (fechaTutoria.isBefore(hoy)) {
      return res.status(400).json({ 
        success: false,
        msg: "No puedes agendar tutorías en fechas pasadas." 
      });
    }

    // ✅ VALIDACIÓN 5: Verificar que el estudiante no tenga otro turno en ese horario
    const turnoEstudianteExistente = await Tutoria.findOne({
      estudiante,
      fecha,
      estado: { $in: ['pendiente', 'confirmada'] },
      $or: [
        {
          $and: [
            { horaInicio: { $lt: horaFin } },
            { horaFin: { $gt: horaInicio } }
          ]
        }
      ]
    });

    if (turnoEstudianteExistente) {
      return res.status(400).json({ 
        success: false,
        msg: "Ya tienes una tutoría agendada en ese horario." 
      });
    }

    // ✅ REGISTRAR TUTORÍA
    const nuevaTutoria = new Tutoria({
      estudiante,
      docente,
      fecha,
      horaInicio,
      horaFin,
      bloqueDocenteId: bloqueValido,
      estado: 'pendiente'
    });

    await nuevaTutoria.save();

    // Poblar datos para respuesta
    await nuevaTutoria.populate('docente', 'nombreDocente emailDocente avatarDocente');
    await nuevaTutoria.populate('estudiante', 'nombreEstudiante emailEstudiante fotoPerfil');

    console.log(`✅ Turno agendado: ${nuevaTutoria._id} (${horaInicio}-${horaFin})`);

    res.status(201).json({ 
      success: true,
      msg: "Turno agendado correctamente. El docente revisará tu solicitud.",
      tutoria: nuevaTutoria
    });

  } catch (error) {
    console.error("❌ Error agendando turno:", error);
    res.status(500).json({ 
      success: false,
      msg: 'Error al agendar turno.', 
      error: error.message 
    });
  }
};

// =====================================================
// ✅ REGISTRAR TUTORIA (FUNCIÓN ORIGINAL - SIN CAMBIOS)
// =====================================================
const registrarTutoria = async (req, res) => {
  try {
    const { docente, fecha, horaInicio, horaFin } = req.body;
    const estudiante = req.estudianteBDD?._id;

    if (!estudiante) {
      return res.status(401).json({ msg: "Estudiante no autenticado" });
    }

    // ✅ VALIDACIÓN 1: Verificar que no exista tutoría en ese horario
    const tutoriaExistente = await Tutoria.findOne({
      docente,
      fecha,
      estado: { $in: ['pendiente', 'confirmada'] },
      $or: [
        {
          $and: [
            { horaInicio: { $lte: horaInicio } },
            { horaFin: { $gt: horaInicio } }
          ]
        },
        {
          $and: [
            { horaInicio: { $lt: horaFin } },
            { horaFin: { $gte: horaFin } }
          ]
        },
        {
          $and: [
            { horaInicio: { $gte: horaInicio } },
            { horaFin: { $lte: horaFin } }
          ]
        }
      ]
    });

    if (tutoriaExistente) {
      return res.status(400).json({ 
        msg: "Este horario ya está ocupado. Por favor, elige otro." 
      });
    }

    // ✅ VALIDACIÓN 2: Verificar que el bloque esté en la disponibilidad del docente
    const fechaUTC = new Date(fecha + 'T05:00:00Z');
    const diaSemana = fechaUTC.toLocaleDateString('es-EC', { weekday: 'long' }).toLowerCase();

    const disponibilidad = await disponibilidadDocente.findOne({ 
      docente, 
      diaSemana 
    });

    if (!disponibilidad) {
      return res.status(400).json({ 
        msg: "El docente no tiene disponibilidad registrada para ese día." 
      });
    }

    const bloqueValido = disponibilidad.bloques.some(
      b => b.horaInicio === horaInicio && b.horaFin === horaFin
    );

    if (!bloqueValido) {
      return res.status(400).json({ 
        msg: "Ese bloque no está en el horario disponible del docente." 
      });
    }

    // ✅ VALIDACIÓN 3: No permitir agendar en el pasado
    const hoy = moment().startOf('day');
    const fechaTutoria = moment(fecha, 'YYYY-MM-DD').startOf('day');

    if (fechaTutoria.isBefore(hoy)) {
      return res.status(400).json({ 
        msg: "No puedes agendar tutorías en fechas pasadas." 
      });
    }

    // ✅ VALIDACIÓN 4: Verificar que el estudiante no tenga otra tutoría a la misma hora
    const tutoriaEstudianteExistente = await Tutoria.findOne({
      estudiante,
      fecha,
      estado: { $in: ['pendiente', 'confirmada'] },
      $or: [
        {
          $and: [
            { horaInicio: { $lte: horaInicio } },
            { horaFin: { $gt: horaInicio } }
          ]
        },
        {
          $and: [
            { horaInicio: { $lt: horaFin } },
            { horaFin: { $gte: horaFin } }
          ]
        }
      ]
    });

    if (tutoriaEstudianteExistente) {
      return res.status(400).json({ 
        msg: "Ya tienes una tutoría agendada en ese horario." 
      });
    }

    // ✅ REGISTRAR TUTORÍA
    const nuevaTutoria = new Tutoria({
      estudiante,
      docente,
      fecha,
      horaInicio,
      horaFin,
      estado: 'pendiente'
    });

    await nuevaTutoria.save();

    // Poblar datos para respuesta
    await nuevaTutoria.populate('docente', 'nombreDocente emailDocente avatarDocente');
    await nuevaTutoria.populate('estudiante', 'nombreEstudiante emailEstudiante fotoPerfil');

    console.log(`✅ Tutoría registrada: ${nuevaTutoria._id}`);

    res.status(201).json({ 
      success: true,
      msg: "Solicitud de tutoría enviada correctamente. El docente la revisará pronto.",
      tutoria: nuevaTutoria
    });

  } catch (error) {
    console.error("❌ Error registrando tutoría:", error);
    res.status(500).json({ 
      success: false,
      msg: 'Error al agendar tutoría.', 
      error: error.message 
    });
  }
};

// =====================================================
// ✅ LISTAR TUTORIAS
// =====================================================
const listarTutorias = async (req, res) => {
  try {
    let filtro = {};

    // Filtrar por rol (docente o estudiante autenticado)
    if (req.docenteBDD) {
      filtro.docente = req.docenteBDD._id;
    } else if (req.estudianteBDD) {
      filtro.estudiante = req.estudianteBDD._id;
    }

    // Extraer parámetros de consulta
    const { fecha, estado, incluirCanceladas, soloSemanaActual } = req.query;

    console.log('📋 [listarTutorias] Parámetros:', { 
      fecha, 
      estado, 
      incluirCanceladas, 
      soloSemanaActual,
      usuario: req.estudianteBDD?._id || req.docenteBDD?._id
    });

    // ✅ CORRECCIÓN: Solo filtrar por semana si se solicita explícitamente
    if (soloSemanaActual === 'true') {
      const inicioSemana = moment().startOf('isoWeek').format("YYYY-MM-DD");
      const finSemana = moment().endOf('isoWeek').format("YYYY-MM-DD");
      filtro.fecha = { $gte: inicioSemana, $lte: finSemana };
      console.log('📅 Filtrando por semana actual:', { inicioSemana, finSemana });
    } else if (fecha) {
      // Filtrar por fecha específica
      filtro.fecha = fecha;
      console.log('📅 Filtrando por fecha específica:', fecha);
    }
    // ✅ Si no se especifica, traer TODAS las fechas

    // Filtrar por estado específico
    if (estado) {
      filtro.estado = estado;
      console.log('🏷️ Filtrando por estado:', estado);
    } else {
      // ✅ Excluir canceladas por defecto (a menos que se pidan explícitamente)
      if (incluirCanceladas !== 'true') {
        filtro.estado = { 
          $nin: ['cancelada_por_estudiante', 'cancelada_por_docente'] 
        };
        console.log('🚫 Excluyendo canceladas');
      } else {
        console.log('✅ Incluyendo todas (incluso canceladas)');
      }
    }

    console.log('🔍 Filtro final:', JSON.stringify(filtro, null, 2));

    // Buscar tutorías con populate
    const tutorias = await Tutoria.find(filtro)
      .populate("estudiante", "nombreEstudiante emailEstudiante fotoPerfil")
      .populate("docente", "nombreDocente emailDocente avatarDocente oficinaDocente")
      .sort({ fecha: -1, horaInicio: 1 }); // ✅ Ordenar por fecha DESC, hora ASC

    console.log(`✅ Tutorías encontradas: ${tutorias.length}`);

    // Log detallado para debugging
    if (tutorias.length > 0) {
      console.log('📊 Estados encontrados:', 
        tutorias.reduce((acc, t) => {
          acc[t.estado] = (acc[t.estado] || 0) + 1;
          return acc;
        }, {})
      );
    }

    res.status(200).json({
      success: true,
      total: tutorias.length,
      tutorias
    });
  } catch (error) {
    console.error("❌ Error al listar tutorías:", error);
    res.status(500).json({ 
      success: false,
      msg: "Error al listar tutorías.", 
      error: error.message 
    });
  }
};

// =====================================================
// ✅ ACTUALIZAR TUTORIA
// =====================================================
const actualizarTutoria = async (req, res) => {
  try {
    const { id } = req.params;
    const { fecha, horaInicio, horaFin } = req.body;
    
    const tutoria = await Tutoria.findById(id);

    if (!tutoria) return res.status(404).json({ msg: 'Tutoría no encontrada.' });

    if (['cancelada_por_estudiante', 'cancelada_por_docente'].includes(tutoria.estado)) {
      return res.status(400).json({ msg: 'No se puede modificar una tutoría cancelada.' });
    }

    if (!req.estudianteBDD || tutoria.estudiante.toString() !== req.estudianteBDD._id.toString()) {
      return res.status(403).json({ msg: 'No autorizado para modificar esta tutoría.' });
    }

    // ✅ Validar que la fecha no sea pasada
    const hoy = moment().startOf('day');
    const fechaTutoria = moment(fecha || tutoria.fecha, 'YYYY-MM-DD').startOf('day');

    if (fechaTutoria.isBefore(hoy)) {
      return res.status(400).json({ msg: 'No puedes modificar una tutoría pasada.' });
    }

    // ✅ Solo actualizar campos permitidos
    if (fecha) tutoria.fecha = fecha;
    if (horaInicio) tutoria.horaInicio = horaInicio;
    if (horaFin) tutoria.horaFin = horaFin;

    await tutoria.save();

    res.json({ success: true, tutoria });
  } catch (error) {
    console.error("❌ Error actualizando tutoría:", error);
    res.status(500).json({ mensaje: 'Error al actualizar tutoría.', error: error.message });
  }
};

// =====================================================
// ✅ CANCELAR TUTORIA (ACTUALIZADO CON EMAILS)
// =====================================================
const cancelarTutoria = async (req, res) => {
  try {
    const { id } = req.params;
    const { motivo, canceladaPor } = req.body;

    console.log(`🗑️ Intentando cancelar tutoría: ${id}`);
    console.log(`   Cancelada por: ${canceladaPor}`);

    const tutoria = await Tutoria.findById(id)
      .populate('estudiante', 'nombreEstudiante emailEstudiante')
      .populate('docente', 'nombreDocente emailDocente oficinaDocente');
      
    if (!tutoria) {
      return res.status(404).json({ msg: 'Tutoría no encontrada.' });
    }

    // Validar que no esté ya cancelada
    if (['cancelada_por_estudiante', 'cancelada_por_docente'].includes(tutoria.estado)) {
      return res.status(400).json({ msg: 'Esta tutoría ya fue cancelada.' });
    }

    // Validar fecha Y hora
    const ahora = moment();
    const fechaTutoria = moment(`${tutoria.fecha} ${tutoria.horaInicio}`, 'YYYY-MM-DD HH:mm');

    if (fechaTutoria.isSameOrBefore(ahora)) {
      return res.status(400).json({ 
        msg: 'No puedes cancelar una tutoría que ya comenzó o finalizó.' 
      });
    }

    // Límite de tiempo para cancelación (2 horas antes)
    const horasAnticipacion = fechaTutoria.diff(ahora, 'hours');
    if (horasAnticipacion < 2) {
      return res.status(400).json({ 
        msg: `Debes cancelar con al menos 2 horas de anticipación. Tiempo restante: ${horasAnticipacion} hora(s).` 
      });
    }

    // Determinar el estado correcto
    if (canceladaPor === 'Estudiante') {
      tutoria.estado = 'cancelada_por_estudiante';
    } else if (canceladaPor === 'Docente') {
      tutoria.estado = 'cancelada_por_docente';
    } else {
      return res.status(400).json({ msg: 'Valor de canceladaPor inválido.' });
    }

    tutoria.motivoCancelacion = motivo || 'Sin motivo especificado';
    tutoria.asistenciaEstudiante = null;
    tutoria.observacionesDocente = null;

    await tutoria.save();

    console.log(`✅ Tutoría cancelada: ${tutoria._id}`);
    console.log(`   Nuevo estado: ${tutoria.estado}`);

    // =====================================================
    // ✅ ENVIAR EMAILS DE NOTIFICACIÓN DE CANCELACIÓN
    // =====================================================
    try {
      const { 
        sendMailCancelacionParaDocente,
        sendMailCancelacionParaEstudiante 
      } = await import('../config/nodemailer.js');

      // Formatear fecha para el email
      const formatearFecha = (fecha) => {
        const date = moment(fecha, 'YYYY-MM-DD');
        const dias = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
        const dia = dias[date.day()];
        return `${dia} ${date.format('DD/MM/YYYY')}`;
      };

      const datosTutoria = {
        fecha: formatearFecha(tutoria.fecha),
        horaInicio: tutoria.horaInicio,
        horaFin: tutoria.horaFin,
        oficinaDocente: tutoria.docente.oficinaDocente
      };

      if (canceladaPor === 'Estudiante') {
        // Notificar al docente
        await sendMailCancelacionParaDocente(
          tutoria.docente.emailDocente,
          tutoria.docente.nombreDocente,
          tutoria.estudiante.nombreEstudiante,
          datosTutoria,
          motivo
        );
        console.log('📧 Email de cancelación enviado al docente');
      } else {
        // Notificar al estudiante
        await sendMailCancelacionParaEstudiante(
          tutoria.estudiante.emailEstudiante,
          tutoria.estudiante.nombreEstudiante,
          tutoria.docente.nombreDocente,
          datosTutoria,
          motivo
        );
        console.log('📧 Email de cancelación enviado al estudiante');
      }
    } catch (emailError) {
      // No fallar la operación si el email falla
      console.error('⚠️ Error enviando email de cancelación:', emailError);
    }

    res.status(200).json({ 
      success: true,
      msg: 'Tutoría cancelada correctamente. Se ha enviado una notificación por correo.', 
      tutoria: {
        _id: tutoria._id,
        estado: tutoria.estado,
        motivoCancelacion: tutoria.motivoCancelacion
      }
    });

  } catch (error) {
    console.error("❌ Error al cancelar tutoría:", error);
    res.status(500).json({ 
      success: false,
      msg: 'Error al cancelar la tutoría.', 
      error: error.message 
    });
  }
};

// =====================================================
// ✅ REAGENDAR TUTORÍA - VERSIÓN FINAL CORREGIDA
// Solo valida materias activas para el NUEVO horario
// Ignora la materia original (puede estar inactiva)
// =====================================================

export const reagendarTutoria = async (req, res) => {
  try {
    const { id } = req.params;
    const { nuevaFecha, nuevaHoraInicio, nuevaHoraFin, motivo } = req.body;

    console.log(`🔄 Intentando reagendar tutoría: ${id}`);

    const tutoria = await Tutoria.findById(id)
      .populate('estudiante', 'nombreEstudiante emailEstudiante')
      .populate('docente', 'nombreDocente emailDocente');
    
    if (!tutoria) {
      return res.status(404).json({
        success: false,
        msg: 'Tutoría no encontrada'
      });
    }

    // ✅ VALIDACIÓN 1: Permisos (estudiante o docente de la tutoría)
    const esEstudiante = req.estudianteBDD && 
                         tutoria.estudiante._id.toString() === req.estudianteBDD._id.toString();
    const esDocente = req.docenteBDD && 
                      tutoria.docente._id.toString() === req.docenteBDD._id.toString();

    if (!esEstudiante && !esDocente) {
      return res.status(403).json({
        success: false,
        msg: 'No tienes permiso para reagendar esta tutoría'
      });
    }

    // ✅ VALIDACIÓN 2: Estados permitidos
    const estadosPermitidos = ['pendiente', 'confirmada'];
    if (!estadosPermitidos.includes(tutoria.estado)) {
      return res.status(400).json({
        success: false,
        msg: `No se puede reagendar una tutoría ${tutoria.estado}`
      });
    }

    // ✅ VALIDACIÓN CRÍTICA: Verificar si la tutoría ya expiró
    const fechaHoraTutoria = moment(`${tutoria.fecha} ${tutoria.horaFin}`, 'YYYY-MM-DD HH:mm');
    const ahora = moment();

    if (fechaHoraTutoria.isBefore(ahora)) {
      console.log(`⏰ Tutoría expirada detectada: ${tutoria._id}`);
      tutoria.estado = 'expirada';
      await tutoria.save();

      return res.status(400).json({
        success: false,
        msg: 'Esta tutoría ya expiró. Por favor, agenda una nueva tutoría con el docente.',
        estado: 'expirada'
      });
    }

    // Validaciones de campos
    if (!nuevaFecha || !nuevaHoraInicio || !nuevaHoraFin) {
      return res.status(400).json({
        success: false,
        msg: 'Nueva fecha, hora inicio y hora fin son obligatorios'
      });
    }

    // Validar que la nueva fecha no sea pasada
    const hoy = moment().startOf('day');
    const nuevaFechaTutoria = moment(nuevaFecha, 'YYYY-MM-DD').startOf('day');

    if (nuevaFechaTutoria.isBefore(hoy)) {
      return res.status(400).json({
        success: false,
        msg: 'No puedes reagendar para una fecha pasada'
      });
    }

    // Validación: Anticipación de 2 horas
    const fechaHoraNueva = moment(`${nuevaFecha} ${nuevaHoraInicio}`, 'YYYY-MM-DD HH:mm');
    const horasAnticipacion = fechaHoraNueva.diff(ahora, 'hours', true);

    if (horasAnticipacion < 2) {
      return res.status(400).json({
        success: false,
        msg: `Debes reagendar con al menos 2 horas de anticipación. Tiempo disponible: ${horasAnticipacion.toFixed(1)} horas`
      });
    }

    // Validación: Duración del turno (máximo 20 minutos)
    const convertirAMinutos = (hora) => {
      const [h, m] = hora.split(':').map(Number);
      return h * 60 + m;
    };

    const minutosInicio = convertirAMinutos(nuevaHoraInicio);
    const minutosFin = convertirAMinutos(nuevaHoraFin);
    const duracion = minutosFin - minutosInicio;

    if (duracion > 20) {
      return res.status(400).json({
        success: false,
        msg: 'La duración del turno no puede exceder 20 minutos'
      });
    }

    if (duracion <= 0) {
      return res.status(400).json({
        success: false,
        msg: 'La hora de fin debe ser posterior a la hora de inicio'
      });
    }

    // ========================================================================
    // ✅ PASO 1: Obtener SOLO materias ACTIVAS del docente
    // ========================================================================
    console.log('🔍 [PASO 1] Obteniendo materias activas del docente...');
    
    const Docente = (await import('../models/docente.js')).default;
    const docenteCompleto = await Docente.findById(tutoria.docente._id);
    
    if (!docenteCompleto) {
      return res.status(404).json({
        success: false,
        msg: 'Docente no encontrado'
      });
    }

    let materiasActivas = docenteCompleto.asignaturas || [];
    
    if (typeof materiasActivas === 'string') {
      try {
        materiasActivas = JSON.parse(materiasActivas);
      } catch {
        materiasActivas = [];
      }
    }

    console.log(`📚 Materias activas del docente: ${materiasActivas.join(', ')}`);

    if (materiasActivas.length === 0) {
      return res.status(400).json({
        success: false,
        msg: 'El docente no tiene materias activas asignadas'
      });
    }

    // ========================================================================
    // ✅ PASO 2: Identificar materia del NUEVO horario (debe estar ACTIVA)
    // ========================================================================
    console.log('🔍 [PASO 2] Identificando materia del nuevo horario...');
    
    // Obtener el día de la semana del NUEVO horario
    const fechaUTC = new Date(nuevaFecha + 'T05:00:00Z');
    const diaSemana = fechaUTC.toLocaleDateString('es-EC', { weekday: 'long' }).toLowerCase();
    
    console.log(`   Nuevo día: ${diaSemana}`);
    console.log(`   Nuevo horario: ${nuevaHoraInicio} - ${nuevaHoraFin}`);
    
    // ✅ BUSCAR EN QUÉ MATERIA ACTIVA CABE EL NUEVO HORARIO
    const bloquesDisponiblesNuevoHorario = await disponibilidadDocente.find({
      docente: tutoria.docente._id,
      diaSemana: diaSemana,
      materia: { $in: materiasActivas }  // ✅ SOLO MATERIAS ACTIVAS
    });
    
    if (bloquesDisponiblesNuevoHorario.length === 0) {
      return res.status(400).json({
        success: false,
        msg: `El docente no tiene disponibilidad registrada en materias activas para los días ${diaSemana}s`
      });
    }
    
    // ✅ ENCONTRAR EN QUÉ MATERIA Y BLOQUE CABE EL NUEVO HORARIO
    let materiaNuevoHorario = null;
    let bloqueValidoNuevoHorario = false;
    let nuevoBloqueMateriaId = null;
    
    for (const disponibilidad of bloquesDisponiblesNuevoHorario) {
      for (const bloque of disponibilidad.bloques) {
        const bloqueInicio = convertirAMinutos(bloque.horaInicio);
        const bloqueFin = convertirAMinutos(bloque.horaFin);

        if (minutosInicio >= bloqueInicio && minutosFin <= bloqueFin) {
          bloqueValidoNuevoHorario = true;
          materiaNuevoHorario = disponibilidad.materia;
          nuevoBloqueMateriaId = disponibilidad._id;
          break;
        }
      }
      if (bloqueValidoNuevoHorario) break;
    }
    
    if (!bloqueValidoNuevoHorario || !materiaNuevoHorario) {
      return res.status(400).json({
        success: false,
        msg: `El horario ${nuevaHoraInicio}-${nuevaHoraFin} no está disponible en ninguna materia activa del docente los días ${diaSemana}s`
      });
    }
    
    console.log(`✅ Nuevo horario asignado a materia activa: ${materiaNuevoHorario}`);

    // ========================================================================
    // ✅ PASO 3: Verificar que el nuevo horario no esté ocupado
    // ========================================================================
    console.log('🔍 [PASO 3] Verificando que el horario no esté ocupado...');
    
    // Verificar que el nuevo horario no esté ocupado POR OTRAS TUTORÍAS
    const horarioOcupado = await Tutoria.findOne({
      docente: tutoria.docente._id,
      fecha: nuevaFecha,
      _id: { $ne: id },
      estado: { $in: ['pendiente', 'confirmada'] },
      $or: [
        {
          $and: [
            { horaInicio: { $lt: nuevaHoraFin } },
            { horaFin: { $gt: nuevaHoraInicio } }
          ]
        }
      ]
    });

    if (horarioOcupado) {
      return res.status(400).json({
        success: false,
        msg: `El horario ${nuevaHoraInicio}-${nuevaHoraFin} ya está ocupado el ${nuevaFecha}`,
        turnoOcupado: {
          horaInicio: horarioOcupado.horaInicio,
          horaFin: horarioOcupado.horaFin
        }
      });
    }

    // Verificar conflictos del estudiante
    const conflictoEstudiante = await Tutoria.findOne({
      estudiante: tutoria.estudiante._id,
      fecha: nuevaFecha,
      _id: { $ne: id },
      estado: { $in: ['pendiente', 'confirmada'] },
      $or: [
        {
          $and: [
            { horaInicio: { $lt: nuevaHoraFin } },
            { horaFin: { $gt: nuevaHoraInicio } }
          ]
        }
      ]
    });

    if (conflictoEstudiante) {
      return res.status(400).json({
        success: false,
        msg: 'Ya tienes otra tutoría agendada en ese horario'
      });
    }
    
    console.log('✅ No hay conflictos de horario');

    // ========================================================================
    // ✅ PASO 4: Actualizar tutoría
    // ========================================================================
    console.log('💾 [PASO 4] Actualizando tutoría...');
    console.log(`   Materia del nuevo horario: ${materiaNuevoHorario}`);
    
    // Guardar datos anteriores para el email
    const datosAnteriores = {
      fechaAnterior: tutoria.fecha,
      horaInicioAnterior: tutoria.horaInicio,
      horaFinAnterior: tutoria.horaFin
    };

    // Actualizar tutoría
    tutoria.fecha = nuevaFecha;
    tutoria.horaInicio = nuevaHoraInicio;
    tutoria.horaFin = nuevaHoraFin;
    
    if (nuevoBloqueMateriaId) {
      tutoria.bloqueDocenteId = nuevoBloqueMateriaId;
    }
    
    if (tutoria.estado === 'confirmada') {
      tutoria.estado = 'pendiente';
    }

    // ✅ Guardar quién reagendó
    tutoria.reagendadaPor = esEstudiante ? 'Estudiante' : 'Docente';
    tutoria.fechaReagendamiento = new Date();
    
    // ✅ GUARDAR MOTIVO EN BD:
    // Siempre guardar algo para registros internos
    if (motivo && motivo.trim() !== '') {
      tutoria.motivoReagendamiento = motivo.trim();
    } else {
      tutoria.motivoReagendamiento = esEstudiante 
        ? 'Reagendada por el estudiante' 
        : 'Reagendada por el docente';
    }

    await tutoria.save();

    // =====================================================
    // ✅ ENVIAR EMAIL SEGÚN QUIÉN REAGENDÓ
    // =====================================================
    
    try {
      // Formatear fechas para el email
      const formatearFecha = (fecha) => {
        const date = moment(fecha, 'YYYY-MM-DD');
        const dias = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
        const dia = dias[date.day()];
        return `${dia} ${date.format('DD/MM/YYYY')}`;
      };

      // ✅ PREPARAR MOTIVO PARA EMAIL:
      // IMPORTANTE: El parámetro "motivo" viene del request.body
      // NO usar tutoria.motivoReagendamiento porque ya tiene el texto por defecto
      const motivoParaEmail = (req.body.motivo && req.body.motivo.trim() !== '') 
        ? req.body.motivo.trim() 
        : null;

      const datosEmail = {
        fechaAnterior: formatearFecha(datosAnteriores.fechaAnterior),
        horaInicioAnterior: datosAnteriores.horaInicioAnterior,
        horaFinAnterior: datosAnteriores.horaFinAnterior,
        fechaNueva: formatearFecha(nuevaFecha),
        horaInicioNueva: nuevaHoraInicio,
        horaFinNueva: nuevaHoraFin,
        motivo: motivoParaEmail  // ✅ Solo se muestra si hay motivo real
      };

      if (esDocente) {
        // 📧 DOCENTE reagendó -> Enviar email al ESTUDIANTE
        console.log('📧 Enviando email al estudiante...');
        await sendMailReagendamientoDocente(
          tutoria.estudiante.emailEstudiante,
          tutoria.estudiante.nombreEstudiante,
          tutoria.docente.nombreDocente,
          datosEmail
        );
      } else {
        // 📧 ESTUDIANTE reagendó -> Enviar email al DOCENTE
        console.log('📧 Enviando email al docente...');
        await sendMailReagendamientoEstudiante(
          tutoria.docente.emailDocente,
          tutoria.docente.nombreDocente,
          tutoria.estudiante.nombreEstudiante,
          datosEmail
        );
      }
    } catch (emailError) {
      // No fallar la operación si el email falla
      console.error('⚠️ Error enviando email de reagendamiento:', emailError);
      // Continuar con la respuesta exitosa
    }

    // Repoblar datos para respuesta
    await tutoria.populate('docente', 'nombreDocente emailDocente avatarDocente');
    await tutoria.populate('estudiante', 'nombreEstudiante emailEstudiante fotoPerfil');

    console.log(`✅ Tutoría reagendada exitosamente`);

    res.status(200).json({
      success: true,
      msg: 'Tutoría reagendada exitosamente. Se ha enviado una notificación por correo.',
      tutoria,
      datosAnteriores,
      materia: materiaNuevoHorario  // ✅ Retornar la materia del NUEVO horario
    });

  } catch (error) {
    console.error("❌ Error al reagendar tutoría:", error);
    res.status(500).json({
      success: false,
      msg: 'Error al reagendar la tutoría',
      error: error.message
    });
  }
};

// =====================================================
// ✅ OBTENER HISTORIAL COMPLETO DE TUTORÍAS CON FILTROS
// =====================================================
export const obtenerHistorialTutorias = async (req, res) => {
  try {
    const { 
      fechaInicio, 
      fechaFin, 
      estado, 
      materia,
      incluirCanceladas = 'true',
      limit = 50,
      page = 1
    } = req.query;

    console.log('📊 Obteniendo historial de tutorías');

    // Construir filtro base
    let filtro = {};

    // Filtrar por rol
    if (req.docenteBDD) {
      filtro.docente = req.docenteBDD._id;
    } else if (req.estudianteBDD) {
      filtro.estudiante = req.estudianteBDD._id;
    } else {
      return res.status(403).json({
        success: false,
        msg: 'No autorizado'
      });
    }

    // Filtrar por rango de fechas
    if (fechaInicio || fechaFin) {
      filtro.fecha = {};
      if (fechaInicio) filtro.fecha.$gte = fechaInicio;
      if (fechaFin) filtro.fecha.$lte = fechaFin;
    }

    // Filtrar por estado
    if (estado) {
      filtro.estado = estado;
    } else if (incluirCanceladas !== 'true') {
      filtro.estado = { 
        $nin: ['cancelada_por_estudiante', 'cancelada_por_docente'] 
      };
    }

    // Paginación
    const skip = (parseInt(page) - 1) * parseInt(limit);

    // Ejecutar consulta
    const tutorias = await Tutoria.find(filtro)
      .populate("estudiante", "nombreEstudiante emailEstudiante fotoPerfil")
      .populate("docente", "nombreDocente emailDocente avatarDocente oficinaDocente")
      .sort({ fecha: -1, horaInicio: -1 })
      .limit(parseInt(limit))
      .skip(skip);

    // Contar total
    const total = await Tutoria.countDocuments(filtro);

    // Estadísticas
    const estadisticas = await Tutoria.aggregate([
      { $match: filtro },
      {
        $group: {
          _id: '$estado',
          count: { $sum: 1 }
        }
      }
    ]);

    const stats = {};
    estadisticas.forEach(stat => {
      stats[stat._id] = stat.count;
    });

    console.log(`✅ Historial obtenido: ${tutorias.length} tutorías`);
    console.log(`   Total en BD: ${total}`);
    console.log(`   Estadísticas:`, stats);

    res.status(200).json({
      success: true,
      total,
      page: parseInt(page),
      totalPages: Math.ceil(total / parseInt(limit)),
      limit: parseInt(limit),
      tutorias,
      estadisticas: stats
    });

  } catch (error) {
    console.error("❌ Error obteniendo historial:", error);
    res.status(500).json({
      success: false,
      msg: 'Error al obtener historial',
      error: error.message
    });
  }
};

// backend/src/controllers/tutorias_controller.js

// =====================================================
// ✅ GENERAR REPORTE DE TUTORÍAS POR MATERIAS
// =====================================================
export const generarReportePorMaterias = async (req, res) => {
  try {
    const docente = req.docenteBDD?._id;

    if (!docente) {
      return res.status(401).json({
        success: false,
        msg: 'Docente no autenticado'
      });
    }

    const { fechaInicio, fechaFin, formato = 'json' } = req.query;

    console.log('📊 Generando reporte por materias');
    console.log(`   Docente: ${req.docenteBDD.nombreDocente}`);
    console.log(`   Período: ${fechaInicio || 'Inicio'} - ${fechaFin || 'Hoy'}`);

    // Construir filtro
    let filtro = { docente };

    if (fechaInicio || fechaFin) {
      filtro.fecha = {};
      if (fechaInicio) filtro.fecha.$gte = fechaInicio;
      if (fechaFin) filtro.fecha.$lte = fechaFin;
    }

    // Obtener todas las tutorías del período
    const tutorias = await Tutoria.find(filtro)
      .populate('estudiante', 'nombreEstudiante emailEstudiante')
      .populate('docente', 'nombreDocente asignaturas')
      .sort({ fecha: -1 });

    // Obtener materias del docente
    const docenteCompleto = await Docente.findById(docente);
    let materias = docenteCompleto.asignaturas || [];

    if (typeof materias === 'string') {
      try {
        materias = JSON.parse(materias);
      } catch {
        materias = [];
      }
    }

    // Obtener horarios por materia
    const horariosPorMateria = await disponibilidadDocente.find({
      docente
    }).lean();

    // Agrupar tutorías por materia
    const reportePorMateria = {};

    for (const materia of materias) {
      // Obtener horarios de esta materia
      const horariosMateria = horariosPorMateria.filter(h => h.materia === materia);
      
      // Filtrar tutorías que corresponden a los horarios de esta materia
      const tutoriasMateria = tutorias.filter(t => {
        // Verificar si la tutoría está en algún horario de esta materia
        return horariosMateria.some(h => {
          if (h.diaSemana !== obtenerDiaSemana(t.fecha)) return false;
          
          return h.bloques.some(b => {
            return estaEnRango(t.horaInicio, t.horaFin, b.horaInicio, b.horaFin);
          });
        });
      });

      // Calcular estadísticas
      const stats = {
        total: tutoriasMateria.length,
        pendientes: tutoriasMateria.filter(t => t.estado === 'pendiente').length,
        confirmadas: tutoriasMateria.filter(t => t.estado === 'confirmada').length,
        finalizadas: tutoriasMateria.filter(t => t.estado === 'finalizada').length,
        canceladas: tutoriasMateria.filter(t => 
          t.estado === 'cancelada_por_estudiante' || 
          t.estado === 'cancelada_por_docente'
        ).length,
        reagendadas: tutoriasMateria.filter(t => t.reagendadaPor).length,
        asistencias: tutoriasMateria.filter(t => t.asistenciaEstudiante === true).length,
        inasistencias: tutoriasMateria.filter(t => t.asistenciaEstudiante === false).length,
      };

      // Calcular tasas
      stats.tasaAsistencia = stats.finalizadas > 0 
        ? ((stats.asistencias / stats.finalizadas) * 100).toFixed(2) + '%'
        : 'N/A';

      stats.tasaCancelacion = stats.total > 0
        ? ((stats.canceladas / stats.total) * 100).toFixed(2) + '%'
        : 'N/A';

      reportePorMateria[materia] = {
        estadisticas: stats,
        tutorias: tutoriasMateria.map(t => ({
          _id: t._id,
          estudiante: t.estudiante?.nombreEstudiante || 'N/A',
          fecha: t.fecha,
          horario: `${t.horaInicio} - ${t.horaFin}`,
          estado: t.estado,
          asistencia: t.asistenciaEstudiante,
          reagendada: t.reagendadaPor ? true : false
        }))
      };
    }

    // Estadísticas globales
    const estadisticasGlobales = {
      totalTutorias: tutorias.length,
      materiasActivas: Object.keys(reportePorMateria).length,
      periodo: {
        inicio: fechaInicio || tutorias[tutorias.length - 1]?.fecha || 'N/A',
        fin: fechaFin || tutorias[0]?.fecha || 'N/A'
      }
    };

    console.log(`✅ Reporte generado`);
    console.log(`   Materias: ${estadisticasGlobales.materiasActivas}`);
    console.log(`   Total tutorías: ${estadisticasGlobales.totalTutorias}`);

    // Responder según formato solicitado
    if (formato === 'csv') {
      return generarCSV(res, reportePorMateria, estadisticasGlobales);
    }

    res.status(200).json({
      success: true,
      docente: {
        id: docenteCompleto._id,
        nombre: docenteCompleto.nombreDocente
      },
      estadisticasGlobales,
      reportePorMateria
    });

  } catch (error) {
    console.error("❌ Error generando reporte:", error);
    res.status(500).json({
      success: false,
      msg: 'Error al generar reporte',
      error: error.message
    });
  }
};

// Funciones auxiliares
const obtenerDiaSemana = (fecha) => {
  const fechaUTC = new Date(fecha + 'T05:00:00Z');
  return fechaUTC.toLocaleDateString('es-EC', { weekday: 'long' }).toLowerCase();
};

const estaEnRango = (inicio1, fin1, inicio2, fin2) => {
  const convertir = (hora) => {
    const [h, m] = hora.split(':').map(Number);
    return h * 60 + m;
  };

  const i1 = convertir(inicio1);
  const f1 = convertir(fin1);
  const i2 = convertir(inicio2);
  const f2 = convertir(fin2);

  return (i1 >= i2 && i1 < f2) || (f1 > i2 && f1 <= f2) || (i1 <= i2 && f1 >= f2);
};

const generarCSV = (res, reporte, stats) => {
  let csv = 'Materia,Total,Pendientes,Confirmadas,Finalizadas,Canceladas,Tasa Asistencia,Tasa Cancelación\n';
  
  for (const [materia, datos] of Object.entries(reporte)) {
    const e = datos.estadisticas;
    csv += `"${materia}",${e.total},${e.pendientes},${e.confirmadas},${e.finalizadas},${e.canceladas},${e.tasaAsistencia},${e.tasaCancelacion}\n`;
  }

  res.setHeader('Content-Type', 'text/csv');
  res.setHeader('Content-Disposition', `attachment; filename="reporte_tutorias_${Date.now()}.csv"`);
  res.send(csv);
};

// =====================================================
// ✅ REGISTRAR ASISTENCIA
// =====================================================
const registrarAsistencia = async (req, res) => {
  try {
    const { id } = req.params;
    const { asistio, observaciones } = req.body;

    const tutoria = await Tutoria.findById(id);
    if (!tutoria) return res.status(404).json({ msg: 'Tutoría no encontrada.' });

    if (['cancelada_por_estudiante', 'cancelada_por_docente'].includes(tutoria.estado)) {
      return res.status(400).json({ msg: 'No se puede registrar asistencia en una tutoría cancelada.' });
    }

    if (tutoria.asistenciaEstudiante !== null) {
      return res.status(400).json({ msg: 'La asistencia ya fue registrada.' });
    }

    tutoria.asistenciaEstudiante = asistio;
    tutoria.observacionesDocente = observaciones || null;
    tutoria.estado = 'finalizada';

    await tutoria.save();

    res.json({ msg: 'Asistencia registrada exitosamente.', tutoria });
  } catch (error) {
    res.status(500).json({ msg: 'Error al registrar asistencia.', error });
  }
};

// =====================================================
// ✅ REGISTRAR DISPONIBILIDAD GENERAL (LEGACY)
// =====================================================
const registrarDisponibilidadDocente = async (req, res) => {
  try {
    const { diaSemana, bloques } = req.body;
    const docente = req.docenteBDD?._id;
    if (!docente) return res.status(401).json({ msg: "Docente no autenticado" });

    let disponibilidad = await disponibilidadDocente.findOne({ docente, diaSemana });

    if (disponibilidad) {
      disponibilidad.bloques = bloques;
    } else {
      disponibilidad = new disponibilidadDocente({ docente, diaSemana, bloques });
    }

    await disponibilidad.save();
    res.status(200).json({ msg: "Su horario se actualizó con éxito.", disponibilidad });
  } catch (error) {
    res.status(500).json({ msg: "Error al actualizar disponibilidad", error });
  }
};

// =====================================================
// ✅ VER DISPONIBILIDAD GENERAL (LEGACY)
// =====================================================
const verDisponibilidadDocente = async (req, res) => {
  try {
    const { docenteId } = req.params;

    const disponibilidad = await disponibilidadDocente.find({ docente: docenteId });

    if (!disponibilidad || disponibilidad.length === 0) {
      return res.status(404).json({ msg: "El docente no tiene disponibilidad registrada." });
    }

    res.status(200).json({ disponibilidad });
  } catch (error) {
    res.status(500).json({ msg: "Error al obtener la disponibilidad.", error });
  }
};

// =====================================================
// ✅ BLOQUES OCUPADOS DOCENTE
// =====================================================
const bloquesOcupadosDocente = async (req, res) => {
  try {
    const { docenteId } = req.params;

    const inicioSemana = moment().startOf('isoWeek').format("YYYY-MM-DD");
    const finSemana = moment().endOf('isoWeek').format("YYYY-MM-DD");

    const ocupados = await Tutoria.find({
      docente: docenteId,
      fecha: { $gte: inicioSemana, $lte: finSemana },
      estado: { $in: ['pendiente', 'confirmada'] }
    }).select("fecha horaInicio horaFin");

    const resultado = ocupados.map(o => {
      const fechaUTC = new Date(o.fecha + 'T05:00:00Z');
      const diaSemana = fechaUTC.toLocaleDateString('es-EC', { weekday: 'long' }).toLowerCase();

      return {
        diaSemana,
        fecha: o.fecha,
        horaInicio: o.horaInicio,
        horaFin: o.horaFin
      };
    });

    res.json(resultado);
  } catch (error) {
    res.status(500).json({ msg: "Error al obtener bloques ocupados.", error });
  }
};

/**
 * ✅ VALIDAR CRUCES DE HORARIOS
 * Verifica que no haya solapamiento entre bloques del mismo día
 */
const validarCrucesHorarios = (bloques) => {
  // Convertir hora a minutos
  const convertirAMinutos = (hora) => {
    const [h, m] = hora.split(':').map(Number);
    return h * 60 + m;
  };

  // Ordenar por hora de inicio
  const bloquesOrdenados = bloques
    .map(b => ({
      inicio: convertirAMinutos(b.horaInicio),
      fin: convertirAMinutos(b.horaFin),
      horaInicio: b.horaInicio,
      horaFin: b.horaFin
    }))
    .sort((a, b) => a.inicio - b.inicio);

  // Verificar solapamientos consecutivos
  for (let i = 0; i < bloquesOrdenados.length - 1; i++) {
    const bloqueActual = bloquesOrdenados[i];
    const bloqueSiguiente = bloquesOrdenados[i + 1];

    if (bloqueActual.fin > bloqueSiguiente.inicio) {
      return {
        valido: false,
        mensaje: `Cruce detectado: ${bloqueActual.horaInicio}-${bloqueActual.horaFin} se solapa con ${bloqueSiguiente.horaInicio}-${bloqueSiguiente.horaFin}`
      };
    }
  }

  return { valido: true };
};

/**
 * ✅ VALIDACIÓN 2: Cruces locales POR DÍA
 * CAMBIO CRÍTICO: Agrupa por día ANTES de validar
 */
const validarCrucesLocales = ({ bloques }) => {
  console.log('🔍 Validación local de cruces');
  
  // ✅ PASO 1: Agrupar bloques POR DÍA
  const bloquesPorDia = {};
  
  for (const bloque of bloques) {
    const dia = bloque.dia.toString().toLowerCase();
    
    if (!bloquesPorDia[dia]) {
      bloquesPorDia[dia] = [];
    }
    
    bloquesPorDia[dia].push(bloque);
  }
  
  console.log(`   Días a validar: ${Object.keys(bloquesPorDia).join(', ')}`);
  
  // ✅ PASO 2: Validar cruces DENTRO de cada día
  for (const [dia, bloquesDelDia] of Object.entries(bloquesPorDia)) {
    console.log(`   Validando ${dia}: ${bloquesDelDia.length} bloques`);
    
    // Ordenar por hora de inicio
    bloquesDelDia.sort((a, b) => {
      const aInicio = _convertirAMinutos(a.horaInicio);
      const bInicio = _convertirAMinutos(b.horaInicio);
      return aInicio - bInicio;
    });
    
    // Verificar solapamientos entre bloques consecutivos
    for (let i = 0; i < bloquesDelDia.length - 1; i++) {
      const bloqueActual = bloquesDelDia[i];
      const bloqueSiguiente = bloquesDelDia[i + 1];
      
      const finActual = _convertirAMinutos(bloqueActual.horaFin);
      const inicioSiguiente = _convertirAMinutos(bloqueSiguiente.horaInicio);
      
      if (finActual > inicioSiguiente) {
        return {
          valido: false,
          mensaje: `Cruce en ${dia}: ${bloqueActual.horaInicio}-${bloqueActual.horaFin} se solapa con ${bloqueSiguiente.horaInicio}-${bloqueSiguiente.horaFin}`
        };
      }
    }
  }
  
  console.log('   ✅ Sin cruces locales');
  return { valido: true };
};

/**
 * ✅ VALIDAR CRUCES ENTRE MATERIAS (SOLO MATERIAS ACTIVAS DEL DOCENTE)
 * CORRECCIÓN: Ignora horarios de materias que el docente ya no imparte
 */
const validarCrucesEntreMaterias = async (docenteId, materia, diaSemana, bloquesNuevos) => {
  try {
    console.log('🔍 Validando cruces entre materias:');
    console.log('   Docente:', docenteId);
    console.log('   Materia actual:', materia);
    console.log('   Día:', diaSemana);
    console.log('   Bloques nuevos:', bloquesNuevos.length);

    // ✅ PASO 1: Obtener materias ACTUALMENTE ASIGNADAS al docente
    const docente = await Docente.findById(docenteId);

    if (!docente) {
      return { 
        valido: false, 
        mensaje: 'Docente no encontrado' 
      };
    }

    let materiasActivas = docente.asignaturas || [];
    
    // Parsear si viene como string
    if (typeof materiasActivas === 'string') {
      try {
        materiasActivas = JSON.parse(materiasActivas);
      } catch {
        materiasActivas = [];
      }
    }

    console.log(`   📚 Materias activas del docente: ${materiasActivas.join(', ')}`);

    // ✅ PASO 2: Normalizar día
    let diaNormalizado = diaSemana
      .toLowerCase()
      .trim()
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '');

    const mapaValidos = {
      'lunes': 'lunes',
      'martes': 'martes',
      'miercoles': 'miércoles',
      'miércoles': 'miércoles',
      'jueves': 'jueves',
      'viernes': 'viernes'
    };
    
    diaNormalizado = mapaValidos[diaNormalizado] || diaNormalizado;
    console.log(`   Día normalizado: "${diaNormalizado}"`);

    // ✅ PASO 3: Buscar horarios del mismo día, PERO SOLO DE MATERIAS ACTIVAS
    const disponibilidadesExistentes = await disponibilidadDocente.find({
      docente: docenteId,
      diaSemana: diaNormalizado,
      materia: { 
        $ne: materia,              // ✅ Diferente a la materia actual
        $in: materiasActivas       // ✅ CRÍTICO: Solo materias activas
      }
    });

    console.log(`   Disponibilidades ACTIVAS en "${diaNormalizado}":`, disponibilidadesExistentes.length);

    if (disponibilidadesExistentes.length === 0) {
      console.log('   ✅ No hay otras materias activas en este día');
      return { valido: true };
    }

    // ✅ PASO 4: Recopilar bloques de materias activas
    const bloquesExistentes = [];
    disponibilidadesExistentes.forEach(disp => {
      console.log(`   📚 Materia activa: ${disp.materia} (${disp.bloques.length} bloques)`);
      disp.bloques.forEach(b => {
        bloquesExistentes.push({
          materia: disp.materia,
          horaInicio: b.horaInicio,
          horaFin: b.horaFin
        });
      });
    });

    // ✅ PASO 5: Verificar solapamientos
    for (const bloqueNuevo of bloquesNuevos) {
      const nuevoInicio = _convertirAMinutos(bloqueNuevo.horaInicio);
      const nuevoFin = _convertirAMinutos(bloqueNuevo.horaFin);

      for (const bloqueExistente of bloquesExistentes) {
        const existenteInicio = _convertirAMinutos(bloqueExistente.horaInicio);
        const existenteFin = _convertirAMinutos(bloqueExistente.horaFin);

        const haySolapamiento = 
          (nuevoInicio < existenteFin && nuevoFin > existenteInicio);

        if (haySolapamiento) {
          const mensaje = `El bloque ${bloqueNuevo.horaInicio}-${bloqueNuevo.horaFin} de "${materia}" ` +
                         `se cruza con ${bloqueExistente.horaInicio}-${bloqueExistente.horaFin} de "${bloqueExistente.materia}" ` +
                         `el día ${diaSemana}`;
          
          console.log(`   ❌ CRUCE DETECTADO: ${mensaje}`);
          return { valido: false, mensaje };
        }
      }
    }

    console.log('   ✅ No se detectaron cruces con materias activas');
    return { valido: true };
    
  } catch (error) {
    console.error('❌ Error validando cruces entre materias:', error);
    return { 
      valido: false, 
      mensaje: 'Error al validar cruces de horarios' 
    };
  }
};

/**
 * ✅ FUNCIÓN AUXILIAR: Convertir hora a minutos
 */
const _convertirAMinutos = (hora) => {
  try {
    const [h, m] = hora.split(':').map(Number);
    return h * 60 + m;
  } catch (e) {
    console.log('⚠️ Error convirtiendo hora:', hora);
    return 0;
  }
};

/**
 * ✅ FUNCIÓN AUXILIAR: Agrupar bloques por día
 */
const _agruparPorDia = (bloques) => {
  const resultado = {};
  
  for (const bloque of bloques) {
    const dia = bloque.dia.toString().toLowerCase();
    
    if (!resultado[dia]) {
      resultado[dia] = [];
    }
    
    resultado[dia].push({
      horaInicio: bloque.horaInicio,
      horaFin: bloque.horaFin
    });
  }
  
  return resultado;
};

// =====================================================
// ✅ REGISTRAR/ACTUALIZAR DISPONIBILIDAD POR MATERIA
// =====================================================
const registrarDisponibilidadPorMateria = async (req, res) => {
  try {
    const { materia, diaSemana, bloques } = req.body;
    const docente = req.docenteBDD?._id;

    // ✅ Validaciones básicas
    if (!docente) {
      return res.status(401).json({ msg: "Docente no autenticado" });
    }

    if (!materia || !diaSemana || !bloques || !Array.isArray(bloques)) {
      return res.status(400).json({
        msg: "Materia, día de la semana y bloques (array) son obligatorios"
      });
    }

    if (bloques.length === 0) {
      return res.status(400).json({
        msg: "Debes agregar al menos un bloque de horario"
      });
    }

    // ✅ Normalizar día
    const diaNormalizado = diaSemana.toLowerCase().trim();
    const diasValidos = ["lunes", "martes", "miércoles", "jueves", "viernes"];
    if (!diasValidos.includes(diaNormalizado)) {
      return res.status(400).json({
        msg: "Día inválido. Usa lunes, martes, miércoles, jueves o viernes"
      });
    }

    // ✅ Verificar que la materia pertenece al docente
    const docenteBDD = await Docente.findById(docente);
    if (!docenteBDD) {
      return res.status(404).json({ msg: "Docente no encontrado" });
    }

    let asignaturasDocente = docenteBDD.asignaturas;
    if (typeof asignaturasDocente === "string") {
      try {
        asignaturasDocente = JSON.parse(asignaturasDocente);
      } catch {
        asignaturasDocente = [];
      }
    }

    if (!asignaturasDocente.includes(materia)) {
      return res.status(400).json({
        msg: `La materia "${materia}" no está asignada a tu perfil. Primero agrega la materia en "Mis Materias".`
      });
    }

    // ✅ Validar formato y coherencia de bloques
    for (const bloque of bloques) {
      if (!bloque.horaInicio || !bloque.horaFin) {
        return res.status(400).json({
          msg: "Cada bloque debe tener horaInicio y horaFin"
        });
      }

      const formatoHora = /^([01]\d|2[0-3]):([0-5]\d)$/;
      if (!formatoHora.test(bloque.horaInicio) || !formatoHora.test(bloque.horaFin)) {
        return res.status(400).json({
          msg: "Formato de hora inválido. Usa HH:MM (ej: 14:00)"
        });
      }

      const [hIni, mIni] = bloque.horaInicio.split(":").map(Number);
      const [hFin, mFin] = bloque.horaFin.split(":").map(Number);
      const inicioMinutos = hIni * 60 + mIni;
      const finMinutos = hFin * 60 + mFin;

      if (finMinutos <= inicioMinutos) {
        return res.status(400).json({
          msg: `El bloque ${bloque.horaInicio}-${bloque.horaFin} es inválido: la hora de fin debe ser mayor que la de inicio`
        });
      }
    }

    // ✅ NUEVA VALIDACIÓN 1: Cruces dentro de la misma materia
    const validacionInterna = validarCrucesHorarios(bloques);
    if (!validacionInterna.valido) {
      return res.status(400).json({
        msg: validacionInterna.mensaje
      });
    }

    // ✅ NUEVA VALIDACIÓN 2: Cruces entre diferentes materias del mismo docente
    const validacionEntreMaterias = await validarCrucesEntreMaterias(
      docente,
      materia,
      diaNormalizado,
      bloques
    );

    if (!validacionEntreMaterias.valido) {
      return res.status(400).json({
        msg: validacionEntreMaterias.mensaje
      });
    }

    // ✅ Buscar o crear disponibilidad
    let disponibilidad = await disponibilidadDocente.findOne({
      docente,
      diaSemana: diaNormalizado,
      materia
    });

    if (disponibilidad) {
      disponibilidad.bloques = bloques.map(b => ({
        horaInicio: b.horaInicio,
        horaFin: b.horaFin
      }));

      console.log(`📝 Actualizando disponibilidad: ${materia} - ${diaNormalizado}`);
    } else {
      disponibilidad = new disponibilidadDocente({
        docente,
        diaSemana: diaNormalizado,
        materia,
        bloques: bloques.map(b => ({
          horaInicio: b.horaInicio,
          horaFin: b.horaFin
        }))
      });

      console.log(`✨ Creando nueva disponibilidad: ${materia} - ${diaNormalizado}`);
    }

    await disponibilidad.save();
    console.log(`✅ Disponibilidad guardada exitosamente`);

    res.status(200).json({
      success: true,
      msg: "Disponibilidad actualizada con éxito.",
      disponibilidad: {
        materia: disponibilidad.materia,
        diaSemana: disponibilidad.diaSemana,
        bloques: disponibilidad.bloques,
        id: disponibilidad._id
      }
    });
  } catch (error) {
    console.error("❌ Error en registrarDisponibilidadPorMateria:", error);

    if (error.code === 11000) {
      return res.status(409).json({
        msg: "Ya existe un registro para esta materia y día. Intenta actualizar en lugar de crear uno nuevo."
      });
    }

    res.status(500).json({
      msg: "Error al actualizar disponibilidad",
      error: error.message
    });
  }
};

// =====================================================
// ✅ VER DISPONIBILIDAD POR MATERIA
// =====================================================
const verDisponibilidadPorMateria = async (req, res) => {
  try {
    const { docenteId, materia } = req.params;

    // Validar ObjectId
    if (!docenteId.match(/^[0-9a-fA-F]{24}$/)) {
      return res.status(400).json({ msg: "ID de docente inválido" });
    }

    console.log(`🔍 Buscando disponibilidad: Docente=${docenteId}, Materia=${materia}`);

    const disponibilidad = await disponibilidadDocente.find({ 
      docente: docenteId,
      materia 
    }).sort({ diaSemana: 1 });

    if (!disponibilidad || disponibilidad.length === 0) {
      console.log(`ℹ️ No hay disponibilidad para ${materia}`);
      return res.status(200).json({
        msg: "El docente no tiene disponibilidad registrada para esta materia.",
        disponibilidad: []
      });
    }

    console.log(`✅ Disponibilidad encontrada: ${disponibilidad.length} días`);

    res.status(200).json({ 
      success: true,
      disponibilidad: disponibilidad.map(d => ({
        diaSemana: d.diaSemana,
        bloques: d.bloques,
        id: d._id
      }))
    });
  } catch (error) {
    console.error("❌ Error en verDisponibilidadPorMateria:", error);
    res.status(500).json({ 
      msg: "Error al obtener la disponibilidad.", 
      error: error.message 
    });
  }
};

// =====================================================
// ✅ VER DISPONIBILIDAD COMPLETA (SOLO MATERIAS ACTIVAS)
// =====================================================

// CORRECCIÓN: Filtra materias que el docente ya no imparte

const verDisponibilidadCompletaDocente = async (req, res) => {
  try {
    const { docenteId } = req.params;

    // Validar ObjectId
    if (!docenteId.match(/^[0-9a-fA-F]{24}$/)) {
      return res.status(400).json({ msg: "ID de docente inválido" });
    }

    console.log(`🔍 Buscando disponibilidad completa del docente: ${docenteId}`);

    // ✅ PASO 1: Obtener materias ACTUALMENTE ASIGNADAS
    const Docente = (await import('../models/docente.js')).default;
    const docente = await Docente.findById(docenteId);

    if (!docente) {
      return res.status(404).json({ msg: "Docente no encontrado" });
    }

    let materiasActivas = docente.asignaturas || [];
    
    // Parsear si viene como string
    if (typeof materiasActivas === 'string') {
      try {
        materiasActivas = JSON.parse(materiasActivas);
      } catch {
        materiasActivas = [];
      }
    }

    console.log(`📚 Materias activas del docente: ${materiasActivas.join(', ')}`);

    // ✅ PASO 2: Buscar disponibilidad SOLO de materias activas
    const disponibilidad = await disponibilidadDocente.find({
      docente: docenteId,
      materia: { $in: materiasActivas }  // ✅ FILTRO CRÍTICO
    }).sort({ materia: 1, diaSemana: 1 });

    if (!disponibilidad || disponibilidad.length === 0) {
      console.log(`ℹ️ No hay disponibilidad registrada`);
      return res.status(200).json({
        success: true,
        msg: "El docente no tiene disponibilidad registrada.",
        docenteId,
        materias: {}
      });
    }

    // ✅ PASO 3: Agrupar por materia
    const porMateria = {};
    let horariosIgnorados = 0;

    disponibilidad.forEach(disp => {
      const mat = disp.materia;
      
      // Doble verificación (por si acaso)
      if (!materiasActivas.includes(mat)) {
        console.log(`⚠️ Ignorando horario obsoleto de: ${mat}`);
        horariosIgnorados++;
        return;
      }

      if (!porMateria[mat]) {
        porMateria[mat] = [];
      }

      porMateria[mat].push({
        diaSemana: disp.diaSemana,
        bloques: disp.bloques
      });
    });

    if (horariosIgnorados > 0) {
      console.log(`🔍 Se ignoraron ${horariosIgnorados} horarios de materias no activas`);
    }

    console.log(`✅ Disponibilidad completa: ${Object.keys(porMateria).length} materias activas`);

    res.status(200).json({
      success: true,
      docenteId,
      materiasActivas,  // ✅ Incluir lista de materias activas
      materias: porMateria
    });

  } catch (error) {
    console.error("❌ Error en verDisponibilidadCompletaDocente:", error);
    res.status(500).json({
      msg: "Error al obtener disponibilidad.",
      error: error.message
    });
  }
};

// =====================================================
// ✅ ELIMINAR DISPONIBILIDAD POR MATERIA Y DÍA
// =====================================================
const eliminarDisponibilidadMateria = async (req, res) => {
  try {
    const { docenteId, materia, dia } = req.params;

    // Solo el docente puede eliminar su propia disponibilidad
    if (req.docenteBDD._id.toString() !== docenteId) {
      return res.status(403).json({
        msg: 'No tienes permiso para eliminar esta disponibilidad'
      });
    }

    const diaNormalizado = dia.toLowerCase().trim();

    const resultado = await disponibilidadDocente.findOneAndDelete({
      docente: docenteId,
      materia,
      diaSemana: diaNormalizado
    });

    if (!resultado) {
      return res.status(404).json({
        msg: "No se encontró disponibilidad para eliminar"
      });
    }

    console.log(`🗑️ Disponibilidad eliminada: ${materia} - ${diaNormalizado}`);

    res.status(200).json({
      success: true,
      msg: "Disponibilidad eliminada correctamente"
    });

  } catch (error) {
    console.error("❌ Error en eliminarDisponibilidadMateria:", error);
    res.status(500).json({
      msg: "Error al eliminar disponibilidad",
      error: error.message
    });
  }
};

/**
 * ✅ ACTUALIZAR HORARIOS CON VALIDACIÓN COMPLETA (CORREGIDO)
 * Permite horarios iguales en días diferentes, solo valida cruces en el mismo día
 */
const actualizarHorarios = async (req, res) => {
  try {
    const { materia, bloques } = req.body;
    const docente = req.docenteBDD?._id;

    // Validaciones básicas
    if (!docente) {
      return res.status(401).json({ msg: "Docente no autenticado" });
    }

    if (!materia || !bloques || !Array.isArray(bloques)) {
      return res.status(400).json({ 
        msg: "Materia y bloques (array) son obligatorios" 
      });
    }

    if (bloques.length === 0) {
      return res.status(400).json({
        msg: "Debes agregar al menos un bloque de horario"
      });
    }

    console.log(`🔄 Actualizando horarios completos de: ${materia}`);
    console.log(`   Bloques recibidos: ${bloques.length}`);

    // ✅ PASO 1: AGRUPAR BLOQUES POR DÍA
    const bloquesPorDia = {};
    
    for (const bloque of bloques) {
      const dia = bloque.dia.toLowerCase().trim();
      
      if (!bloquesPorDia[dia]) {
        bloquesPorDia[dia] = [];
      }
      
      bloquesPorDia[dia].push({
        horaInicio: bloque.horaInicio,
        horaFin: bloque.horaFin
      });
    }

    console.log(`📋 Días a guardar: ${Object.keys(bloquesPorDia).join(', ')}`);

    // ✅ PASO 2: VALIDAR CRUCES INTERNOS POR DÍA
    for (const [dia, bloquesDelDia] of Object.entries(bloquesPorDia)) {
      console.log(`   Validando cruces internos en ${dia}...`);
      const validacion = validarCrucesHorarios(bloquesDelDia);
      if (!validacion.valido) {
        return res.status(400).json({
          msg: `Error en ${dia}: ${validacion.mensaje}`
        });
      }
    }
    console.log('   ✅ Sin cruces internos');

    // ✅ PASO 3: VALIDAR CRUCES ENTRE MATERIAS (SOLO POR DÍA)
    for (const [dia, bloquesDelDia] of Object.entries(bloquesPorDia)) {
      console.log(`   Validando cruces con otras materias en ${dia}...`);
      
      const validacion = await validarCrucesEntreMaterias(
        docente,
        materia,
        dia,
        bloquesDelDia
      );

      if (!validacion.valido) {
        return res.status(400).json({
          msg: validacion.mensaje
        });
      }
    }
    console.log('   ✅ Sin cruces con otras materias');

    // ✅ PASO 4: ELIMINAR FÍSICAMENTE TODOS LOS REGISTROS ANTERIORES
    const eliminados = await disponibilidadDocente.deleteMany({
      docente: docente,
      materia: materia
    });

    console.log(`🗑️ Registros eliminados: ${eliminados.deletedCount}`);

    // ✅ PASO 5: CREAR NUEVOS REGISTROS (UN DOCUMENTO POR DÍA)
    const registrosCreados = [];

    for (const [dia, bloquesDelDia] of Object.entries(bloquesPorDia)) {
      const nuevoRegistro = new disponibilidadDocente({
        docente: docente,
        diaSemana: dia,
        materia: materia,
        bloques: bloquesDelDia
      });

      await nuevoRegistro.save();
      registrosCreados.push(nuevoRegistro);
      
      console.log(`✅ Creado: ${dia} con ${bloquesDelDia.length} bloques`);
    }

    console.log(`✅ Total registros creados: ${registrosCreados.length}`);

    res.status(200).json({
      success: true,
      msg: "Horarios actualizados correctamente",
      registrosEliminados: eliminados.deletedCount,
      registrosCreados: registrosCreados.length,
      disponibilidad: registrosCreados.map(r => ({
        dia: r.diaSemana,
        bloques: r.bloques
      }))
    });

  } catch (error) {
    console.error('❌ Error actualizando horarios:', error);
    res.status(500).json({
      msg: "Error al actualizar horarios",
      error: error.message
    });
  }
};

// =====================================================
// ✅ ACEPTAR SOLICITUD DE TUTORÍA (DOCENTE)
// =====================================================
export const aceptarTutoria = async (req, res) => {
  try {
    const { id } = req.params;
    const docente = req.docenteBDD?._id;

    if (!docente) {
      return res.status(401).json({ 
        success: false,
        msg: "Docente no autenticado" 
      });
    }

    const tutoria = await Tutoria.findById(id);

    if (!tutoria) {
      return res.status(404).json({ 
        success: false,
        msg: 'Tutoría no encontrada' 
      });
    }

    // Verificar que sea el docente correcto
    if (tutoria.docente.toString() !== docente.toString()) {
      return res.status(403).json({ 
        success: false,
        msg: 'No tienes permiso para gestionar esta tutoría' 
      });
    }

    // Validar estado actual
    if (tutoria.estado !== 'pendiente') {
      return res.status(400).json({ 
        success: false,
        msg: `Esta tutoría ya fue ${tutoria.estado}` 
      });
    }

    // Actualizar estado
    tutoria.estado = 'confirmada';
    await tutoria.save();

    console.log(`✅ Tutoría aceptada: ${tutoria._id}`);

    res.status(200).json({ 
      success: true,
      msg: 'Tutoría aceptada exitosamente', 
      tutoria: {
        _id: tutoria._id,
        estado: tutoria.estado,
        estudiante: tutoria.estudiante,
        fecha: tutoria.fecha,
        horaInicio: tutoria.horaInicio,
        horaFin: tutoria.horaFin
      }
    });

  } catch (error) {
    console.error("❌ Error aceptando tutoría:", error);
    res.status(500).json({ 
      success: false,
      msg: 'Error al aceptar la tutoría', 
      error: error.message 
    });
  }
};

// =====================================================
// ✅ RECHAZAR SOLICITUD DE TUTORÍA (DOCENTE)
// =====================================================
export const rechazarTutoria = async (req, res) => {
  try {
    const { id } = req.params;
    const { motivoRechazo } = req.body;
    const docente = req.docenteBDD?._id;

    if (!docente) {
      return res.status(401).json({ 
        success: false,
        msg: "Docente no autenticado" 
      });
    }

    const tutoria = await Tutoria.findById(id);

    if (!tutoria) {
      return res.status(404).json({ 
        success: false,
        msg: 'Tutoría no encontrada' 
      });
    }

    // Verificar que sea el docente correcto
    if (tutoria.docente.toString() !== docente.toString()) {
      return res.status(403).json({ 
        success: false,
        msg: 'No tienes permiso para gestionar esta tutoría' 
      });
    }

    // Validar estado actual
    if (tutoria.estado !== 'pendiente') {
      return res.status(400).json({ 
        success: false,
        msg: `Esta tutoría ya fue ${tutoria.estado}` 
      });
    }

    // Actualizar estado
    tutoria.estado = 'rechazada';
    tutoria.motivoRechazo = motivoRechazo || 'Sin motivo especificado';
    await tutoria.save();

    console.log(`❌ Tutoría rechazada: ${tutoria._id}`);

    res.status(200).json({ 
      success: true,
      msg: 'Tutoría rechazada', 
      tutoria: {
        _id: tutoria._id,
        estado: tutoria.estado,
        motivoRechazo: tutoria.motivoRechazo
      }
    });

  } catch (error) {
    console.error("❌ Error rechazando tutoría:", error);
    res.status(500).json({ 
      success: false,
      msg: 'Error al rechazar la tutoría', 
      error: error.message 
    });
  }
};

// =====================================================
// ✅ LISTAR TUTORÍAS PENDIENTES (SOLO DOCENTE)
// =====================================================
export const listarTutoriasPendientes = async (req, res) => {
  try {
    const docente = req.docenteBDD?._id;

    if (!docente) {
      return res.status(401).json({ 
        success: false,
        msg: "Docente no autenticado" 
      });
    }

    const tutorias = await Tutoria.find({
      docente: docente,
      estado: 'pendiente'
    })
    .populate("estudiante", "nombreEstudiante emailEstudiante fotoPerfil")
    .sort({ fecha: 1, horaInicio: 1 });

    console.log(`📋 Tutorías pendientes: ${tutorias.length}`);

    res.status(200).json({
      success: true,
      total: tutorias.length,
      tutorias
    });

  } catch (error) {
    console.error("❌ Error listando tutorías pendientes:", error);
    res.status(500).json({ 
      success: false,
      msg: "Error al listar tutorías", 
      error: error.message 
    });
  }
};

// =====================================================
// Finalizar tutoría y registrar asistencia
// - Solo el docente puede finalizar
// - Solo se pueden finalizar tutorías confirmadas
// - Se marca asistencia y observaciones
// =====================================================
export const finalizarTutoria = async (req, res) => {
  try {
    const { id } = req.params;
    const { asistio, observaciones } = req.body;
    const docente = req.docenteBDD?._id;

    console.log(`🏁 Finalizando tutoría: ${id}`);

    if (!docente) {
      return res.status(401).json({
        success: false,
        msg: "Docente no autenticado"
      });
    }

    // Validar que asistio sea booleano
    if (typeof asistio !== 'boolean') {
      return res.status(400).json({
        success: false,
        msg: "Debes indicar si el estudiante asistió (true/false)"
      });
    }

    const tutoria = await Tutoria.findById(id);

    if (!tutoria) {
      return res.status(404).json({
        success: false,
        msg: 'Tutoría no encontrada'
      });
    }

    // Verificar que sea el docente correcto
    if (tutoria.docente.toString() !== docente.toString()) {
      return res.status(403).json({
        success: false,
        msg: 'No tienes permiso para finalizar esta tutoría'
      });
    }

    // Validar estado actual
    if (tutoria.estado !== 'confirmada') {
      return res.status(400).json({
        success: false,
        msg: `Solo se pueden finalizar tutorías confirmadas. Estado actual: ${tutoria.estado}`
      });
    }

    // Validar que la fecha no sea futura
    const fechaTutoria = moment(tutoria.fecha, 'YYYY-MM-DD');
    const hoy = moment().startOf('day');

    if (fechaTutoria.isAfter(hoy)) {
      return res.status(400).json({
        success: false,
        msg: 'No puedes finalizar una tutoría que aún no ha ocurrido'
      });
    }

    // Actualizar tutoría
    tutoria.estado = 'finalizada';
    tutoria.asistenciaEstudiante = asistio;
    tutoria.observacionesDocente = observaciones?.trim() || null;

    await tutoria.save();

    console.log(`✅ Tutoría finalizada: ${tutoria._id}`);
    console.log(`   Asistencia: ${asistio ? 'SÍ' : 'NO'}`);
    console.log(`   Observaciones: ${observaciones || 'ninguna'}`);

    // Poblar datos para respuesta
    await tutoria.populate('estudiante', 'nombreEstudiante emailEstudiante fotoPerfil');
    await tutoria.populate('docente', 'nombreDocente emailDocente');

    res.status(200).json({
      success: true,
      msg: 'Tutoría finalizada exitosamente',
      tutoria: {
        _id: tutoria._id,
        estado: tutoria.estado,
        asistenciaEstudiante: tutoria.asistenciaEstudiante,
        observacionesDocente: tutoria.observacionesDocente,
        estudiante: tutoria.estudiante,
        fecha: tutoria.fecha,
        horaInicio: tutoria.horaInicio,
        horaFin: tutoria.horaFin
      }
    });

  } catch (error) {
    console.error("❌ Error finalizando tutoría:", error);
    res.status(500).json({
      success: false,
      msg: 'Error al finalizar la tutoría',
      error: error.message
    });
  }
};

// =====================================================
// ✅ TAREA AUTOMÁTICA: Marcar tutorías expiradas
// =====================================================
export const marcarTutoriasExpiradas = async () => {
  try {
    const ahora = moment();
    const fechaHoy = ahora.format('YYYY-MM-DD');
    const horaActual = ahora.format('HH:mm');

    console.log('🔍 Buscando tutorías expiradas...');

    // Buscar tutorías pendientes o confirmadas cuya fecha/hora ya pasó
    const tutoriasActivas = await Tutoria.find({
      estado: { $in: ['pendiente', 'confirmada'] }
    });

    let marcadas = 0;

    for (const tutoria of tutoriasActivas) {
      const fechaHoraTutoria = moment(`${tutoria.fecha} ${tutoria.horaFin}`, 'YYYY-MM-DD HH:mm');
      
      if (fechaHoraTutoria.isBefore(ahora)) {
        tutoria.estado = 'expirada';
        await tutoria.save();
        marcadas++;
        console.log(`   ⏰ Marcada como expirada: ${tutoria._id}`);
      }
    }

    console.log(`✅ Total tutorías expiradas: ${marcadas}`);
    return marcadas;

  } catch (error) {
    console.error('❌ Error marcando tutorías expiradas:', error);
    return 0;
  }
};

// =====================================================
// ✅ GENERAR REPORTE GENERAL PARA ADMINISTRADOR
// Resumen de todas las tutorías del sistema
// =====================================================
export const generarReporteGeneralAdmin = async (req, res) => {
  try {
    const { fechaInicio, fechaFin, formato = 'json' } = req.query;

    console.log('📊 Generando reporte general para administrador');
    console.log(`   Período: ${fechaInicio || 'Inicio'} - ${fechaFin || 'Hoy'}`);

    // Construir filtro
    let filtro = {};

    if (fechaInicio || fechaFin) {
      filtro.fecha = {};
      if (fechaInicio) filtro.fecha.$gte = fechaInicio;
      if (fechaFin) filtro.fecha.$lte = fechaFin;
    }

    // Obtener todas las tutorías del período
    const tutorias = await Tutoria.find(filtro)
      .populate('estudiante', 'nombreEstudiante emailEstudiante')
      .populate('docente', 'nombreDocente emailDocente')
      .sort({ fecha: -1 });

    console.log(`   Total tutorías encontradas: ${tutorias.length}`);

    // Contar docentes y estudiantes únicos
    const docentesSet = new Set();
    const estudiantesSet = new Set();

    tutorias.forEach(t => {
      if (t.docente?._id) docentesSet.add(t.docente._id.toString());
      if (t.estudiante?._id) estudiantesSet.add(t.estudiante._id.toString());
    });

    // Estadísticas globales
    const estadisticasGlobales = {
      totalTutorias: tutorias.length,
      docentesActivos: docentesSet.size,
      estudiantesUnicos: estudiantesSet.size,
      pendientes: tutorias.filter(t => t.estado === 'pendiente').length,
      confirmadas: tutorias.filter(t => t.estado === 'confirmada').length,
      finalizadas: tutorias.filter(t => t.estado === 'finalizada').length,
      canceladas: tutorias.filter(t => 
        t.estado === 'cancelada_por_estudiante' || 
        t.estado === 'cancelada_por_docente'
      ).length,
      rechazadas: tutorias.filter(t => t.estado === 'rechazada').length,
      expiradas: tutorias.filter(t => t.estado === 'expirada').length,
      periodo: {
        inicio: fechaInicio || (tutorias.length > 0 ? tutorias[tutorias.length - 1]?.fecha : 'N/A') || 'N/A',
        fin: fechaFin || (tutorias.length > 0 ? tutorias[0]?.fecha : 'N/A') || 'N/A'
      }
    };

    console.log(`✅ Estadísticas calculadas:`);
    console.log(`   Tutorías: ${estadisticasGlobales.totalTutorias}`);
    console.log(`   Docentes: ${estadisticasGlobales.docentesActivos}`);
    console.log(`   Estudiantes: ${estadisticasGlobales.estudiantesUnicos}`);

    // Agrupar por docente
    const reportePorDocente = {};

    tutorias.forEach(tutoria => {
      const nombreDocente = tutoria.docente?.nombreDocente || 'Sin docente';
      
      if (!reportePorDocente[nombreDocente]) {
        reportePorDocente[nombreDocente] = {
          estadisticas: {
            total: 0,
            pendientes: 0,
            confirmadas: 0,
            finalizadas: 0,
            canceladas: 0,
            rechazadas: 0,
            asistencias: 0,
            inasistencias: 0,
          },
          tutorias: []
        };
      }

      const stats = reportePorDocente[nombreDocente].estadisticas;
      stats.total++;

      switch (tutoria.estado) {
        case 'pendiente':
          stats.pendientes++;
          break;
        case 'confirmada':
          stats.confirmadas++;
          break;
        case 'finalizada':
          stats.finalizadas++;
          if (tutoria.asistenciaEstudiante === true) stats.asistencias++;
          if (tutoria.asistenciaEstudiante === false) stats.inasistencias++;
          break;
        case 'cancelada_por_estudiante':
        case 'cancelada_por_docente':
          stats.canceladas++;
          break;
        case 'rechazada':
          stats.rechazadas++;
          break;
      }

      reportePorDocente[nombreDocente].tutorias.push({
        _id: tutoria._id,
        estudiante: tutoria.estudiante?.nombreEstudiante || 'N/A',
        fecha: tutoria.fecha,
        horario: `${tutoria.horaInicio} - ${tutoria.horaFin}`,
        estado: tutoria.estado,
        asistencia: tutoria.asistenciaEstudiante
      });
    });

    // Calcular tasas de asistencia por docente
    Object.values(reportePorDocente).forEach(data => {
      const stats = data.estadisticas;
      if (stats.finalizadas > 0) {
        stats.tasaAsistencia = ((stats.asistencias / stats.finalizadas) * 100).toFixed(2) + '%';
      } else {
        stats.tasaAsistencia = 'N/A';
      }
    });

    console.log(`✅ Reporte generado con ${Object.keys(reportePorDocente).length} docentes`);

    // Responder según formato solicitado
    if (formato === 'csv') {
      return generarCSVAdmin(res, reportePorDocente, estadisticasGlobales);
    }

    res.status(200).json({
      success: true,
      estadisticasGlobales,
      reportePorDocente
    });

  } catch (error) {
    console.error("❌ Error generando reporte general:", error);
    res.status(500).json({
      success: false,
      msg: 'Error al generar reporte',
      error: error.message
    });
  }
};

// Función auxiliar para generar CSV
const generarCSVAdmin = (res, reporte, stats) => {
  let csv = 'RESUMEN GENERAL\n';
  csv += `Total Tutorías,${stats.totalTutorias}\n`;
  csv += `Docentes Activos,${stats.docentesActivos}\n`;
  csv += `Estudiantes Únicos,${stats.estudiantesUnicos}\n`;
  csv += `Período,${stats.periodo.inicio} a ${stats.periodo.fin}\n\n`;
  
  csv += 'DETALLE POR DOCENTE\n';
  csv += 'Docente,Total,Pendientes,Confirmadas,Finalizadas,Canceladas,Tasa Asistencia\n';
  
  for (const [docente, datos] of Object.entries(reporte)) {
    const e = datos.estadisticas;
    csv += `"${docente}",${e.total},${e.pendientes},${e.confirmadas},${e.finalizadas},${e.canceladas},${e.tasaAsistencia}\n`;
  }

  res.setHeader('Content-Type', 'text/csv');
  res.setHeader('Content-Disposition', `attachment; filename="reporte_admin_${Date.now()}.csv"`);
  res.send(csv);
};

// =====================================================
// ✅ EXPORTAR TODAS LAS FUNCIONES (BLOQUE ÚNICO)
// =====================================================
export {
  // ✅ NUEVAS FUNCIONES DE TURNOS (AGREGADAS)
  calcularTurnosDisponibles,
  obtenerTurnosDisponibles,
  registrarTutoriaConTurnos,
  
  // Tutorías (funciones originales)
  registrarTutoria,
  listarTutorias,
  actualizarTutoria,
  cancelarTutoria,
  registrarAsistencia,
  
  // Disponibilidad general (legacy)
  registrarDisponibilidadDocente,
  verDisponibilidadDocente,
  bloquesOcupadosDocente,

  // Disponibilidad por materia (nuevo)
  registrarDisponibilidadPorMateria,
  verDisponibilidadPorMateria,
  verDisponibilidadCompletaDocente,
  eliminarDisponibilidadMateria,
  actualizarHorarios,
  
  // Validaciones de horarios
  validarCrucesHorarios,
  validarCrucesLocales,
  validarCrucesEntreMaterias,
  _convertirAMinutos,
  _agruparPorDia
};
