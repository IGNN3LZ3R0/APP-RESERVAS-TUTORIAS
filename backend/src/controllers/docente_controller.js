import Docente from "../models/docente.js";
import { sendMailToOwner, sendMailToRecoveryPassword } from "../config/nodemailer.js";
import { v2 as cloudinary } from 'cloudinary';
import fs from "fs-extra";
import mongoose from "mongoose";
import { crearTokenJWT } from "../middlewares/JWT.js";

// ========== REGISTRO DE DOCENTE (POR ADMINISTRADOR) ==========
const registrarDocente = async (req, res) => {
  try {
    const { emailDocente, fechaNacimientoDocente } = req.body;
    
    if (Object.values(req.body).includes(""))
      return res.status(400).json({ msg: "Lo sentimos, debes llenar todos los campos" });

    const verificarEmailBDD = await Docente.findOne({ emailDocente });
    if (verificarEmailBDD)
      return res.status(400).json({ msg: "Lo sentimos, el email ya se encuentra registrado" });

    // ⭐ VALIDAR FECHA DE NACIMIENTO
    if (fechaNacimientoDocente) {
      const fechaNac = new Date(fechaNacimientoDocente);
      const hoy = new Date();
      
      // Validar año mínimo 1960
      if (fechaNac.getFullYear() < 1960) {
        return res.status(400).json({
          msg: "El año de nacimiento debe ser 1960 o posterior"
        });
      }
      
      // Calcular edad
      let edad = hoy.getFullYear() - fechaNac.getFullYear();
      const mesActual = hoy.getMonth();
      const mesNac = fechaNac.getMonth();
      
      if (mesActual < mesNac || 
          (mesActual === mesNac && hoy.getDate() < fechaNac.getDate())) {
        edad--;
      }
      
      // Validar edad mínima 18 años
      if (edad < 18) {
        return res.status(400).json({
          msg: "El docente debe tener al menos 18 años"
        });
      }
    }

    let asignaturas = req.body.asignaturas;
    if (typeof asignaturas === "string") {
      try {
        asignaturas = JSON.parse(asignaturas);
      } catch {
        return res.status(400).json({ msg: "Formato inválido en asignaturas" });
      }
    }

    const password = Math.random().toString(36).toUpperCase().slice(2, 5);

    const nuevoDocente = new Docente({
      ...req.body,
      asignaturas,
      passwordDocente: await Docente.prototype.encrypPassword("ESFOT" + password),
      administrador: req.administradorBDD._id,
      requiresPasswordChange: true // Obligado a cambiar contraseña en primer login 
    });

    if (req.files?.imagen) {
      const { secure_url, public_id } = await cloudinary.uploader.upload(
        req.files.imagen.tempFilePath,
        { folder: "Docentes" }
      );
      nuevoDocente.avatarDocente = secure_url;
      nuevoDocente.avatarDocenteID = public_id;
      await fs.unlink(req.files.imagen.tempFilePath);
    }

    await nuevoDocente.save();
    await sendMailToOwner(emailDocente, "ESFOT" + password);

    res.status(201).json({ 
      msg: "Registro exitoso! El correo ha sido enviado con éxito al docente creado." 
    });
  } catch (error) {
    console.error("Error en registrarDocente:", error);
    res.status(500).json({ 
      msg: "Error interno del servidor", 
      error: error.message 
    });
  }
};

// ========== CAMBIO DE CONTRASEÑA OBLIGATORIO ==========
const cambiarPasswordObligatorio = async (req, res) => {
  try {
    const { email, passwordActual, passwordNueva } = req.body;

    console.log('🔐 Cambio obligatorio para:', email);

    // Validaciones
    if (!email || !passwordActual || !passwordNueva) {
      return res.status(400).json({
        msg: "Todos los campos son obligatorios"
      });
    }

    if (passwordNueva.length < 8) {
      return res.status(400).json({
        msg: "La nueva contraseña debe tener al menos 8 caracteres"
      });
    }

    // Validación de complejidad
    if (!/[A-Z]/.test(passwordNueva)) {
      return res.status(400).json({
        msg: "La contraseña debe incluir al menos una mayúscula"
      });
    }
    if (!/[a-z]/.test(passwordNueva)) {
      return res.status(400).json({
        msg: "La contraseña debe incluir al menos una minúscula"
      });
    }
    if (!/[0-9]/.test(passwordNueva)) {
      return res.status(400).json({
        msg: "La contraseña debe incluir al menos un número"
      });
    }
    if (!/[!@#$%^&*(),.?":{}|<>]/.test(passwordNueva)) {
      return res.status(400).json({
        msg: "La contraseña debe incluir al menos un carácter especial"
      });
    }

    // Normalizar email
    const emailNormalizado = email.trim().toLowerCase();

    // Buscar docente
    const docenteBDD = await Docente.findOne({ 
      emailDocente: emailNormalizado 
    });

    if (!docenteBDD) {
      return res.status(404).json({
        msg: "Docente no encontrado"
      });
    }

    // Verificar contraseña temporal
    const verificarPassword = await docenteBDD.matchPassword(passwordActual);
    if (!verificarPassword) {
      return res.status(401).json({
        msg: "La contraseña temporal es incorrecta"
      });
    }

    // Actualizar contraseña
    docenteBDD.passwordDocente = await docenteBDD.encrypPassword(passwordNueva);
    docenteBDD.requiresPasswordChange = false;  // Ya cambió la contraseña
    
    await docenteBDD.save();

    console.log(`✅ Contraseña cambiada exitosamente: ${emailNormalizado}`);

    res.status(200).json({
      success: true,
      msg: "Contraseña actualizada correctamente"
    });
  } catch (error) {
    console.error("❌ Error en cambio obligatorio:", error);
    res.status(500).json({
      msg: "Error al cambiar contraseña",
      error: error.message
    });
  }
};

// ========== RECUPERACIÓN DE CONTRASEÑA ==========
const recuperarPasswordDocente = async (req, res) => {
  try {
    const { emailDocente } = req.body;

    console.log('📨 Solicitud de recuperación docente:', { emailDocente });

    if (!emailDocente) {
      return res.status(400).json({ 
        success: false,
        msg: "El email es obligatorio" 
      });
    }

    // Normalizar email
    const emailNormalizado = emailDocente.trim().toLowerCase();

    console.log('🔍 Buscando docente con email:', emailNormalizado);

    const docenteBDD = await Docente.findOne({ 
      emailDocente: emailNormalizado 
    });

    if (!docenteBDD) {
      console.log(`ℹ️ Email de docente no encontrado: ${emailNormalizado}`);
      return res.status(404).json({ 
        success: false,
        msg: "Lo sentimos, el usuario no existe" 
      });
    }

    console.log('✅ Docente encontrado:', docenteBDD.nombreDocente);

    // Generar token de recuperación
    const token = docenteBDD.crearToken();
    docenteBDD.token = token;

    await sendMailToRecoveryPassword(emailDocente, token);
    await docenteBDD.save();

    console.log(`✅ Email de recuperación enviado a docente: ${emailDocente}`);

    res.status(200).json({ 
      success: true,
      msg: "Revisa tu correo electrónico para restablecer tu contraseña.",
      email: emailDocente
    });
  } catch (error) {
    console.error("❌ Error en recuperación de password docente:", error);
    res.status(500).json({ 
      success: false,
      msg: "Error al procesar solicitud",
      error: error.message
    });
  }
};

const comprobarTokenPasswordDocente = async (req, res) => {
  try {
    const { token } = req.params;

    console.log('🔍 Comprobando token de docente:', token);

    if (!token) {
      return res.status(400).json({ 
        success: false,
        msg: "Token no proporcionado" 
      });
    }

    const docenteBDD = await Docente.findOne({ token });

    if (!docenteBDD || docenteBDD.token !== token) {
      console.log('❌ Token de docente no encontrado o ya usado');
      return res.status(404).json({ 
        success: false,
        msg: "Lo sentimos, no se puede validar la cuenta" 
      });
    }

    console.log('✅ Token de docente válido para:', docenteBDD.emailDocente);

    res.status(200).json({ 
      success: true,
      msg: "Token confirmado, ya puedes crear tu password" 
    });
  } catch (error) {
    console.error("❌ Error comprobando token docente:", error);
    res.status(500).json({ 
      success: false,
      msg: "Error al validar token" 
    });
  }
};

const crearNuevoPasswordDocente = async (req, res) => {
  try {
    const { password, confirmpassword } = req.body;
    const { token } = req.params;

    console.log('🔐 Creando nueva contraseña para docente con token:', token);

    if (!password || !confirmpassword) {
      return res.status(400).json({ 
        success: false,
        msg: "Lo sentimos, debes llenar todos los campos" 
      });
    }

    if (password !== confirmpassword) {
      return res.status(400).json({ 
        success: false,
        msg: "Lo sentimos, los passwords no coinciden" 
      });
    }

    if (password.length < 8) {
      return res.status(400).json({ 
        success: false,
        msg: "La contraseña debe tener al menos 8 caracteres" 
      });
    }

    const docenteBDD = await Docente.findOne({ token });

    if (!docenteBDD || docenteBDD.token !== token) {
      console.log('❌ Token de docente no encontrado');
      return res.status(404).json({ 
        success: false,
        msg: "Lo sentimos, no se puede validar su cuenta" 
      });
    }

    console.log('✅ Actualizando contraseña de docente:', docenteBDD.emailDocente);

    docenteBDD.token = null;
    docenteBDD.passwordDocente = await docenteBDD.encrypPassword(password);
    await docenteBDD.save();

    console.log(`✅ Contraseña de docente actualizada exitosamente`);

    res.status(200).json({ 
      success: true,
      msg: "Ya puede iniciar sesión con su nueva contraseña.",
      email: docenteBDD.emailDocente
    });
  } catch (error) {
    console.error("❌ Error creando nueva contraseña docente:", error);
    res.status(500).json({ 
      success: false,
      msg: "Error al actualizar contraseña" 
    });
  }
};

// ========== LISTAR DOCENTES ==========
const listarDocentes = async (req, res) => {
  try {
    let docentes = [];
    
    if (req.administradorBDD) {
      docentes = await Docente.find({ 
        estadoDocente: true, 
        administrador: req.administradorBDD._id 
      }).select("-salida -createdAt -updatedAt -__v");
    } else if (req.estudianteBDD) {
      docentes = await Docente.find({ 
        estadoDocente: true 
      }).select("-salida -createdAt -updatedAt -__v");
    } else {
      return res.status(403).json({ 
        msg: "No autorizado para ver docentes" 
      });
    }

    // Asegurar que asignaturas sea siempre un array
    docentes = docentes.map(doc => {
      if (typeof doc.asignaturas === "string") {
        try {
          doc.asignaturas = JSON.parse(doc.asignaturas);
        } catch {
          doc.asignaturas = [];
        }
      }
      return doc;
    });

    return res.status(200).json({ docentes });
  } catch (error) {
    return res.status(500).json({ 
      msg: "Error al listar docentes", 
      error 
    });
  }
};

// ========== DETALLE DE DOCENTE ==========
const detalleDocente = async (req, res) => {
  try {
    const { id } = req.params;
    
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(404).json({ 
        msg: `Lo sentimos, no existe el registro del docente ${id}` 
      });
    }
    
    const docente = await Docente.findById(id)
      .select("-createdAt -updatedAt -__v")
      .populate('administrador', '_id nombre apellido');

    if (!docente) {
      return res.status(404).json({ 
        msg: "Docente no encontrado" 
      });
    }

    // Validar asignaturas
    if (docente && typeof docente.asignaturas === "string") {
      try {
        docente.asignaturas = JSON.parse(docente.asignaturas);
      } catch {
        docente.asignaturas = [];
      }
    }

    res.status(200).json(docente);
  } catch (error) {
    res.status(500).json({ 
      msg: "Error al obtener detalle", 
      error 
    });
  }
};

// ========== ELIMINAR DOCENTE (DESHABILITAR) ==========
const eliminarDocente = async (req, res) => {
  try {
    const { id } = req.params;
    
    if (!req.body.salidaDocente) {
      return res.status(400).json({ 
        msg: "Lo sentimos, debes llenar todos los campos" 
      });
    }
    
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(404).json({ 
        msg: `Lo sentimos, no existe el docente ${id}` 
      });
    }
    
    const { salidaDocente } = req.body;
    
    await Docente.findByIdAndUpdate(id, {
      salidaDocente: new Date(salidaDocente),
      estadoDocente: false
    });
    
    res.status(200).json({ 
      msg: "El registro fue deshabilitado con éxito." 
    });
  } catch (error) {
    res.status(500).json({ 
      msg: "Error al deshabilitar docente", 
      error 
    });
  }
};

// ========== ACTUALIZAR DOCENTE (POR ADMINISTRADOR) ==========
const actualizarDocente = async (req, res) => {
  try {
    const { id } = req.params;
    
    if (Object.values(req.body).includes("")) {
      return res.status(400).json({ 
        msg: "Lo sentimos, debes llenar todos los campos" 
      });
    }
    
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(404).json({ 
        msg: `Lo sentimos, no existe el docente ${id}` 
      });
    }

    let asignaturas = req.body.asignaturas;
    if (typeof asignaturas === "string") {
      try {
        asignaturas = JSON.parse(asignaturas);
      } catch {
        return res.status(400).json({ 
          msg: "Formato inválido en asignaturas" 
        });
      }
    }
    req.body.asignaturas = asignaturas;

    if (req.files?.imagen) {
      const docente = await Docente.findById(id);
      if (docente.avatarDocenteID) {
        await cloudinary.uploader.destroy(docente.avatarDocenteID);
      }
      const cloudiResponse = await cloudinary.uploader.upload(
        req.files.imagen.tempFilePath,
        { folder: 'Docentes' }
      );
      req.body.avatarDocente = cloudiResponse.secure_url;
      req.body.avatarDocenteID = cloudiResponse.public_id;
      await fs.unlink(req.files.imagen.tempFilePath);
    }
    
    const docenteActualizado = await Docente.findByIdAndUpdate(id, req.body, { new: true })
      .select("-passwordDocente -confirmEmail -createdAt -updatedAt -__v");
    
    res.status(200).json({ docente: docenteActualizado });
  } catch (error) {
    res.status(500).json({ 
      msg: "Error al actualizar docente", 
      error 
    });
  }
};

// ========== LOGIN DOCENTE ==========
const loginDocente = async (req, res) => {
  try {
    const { email: emailDocente, password: passwordDocente } = req.body;
    
    if (!emailDocente || !passwordDocente) {
      return res.status(400).json({ 
        msg: "Lo sentimos, debes llenar todos los campos" 
      });
    }
    
    const docenteBDD = await Docente.findOne({ emailDocente });
    
    if (!docenteBDD) {
      return res.status(404).json({ 
        msg: "Lo sentimos, el usuario no se encuentra registrado" 
      });
    }
    
    const verificarPassword = await docenteBDD.matchPassword(passwordDocente);
    
    if (!verificarPassword) {
      return res.status(401).json({ 
        msg: "Lo sentimos, el password no es el correcto" 
      });
    }
    
    const token = crearTokenJWT(docenteBDD._id, docenteBDD.rol);
    const { _id, rol, avatarDocente, requiresPasswordChange } = docenteBDD;
    
    // ✅ CONSTRUIR RESPUESTA CON FLAG CONDICIONAL
    const response = { 
      token, 
      rol, 
      _id, 
      avatarDocente 
    };

    // Solo agregar requiresPasswordChange si es true
    if (requiresPasswordChange === true) {
      response.requiresPasswordChange = true;
    }

    res.status(200).json(response);
  } catch (error) {
    res.status(500).json({ 
      msg: "Error al iniciar sesión", 
      error 
    });
  }
};

// ========== PERFIL DOCENTE ==========
const perfilDocente = (req, res) => {
  try {
    const docente = req.docenteBDD;
    
    if (!docente) {
      return res.status(404).json({ 
        msg: "Docente no encontrado." 
      });
    }
    
    const camposAEliminar = [
      "fechaIngresoDocente", 
      "salidaDocente",
      "estadoDocente", 
      "passwordDocente", 
      "confirmEmail", 
      "createdAt", 
      "updatedAt", 
      "__v"
    ];
    
    camposAEliminar.forEach(campo => delete req.docenteBDD[campo]);
    
    res.status(200).json(req.docenteBDD);
  } catch (error) {
    res.status(500).json({ 
      msg: "Error al obtener perfil", 
      error 
    });
  }
};

// ========== ACTUALIZAR PERFIL DOCENTE (POR ÉL MISMO) ==========
const actualizarPerfilDocente = async (req, res) => {
  try {
    const { id } = req.params;
    // ✅ PERMITIR: Docente edita su propio perfil O Admin edita cualquier perfil
    const esDocente = req.docenteBDD && req.docenteBDD._id.toString() === id;
    const esAdmin = req.administradorBDD; // Si existe, es admin
    
    if (!esDocente && !esAdmin) {
      return res.status(403).json({ 
        msg: "No tienes permiso para modificar este perfil" 
      });
    }

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ 
        msg: "ID de docente inválido" 
      });
    }

    const { nombreDocente, celularDocente, oficinaDocente, emailAlternativoDocente } = req.body;

    const docenteBDD = await Docente.findById(id);
    
    if (!docenteBDD) {
      return res.status(404).json({ 
        msg: "Docente no encontrado" 
      });
    }

    // Actualizar campos permitidos
    if (nombreDocente !== undefined && nombreDocente.trim() !== '') {
      if (nombreDocente.trim().length < 3) {
        return res.status(400).json({
          msg: "El nombre debe tener al menos 3 caracteres"
        });
      }
      docenteBDD.nombreDocente = nombreDocente.trim();
    }

    if (celularDocente !== undefined && celularDocente.trim() !== '') {
      const telefonoLimpio = celularDocente.replace(/[\s\-\(\)]/g, '');
      if (!/^\d+$/.test(telefonoLimpio)) {
        return res.status(400).json({
          msg: "El teléfono solo debe contener números"
        });
      }
      if (telefonoLimpio.length !== 10) {
        return res.status(400).json({
          msg: "El teléfono debe tener exactamente 10 dígitos"
        });
      }
      docenteBDD.celularDocente = telefonoLimpio;
    }

    if (oficinaDocente !== undefined && oficinaDocente.trim() !== '') {
      docenteBDD.oficinaDocente = oficinaDocente.trim();
    }

    if (emailAlternativoDocente !== undefined && emailAlternativoDocente.trim() !== '') {
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(emailAlternativoDocente)) {
        return res.status(400).json({
          msg: "Por favor ingresa un email alternativo válido"
        });
      }
      
      // Verificar que el email alternativo no esté en uso por otro docente
      const emailExistente = await Docente.findOne({ 
        emailAlternativoDocente: emailAlternativoDocente.toLowerCase() 
      });
      
      if (emailExistente && emailExistente._id.toString() !== id) {
        return res.status(400).json({
          msg: "El email alternativo ya está en uso por otro docente"
        });
      }
      
      docenteBDD.emailAlternativoDocente = emailAlternativoDocente.toLowerCase();
    }

    // Actualizar foto de perfil si se envía
    if (req.files?.imagen) {
      try {
        if (docenteBDD.avatarDocenteID) {
          await cloudinary.uploader.destroy(docenteBDD.avatarDocenteID);
        }

        const allowedTypes = ['image/jpeg', 'image/png', 'image/jpg'];
        if (!allowedTypes.includes(req.files.imagen.mimetype)) {
          await fs.unlink(req.files.imagen.tempFilePath);
          return res.status(400).json({
            msg: "Solo se permiten imágenes en formato JPG, JPEG o PNG"
          });
        }

        const maxSize = 5 * 1024 * 1024; // 5MB
        if (req.files.imagen.size > maxSize) {
          await fs.unlink(req.files.imagen.tempFilePath);
          return res.status(400).json({
            msg: "La imagen no debe superar los 5MB"
          });
        }

        const { secure_url, public_id } = await cloudinary.uploader.upload(
          req.files.imagen.tempFilePath,
          {
            folder: "Docentes",
            transformation: [
              { width: 500, height: 500, crop: "limit" },
              { quality: "auto:good" }
            ]
          }
        );

        docenteBDD.avatarDocente = secure_url;
        docenteBDD.avatarDocenteID = public_id;

        await fs.unlink(req.files.imagen.tempFilePath);
      } catch (cloudinaryError) {
        console.error("Error subiendo imagen:", cloudinaryError);
        return res.status(500).json({
          msg: "Error al subir la imagen. Intenta con una imagen más pequeña."
        });
      }
    }

    await docenteBDD.save();

    const docenteActualizado = await Docente.findById(id)
      .select('-passwordDocente -token -__v -createdAt -updatedAt');

    res.status(200).json({
      success: true,
      msg: "Perfil actualizado con éxito",
      docente: docenteActualizado
    });
  } catch (error) {
    console.error("Error actualizando perfil:", error);
    res.status(500).json({ 
      msg: "Error al actualizar perfil", 
      error: error.message 
    });
  }
};

// ========== ACTUALIZAR CONTRASEÑA DOCENTE (POR ÉL MISMO) ==========
const actualizarPasswordDocente = async (req, res) => {
  try {
    const { passwordactual, passwordnuevo } = req.body;

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

    const docenteBDD = await Docente.findById(req.docenteBDD._id);

    if (!docenteBDD) {
      return res.status(404).json({ 
        msg: "Docente no encontrado" 
      });
    }

    const verificarPassword = await docenteBDD.matchPassword(passwordactual);

    if (!verificarPassword) {
      return res.status(401).json({ 
        msg: "La contraseña actual es incorrecta" 
      });
    }

    docenteBDD.passwordDocente = await docenteBDD.encrypPassword(passwordnuevo);
    await docenteBDD.save();

    console.log(`✅ Contraseña actualizada: ${docenteBDD.emailDocente}`);

    res.status(200).json({
      success: true,
      msg: "Contraseña actualizada correctamente"
    });
  } catch (error) {
    console.error("Error actualizando contraseña:", error);
    res.status(500).json({ 
      msg: "Error al actualizar contraseña", 
      error: error.message 
    });
  }
};

// ========== EXPORTACIONES ==========
export {
  registrarDocente,
  listarDocentes,
  detalleDocente,
  eliminarDocente,
  actualizarDocente,
  loginDocente,
  perfilDocente,
  recuperarPasswordDocente,
  comprobarTokenPasswordDocente,
  crearNuevoPasswordDocente,
  actualizarPerfilDocente,      
  actualizarPasswordDocente,
  cambiarPasswordObligatorio    
};