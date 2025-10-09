import jwt from "jsonwebtoken"
import administrador from "../models/administrador.js"
import docente from "../models/docente.js"
import estudiante from "../models/estudiante.js"

const crearTokenJWT = (id, rol) => {
    return jwt.sign({ id, rol }, process.env.JWT_SECRET, { expiresIn: "1d" })
}

const verificarTokenJWT = async (req, res, next) => {

	const { authorization } = req.headers
    if (!authorization) return res.status(401).json({ msg: "Acceso denegado: token no proporcionado o inválido" })

    try {
        const token = authorization.split(" ")[1];
        const { id, rol } = jwt.verify(token,process.env.JWT_SECRET)
        //console.log("ID y rol extraídos del token:", id, rol);
        if (rol === "Administrador") {
            req.administradorBDD = await administrador.findById(id).lean().select("-password")
        }
        else if (rol === "Docente") {
            req.docenteBDD = await docente.findById(id).lean().select("-passwordDocente");
            //console.log("Docente encontrado:", req.docenteBDD)
        } else if (rol === "Estudiante") {
            req.estudianteBDD = await estudiante.findById(id).lean().select("-password");
        } else {
            return res.status(403).json({ msg: "Usuario no encontrado o no autorizado." });
        }
        next()
        
    } catch (error) {
        return res.status(401).json({ msg: "Token inválido o expirado" });
    }
}

export { 
    crearTokenJWT,
    verificarTokenJWT 
}