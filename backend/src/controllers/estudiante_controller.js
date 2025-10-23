import Estudiante from "../models/estudiante.js";
import { sendMailToRegister, sendMailToRecoveryPassword } from "../config/nodemailer.js";
import { crearTokenJWT } from "../middlewares/JWT.js";
import mongoose from "mongoose";
import cloudinary from "cloudinary";
import fs from "fs-extra";

// ========== REGISTRO Y CONFIRMACIÓN DE CUENTA ==========

/**
 * Registrar nuevo estudiante y enviar email de confirmación
 * POST /api/estudiante/registro
 */
const registroEstudiante = async (req, res) => {
  try {
    const { emailEstudiante, password, nombreEstudiante } = req.body;

    // Validar campos obligatorios
    if (!emailEstudiante || !password || !nombreEstudiante) {
      return res.status(400).json({
        msg: "Todos los campos son obligatorios (nombre, email, contraseña)."
      });
    }

    // Validar formato de email
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(emailEstudiante)) {
      return res.status(400).json({
        msg: "Por favor ingresa un email válido."
      });
    }

    // Validar longitud de contraseña
    if (password.length < 8) {
      return res.status(400).json({
        msg: "La contraseña debe tener al menos 8 caracteres."
      });
    }

    // Validar longitud del nombre
    if (nombreEstudiante.trim().length < 3 || nombreEstudiante.trim().length > 100) {
      return res.status(400).json({
        msg: "El nombre debe tener entre 3 y 100 caracteres."
      });
    }    // Verificar si el email ya existe
    const verificarEmailBDD = await Estudiante.findOne({ emailEstudiante });
    if (verificarEmailBDD) {
      return res.status(400).json({
        msg: "Este email ya está registrado. Intenta iniciar sesión o recuperar tu contraseña."
      });
    }

    // Crear nuevo estudiante
    const nuevoEstudiante = new Estudiante(req.body);
    nuevoEstudiante.password = await nuevoEstudiante.encrypPassword(password);

    // Generar token de confirmación
    const token = nuevoEstudiante.crearToken();

    // Guardar en base de datos
    await nuevoEstudiante.save();

    // Enviar email de confirmación
    await sendMailToRegister(emailEstudiante, token);

    console.log(`✅ Estudiante registrado: ${emailEstudiante}`);

    res.status(200).json({
      msg: "¡Registro exitoso! Revisa tu correo electrónico para activar tu cuenta.",
      email: emailEstudiante
    });
  } catch (error) {
    console.error("❌ Error en registro:", error);
    res.status(500).json({
      msg: "Error al registrar estudiante. Intenta nuevamente.",
      error: error.message
    });
  }
};

/**
 * Confirmar email con token desde deep link o API
 * GET /api/confirmar/:token
 */
const confirmarMailEstudiante = async (req, res) => {
  try {
    const { token } = req.params;

    if (!token) {
      return res.status(400).json({
        success: false,
        msg: "Token no proporcionado"
      });
    }

    // Buscar estudiante con ese token
    const estudianteBDD = await Estudiante.findOne({ token });

    if (!estudianteBDD) {
      return res.status(404).json({
        success: false,
        msg: "Token inválido o cuenta ya confirmada"
      });
    }

    if (!estudianteBDD.token) {
      return res.status(400).json({
        success: false,
        msg: "Esta cuenta ya fue activada anteriormente"
      });
    }

    // Activar cuenta
    estudianteBDD.token = null;
    estudianteBDD.confirmEmail = true;
    await estudianteBDD.save();

    console.log(`✅ Cuenta confirmada: ${estudianteBDD.emailEstudiante}`);

    // Responder con JSON para que la app lo maneje
    return res.status(200).json({
      success: true,
      msg: "¡Cuenta activada exitosamente! Ya puedes iniciar sesión en la aplicación.",
      email: estudianteBDD.emailEstudiante,
      nombre: estudianteBDD.nombreEstudiante
    });
  } catch (error) {
    console.error("❌ Error en confirmación:", error);
    return res.status(500).json({
      success: false,
      msg: "Error al confirmar cuenta. Intenta nuevamente o contacta a soporte."
    });
  }
};

// ========== RECUPERACIÓN DE CONTRASEÑA ==========

/**
 * Solicitar recuperación de contraseña
 * POST /api/recuperarpassword
 */
const recuperarPasswordEstudiante = async (req, res) => {
  try {
    const { email } = req.body;

    console.log('📨 Solicitud de recuperación recibida:', { email });

    if (!email) {
      console.log('❌ Email no proporcionado');
      return res.status(400).json({
        success: false,
        msg: "El email es obligatorio"
      });
    }

    // Normalizar el email (trim y lowercase)
    const emailNormalizado = email.trim().toLowerCase();

    console.log('� Buscando estudiante con email:', emailNormalizado);

    // Buscar estudiante - asegurarse de usar el email normalizado
    const estudianteBDD = await Estudiante.findOne({
      emailEstudiante: emailNormalizado
    });

    if (!estudianteBDD) {
      console.log(`ℹ️ Email no encontrado en la base de datos: ${emailNormalizado}`);
      return res.status(404).json({
        success: false,
        msg: "Lo sentimos, el usuario no existe"
      });
    }

    // Verificar si la cuenta está confirmada
    if (!estudianteBDD.confirmEmail) {
      console.log(`⚠️ Intento de recuperación para cuenta no confirmada: ${email}`);
      return res.status(400).json({
        success: false,
        msg: "Por favor, confirma tu cuenta primero. Revisa tu correo electrónico."
      });
    }

    // Generar token de recuperación
    const token = estudianteBDD.crearToken();
    estudianteBDD.token = token;
    await estudianteBDD.save();

    // Enviar email
    await sendMailToRecoveryPassword(email, token);

    console.log(`✅ Email de recuperación enviado a: ${email}`);

    res.status(200).json({
      msg: "Correo enviado. Revisa tu bandeja de entrada y sigue las instrucciones para restablecer tu contraseña.",
      email: email
    });
  } catch (error) {
    console.error("❌ Error en recuperación de password:", error);
    res.status(500).json({
      msg: "Error al procesar solicitud. Intenta nuevamente.",
      error: error.message
    });
  }
};

/**
 * Comprobar validez del token de recuperación
 * GET /api/recuperarpassword/:token
 */
const comprobarTokenPasswordEstudiante = async (req, res) => {
  try {
    const { token } = req.params;

    if (!token) {
      return res.status(400).json({
        success: false,
        msg: "Token no proporcionado"
      });
    }

    // Buscar estudiante con ese token
    const estudianteBDD = await Estudiante.findOne({ token });

    if (!estudianteBDD || !estudianteBDD.token) {
      return res.status(404).json({
        success: false,
        msg: "Token inválido o expirado. Solicita un nuevo enlace de recuperación."
      });
    }

    res.status(200).json({
      success: true,
      msg: "Token válido. Puedes proceder a crear tu nueva contraseña.",
      token: token
    });
  } catch (error) {
    console.error("❌ Error comprobando token:", error);
    res.status(500).json({
      success: false,
      msg: "Error al validar token"
    });
  }
};

/**
 * Crear nueva contraseña con token válido
 * POST /api/nuevopassword/:token
 */
const crearNuevoPasswordEstudiante = async (req, res) => {
  try {
    const { password, confirmpassword } = req.body;
    const { token } = req.params;

    // Validaciones
    if (!password || !confirmpassword) {
      return res.status(400).json({
        msg: "Debes llenar todos los campos"
      });
    }

    if (password !== confirmpassword) {
      return res.status(400).json({
        msg: "Las contraseñas no coinciden"
      });
    }

    if (password.length < 8) {
      return res.status(400).json({
        msg: "La contraseña debe tener al menos 8 caracteres"
      });
    }

    // Buscar estudiante con el token
    const estudianteBDD = await Estudiante.findOne({ token });

    if (!estudianteBDD) {
      return res.status(404).json({
        msg: "Token inválido o expirado. Solicita un nuevo enlace de recuperación."
      });
    }

    // Actualizar contraseña
    estudianteBDD.token = null;
    estudianteBDD.password = await estudianteBDD.encrypPassword(password);
    await estudianteBDD.save();

    console.log(`✅ Contraseña actualizada para: ${estudianteBDD.emailEstudiante}`);

    res.status(200).json({
      success: true,
      msg: "¡Contraseña actualizada exitosamente! Ya puedes iniciar sesión con tu nueva contraseña.",
      email: estudianteBDD.emailEstudiante
    });
  } catch (error) {
    console.error("❌ Error creando nueva contraseña:", error);
    res.status(500).json({
      msg: "Error al actualizar contraseña. Intenta nuevamente"
    });
  }
};

// ========== LOGIN ==========

/**
 * Iniciar sesión de estudiante
 * POST /api/estudiante/login
 */
const loginEstudiante = async (req, res) => {
  try {
    const { emailEstudiante, password } = req.body;

    // Validar campos
    if (!emailEstudiante || !password) {
      return res.status(400).json({
        msg: "Email y contraseña son obligatorios"
      });
    }

    // Buscar estudiante
    const estudianteBDD = await Estudiante.findOne({ emailEstudiante })
      .select("-status -__v -token -createdAt -updatedAt");

    if (!estudianteBDD) {
      return res.status(404).json({
        msg: "Email o contraseña incorrectos"
      });
    }

    // Verificar si la cuenta está confirmada
    if (estudianteBDD.confirmEmail === false) {
      return res.status(401).json({
        msg: "Debes confirmar tu cuenta antes de iniciar sesión. Revisa tu correo electrónico.",
        requiresConfirmation: true,
        email: emailEstudiante
      });
    }

    // Verificar contraseña
    const verificarPassword = await estudianteBDD.matchPassword(password);
    if (!verificarPassword) {
      return res.status(401).json({
        msg: "Email o contraseña incorrectos"
      });
    }

    // Generar token JWT
    const token = crearTokenJWT(estudianteBDD._id, estudianteBDD.rol);

    console.log(`✅ Login exitoso: ${emailEstudiante}`);

    // Responder con datos del usuario
    res.status(200).json({
      success: true,
      msg: "Login exitoso",
      token,
      usuario: {
        _id: estudianteBDD._id,
        nombreEstudiante: estudianteBDD.nombreEstudiante,
        emailEstudiante: estudianteBDD.emailEstudiante,
        telefono: estudianteBDD.telefono,
        fotoPerfil: estudianteBDD.fotoPerfil,
        rol: estudianteBDD.rol
      }
    });
  } catch (error) {
    console.error("❌ Error en login:", error);
    res.status(500).json({
      msg: "Error al iniciar sesión. Intenta nuevamente.",
      error: error.message
    });
  }
};

// ========== PERFIL ==========

/**
 * Obtener perfil del estudiante autenticado
 * GET /api/estudiante/perfil
 */
const perfilEstudiante = (req, res) => {
  try {
    const { token, confirmEmail, createdAt, updatedAt, __v, password, ...datosPerfil } = req.estudianteBDD;

    res.status(200).json({
      success: true,
      estudiante: datosPerfil
    });
  } catch (error) {
    console.error("❌ Error obteniendo perfil:", error);
    res.status(500).json({
      msg: "Error al obtener perfil"
    });
  }
};

/**
 * Actualizar perfil del estudiante (nombre, teléfono, foto)
 * PUT /api/estudiante/:id
 */
const actualizarPerfilEstudiante = async (req, res) => {
  try {
    const { id } = req.params;
    const { nombreEstudiante, telefono } = req.body;

    // Validar ID
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        msg: "ID de estudiante inválido"
      });
    }

    // Buscar estudiante
    const estudianteBDD = await Estudiante.findById(id);

    if (!estudianteBDD) {
      return res.status(404).json({
        msg: "Estudiante no encontrado"
      });
    }

    // Validar que el usuario autenticado es el mismo estudiante
    if (req.estudianteBDD._id.toString() !== id) {
      return res.status(403).json({
        msg: "No tienes permiso para modificar este perfil"
      });
    }

    // ========== ACTUALIZAR NOMBRE ==========
    if (nombreEstudiante !== undefined && nombreEstudiante !== null && nombreEstudiante.trim() !== '') {
      if (nombreEstudiante.trim().length < 3) {
        return res.status(400).json({
          msg: "El nombre debe tener al menos 3 caracteres"
        });
      }
      if (nombreEstudiante.trim().length > 100) {
        return res.status(400).json({
          msg: "El nombre no puede tener más de 100 caracteres"
        });
      }
      estudianteBDD.nombreEstudiante = nombreEstudiante.trim();
      console.log(`📝 Nombre actualizado a: ${nombreEstudiante.trim()}`);
    }

    // ========== ACTUALIZAR EMAIL ==========
    if (req.body.emailEstudiante !== undefined && req.body.emailEstudiante !== null && req.body.emailEstudiante.trim() !== '') {
      const nuevoEmail = req.body.emailEstudiante.trim();

      // Validar formato de email
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(nuevoEmail)) {
        return res.status(400).json({
          msg: "Por favor ingresa un email válido."
        });
      }

      // Verificar si el email ya existe en otro usuario
      const emailExistente = await Estudiante.findOne({ emailEstudiante: nuevoEmail });
      if (emailExistente && emailExistente._id.toString() !== id) {
        return res.status(400).json({
          msg: "El email ingresado ya está en uso por otro usuario"
        });
      }

      estudianteBDD.emailEstudiante = nuevoEmail;
      console.log(`✉️ Email actualizado a: ${nuevoEmail}`);
    }

    // ========== ACTUALIZAR TELÉFONO ==========
    if (telefono !== undefined && telefono !== null && telefono.trim() !== '') {
      // Limpiar teléfono (quitar espacios, guiones, paréntesis)
      const telefonoLimpio = telefono.replace(/[\s\-\(\)]/g, '');

      // Validar que solo contenga números
      if (!/^\d+$/.test(telefonoLimpio)) {
        return res.status(400).json({
          msg: "El teléfono solo debe contener números"
        });
      }

      // Validar longitud (10 dígitos para Ecuador)
      if (telefonoLimpio.length !== 10) {
        return res.status(400).json({
          msg: "El teléfono debe tener exactamente 10 dígitos"
        });
      }

      estudianteBDD.telefono = telefonoLimpio;
      console.log(`📱 Teléfono actualizado a: ${telefonoLimpio}`);
    }

    // ========== ACTUALIZAR FOTO DE PERFIL ==========
    if (req.files?.imagen) {
      try {
        // Eliminar imagen anterior de Cloudinary si existe
        if (estudianteBDD.fotoPerfilID) {
          await cloudinary.uploader.destroy(estudianteBDD.fotoPerfilID);
          console.log(`🗑️ Imagen anterior eliminada de Cloudinary`);
        }

        // Validar tipo de archivo
        const allowedTypes = ['image/jpeg', 'image/png', 'image/jpg'];
        if (!allowedTypes.includes(req.files.imagen.mimetype)) {
          await fs.unlink(req.files.imagen.tempFilePath);
          return res.status(400).json({
            msg: "Solo se permiten imágenes en formato JPG, JPEG o PNG"
          });
        }

        // Validar tamaño de archivo (máximo 5MB)
        const maxSize = 5 * 1024 * 1024; // 5MB en bytes
        if (req.files.imagen.size > maxSize) {
          await fs.unlink(req.files.imagen.tempFilePath);
          return res.status(400).json({
            msg: "La imagen no debe superar los 5MB"
          });
        }

        // Subir nueva imagen a Cloudinary
        const { secure_url, public_id } = await cloudinary.uploader.upload(
          req.files.imagen.tempFilePath,
          {
            folder: "Estudiantes",
            transformation: [
              { width: 500, height: 500, crop: "limit" },
              { quality: "auto:good" }
            ]
          }
        ); estudianteBDD.fotoPerfil = secure_url;
        estudianteBDD.fotoPerfilID = public_id;

        // Eliminar archivo temporal
        await fs.unlink(req.files.imagen.tempFilePath);

        console.log(`📸 Foto de perfil actualizada`);
      } catch (cloudinaryError) {
        console.error("❌ Error subiendo imagen a Cloudinary:", cloudinaryError);
        return res.status(500).json({
          msg: "Error al subir la imagen. Intenta con una imagen más pequeña."
        });
      }
    }

    // Guardar cambios
    await estudianteBDD.save();

    // Obtener estudiante actualizado sin campos sensibles
    const estudianteActualizado = await Estudiante.findById(id)
      .select('-password -token -__v -createdAt -updatedAt');

    console.log(`✅ Perfil actualizado exitosamente: ${estudianteBDD.emailEstudiante}`);

    res.status(200).json({
      success: true,
      msg: "Perfil actualizado con éxito",
      estudiante: estudianteActualizado
    });
  } catch (error) {
    console.error("❌ Error actualizando perfil:", error);
    res.status(500).json({
      msg: "Error al actualizar perfil. Intenta nuevamente.",
      error: error.message
    });
  }
};

/**
 * Actualizar contraseña del estudiante
 * PUT /api/estudiante/actualizarpassword/:id
 */
const actualizarPasswordEstudiante = async (req, res) => {
  try {
    const { passwordactual, passwordnuevo } = req.body;

    // Validaciones
    if (!passwordactual || !passwordnuevo) {
      return res.status(400).json({
        msg: "Debes proporcionar la contraseña actual y la nueva contraseña"
      });
    }

    if (passwordnuevo.length < 8) {
      return res.status(400).json({
        msg: "La nueva contraseña debe tener al menos 8 caracteres"
      });
    }

    // Buscar estudiante
    const estudianteBDD = await Estudiante.findById(req.estudianteBDD._id);

    if (!estudianteBDD) {
      return res.status(404).json({
        msg: "Estudiante no encontrado"
      });
    }

    // Verificar contraseña actual
    const verificarPassword = await estudianteBDD.matchPassword(passwordactual);

    if (!verificarPassword) {
      return res.status(401).json({
        msg: "La contraseña actual es incorrecta"
      });
    }

    // Actualizar contraseña
    estudianteBDD.password = await estudianteBDD.encrypPassword(passwordnuevo);
    await estudianteBDD.save();

    console.log(`✅ Contraseña actualizada: ${estudianteBDD.emailEstudiante}`);

    res.status(200).json({
      success: true,
      msg: "Contraseña actualizada correctamente"
    });
  } catch (error) {
    console.error("❌ Error actualizando contraseña:", error);
    res.status(500).json({
      msg: "Error al actualizar contraseña",
      error: error.message
    });
  }
};

// ========== EXPORTACIONES ==========
export {
  registroEstudiante,
  confirmarMailEstudiante,
  recuperarPasswordEstudiante,
  comprobarTokenPasswordEstudiante,
  crearNuevoPasswordEstudiante,
  loginEstudiante,
  perfilEstudiante,
  actualizarPerfilEstudiante,
  actualizarPasswordEstudiante
};