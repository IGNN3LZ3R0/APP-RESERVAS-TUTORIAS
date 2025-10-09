import jwt from "jsonwebtoken"
import administrador from "../models/administrador.js"
import docente from "../models/docente.js"
import estudiante from "../models/estudiante.js"

const verificarRol = (rolesPermitidos = []) => {
  return (req, res, next) => {
    //El token ya fue verificado y el rol está en req (verificarTokenJWT debe ir antes)
    const rolUsuario = req.administradorBDD ? "Administrador"
                   : req.docenteBDD ? "Docente"
                   : req.estudianteBDD ? "Estudiante"
                   : null;

    if (!rolUsuario) {
      return res.status(403).json({ msg: "Usuario no autorizado" });
    }

    if (!rolesPermitidos.includes(rolUsuario)) {
      return res.status(403).json({ msg: `Acceso denegado` });
    }
    next();
  };
};

export default verificarRol;
