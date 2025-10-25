import mongoose, { Schema, model } from "mongoose";

const tutoriaSchema = new Schema({
  estudiante: { type: Schema.Types.ObjectId, ref: "Estudiante", required: true },
  docente: { type: Schema.Types.ObjectId, ref: "Docente", required: true },

  fecha: { type: String, required: true },

  // Bloque de tiempo elegido, basado en la disponibilidad del docente
  horaInicio: { type: String, required: true }, // Ej. "16:00"
  horaFin: { type: String, required: true },    // Ej. "16:40"

  estado: {
    type: String,
    enum: [
      "pendiente", 
      "confirmada", 
      "cancelada_por_estudiante", 
      "cancelada_por_docente", 
      "no_asiste"
    ],
    default: "pendiente"
  },

  asistenciaEstudiante: { type: Boolean, default: null },
  motivoCancelacion: { type: String, default: null },
  observacionesDocente: { type: String, default: null },

  creadaEn: { type: Date, default: Date.now },
  actualizadaEn: { type: Date, default: Date.now }
});

// Middleware para actualizar la fecha de modificación
tutoriaSchema.pre("save", function (next) {
  this.actualizadaEn = new Date();
  next();
});

export default model("Tutoria", tutoriaSchema);