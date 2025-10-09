// src/config/nodemailer.js
import nodemailer from "nodemailer";
import dotenv from "dotenv";
dotenv.config();

let transporter = nodemailer.createTransport({
  service: "gmail",
  host: process.env.HOST_MAILTRAP,
  port: process.env.PORT_MAILTRAP,
  auth: {
    user: process.env.USER_MAILTRAP,
    pass: process.env.PASS_MAILTRAP,
  },
});

const sendMailToRegister = (userMail, token) => {
  const urlConfirmacion = `${process.env.URL_FRONTEND}confirmar/${token}`;

  let mailOptions = {
    from: "tutorias.esfot@gmail.com",
    to: userMail,
    subject: "Confirmación de cuenta para acceder a la plataforma de tutorías",
    html: `
      <div style="font-family: Verdana, sans-serif; max-width: 600px; margin: auto; border: 1px solid #e0e0e0; padding: 20px; text-align: center;">
        <h2 style="color: #81180aff; font-weight: bold;">¡Bienvenido/a!</h2>
        <p style="font-size: 16px; color: #333;">
          Para tener acceso a la plataforma y agendar una cita con el docente de tu preferencia, haz clic en el siguiente botón para activar tu cuenta.
        </p>
        <a href="${urlConfirmacion}" 
           style="display: inline-block; padding: 12px 24px; margin: 20px 0; font-family: Verdana; font-size: 16px; font-weight: bold; color: #ffffff; background-color: #791515ff; text-decoration: none; border-radius: 10px;">
          Activar Cuenta
        </a>
        <p style="font-size: 14px; color: #777;">
          Si el botón no funciona, copia y pega el siguiente enlace en tu navegador:
        </p>
        <p style="font-size: 12px; color: #1b1a1aff; word-break: break-all;">
          ${urlConfirmacion}
        </p>
        <hr style="border: 0; border-top: 1px solid #424040ff; margin: 20px 0;">
        <footer style="font-size: 12px; color: #999;">
          <p>&copy; 2025 ESFOT Tutorías. Todos los derechos reservados.</p>
        </footer>
      </div>
    `,
  };

  transporter.sendMail(mailOptions, (error) => {
    if (error) {
      console.error("Error enviando correo de confirmación:", error);
    } else {
      console.log("Correo de confirmación enviado correctamente");
    }
  });
};

const sendMailToRecoveryPassword = async (userMail, token) => {
  await transporter.sendMail({
    from: "Tutorías ESFOT <tutorias.esfot@gmail.com>",
    to: userMail,
    subject: "Solicitud para restablecer tu contraseña",
    html: `
      <div style="font-family: 'Segoe UI', sans-serif; background-color: #f9f9f9; padding: 30px;">
        <div style="max-width: 600px; margin: auto; background: white; border-radius: 8px; padding: 30px; box-shadow: 0 2px 5px rgba(0,0,0,0.1);">
          <h2 style="color: #1c3d5a; text-align: center; margin-bottom: 20px;">
            Plataforma de Gestión de Tutorías - ESFOT
          </h2>
          <p style="font-size: 15px; color: #333;">
            Hola, hemos recibido una solicitud para <strong>restablecer la contraseña</strong> de tu cuenta en la plataforma de Tutorías ESFOT.
          </p>
          <p style="font-size: 15px; color: #333;">
            Si realizaste esta solicitud, haz clic en el siguiente enlace:
          </p>
          <p style="text-align: center; margin: 25px 0;">
            <a href="${process.env.URL_BACKEND}reset/${token}" 
               style="color: #234c83ff; text-decoration: underline; font-weight: bold;" 
               target="_blank">
              Restablecer Contraseña
            </a>
          </p>
          <p style="font-size: 14px; color: #666;">
            Si tú no realizaste esta solicitud, puedes ignorar este correo.
          </p>
          <hr style="margin: 30px 0; border: none; border-top: 1px solid #ddd;" />
          <p style="text-align: center; font-size: 12px; color: #999;">
            © 2025 Tutorías ESFOT. Todos los derechos reservados.
          </p>
        </div>
      </div>
    `,
  });

  console.log("Correo de restablecimiento enviado con éxito");
};

const sendMailToOwner = async (userMail, password) => {
  let info = await transporter.sendMail({
    from: "tutorias.esfot@gmail.com",
    to: userMail,
    subject: "Registro del docente en la plataforma",
    html: `
      <h1>Tutorias ESFOT</h1>
      <hr>
      <p>La plataforma le da la más cordial bienvenida. Sus credenciales otorgadas son:</p>
      <p>Correo electrónico: ${userMail}</p>
      <p>Contraseña de acceso: ${password}</p>
      <a href=${process.env.URL_FRONTEND}login>Iniciar sesión</a>
      <hr>
      <footer>2025 - TUTORIAS ESFOT - Todos los derechos reservados.</footer>
    `,
  });
  console.log("Mensaje enviado con éxito al docente: ", info.messageId);
};

const sendMailWithCredentials = async (email, nombreAdministrador, passwordGenerada) => {
  try {
    let mailOptions = {
      from: "Equipo de Desarrollo <no-reply@gmail.com>",
      to: email,
      subject: "Credenciales de acceso a la plataforma de tutorías",
      html: `
        <div style="font-family: Verdana, sans-serif; max-width: 600px; margin: auto; border: 1px solid #e0e0e0; padding: 20px; text-align: center;">
          <h2 style="color: #81180aff; font-weight: bold;">¡Bienvenido/a, ${nombreAdministrador}!</h2>
          <p>Tus credenciales para acceder a tu perfil de administrador en la plataforma son:</p>
          <p><strong>Correo electrónico:</strong> ${email}</p>
          <p><strong>Contraseña:</strong> ${passwordGenerada}</p>
          <p>Por favor, cambia tu contraseña en tu primer inicio de sesión.</p>
          <hr style="border: 0; border-top: 1px solid #424040ff; margin: 20px 0;">
          <footer style="font-size: 12px; color: #999;">
            <p>&copy; 2025 ESFOT Tutorías. Todos los derechos reservados.</p>
          </footer>
        </div>
      `,
    };

    await transporter.sendMail(mailOptions);
    console.log("Mensaje enviado con éxito.");
  } catch (error) {
    console.log("Error enviando correo con credenciales:", error);
  }
};

export {
  sendMailToRegister,
  sendMailToRecoveryPassword,
  sendMailToOwner,
  sendMailWithCredentials,
};

