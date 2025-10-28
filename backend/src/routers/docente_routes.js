import { Router } from 'express'
import { 
  registrarDocente, 
  listarDocentes, 
  detalleDocente,
  eliminarDocente, 
  actualizarDocente, 
  loginDocente, 
  perfilDocente,
  crearNuevoPasswordDocente,
  comprobarTokenPasswordDocente,
  recuperarPasswordDocente,
  actualizarPerfilDocente,      
  actualizarPasswordDocente,
  cambiarPasswordObligatorio      
} from '../controllers/docente_controller.js'
import { loginOAuthDocente } from "../controllers/sesion_google_correo_controller.js";
import { verificarTokenJWT } from '../middlewares/JWT.js'
import verificarRol from "../middlewares/rol.js";

const routerDocente = Router()

// ========== RUTAS PÚBLICAS ==========

// Login
routerDocente.post('/docente/login', loginDocente)

// Login con OAuth
routerDocente.post('/docente/login-oauth', loginOAuthDocente)

// Recuperación de contraseña
routerDocente.post('/docente/recuperarpassword', recuperarPasswordDocente)
routerDocente.get('/docente/recuperarpassword/:token', comprobarTokenPasswordDocente)
routerDocente.post('/docente/nuevopassword/:token', crearNuevoPasswordDocente)
routerDocente.post('/docente/cambiar-password-obligatorio',verificarTokenJWT,cambiarPasswordObligatorio)

// ========== RUTAS PRIVADAS - DOCENTE ==========

// Perfil del docente autenticado
routerDocente.get('/docente/perfil', verificarTokenJWT, verificarRol(["Docente"]), perfilDocente)

// ✅ CAMBIO AQUÍ: Actualizar perfil del docente (ÉL MISMO O ADMIN)
routerDocente.put('/docente/perfil/:id', verificarTokenJWT, verificarRol(["Docente", "Administrador"]), actualizarPerfilDocente)

// Actualizar contraseña del docente autenticado (ÉL MISMO)
routerDocente.put('/docente/actualizarpassword/:id', verificarTokenJWT, verificarRol(["Docente"]), actualizarPasswordDocente)

// ========== RUTAS PRIVADAS - ADMINISTRADOR ==========

// Registro de docente (solo admin)
routerDocente.post("/docente/registro", verificarTokenJWT, verificarRol(["Administrador"]), registrarDocente)

// Listar docentes (admin o estudiantes)
routerDocente.get("/docentes", verificarTokenJWT, verificarRol(["Administrador", "Estudiante"]), listarDocentes)

// Detalle de docente
routerDocente.get("/docente/:id", verificarTokenJWT, detalleDocente)

// Eliminar (deshabilitar) docente (solo admin)
routerDocente.delete("/docente/eliminar/:id", verificarTokenJWT, verificarRol(["Administrador"]), eliminarDocente)

// Actualizar docente (solo admin - actualiza cualquier docente)
routerDocente.put("/docente/actualizar/:id", verificarTokenJWT, verificarRol(["Administrador"]), actualizarDocente)

export default routerDocente