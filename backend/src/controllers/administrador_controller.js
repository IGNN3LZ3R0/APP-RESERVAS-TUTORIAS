import Administrador from "../models/administrador.js"
import {sendMailToRecoveryPassword, sendMailWithCredentials} from "../config/nodemailer.js"
import { v2 as cloudinary } from 'cloudinary'
import fs from "fs-extra"
import { crearTokenJWT } from "../middlewares/JWT.js"
import mongoose from "mongoose" 

//Etapa 1
const registrarAdministrador = async () => {
    const admin = await Administrador.findOne({ email: "danna.lopez@epn.edu.ec" });

    if (!admin) {
        const passwordGenerada = "Admin12345678$";
        const nuevoAdmin = new Administrador({
            nombreAdministrador: "Garviel",
            email: "garviel.loken@epn.edu.ec",
            password: await new Administrador().encrypPassword(passwordGenerada),
            confirmEmail: true,
        });
        await nuevoAdmin.save();
        console.log("Administrador registrado con éxito.");
        //Enviar correo al administrador con las credenciales generadas por el equipo de desarrollo
        await sendMailWithCredentials(nuevoAdmin.email, nuevoAdmin.nombreAdministrador, passwordGenerada);
    } else {
        console.log("El administrador ya se encuentra registrado en la base de datos.");
    }
};

const recuperarPasswordAdministrador = async(req, res) => {
    //Primera validacion: Obtener el email 
    const {email} = req.body
    //2: Verificar que el correo electronico no este en blanco
    if (Object.values(req.body).includes("")) return res.status(404).json({msg: "Todos los campos deben ser llenados obligatoriamente."})

    //Verificar que exista el correo electronico en la base de datos
    const administradorBDD = await Administrador.findOne({email})

    if (!administradorBDD) return res.status(404).json({msg: "Lo sentimos, el usuario no existe"})
    //3
    const token = administradorBDD.crearToken()
    administradorBDD.token = token

    //Enviar email
    await sendMailToRecoveryPassword(email,token)
    await administradorBDD.save()
    //4
    res.status(200).json({msg: "Revisa tu correo electrónico para restablecer tu contraseña."})
}

//Etapa 2
const comprobarTokenPasswordAdministrador = async (req, res) => {
    //1
    const {token} = req.params
    //2
    const administradorBDD = await Administrador.findOne({token})
    if (administradorBDD.token !== token) return res.status (404).json({msg:"Lo sentimos, no se puede validar la cuenta"})
    //3
    await administradorBDD.save()
    //4
    res.status(200).json({msg:"Token confirmado ya puedes crear tu password"})
}

//Etapa 3
const crearNuevoPasswordAdministrador = async (req, res) => {
    //1
    const {password,confirmpassword} = req.body
    //2
    if (Object.values(req.body).includes("")) return res.status(404).json({msg: "Lo sentimos debes llenar todos los campos"})
    
    if (password!== confirmpassword) return res.status(404).json({msg: "Lo sentimos, los passwords no coinciden"})
    
    const administradorBDD = await Administrador.findOne({token:req.params.token})

    console.log(administradorBDD);
    

    if (administradorBDD.token !== req.params.token) return res.status(404).json({msg: "Lo sentimos no se puede validar su cuenta"})

    //3
    administradorBDD.token = null
    administradorBDD.password = await administradorBDD.encrypPassword(password)
    await administradorBDD.save()

    //4
    res.status(200).json({msg:"Ya puede iniciar sesion con su nueva contraseña."})
}

const loginAdministrador = async (req, res) => {
    //1
    const {email, password} = req.body
    //2
    if(Object.values(req.body).includes("")) return res.status(400).json({msg: "Todos los campos son obligatorios."})
    
    const administradorBDD = await Administrador.findOne({email}).select("-status -__v -token -createdAt -updateAt")   //Quitar de la base de datos los siguientes campos
    
    //Verificar que el email del usuario exista en la base de datos.
    if(!administradorBDD) return res.status(404).json({msg: "Lo sentimos, el usuario no existe."})
    
    //Comparar que la contraseña proporcionada por el usuario sea la misma que está guardada en la BDD
    const verificarPassword = await administradorBDD.matchPassword(password)

    if (!verificarPassword) return res.status(401).json({msg: "Lo sentimos, la contraseña es incorrecta."})
    //3
    const{nombreAdministrador, _id, rol, fotoPerfilAdmin} = administradorBDD
    const token = crearTokenJWT(administradorBDD._id,administradorBDD.rol)

    //4: Enviar los siguientes campos al frontend
    res.status(200).json({
        token,
        rol,
        nombreAdministrador,
        _id,
        email: administradorBDD.email,
        fotoPerfilAdmin
    })
}

const perfilAdministrador =(req,res)=>{
		const {token,confirmEmail,createdAt,updatedAt,__v,...datosPerfil} = req.administradorBDD
    res.status(200).json(datosPerfil);
}

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

  // Validar y actualizar el email si es nuevo
  if (email && administradorBDD.email !== email) {
    const administradorBDDMail = await Administrador.findOne({ email });
    if (administradorBDDMail) {
      return res.status(400).json({ msg: `El email ya está registrado por otro administrador` });
    }
    administradorBDD.email = email;
  }

  // Actualizar nombre si se envía
  if (nombreAdministrador) {
    administradorBDD.nombreAdministrador = nombreAdministrador;
  }

  // Subir imagen si se envía
  if (req.files?.imagen) {
    // Si ya tiene una imagen previa, eliminarla de Cloudinary
    if (administradorBDD.fotoPerfilID) {
      await cloudinary.uploader.destroy(administradorBDD.fotoPerfilID);
    }

    const { secure_url, public_id } = await cloudinary.uploader.upload(
      req.files.imagen.tempFilePath,
      { folder: "Administradores" }
    );

    administradorBDD.fotoPerfilAdmin = secure_url;
    administradorBDD.fotoPerfilAdminID = public_id;

    // Eliminar archivo temporal
    await fs.unlink(req.files.imagen.tempFilePath);
  }

  await administradorBDD.save();

  res.status(200).json({
    msg: "Perfil actualizado con éxito",
    administrador: administradorBDD
  });
};


const actualizarPasswordAdministrador = async (req,res)=>{
    const administradorBDD = await Administrador.findById(req.administradorBDD._id)
    if(!administradorBDD) return res.status(404).json({msg:`Lo sentimos, no existe el Administrador ${id}`})
    const verificarPassword = await administradorBDD.matchPassword(req.body.passwordactual)
    if(!verificarPassword) return res.status(404).json({msg:"Lo sentimos, el password actual no es el correcto"})
    administradorBDD.password = await administradorBDD.encrypPassword(req.body.passwordnuevo)
    await administradorBDD.save()
    res.status(200).json({msg:"Password actualizado correctamente"})
}

export {
    registrarAdministrador, recuperarPasswordAdministrador,
    comprobarTokenPasswordAdministrador,
    crearNuevoPasswordAdministrador,
    loginAdministrador,
    perfilAdministrador,
    actualizarPerfilAdministrador,
    actualizarPasswordAdministrador
}
