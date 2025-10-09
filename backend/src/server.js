import express from 'express'
import dotenv from 'dotenv'
import cors from 'cors';
import { registrarAdministrador } from './controllers/administrador_controller.js'
import routerAdministrador from './routers/administrador_routes.js'
import routerDocente from "./routers/docente_routes.js"
import routerEstudiante from "./routers/estudiante_routes.js"
import routerTutorias from './routers/tutorias_routes.js';
import cloudinary from 'cloudinary'
import fileUpload from "express-fileupload"

//Inicializaciones
const app = express()
dotenv.config()

// Configuraciones 
app.set('port',process.env.port || 3000)

// CORS configurado para frontend específico
app.use(cors({
  //origin: 'https://gestion-tutorias-modified-aw-1.onrender.com',  // Reemplaza con tu URL frontend
  origin: 'http://10.0.2.2:3000',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  credentials: true,
}))

app.use(fileUpload({
    useTempFiles : true,
    tempFileDir : './uploads'
}))

// Middlewares 
app.use(express.json())

// Rutas 
app.get('/',(req,res)=>{
    res.send("Server on")
})

// Rutas especificas
app.use('/api/', routerAdministrador)

//Llamar a la funcion de registro del administrador
registrarAdministrador()

// Rutas para docentes
app.use('/api',routerDocente)

// Rutas para estudiantes
app.use('/api',routerEstudiante)

//Rutas para tutorias
app.use('/api',routerTutorias)

// Manejo de una ruta que no sea encontrada
app.use((req,res)=>res.status(404).send("Endpoint no encontrado - 404"))

// Inicializaciones
cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET
})

// Exportar la instancia 
export default app
