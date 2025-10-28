/*import mongoose, {Schema,model} from 'mongoose'
import bcrypt from "bcryptjs"

const docenteSchema = new Schema({
    cedulaDocente:{
        type:String,
        required:true,
        trim:true,
        unique: true
    },
    nombreDocente:{
        type:String,
        required:true,
        trim:true
    },
    fechaNacimientoDocente:{
        type:Date,
        required:true,
        trim:true
    },
    oficinaDocente: {
        type: String,
        required: true,
        trim: true
    },
    emailDocente:{
        type:String,
        required:true,
        trim:true,
        unique: true
    },
    emailAlternativoDocente: {
        type: String,
        required: true,
        trim: true,
        unique: true
    },
    passwordDocente:{
        type:String,
        required:true
    },
    celularDocente:{
        type:String,
        required:true,
        trim:true
    },
    avatarDocente:{
        type:String,
        default: "https://cdn-icons-png.flaticon.com/512/4715/4715329.png",
        trim:true
    },
    avatarDocenteID:{
        type:String,
        trim:true
    },
    fechaIngresoDocente:{
        type:Date,
        required:true,
        trim:true,
        default:Date.now
    },
    salidaDocente: {
        type: Date,
        trim: true,
        default: null
    },
    semestreAsignado: {
        type: String,
        enum: ['Nivelacion', 'Primer Semestre'],
        required: true
    },
    asignaturas: {
        type: [String],
        required: true
    },
    confirmEmail: {
    type: Boolean,
    default: false,
    },
    token: {
    type: String,
    default: null
    },
    estadoDocente:{
        type:Boolean,
        default:true
    },
    rol:{
        type:String,
        default:"Docente"
    },
    administrador:{
        type:mongoose.Schema.Types.ObjectId,
        ref:'Administrador'
    }
},{
    timestamps:true
})


// Método para cifrar el password del Docente
docenteSchema.methods.encrypPassword = async function(password){
    const salt = await bcrypt.genSalt(10)
    return bcrypt.hash(password, salt)
}

// Método para verificar si el password ingresado es el mismo de la BDD
docenteSchema.methods.matchPassword = async function(password){
    return bcrypt.compare(password, this.passwordDocente)
}

export default model('Docente',docenteSchema)*/

//MODELO DOCENTE MODIFICADO PARA INCLUIR AUTENTICACIÓN OAUTH

import mongoose, { Schema, model } from 'mongoose'
import bcrypt from 'bcryptjs'

const docenteSchema = new Schema({
  cedulaDocente: {
    type: String,
    required: function () {
      return !this.isOAuth // Requerido solo si no es OAuth lo mismo con el resto de datos (puede haber errores de registro
    },                     // ya que con estas opciones no se requiere el registro manual)
    trim: true,
    unique: true
  },
  nombreDocente: {
    type: String,
    required: function () {
      return !this.isOAuth
    },
    trim: true
  },
  fechaNacimientoDocente: {
    type: Date,
    required: function () {
      return !this.isOAuth
    },
    trim: true
  },
  oficinaDocente: {
    type: String,
    required: function () {
      return !this.isOAuth
    },
    trim: true
  },
  emailDocente: {
    type: String,
    required: true,
    trim: true,
    unique: true
  },
  emailAlternativoDocente: {
    type: String,
    required: function () {
      return !this.isOAuth
    },
    trim: true,
    unique: true
  },
  passwordDocente: {
    type: String,
    required: function () {
      return !this.isOAuth
    }
  },

  celularDocente: {
    type: String,
    required: function () {
      return !this.isOAuth
    },
    trim: true
  },
  avatarDocente: {
    type: String,
    default: "https://cdn-icons-png.flaticon.com/512/4715/4715329.png",
    trim: true
  },
  avatarDocenteID: {
    type: String,
    trim: true
  },
  fechaIngresoDocente: {
    type: Date,
    required: function () {
      return !this.isOAuth
    },
    trim: true,
    default: Date.now
  },
  salidaDocente: {
    type: Date,
    trim: true,
    default: null
  },
  /*semestreAsignado: {
    type: String,
    enum: ['Nivelacion', 'Primer Semestre'],
    required: function () {
      return !this.isOAuth
    }
  },
  asignaturas: {
    type: [String],
    required: function () {
      return !this.isOAuth
    }
  },*/
  confirmEmail: {
    type: Boolean,
    default: false
  },
  token: {
    type: String,
    default: null
  },
  estadoDocente: {
    type: Boolean,
    default: true
  },
  rol: {
    type: String,
    default: "Docente"
  },
  administrador: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Administrador'
  },

    requiresPasswordChange: {
    type: Boolean,
    default: false  // Se marca true cuando admin crea docente
  },

  // Campos nuevos para login con OAuth
  isOAuth: {
    type: Boolean,
    default: false
  },
  oauthProvider: {
    type: String,
    enum: ['google', 'microsoft'],
    default: null
  }
}, {
  timestamps: true
})

// Método para cifrar el password del Docente
docenteSchema.methods.encrypPassword = async function (password) {
  const salt = await bcrypt.genSalt(10)
  return bcrypt.hash(password, salt)
}

// Método para verificar si el password ingresado es el mismo de la BDD
docenteSchema.methods.matchPassword = async function (password) {
  return bcrypt.compare(password, this.passwordDocente)
}

// ✅ Método para crear token de recuperación de contraseña
docenteSchema.methods.crearToken = function () {
  const tokenGenerado = this.token = Math.random().toString(36).slice(2)
  return tokenGenerado
}

// ✅ Middleware para normalizar emails antes de guardar
docenteSchema.pre('save', function(next) {
  // Normalizar email antes de guardar
  if (this.emailDocente) {
    this.emailDocente = this.emailDocente.trim().toLowerCase();
  }
  if (this.emailAlternativoDocente) {
    this.emailAlternativoDocente = this.emailAlternativoDocente.trim().toLowerCase();
  }
  next();
});

export default model('Docente', docenteSchema)