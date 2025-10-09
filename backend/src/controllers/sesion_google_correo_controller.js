import Estudiante from "../models/estudiante.js";
import Docente from "../models/docente.js";
import Administrador from "../models/administrador.js";
import { crearTokenJWT } from "../middlewares/JWT.js";

// Función para el inicio de sesión de un estudiante mediante OAuth
const loginOAuthEstudiante = async (req, res) => {
  const { email, nombre, provider } = req.body;
  try {
    // Validación para permitir solo cuentas institucionales de EPN
    if (provider === "microsoft" && !email.endsWith("@epn.edu.ec")) {
      return res.status(403).json({ msg: "Solo cuentas institucionales EPN" });
    }
    // Buscar estudiante por email
    let estudiante = await Estudiante.findOne({ emailEstudiante: email });
    if (!estudiante) {
      // Registro automático de estudiante si no existe (sin contraseña porque es OAuth)
      estudiante = new Estudiante({
        nombreEstudiante: nombre,
        emailEstudiante: email,
        password: "", // vacío porque es OAuth
        isOAuth: true,
        oauthProvider: provider,
        confirmEmail: true // Validación de que el correo es confiable
      });
      await estudiante.save();
    }
    // Creación de token con el middleware
    const token = crearTokenJWT(estudiante._id, estudiante.rol);
    res.json({ token, usuario: estudiante });
  } catch (error) {
    res.status(500).json({ msg: "Error en autenticación OAuth", error });
  }
};

// Función para el inicio de sesión de un docente mediante OAuth
const loginOAuthDocente = async (req, res) => {
  const { email, nombre, provider } = req.body;
  try {
    // Validación para permitir solo cuentas institucionales de EPN
    if (provider === 'microsoft' && !email.endsWith('@epn.edu.ec')) {
      return res.status(403).json({ msg: 'Solo se permiten cuentas institucionales EPN' });
    }
    // Buscar docente por email
    let docente = await Docente.findOne({ emailDocente: email });
    if (!docente) {
      // Registro automático de docente si no existe (solo con campos mínimos gracias a isOAuth)
      docente = new Docente({
        nombreDocente: nombre,
        emailDocente: email,
        emailAlternativoDocente: email, // Opcional: mismo email como alternativo
        isOAuth: true,
        oauthProvider: provider,
        confirmEmail: true // Validación de que el correo es confiable
      });
      await docente.save();
    }
    // Generar token JWT
    const token = crearTokenJWT(docente._id, docente.rol);
    return res.json({
      msg: 'Inicio de sesión exitoso',
      token,
      usuario: docente
    });
  } catch (error) {
    console.error('Error en login OAuth:', error);
    return res.status(500).json({
      msg: 'Error al iniciar sesión con OAuth',
      error: error.message
    });
  }
};


// Función para el inicio de sesión de un administrador mediante OAuth
const loginOAuthAdministrador = async (req, res) => {
  const { email, nombre, provider } = req.body;
  try {
    // Validación para permitir solo cuentas institucionales de EPN
    if (provider === "microsoft" && !email.endsWith("@epn.edu.ec")) {
      return res.status(403).json({ msg: "Solo cuentas institucionales EPN permitidas" });
    }
    // Buscar administrador por email
    let administrador = await Administrador.findOne({ email });
    if (!administrador) {
      // Registro automático de administrador si no existe (sin contraseña porque es OAuth)
      administrador = new Administrador({
        nombreAdministrador: nombre,
        email,
        password: "", // vacío por si es OAuth
        isOAuth: true,
        oauthProvider: provider,
        confirmEmail: true // Validación de que el correo es confiable
      });
      await administrador.save();
    }
    // Generar token JWT
    const token = crearTokenJWT(administrador._id, administrador.rol);
    res.json({ token, usuario: administrador });
  } catch (error) {
    console.error("Error en login OAuth Administrador:", error);
    res.status(500).json({ msg: "Error al iniciar sesión con OAuth", error: error.message });
  }
};

export { loginOAuthEstudiante, loginOAuthDocente, loginOAuthAdministrador };