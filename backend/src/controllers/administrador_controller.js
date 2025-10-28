import Administrador from "../models/administrador.js";
import { sendMailToRecoveryPassword, sendMailWithCredentials } from "../config/nodemailer.js";
import { v2 as cloudinary } from 'cloudinary';
import fs from "fs-extra";
import { crearTokenJWT } from "../middlewares/JWT.js";
import mongoose from "mongoose";

// Etapa 1: Registrar Administrador por defecto
const registrarAdministrador = async () => {
  try {
    const emailAdmin = "garviel.loken@epn.edu.ec"; // 🔹 Correo del administrador principal

    // Buscar si ya existe ese correo
    const admin = await Administrador.findOne({ email: emailAdmin });

    if (!admin) {
      const passwordGenerada = "Admin12345678$";
      const nuevoAdmin = new Administrador({
        nombreAdministrador: "Garviel",
        email: emailAdmin,
        password: await new Administrador().encrypPassword(passwordGenerada),
        confirmEmail: true,
      });
      await nuevoAdmin.save();
      console.log("Administrador registrado con éxito.");

      // Enviar correo con las credenciales
      await sendMailWithCredentials(
        nuevoAdmin.email,
        nuevoAdmin.nombreAdministrador,
        passwordGenerada
      );
    } else {
      console.log("El administrador ya se encuentra registrado en la base de datos.");
    }
  } catch (error) {
    if (error.code === 11000) {
      console.log("El administrador ya existe, no se volverá a crear.");
    } else {
      console.error("Error al registrar administrador:", error);
    }
  }
};

const recuperarPasswordAdministrador = async (req, res) => {
  const { email } = req.body;

  if (Object.values(req.body).includes(""))
    return res.status(404).json({ msg: "Todos los campos deben ser llenados obligatoriamente." });

  const administradorBDD = await Administrador.findOne({ email });
  if (!administradorBDD)
    return res.status(404).json({ msg: "Lo sentimos, el usuario no existe" });

  const token = administradorBDD.crearToken();
  administradorBDD.token = token;

  await sendMailToRecoveryPassword(email, token);
  await administradorBDD.save();

  res.status(200).json({ msg: "Revisa tu correo electrónico para restablecer tu contraseña." });
};

// Etapa 2
const comprobarTokenPasswordAdministrador = async (req, res) => {
  const { token } = req.params;
  const administradorBDD = await Administrador.findOne({ token });

  if (!administradorBDD || administradorBDD.token !== token)
    return res.status(404).json({ msg: "Lo sentimos, no se puede validar la cuenta" });

  await administradorBDD.save();
  res.status(200).json({ msg: "Token confirmado, ya puedes crear tu password" });
};

// Etapa 3
const crearNuevoPasswordAdministrador = async (req, res) => {
  const { password, confirmpassword } = req.body;

  if (Object.values(req.body).includes(""))
    return res.status(404).json({ msg: "Lo sentimos, debes llenar todos los campos" });

  if (password !== confirmpassword)
    return res.status(404).json({ msg: "Lo sentimos, los passwords no coinciden" });

  const administradorBDD = await Administrador.findOne({ token: req.params.token });

  if (!administradorBDD || administradorBDD.token !== req.params.token)
    return res.status(404).json({ msg: "Lo sentimos, no se puede validar su cuenta" });

  administradorBDD.token = null;
  administradorBDD.password = await administradorBDD.encrypPassword(password);
  await administradorBDD.save();

  res.status(200).json({ msg: "Ya puede iniciar sesión con su nueva contraseña." });
};

// Login
const loginAdministrador = async (req, res) => {
  const { email, password } = req.body;

  if (Object.values(req.body).includes(""))
    return res.status(400).json({ msg: "Todos los campos son obligatorios." });

  const administradorBDD = await Administrador.findOne({ email }).select(
    "-status -__v -token -createdAt -updateAt"
  );

  if (!administradorBDD)
    return res.status(404).json({ msg: "Lo sentimos, el usuario no existe." });

  const verificarPassword = await administradorBDD.matchPassword(password);
  if (!verificarPassword)
    return res.status(401).json({ msg: "Lo sentimos, la contraseña es incorrecta." });

  const { nombreAdministrador, _id, rol, fotoPerfilAdmin } = administradorBDD;
  const token = crearTokenJWT(administradorBDD._id, administradorBDD.rol);
  
  // ✅ RESPUESTA CORRECTA
  res.status(200).json({
    token,
    rol,
    nombreAdministrador,
    _id,
    email: administradorBDD.email,
    fotoPerfilAdmin,
  });
};

// Perfil
const perfilAdministrador = (req, res) => {
  const { token, confirmEmail, createdAt, updatedAt, __v, ...datosPerfil } = req.administradorBDD;
  res.status(200).json(datosPerfil);
};

// Actualizar perfil
const actualizarPerfilAdministrador = async (req, res) => {
  const { id } = req.params;
  const { nombreAdministrador, email } = req.body;

  if (!mongoose.Types.ObjectId.isValid(id)) {
    return res.status(404).json({ msg: `Lo sentimos, debe ser un id válido` });
  }

  const administradorBDD = await Administrador.findById(id);
  if (!administradorBDD) {
    return res.status(404).json({ msg: `Lo sentimos, no existe el Administrador ${id}` });
  }

  if (email && administradorBDD.email !== email) {
    const administradorBDDMail = await Administrador.findOne({ email });
    if (administradorBDDMail) {
      return res.status(400).json({ msg: `El email ya está registrado por otro administrador` });
    }
    administradorBDD.email = email;
  }

  if (nombreAdministrador) {
    administradorBDD.nombreAdministrador = nombreAdministrador;
  }

  if (req.files?.imagen) {
    if (administradorBDD.fotoPerfilID) {
      await cloudinary.uploader.destroy(administradorBDD.fotoPerfilID);
    }

    const { secure_url, public_id } = await cloudinary.uploader.upload(
      req.files.imagen.tempFilePath,
      { folder: "Administradores" }
    );

    administradorBDD.fotoPerfilAdmin = secure_url;
    administradorBDD.fotoPerfilAdminID = public_id;

    await fs.unlink(req.files.imagen.tempFilePath);
  }

  await administradorBDD.save();

  res.status(200).json({
    msg: "Perfil actualizado con éxito",
    administrador: administradorBDD,
  });
};

// Actualizar contraseña
const actualizarPasswordAdministrador = async (req, res) => {
  const administradorBDD = await Administrador.findById(req.administradorBDD._id);
  if (!administradorBDD)
    return res.status(404).json({ msg: `Lo sentimos, no existe el Administrador` });

  const verificarPassword = await administradorBDD.matchPassword(req.body.passwordactual);
  if (!verificarPassword)
    return res.status(404).json({ msg: "Lo sentimos, el password actual no es el correcto" });

  administradorBDD.password = await administradorBDD.encrypPassword(req.body.passwordnuevo);
  await administradorBDD.save();

  res.status(200).json({ msg: "Password actualizado correctamente" });
};

export {
  registrarAdministrador,
  recuperarPasswordAdministrador,
  comprobarTokenPasswordAdministrador,
  crearNuevoPasswordAdministrador,
  loginAdministrador,
  perfilAdministrador,
  actualizarPerfilAdministrador,
  actualizarPasswordAdministrador,
};