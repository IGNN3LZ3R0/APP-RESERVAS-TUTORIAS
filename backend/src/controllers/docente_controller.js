import Docente from "../models/docente.js";
import { sendMailToOwner } from "../config/nodemailer.js";
import { v2 as cloudinary } from 'cloudinary';
import fs from "fs-extra";
import mongoose from "mongoose";
import { crearTokenJWT } from "../middlewares/JWT.js";

const registrarDocente = async (req, res) => {
  try {
    const { emailDocente } = req.body;
    if (Object.values(req.body).includes(""))
      return res.status(400).json({ msg: "Lo sentimos, debes llenar todos los campos" });

    const verificarEmailBDD = await Docente.findOne({ emailDocente });
    if (verificarEmailBDD)
      return res.status(400).json({ msg: "Lo sentimos, el email ya se encuentra registrado" });

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
    });

    if (req.files?.imagen) {
      const { secure_url, public_id } = await cloudinary.uploader.upload(req.files.imagen.tempFilePath, { folder: "Docentes" });
      nuevoDocente.avatarDocente = secure_url;
      nuevoDocente.avatarDocenteID = public_id;
      await fs.unlink(req.files.imagen.tempFilePath);
    }

    await nuevoDocente.save();

    await sendMailToOwner(emailDocente, "ESFOT" + password);

    res.status(201).json({ msg: "Registro exitoso! El correo ha sido enviado con éxito al docente creado." });
  } catch (error) {
    console.error("Error en registrarDocente:", error);
    res.status(500).json({ msg: "Error interno del servidor", error: error.message });
  }
};

const listarDocentes = async (req, res) => {
  try {
    let docentes = [];
    if (req.administradorBDD) {
      docentes = await Docente.find({ estadoDocente: true, administrador: req.administradorBDD._id })
        .select("-salida -createdAt -updatedAt -__v");
    } else if (req.estudianteBDD) {
      docentes = await Docente.find({ estadoDocente: true })
        .select("-salida -createdAt -updatedAt -__v");
    } else {
      return res.status(403).json({ msg: "No autorizado para ver docentes" });
    }

    // Aseguramos que asignaturas sea siempre un array
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
    return res.status(500).json({ msg: "Error al listar docentes", error });
  }
};

const detalleDocente = async (req, res) => {
  const { id } = req.params;
  if (!mongoose.Types.ObjectId.isValid(id)) return res.status(404).json({ msg: `Lo sentimos, no existe el registro del docente ${id}` });
  
  const docente = await Docente.findById(id).select("-createdAt -updatedAt -__v").populate('administrador', '_id nombre apellido');

  // Validar asignaturas para detalle también
  if (docente && typeof docente.asignaturas === "string") {
    try {
      docente.asignaturas = JSON.parse(docente.asignaturas);
    } catch {
      docente.asignaturas = [];
    }
  }

  res.status(200).json(docente);
};

const eliminarDocente = async (req, res) => {
  const { id } = req.params;
  if (!req.body.salidaDocente) {
    return res.status(400).json({ msg: "Lo sentimos, debes llenar todos los campos" });
  }
  if (!mongoose.Types.ObjectId.isValid(id)) {
    return res.status(404).json({ msg: `Lo sentimos, no existe el docente ${id}` });
  }
  
  const { salidaDocente } = req.body;
  await Docente.findByIdAndUpdate(id, {
    salidaDocente: new Date(salidaDocente),
    estadoDocente: false
  });
  res.status(200).json({ msg: "El registro fue deshabilitado con éxito." });
};

const actualizarDocente = async (req, res) => {
  const { id } = req.params;
  if (Object.values(req.body).includes("")) return res.status(400).json({ msg: "Lo sentimos, debes llenar todos los campos" });
  if (!mongoose.Types.ObjectId.isValid(id)) return res.status(404).json({ msg: `Lo sentimos, no existe el docente ${id}` });

  let asignaturas = req.body.asignaturas;
  if (typeof asignaturas === "string") {
    try {
      asignaturas = JSON.parse(asignaturas);
    } catch {
      return res.status(400).json({ msg: "Formato inválido en asignaturas" });
    }
  }
  req.body.asignaturas = asignaturas;

  if (req.files?.imagen) {
    const docente = await Docente.findById(id);
    if (docente.avatarDocenteID) {
      await cloudinary.uploader.destroy(docente.avatarDocenteID);
    }
    const cloudiResponse = await cloudinary.uploader.upload(req.files.imagen.tempFilePath, { folder: 'Docentes' });
    req.body.avatarDocente = cloudiResponse.secure_url;
    req.body.avatarDocenteID = cloudiResponse.public_id;
    await fs.unlink(req.files.imagen.tempFilePath);
  }
  
  const docenteActualizado = await Docente.findByIdAndUpdate(id, req.body, { new: true }).select("-passwordDocente -confirmEmail -createdAt -updatedAt -__v");
  res.status(200).json({docente: docenteActualizado})
};

const loginDocente = async (req, res) => {
  const { email: emailDocente, password: passwordDocente } = req.body;
  if (Object.values(req.body).includes("")) return res.status(400).json({ msg: "Lo sentimos, debes llenar todos los campos" });
  const docenteBDD = await Docente.findOne({ emailDocente });
  if (!docenteBDD) return res.status(404).json({ msg: "Lo sentimos, el usuario no se encuentra registrado" });
  const verificarPassword = await docenteBDD.matchPassword(passwordDocente);
  if (!verificarPassword) return res.status(401).json({ msg: "Lo sentimos, el password no es el correcto" });
  const token = crearTokenJWT(docenteBDD._id, docenteBDD.rol);
  const { _id, rol, avatarDocente } = docenteBDD;
  res.status(200).json({ token, rol, _id, avatarDocente });
};

const perfilDocente = (req, res) => {
  const docente = req.docenteBDD;
  if (!docente) {
    return res.status(404).json({ msg: "Docente no encontrado." });
  }
  
  const camposAEliminar = [
    "fechaIngresoDocente", "salidaDocente",
    "estadoDocente", "passwordDocente", 
    "confirmEmail", "createdAt", "updatedAt", "__v"
  ];
  camposAEliminar.forEach(campo => delete req.docenteBDD[campo]);
  res.status(200).json(req.docenteBDD);
};

export {
  registrarDocente,
  listarDocentes,
  detalleDocente,
  eliminarDocente,
  actualizarDocente,
  loginDocente,
  perfilDocente
};

