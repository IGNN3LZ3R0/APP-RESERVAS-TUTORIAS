import { Router } from 'express'
import { loginOAuthEstudiante } from "../controllers/sesion_google_correo_controller.js"; // Nueva importacion del controlador para OAuth
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

// Rutas públicas
routerEstudiante.post('/estudiante/registro', registroEstudiante)

routerEstudiante.get('/confirmar/:token', confirmarMailEstudiante)

routerEstudiante.post('/recuperarpassword', recuperarPasswordEstudiante)

routerEstudiante.get('/recuperarpassword/:token', comprobarTokenPasswordEstudiante)

routerEstudiante.post('/nuevopassword/:token', crearNuevoPasswordEstudiante)

routerEstudiante.post('/estudiante/login', loginEstudiante)

// Nueva ruta para login con OAuth (Google, Microsoft)
routerEstudiante.post('/estudiante/login-oauth', loginOAuthEstudiante)

// Rutas privadas
routerEstudiante.get('/estudiante/perfil', verificarTokenJWT, perfilEstudiante)

routerEstudiante.put('/estudiante/:id', verificarTokenJWT, actualizarPerfilEstudiante)

routerEstudiante.put('/estudiante/actualizarpassword/:id', verificarTokenJWT, actualizarPasswordEstudiante)

export default routerEstudiante
