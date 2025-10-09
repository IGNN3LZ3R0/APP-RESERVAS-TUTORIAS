import mongoose, { Schema, model } from "mongoose";

const disponibilidadSchema = new Schema({
  docente: { type: Schema.Types.ObjectId, ref: "Docente", required: true },
  diaSemana: {
    type: String,
    enum: ["lunes", "martes", "miércoles", "jueves", "viernes"],
    required: true
  },
  bloques: [
    {
      horaInicio: { type: String, required: true }, 
      horaFin: { type: String, required: true },   
    }
  ]
});

export default model("disponibilidadDocente", disponibilidadSchema);