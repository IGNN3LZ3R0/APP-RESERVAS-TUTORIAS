import Estudiante from "../models/estudiante.js";
import { sendMailToRegister, sendMailToRecoveryPassword } from "../config/nodemailer.js";
import { crearTokenJWT } from "../middlewares/JWT.js";
import mongoose from "mongoose";
import cloudinary from "cloudinary";
import fs from "fs-extra";

// Registro de estudiante y envío de correo
const registroEstudiante = async (req, res) => {
  const { emailEstudiante, password } = req.body;
  if (Object.values(req.body).includes("")) return res.status(400).json({ msg: "Todos los campos son obligatorios." });

  const verificarEmailBDD = await Estudiante.findOne({ emailEstudiante });
  if (verificarEmailBDD) return res.status(400).json({ msg: "Lo sentimos, el email ya se encuentra registrado" });

  const nuevoestudiante = new Estudiante(req.body);
  nuevoestudiante.password = await nuevoestudiante.encrypPassword(password);

  const token = nuevoestudiante.crearToken();

  // Enviar correo apuntando al FRONTEND
  await sendMailToRegister(emailEstudiante, token);

  await nuevoestudiante.save();
  res.status(200).json({ msg: "Revisa tu correo electrónico para confirmar tu cuenta" });
};

// Confirmar correo con redirección al frontend
const confirmarMailEstudiante = async (req, res) => {
  try {
    const { token } = req.params;
    if (!token) return res.redirect(`${process.env.URL_FRONTEND}confirm/${token}?error=1`);

    const estudianteBDD = await Estudiante.findOne({ token });

    if (!estudianteBDD?.token) {
      // Ya confirmado o token inválido
      return res.redirect(`${process.env.URL_FRONTEND}confirm/${token}?error=1`);
    }

    estudianteBDD.token = null;
    estudianteBDD.confirmEmail = true;
    await estudianteBDD.save();

    return res.redirect(`${process.env.URL_FRONTEND}confirm/${token}?success=1`);
  } catch (error) {
    console.log(error);
    return res.redirect(`${process.env.URL_FRONTEND}confirm/${req.params.token}?error=1`);
  }
};

// Recuperar contraseña
const recuperarPasswordEstudiante = async (req, res) => {
  const { email } = req.body;
  if (Object.values(req.body).includes("")) return res.status(404).json({ msg: "Todos los campos deben ser llenados obligatoriamente." });

  const estudianteBDD = await Estudiante.findOne({ email });
  if (!estudianteBDD) return res.status(404).json({ msg: "Lo sentimos, el usuario no existe" });

  const token = estudianteBDD.crearToken();
  estudianteBDD.token = token;

  await sendMailToRecoveryPassword(email, token);
  await estudianteBDD.save();

  res.status(200).json({ msg: "Revisa tu correo electrónico para restablecer tu contraseña." });
};

// Comprobar token de recuperación
const comprobarTokenPasswordEstudiante = async (req, res) => {
  const { token } = req.params;
  const estudianteBDD = await Estudiante.findOne({ token });

  if (!estudianteBDD) return res.status(404).json({ msg: "Lo sentimos, no se puede validar la cuenta" });

  res.status(200).json({ msg: "Token confirmado ya puedes crear tu password" });
};

// Crear nueva contraseña
const crearNuevoPasswordEstudiante = async (req, res) => {
  const { password, confirmpassword } = req.body;

  if (Object.values(req.body).includes("")) return res.status(404).json({ msg: "Lo sentimos debes llenar todos los campos" });
  if (password !== confirmpassword) return res.status(404).json({ msg: "Lo sentimos, los passwords no coinciden" });

  const estudianteBDD = await Estudiante.findOne({ token: req.params.token });
  if (!estudianteBDD) return res.status(404).json({ msg: "Lo sentimos no se puede validar su cuenta" });

  estudianteBDD.token = null;
  estudianteBDD.password = await estudianteBDD.encrypPassword(password);
  await estudianteBDD.save();

  res.status(200).json({ msg: "Ya puede iniciar sesion con su nueva contraseña." });
};

// Login
const loginEstudiante = async (req, res) => {
  const { emailEstudiante, password } = req.body;

  if (Object.values(req.body).includes("")) {
    return res.status(400).json({ msg: "Todos los campos son obligatorios." });
  }

  const estudianteBDD = await Estudiante.findOne({ emailEstudiante }).select("-status -__v -token -createdAt -updateAt");

  if (!estudianteBDD) {
    return res.status(404).json({ msg: "Lo sentimos, el usuario no existe." });
  }

  if (estudianteBDD.confirmEmail === false) {
    return res.status(401).json({ msg: "Debe confirmar su cuenta antes de iniciar sesión." });
  }

  const verificarPassword = await estudianteBDD.matchPassword(password);
  if (!verificarPassword) {
    return res.status(401).json({ msg: "Lo sentimos, la contraseña es incorrecta." });
  }

  const { nombreEstudiante, telefono, _id, rol, fotoPerfil } = estudianteBDD;
  const token = crearTokenJWT(_id, rol);

  res.status(200).json({
    token,
    rol,
    nombreEstudiante,  // ✅ Cambiado de "nombre" a "nombreEstudiante"
    telefono,
    _id,
    emailEstudiante: estudianteBDD.emailEstudiante,
    fotoPerfil
  });
};

// Ver perfil
const perfilEstudiante = (req, res) => {
  const { token, confirmEmail, createdAt, updatedAt, __v, ...datosPerfil } = req.estudianteBDD;
  res.status(200).json(datosPerfil);
};

// Actualizar foto de perfil
const actualizarPerfilEstudiante = async (req, res) => {
  const { id } = req.params;

  if (!mongoose.Types.ObjectId.isValid(id)) {
    return res.status(404).json({ msg: "Lo sentimos, debe ser un id válido" });
  }

  const estudianteBDD = await Estudiante.findById(id);
  if (!estudianteBDD) {
    return res.status(404).json({ msg: `No existe el estudiante ${id}` });
  }

  if (req.files?.imagen) {
    if (estudianteBDD.fotoPerfilID) {
      await cloudinary.uploader.destroy(estudianteBDD.fotoPerfilID);
    }

    const { secure_url, public_id } = await cloudinary.uploader.upload(
      req.files.imagen.tempFilePath,
      { folder: "Estudiantes" }
    );

    estudianteBDD.fotoPerfil = secure_url;
    estudianteBDD.fotoPerfilID = public_id;

    await fs.unlink(req.files.imagen.tempFilePath);
  } else {
    return res.status(400).json({ msg: "No se envió ninguna imagen" });
  }

  await estudianteBDD.save();

  res.status(200).json({
    msg: "Foto actualizada con éxito",
    estudiante: estudianteBDD
  });
};

// Actualizar contraseña
const actualizarPasswordEstudiante = async (req, res) => {
  const estudianteBDD = await Estudiante.findById(req.estudianteBDD._id);
  if (!estudianteBDD) return res.status(404).json({ msg: "Lo sentimos, no existe el estudiante" });

  const verificarPassword = await estudianteBDD.matchPassword(req.body.passwordactual);
  if (!verificarPassword) return res.status(404).json({ msg: "Lo sentimos, el password actual no es el correcto" });

  estudianteBDD.password = await estudianteBDD.encrypPassword(req.body.passwordnuevo);
  await estudianteBDD.save();

  res.status(200).json({ msg: "Password actualizado correctamente" });
};

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
