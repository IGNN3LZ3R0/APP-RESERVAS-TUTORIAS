import { Router } from "express";
import {
  registrarTutoria,
  actualizarTutoria,
  cancelarTutoria,
  listarTutorias,
  registrarAsistencia,
  registrarDisponibilidadDocente,
  verDisponibilidadDocente,
  bloquesOcupadosDocente
} from "../controllers/tutorias_controller.js";

import { verificarTokenJWT } from "../middlewares/JWT.js";
import verificarRol from "../middlewares/rol.js";

const routerTutorias = Router();

//Ruta para que el estudiante agende, actualice o cancele su tutoria 
routerTutorias.post("/tutoria/registro", verificarTokenJWT, verificarRol(["Estudiante"]),registrarTutoria);

//Listar todas las tutorías
routerTutorias.get("/tutorias",verificarTokenJWT,verificarRol(["Docente", "Estudiante"]),listarTutorias);

routerTutorias.put("/tutoria/actualizar/:id",verificarTokenJWT,verificarRol(["Estudiante"]),actualizarTutoria);

routerTutorias.delete("/tutoria/cancelar/:id", verificarTokenJWT,verificarRol(["Estudiante", "Docente"]),cancelarTutoria);

//Ruta para que el docente registre la asistencia del estudiante
routerTutorias.put("/tutoria/registrar-asistencia/:id_tutoria",verificarTokenJWT,verificarRol(["Docente"]),registrarAsistencia);

//Ruta para que el docente registre o actualice su disponibilidad semanal
routerTutorias.post("/tutorias/registrar-disponibilidad",verificarTokenJWT,verificarRol(["Docente"]),registrarDisponibilidadDocente);

//Ruta para que el docente y estudiante vean la disponibilidad del docente para agendar tutoria
routerTutorias.get("/ver-disponibilidad-docente/:docenteId", verificarTokenJWT, verificarRol(["Estudiante", "Docente"]), verDisponibilidadDocente);

routerTutorias.get('/tutorias-ocupadas/:docenteId', bloquesOcupadosDocente);

export default routerTutorias;
