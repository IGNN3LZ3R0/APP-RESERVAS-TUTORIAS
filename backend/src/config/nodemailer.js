import nodemailer from "nodemailer";
import dotenv from "dotenv";
dotenv.config();

// Configuración del transportador de correo
let transporter = nodemailer.createTransport({
  service: "gmail",
  host: process.env.HOST_MAILTRAP,
  port: process.env.PORT_MAILTRAP,
  auth: {
    user: process.env.USER_MAILTRAP,
    pass: process.env.PASS_MAILTRAP,
  },
});

// ========== EMAIL DE CONFIRMACIÓN DE CUENTA ==========
const sendMailToRegister = (userMail, token) => {
  // Deep link que abre la app directamente
  const deepLink = `myapp://confirm/${token}`;
  
  // Fallback: URL del backend que devuelve JSON si se abre en navegador
  const apiFallback = `${process.env.URL_BACKEND}confirmar/${token}`;

  let mailOptions = {
    from: "Tutorías ESFOT <tutorias.esfot@gmail.com>",
    to: userMail,
    subject: "✅ Confirma tu cuenta - Tutorías ESFOT",
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
      </head>
      <body style="margin: 0; padding: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f4f4;">
        <div style="max-width: 600px; margin: 20px auto; background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
          
          <!-- Header -->
          <div style="background: linear-gradient(135deg, #1565C0 0%, #0D47A1 100%); padding: 40px 20px; text-align: center;">
            <div style="background-color: white; width: 80px; height: 80px; margin: 0 auto 20px; border-radius: 50%; display: flex; align-items: center; justify-content: center; box-shadow: 0 4px 8px rgba(0,0,0,0.2);">
              <span style="font-size: 40px;">🎓</span>
            </div>
            <h1 style="color: #ffffff; margin: 0; font-size: 28px; font-weight: 600;">
              ¡Bienvenido/a!
            </h1>
            <p style="color: #E3F2FD; margin: 10px 0 0; font-size: 16px;">
              Tutorías ESFOT
            </p>
          </div>
          
          <!-- Body -->
          <div style="padding: 40px 30px;">
            <h2 style="color: #1565C0; font-size: 22px; margin: 0 0 20px; font-weight: 600;">
              Un paso más para empezar
            </h2>
            
            <p style="color: #333333; font-size: 16px; line-height: 1.6; margin: 0 0 20px;">
              Gracias por registrarte en nuestra plataforma de tutorías. Para comenzar a agendar sesiones con tus docentes, necesitas activar tu cuenta.
            </p>
            
            <p style="color: #333333; font-size: 16px; line-height: 1.6; margin: 0 0 30px;">
              Haz clic en el botón de abajo para <strong>activar tu cuenta inmediatamente</strong>:
            </p>
            
            <!-- Botón Principal -->
            <div style="text-align: center; margin: 30px 0;">
              <a href="${deepLink}" 
                 style="display: inline-block; background: linear-gradient(135deg, #1565C0 0%, #0D47A1 100%); color: #ffffff; text-decoration: none; padding: 16px 40px; border-radius: 8px; font-size: 18px; font-weight: 600; box-shadow: 0 4px 12px rgba(21,101,192,0.3); transition: transform 0.2s;">
                🚀 Activar Mi Cuenta
              </a>
            </div>
            
            <!-- Código alternativo -->
            <div style="background-color: #F5F5F5; border-left: 4px solid #1565C0; padding: 15px; margin: 25px 0; border-radius: 4px;">
              <p style="color: #666; font-size: 14px; margin: 0 0 10px;">
                <strong>¿El botón no funciona?</strong> Copia este código y pégalo en la app:
              </p>
              <div style="background-color: #ffffff; padding: 12px; border-radius: 6px; border: 1px dashed #1565C0; text-align: center;">
                <code style="color: #1565C0; font-size: 16px; font-weight: 600; letter-spacing: 1px; word-break: break-all;">
                  ${token}
                </code>
              </div>
            </div>
            
            <!-- Info adicional -->
            <div style="background-color: #E3F2FD; padding: 15px; border-radius: 8px; margin: 25px 0;">
              <p style="color: #0D47A1; font-size: 14px; margin: 0; line-height: 1.5;">
                💡 <strong>Consejo:</strong> Una vez activada tu cuenta, podrás ver la disponibilidad de docentes y agendar tutorías directamente desde tu celular.
              </p>
            </div>
            
            <p style="color: #999999; font-size: 13px; line-height: 1.5; margin: 25px 0 0;">
              Si no creaste esta cuenta, puedes ignorar este correo de forma segura.
            </p>
          </div>
          
          <!-- Footer -->
          <div style="background-color: #F5F5F5; padding: 20px 30px; border-top: 1px solid #E0E0E0;">
            <p style="color: #999999; font-size: 12px; margin: 0; text-align: center; line-height: 1.5;">
              Este enlace expirará cuando actives tu cuenta.<br>
              © 2025 <strong>ESFOT Tutorías</strong>. Todos los derechos reservados.
            </p>
          </div>
          
        </div>
      </body>
      </html>
    `,
  };

  transporter.sendMail(mailOptions, (error, info) => {
    if (error) {
      console.error("❌ Error enviando correo de confirmación:", error);
    } else {
      console.log("✅ Correo de confirmación enviado:", info.messageId);
    }
  });
};

// ========== EMAIL DE RECUPERACIÓN DE CONTRASEÑA ==========
const sendMailToRecoveryPassword = async (userMail, token) => {
  // Deep link que abre la app directamente con el token
  const deepLink = `myapp://reset-password/${token}`;
  
  // Fallback: URL del backend para validar token
  const apiFallback = `${process.env.URL_BACKEND}recuperarpassword/${token}`;

  try {
    await transporter.sendMail({
      from: "Tutorías ESFOT <tutorias.esfot@gmail.com>",
      to: userMail,
      subject: "🔐 Restablecer tu contraseña - Tutorías ESFOT",
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
        </head>
        <body style="margin: 0; padding: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f4f4;">
          <div style="max-width: 600px; margin: 20px auto; background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
            
            <!-- Header -->
            <div style="background: linear-gradient(135deg, #EF5350 0%, #D32F2F 100%); padding: 40px 20px; text-align: center;">
              <div style="background-color: white; width: 80px; height: 80px; margin: 0 auto 20px; border-radius: 50%; display: flex; align-items: center; justify-content: center; box-shadow: 0 4px 8px rgba(0,0,0,0.2);">
                <span style="font-size: 40px;">🔐</span>
              </div>
              <h1 style="color: #ffffff; margin: 0; font-size: 28px; font-weight: 600;">
                Restablecer Contraseña
              </h1>
              <p style="color: #FFEBEE; margin: 10px 0 0; font-size: 16px;">
                Tutorías ESFOT
              </p>
            </div>
            
            <!-- Body -->
            <div style="padding: 40px 30px;">
              <h2 style="color: #D32F2F; font-size: 22px; margin: 0 0 20px; font-weight: 600;">
                ¿Olvidaste tu contraseña?
              </h2>
              
              <p style="color: #333333; font-size: 16px; line-height: 1.6; margin: 0 0 20px;">
                No te preocupes, recibimos tu solicitud para restablecer tu contraseña. Puedes crear una nueva de forma segura.
              </p>
              
              <p style="color: #333333; font-size: 16px; line-height: 1.6; margin: 0 0 30px;">
                Haz clic en el botón de abajo para <strong>continuar con el proceso</strong>:
              </p>
              
              <!-- Botón Principal -->
              <div style="text-align: center; margin: 30px 0;">
                <a href="${deepLink}" 
                   style="display: inline-block; background: linear-gradient(135deg, #EF5350 0%, #D32F2F 100%); color: #ffffff; text-decoration: none; padding: 16px 40px; border-radius: 8px; font-size: 18px; font-weight: 600; box-shadow: 0 4px 12px rgba(239,83,80,0.3);">
                  🔑 Restablecer Contraseña
                </a>
              </div>
              
              <!-- Código alternativo -->
              <div style="background-color: #F5F5F5; border-left: 4px solid #D32F2F; padding: 15px; margin: 25px 0; border-radius: 4px;">
                <p style="color: #666; font-size: 14px; margin: 0 0 10px;">
                  <strong>¿El botón no funciona?</strong> Copia este código de verificación:
                </p>
                <div style="background-color: #ffffff; padding: 12px; border-radius: 6px; border: 1px dashed #D32F2F; text-align: center;">
                  <code style="color: #D32F2F; font-size: 16px; font-weight: 600; letter-spacing: 1px; word-break: break-all;">
                    ${token}
                  </code>
                </div>
                <p style="color: #666; font-size: 13px; margin: 10px 0 0;">
                  Abre la app, ve a "Olvidé mi contraseña" y pega este código.
                </p>
              </div>
              
              <!-- Advertencia de seguridad -->
              <div style="background-color: #FFF3E0; padding: 15px; border-radius: 8px; margin: 25px 0; border-left: 4px solid #FF9800;">
                <p style="color: #E65100; font-size: 14px; margin: 0; line-height: 1.5;">
                  ⚠️ <strong>Importante:</strong> Si no solicitaste este cambio, ignora este correo. Tu contraseña actual seguirá siendo válida.
                </p>
              </div>
              
              <div style="background-color: #E3F2FD; padding: 15px; border-radius: 8px; margin: 25px 0;">
                <p style="color: #1565C0; font-size: 14px; margin: 0; line-height: 1.5;">
                  🕐 <strong>Validez:</strong> Este enlace expirará en <strong>24 horas</strong> por seguridad. Después de ese tiempo, deberás solicitar uno nuevo.
                </p>
              </div>
            </div>
            
            <!-- Footer -->
            <div style="background-color: #F5F5F5; padding: 20px 30px; border-top: 1px solid #E0E0E0;">
              <p style="color: #999999; font-size: 12px; margin: 0; text-align: center; line-height: 1.5;">
                Si tienes problemas, contacta a soporte.<br>
                © 2025 <strong>ESFOT Tutorías</strong>. Todos los derechos reservados.
              </p>
            </div>
            
          </div>
        </body>
        </html>
      `,
    });

    console.log("✅ Correo de recuperación enviado correctamente a:", userMail);
  } catch (error) {
    console.error("❌ Error enviando correo de recuperación:", error);
  }
};

// ========== EMAIL PARA DOCENTES (Mantener igual) ==========
const sendMailToOwner = async (userMail, password) => {
  try {
    let info = await transporter.sendMail({
      from: "Tutorías ESFOT <tutorias.esfot@gmail.com>",
      to: userMail,
      subject: "✅ Bienvenido/a al equipo docente - Tutorías ESFOT",
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 20px; background-color: #f9f9f9;">
          <div style="background-color: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
            <h1 style="color: #1565C0; text-align: center;">¡Bienvenido/a!</h1>
            <hr style="border: none; border-top: 2px solid #1565C0;">
            <p style="font-size: 16px; color: #333;">
              El administrador te ha registrado en la plataforma de Tutorías ESFOT.
            </p>
            <p style="font-size: 16px; color: #333;">
              Tus credenciales de acceso son:
            </p>
            <div style="background-color: #E3F2FD; padding: 15px; border-radius: 6px; margin: 20px 0;">
              <p style="margin: 5px 0;"><strong>📧 Correo:</strong> ${userMail}</p>
              <p style="margin: 5px 0;"><strong>🔑 Contraseña:</strong> <code style="background-color: white; padding: 4px 8px; border-radius: 4px; color: #D32F2F;">${password}</code></p>
            </div>
            <p style="font-size: 14px; color: #666;">
              ⚠️ <strong>Importante:</strong> Por seguridad, cambia tu contraseña en tu primer inicio de sesión.
            </p>
            <hr style="margin: 30px 0; border: none; border-top: 1px solid #ddd;">
            <footer style="text-align: center; font-size: 12px; color: #999;">
              <p>2025 - TUTORÍAS ESFOT - Todos los derechos reservados.</p>
            </footer>
          </div>
        </div>
      `,
    });
    console.log("✅ Correo enviado al docente:", info.messageId);
  } catch (error) {
    console.error("❌ Error enviando correo al docente:", error);
  }
};

// ========== EMAIL PARA ADMINISTRADORES (Mantener igual) ==========
const sendMailWithCredentials = async (email, nombreAdministrador, passwordGenerada) => {
  try {
    let mailOptions = {
      from: "Sistema de Tutorías <no-reply@tutorias-esfot.com>",
      to: email,
      subject: "🔐 Credenciales de Administrador - Tutorías ESFOT",
      html: `
        <div style="font-family: Verdana, sans-serif; max-width: 600px; margin: auto; border: 1px solid #e0e0e0; padding: 20px; text-align: center; background-color: #fafafa;">
          <h2 style="color: #81180aff; font-weight: bold;">¡Bienvenido/a, ${nombreAdministrador}!</h2>
          <p style="font-size: 16px; color: #333;">
            Se ha creado tu cuenta de <strong>Administrador</strong> en la plataforma de Tutorías ESFOT.
          </p>
          <div style="background-color: white; padding: 20px; border-radius: 8px; margin: 20px 0; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
            <p style="margin: 10px 0;"><strong>📧 Correo electrónico:</strong><br>${email}</p>
            <p style="margin: 10px 0;"><strong>🔑 Contraseña:</strong><br>
              <code style="background-color: #f5f5f5; padding: 8px 12px; border-radius: 4px; font-size: 16px; color: #D32F2F;">${passwordGenerada}</code>
            </p>
          </div>
          <p style="font-size: 14px; color: #666;">
            ⚠️ Por favor, <strong>cambia tu contraseña</strong> inmediatamente después de tu primer inicio de sesión.
          </p>
          <hr style="border: 0; border-top: 1px solid #424040ff; margin: 20px 0;">
          <footer style="font-size: 12px; color: #999;">
            <p>&copy; 2025 ESFOT Tutorías. Todos los derechos reservados.</p>
          </footer>
        </div>
      `,
    };

    await transporter.sendMail(mailOptions);
    console.log("✅ Correo de credenciales enviado al administrador");
  } catch (error) {
    console.error("❌ Error enviando correo con credenciales:", error);
  }
};

export {
  sendMailToRegister,
  sendMailToRecoveryPassword,
  sendMailToOwner,
  sendMailWithCredentials,
};