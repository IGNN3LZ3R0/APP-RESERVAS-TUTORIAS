import { Router } from 'express'
import { loginOAuthEstudiante } from "../controllers/sesion_google_correo_controller.js";
import {
  confirmarMailEstudiante,
  recuperarPasswordEstudiante,
  registroEstudiante,
  comprobarTokenPasswordEstudiante,
  crearNuevoPasswordEstudiante,
  loginEstudiante,
  perfilEstudiante,
  actualizarPerfilEstudiante,
  actualizarPasswordEstudiante,
} from '../controllers/estudiante_controller.js'
import { verificarTokenJWT } from '../middlewares/JWT.js'

const routerEstudiante = Router()

// ========== RUTAS PÚBLICAS ==========

// Registro
routerEstudiante.post('/estudiante/registro', registroEstudiante)

// Confirmación de email
routerEstudiante.get('/confirmar/:token', confirmarMailEstudiante)

// Recuperar contraseña
routerEstudiante.post('/recuperarpassword', recuperarPasswordEstudiante)
routerEstudiante.get('/recuperarpassword/:token', comprobarTokenPasswordEstudiante)
routerEstudiante.post('/nuevopassword/:token', crearNuevoPasswordEstudiante)

// Login
routerEstudiante.post('/estudiante/login', loginEstudiante)

// Login con OAuth (Google, Microsoft)
routerEstudiante.post('/estudiante/login-oauth', loginOAuthEstudiante)

// ========== RUTAS PRIVADAS (requieren autenticación) ==========

// Perfil
routerEstudiante.get('/estudiante/perfil', verificarTokenJWT, perfilEstudiante)

// Actualizar perfil
routerEstudiante.put('/estudiante/:id', verificarTokenJWT, actualizarPerfilEstudiante)

// Actualizar contraseña
routerEstudiante.put('/estudiante/actualizarpassword/:id', verificarTokenJWT, actualizarPasswordEstudiante)

export default routerEstudiante