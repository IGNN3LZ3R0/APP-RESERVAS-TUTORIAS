import { Router } from 'express'
import { 
  registrarDocente, 
  listarDocentes, 
  detalleDocente,
  eliminarDocente, 
  actualizarDocente, 
  loginDocente, 
  perfilDocente, 
} from '../controllers/docente_controller.js'
import { loginOAuthDocente } from "../controllers/sesion_google_correo_controller.js"; // Nueva importación del controlador para OAuth
import { verificarTokenJWT } from '../middlewares/JWT.js'
import verificarRol from "../middlewares/rol.js";

const routerDocente = Router()

// --- Login del docente ---
routerDocente.post('/docente/login', loginDocente)
routerDocente.post('/docente/login-oauth', loginOAuthDocente)  //Nueva ruta para el inicio/registro con Google/Microsoft
routerDocente.get('/docente/perfil', verificarTokenJWT, perfilDocente)

// --- Registro y administración del docente por el administrador ---
routerDocente.post("/docente/registro", verificarTokenJWT, registrarDocente)
routerDocente.get("/docentes",verificarTokenJWT,verificarRol(["Administrador", "Estudiante"]),listarDocentes);
routerDocente.get("/docente/:id", verificarTokenJWT, detalleDocente)
routerDocente.delete("/docente/eliminar/:id", verificarTokenJWT, eliminarDocente)
routerDocente.put("/docente/actualizar/:id", verificarTokenJWT, actualizarDocente)

export default routerDocente