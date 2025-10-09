import {Router} from 'express'
import {
        recuperarPasswordAdministrador, 
        comprobarTokenPasswordAdministrador, 
        crearNuevoPasswordAdministrador, 
        loginAdministrador, 
        perfilAdministrador, 
        actualizarPerfilAdministrador, 
        actualizarPasswordAdministrador} from '../controllers/administrador_controller.js'
import { loginOAuthAdministrador } from "../controllers/sesion_google_correo_controller.js"; // Nueva importación del controlador para OAuth
import { verificarTokenJWT } from '../middlewares/JWT.js'

const routerAdministrador = Router()

//Rutas públicas

//routerAdministrador.get('/confirmar/:token', confirmarMailAdministrador)

routerAdministrador.post('/recuperarpassword', recuperarPasswordAdministrador)

routerAdministrador.get('/recuperarpassword/:token', comprobarTokenPasswordAdministrador)

routerAdministrador.post('/nuevopassword/:token',crearNuevoPasswordAdministrador)

routerAdministrador.post ('/login',loginAdministrador)

// Nueva ruta para login del administrador con Outlook o Gmail
routerAdministrador.post('/administrador/login-oauth', loginOAuthAdministrador);

//Rutas privadas
routerAdministrador.get('/perfil',verificarTokenJWT,perfilAdministrador)

routerAdministrador.put('/administrador/:id',verificarTokenJWT,actualizarPerfilAdministrador)

routerAdministrador.put('/administrador/actualizarpassword/:id',verificarTokenJWT,actualizarPasswordAdministrador)

export default routerAdministrador