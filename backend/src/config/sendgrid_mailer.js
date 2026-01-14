import sgMail from '@sendgrid/mail';
import dotenv from 'dotenv';
dotenv.config();

// Configurar SendGrid con API Key
sgMail.setApiKey(process.env.SENDGRID_API_KEY);

// ========== EMAIL DE CONFIRMACIÓN DE CUENTA (ESTUDIANTE) ==========
const sendMailToRegister = async (userMail, token) => {
  try {
    const msg = {
      to: userMail,
      from: 'maehdros863@gmail.com',
      subject: '✅ Confirma tu cuenta - Tutorías ESFOT',
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
        </head>
        <body style="margin: 0; padding: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f4f4;">
          <div style="max-width: 600px; margin: 20px auto; background-color: #ffffff; border-radius: 12px; overflow:  hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
            <div style="background: linear-gradient(135deg, #1565C0 0%, #0D47A1 100%); padding: 40px 20px; text-align: center;">
              <div style="background-color: white; width: 80px; height: 80px; margin: 0 auto 20px; border-radius: 50%; display: flex; align-items:  center; justify-content: center; box-shadow: 0 4px 8px rgba(0,0,0,0.2);">
                <span style="font-size: 40px;">🎓</span>
              </div>
              <h1 style="color: #ffffff; margin: 0; font-size: 28px; font-weight: 600;">¡Bienvenido/a!</h1>
              <p style="color: #E3F2FD; margin: 10px 0 0; font-size: 16px;">Tutorías ESFOT</p>
            </div>
            <div style="padding: 40px 30px;">
              <h2 style="color:  #1565C0; font-size: 22px; margin:  0 0 20px; font-weight: 600;">Un paso más para empezar</h2>
              <p style="color: #333333; font-size: 16px; line-height: 1.6; margin: 0 0 20px;">
                Gracias por registrarte en nuestra plataforma de tutorías. Para comenzar a agendar sesiones con tus docentes, necesitas activar tu cuenta.
              </p>
              <p style="color: #333333; font-size: 16px; line-height: 1.6; margin: 0 0 30px;">
                Copia el código de abajo en nuestra app <strong>desde tu dispositivo móvil</strong> para <strong>activar tu cuenta inmediatamente</strong>:
              </p>
              <div style="background-color:  #F5F5F5; border-left: 4px solid #1565C0; padding: 15px; margin: 25px 0; border-radius: 4px;">
                <p style="color: #666; font-size: 14px; margin: 0 0 10px;">
                  <strong>Paso 1:</strong> Copia este código y pégalo en la app: 
                </p>
                <div style="background-color: #ffffff; padding: 12px; border-radius: 6px; border: 1px dashed #1565C0; text-align: center;">
                  <code style="color: #1565C0; font-size: 16px; font-weight: 600; letter-spacing: 1px; word-break: break-all;">
                    ${token}
                  </code>
                </div>
              </div>
              <div style="background-color: #E3F2FD; padding:  15px; border-radius:  8px; margin: 25px 0;">
                <p style="color: #0D47A1; font-size: 14px; margin: 0; line-height: 1.5;">
                  💡 <strong>Consejo:</strong> Una vez activada tu cuenta, podrás ver la disponibilidad de docentes y agendar tutorías directamente desde tu celular.
                </p>
              </div>
              <p style="color: #999999; font-size: 13px; line-height: 1.5; margin: 25px 0 0;">
                Si no creaste esta cuenta, puedes ignorar este correo de forma segura.
              </p>
            </div>
            <div style="background-color: #F5F5F5; padding: 20px 30px; border-top: 1px solid #E0E0E0;">
              <p style="color:  #999999; font-size:  12px; margin: 0; text-align: center; line-height: 1.5;">
                Este enlace expirará cuando actives tu cuenta. <br>
                © 2025 <strong>ESFOT Tutorías</strong>.  Todos los derechos reservados.
              </p>
            </div>
          </div>
        </body>
        </html>
      `,
    };

    await sgMail.send(msg);
    console.log('✅ Correo de confirmación enviado a:', userMail);
  } catch (error) {
    console.error('❌ Error enviando correo de confirmación:', error);
    if (error.response) {
      console.error('Detalles del error:', error.response.body);
    }
    throw error;
  }
};

// ========== EMAIL DE RECUPERACIÓN DE CONTRASEÑA ==========
const sendMailToRecoveryPassword = async (userMail, token) => {
  try {
    const msg = {
      to: userMail,
      from: 'maehdros863@gmail.com',
      subject: '🔐 Restablecer tu contraseña - Tutorías ESFOT',
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
        </head>
        <body style="margin: 0; padding: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f4f4;">
          <div style="max-width:  600px; margin: 20px auto; background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
            <div style="background: linear-gradient(135deg, #EF5350 0%, #D32F2F 100%); padding: 40px 20px; text-align: center;">
              <div style="background-color: white; width: 80px; height: 80px; margin: 0 auto 20px; border-radius: 50%; display: flex; align-items:  center; justify-content: center; box-shadow: 0 4px 8px rgba(0,0,0,0.2);">
                <span style="font-size: 40px;">🔐</span>
              </div>
              <h1 style="color: #ffffff; margin: 0; font-size:  28px; font-weight:  600;">Restablecer Contraseña</h1>
              <p style="color: #FFEBEE; margin: 10px 0 0; font-size:  16px;">Tutorías ESFOT</p>
            </div>
            <div style="padding: 40px 30px;">
              <h2 style="color: #D32F2F; font-size: 22px; margin: 0 0 20px; font-weight: 600;">¿Olvidaste tu contraseña? </h2>
              <p style="color: #333333; font-size: 16px; line-height: 1.6; margin: 0 0 20px;">
                No te preocupes, recibimos tu solicitud para restablecer tu contraseña.  Puedes crear una nueva de forma segura.
              </p>
              <p style="color:  #333333; font-size:  16px; line-height:  1.6; margin: 0 0 30px;">
                <strong>Copia el código de verificación</strong> de abajo y pégalo en la aplicación para continuar:
              </p>
              <div style="background-color: #F5F5F5; border-left: 4px solid #D32F2F; padding: 15px; margin:  25px 0; border-radius: 4px;">
                <p style="color: #666; font-size: 14px; margin: 0 0 10px;">
                  <strong>Código de verificación:</strong>
                </p>
                <div style="background-color: #ffffff; padding: 12px; border-radius: 6px; border: 1px dashed #D32F2F; text-align: center;">
                  <code style="color: #D32F2F; font-size:  18px; font-weight: 600; letter-spacing: 1px; word-break: break-all;">
                    ${token}
                  </code>
                </div>
                <p style="color: #666; font-size: 13px; margin: 10px 0 0;">
                  Abre la app, ve a "Olvidé mi contraseña" y pega este código. 
                </p>
              </div>
              <div style="background-color: #FFF3E0; padding: 15px; border-radius: 8px; margin: 25px 0; border-left: 4px solid #FF9800;">
                <p style="color: #E65100; font-size: 14px; margin: 0; line-height: 1.5;">
                  ⚠️ <strong>Importante:</strong> Si no solicitaste este cambio, ignora este correo.  Tu contraseña actual seguirá siendo válida.
                </p>
              </div>
            </div>
            <div style="background-color: #F5F5F5; padding: 20px 30px; border-top: 1px solid #E0E0E0;">
              <p style="color: #999999; font-size: 12px; margin: 0; text-align: center; line-height: 1.5;">
                Si tienes problemas, contacta a soporte. <br>
                © 2025 <strong>ESFOT Tutorías</strong>.  Todos los derechos reservados.
              </p>
            </div>
          </div>
        </body>
        </html>
      `,
    };

    await sgMail.send(msg);
    console.log('✅ Correo de recuperación enviado correctamente a:', userMail);
  } catch (error) {
    console.error('❌ Error enviando correo de recuperación:', error);
    if (error.response) {
      console.error('Detalles del error:', error.response.body);
    }
    throw error;
  }
};

// ========== EMAIL PARA DOCENTES ==========
const sendMailToOwner = async (userMail, password) => {
  try {
    const msg = {
      to: userMail,
      from: 'maehdros863@gmail.com',
      subject: '✅ Bienvenido/a al equipo docente - Tutorías ESFOT',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 20px; background-color: #f9f9f9;">
          <div style="background-color: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
            <h1 style="color: #1565C0; text-align: center;">¡Bienvenido/a! </h1>
            <hr style="border: none; border-top: 2px solid #1565C0;">
            <p style="font-size: 16px; color: #333;">El administrador te ha registrado en la plataforma de Tutorías ESFOT. </p>
            <p style="font-size: 16px; color: #333;">Tus credenciales de acceso son:</p>
            <div style="background-color:  #E3F2FD; padding: 15px; border-radius: 6px; margin: 20px 0;">
              <p style="margin: 5px 0;"><strong>📧 Correo:</strong> ${userMail}</p>
              <p style="margin: 5px 0;"><strong>🔑 Contraseña:</strong> <code style="background-color: white; padding: 4px 8px; border-radius: 4px; color: #D32F2F;">${password}</code></p>
            </div>
            <p style="font-size: 14px; color: #666;">⚠️ <strong>Importante:</strong> Por seguridad, cambia tu contraseña en tu primer inicio de sesión.</p>
            <hr style="margin: 30px 0; border: none; border-top:  1px solid #ddd;">
            <footer style="text-align: center; font-size: 12px; color: #999;">
              <p>2025 - TUTORÍAS ESFOT - Todos los derechos reservados. </p>
            </footer>
          </div>
        </div>
      `,
    };

    await sgMail.send(msg);
    console.log('✅ Correo enviado al docente:', userMail);
  } catch (error) {
    console.error('❌ Error enviando correo al docente:', error);
    if (error.response) {
      console.error('Detalles del error:', error.response.body);
    }
    throw error;
  }
};

// ========== EMAIL PARA ADMINISTRADORES ==========
const sendMailWithCredentials = async (email, nombreAdministrador, passwordGenerada) => {
  try {
    const msg = {
      to: email,
      from: 'maehdros863@gmail.com',
      subject: '🔐 Credenciales de Administrador - Tutorías ESFOT',
      html: `
        <div style="font-family:  Verdana, sans-serif; max-width: 600px; margin:  auto; border: 1px solid #e0e0e0; padding:  20px; text-align: center; background-color: #fafafa;">
          <h2 style="color: #81180aff; font-weight: bold;">¡Bienvenido/a, ${nombreAdministrador}!</h2>
          <p style="font-size: 16px; color: #333;">Se ha creado tu cuenta de <strong>Administrador</strong> en la plataforma de Tutorías ESFOT.</p>
          <div style="background-color: white; padding: 20px; border-radius: 8px; margin: 20px 0; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
            <p style="margin: 10px 0;"><strong>📧 Correo electrónico:</strong><br>${email}</p>
            <p style="margin: 10px 0;"><strong>🔑 Contraseña: </strong><br>
              <code style="background-color: #f5f5f5; padding: 8px 12px; border-radius: 4px; font-size: 16px; color: #D32F2F;">${passwordGenerada}</code>
            </p>
          </div>
          <p style="font-size:  14px; color: #666;">⚠️ Por favor, <strong>cambia tu contraseña</strong> inmediatamente después de tu primer inicio de sesión.</p>
          <hr style="border: 0; border-top: 1px solid #424040ff; margin: 20px 0;">
          <footer style="font-size: 12px; color: #999;">
            <p>&copy; 2025 ESFOT Tutorías.  Todos los derechos reservados.</p>
          </footer>
        </div>
      `,
    };

    await sgMail.send(msg);
    console.log('✅ Correo de credenciales enviado al administrador');
  } catch (error) {
    console.error('❌ Error enviando correo con credenciales:', error);
    if (error.response) {
      console.error('Detalles del error:', error.response.body);
    }
    throw error;
  }
};

// ========== EMAILS REAGENDAMIENTO (VERSIÓN MEJORADA) ==========
const sendMailReagendamientoDocente = async (emailEstudiante, nombreEstudiante, nombreDocente, datosReagendamiento) => {
  try {
    const { fechaAnterior, horaInicioAnterior, horaFinAnterior, fechaNueva, horaInicioNueva, horaFinNueva, motivo } = datosReagendamiento;

    const msg = {
      to: emailEstudiante,
      from: 'maehdros863@gmail.com',
      subject: '📅 Tu tutoría ha sido reagendada - Tutorías ESFOT',
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
            <div style="background: linear-gradient(135deg, #FF9800 0%, #F57C00 100%); padding: 40px 20px; text-align: center;">
              <div style="background-color: white; width: 80px; height: 80px; margin: 0 auto 20px; border-radius: 50%; display: flex; align-items: center; justify-content: center; box-shadow: 0 4px 8px rgba(0,0,0,0.1);">
                <span style="font-size: 40px;">📅</span>
              </div>
              <h1 style="color: #ffffff; margin: 0; font-size: 28px; font-weight: 600;">Tutoría Reagendada</h1>
              <p style="color: #FFF3E0; margin: 10px 0 0; font-size: 16px;">Tutorías ESFOT</p>
            </div>

            <!-- Body -->
            <div style="padding: 40px 30px;">
              <p style="color: #333333; font-size: 16px; line-height: 1.6; margin: 0 0 20px;">
                Hola <strong>${nombreEstudiante}</strong>,
              </p>
              <p style="color: #333333; font-size: 16px; line-height: 1.6; margin: 0 0 30px;">
                El docente <strong>${nombreDocente}</strong> ha reagendado tu tutoría a un nuevo horario.
              </p>

              <!-- Horario Anterior -->
              <div style="background-color: #FFEBEE; border-left: 4px solid #EF5350; padding: 20px; margin: 20px 0; border-radius: 8px;">
                <p style="color: #C62828; font-size: 14px; margin: 0 0 10px; font-weight: 600;">
                  ❌ HORARIO ANTERIOR (cancelado)
                </p>
                <p style="color: #666; font-size: 16px; margin: 5px 0;">
                  <strong>📅 Fecha:</strong> ${fechaAnterior}
                </p>
                <p style="color: #666; font-size: 16px; margin: 5px 0;">
                  <strong>⏰ Hora:</strong> ${horaInicioAnterior} - ${horaFinAnterior}
                </p>
              </div>

              <!-- Nuevo Horario -->
              <div style="background-color: #E8F5E9; border-left: 4px solid #4CAF50; padding: 20px; margin: 20px 0; border-radius: 8px;">
                <p style="color: #2E7D32; font-size: 14px; margin: 0 0 10px; font-weight: 600;">
                  ✅ NUEVO HORARIO (confirmado)
                </p>
                <p style="color: #666; font-size: 16px; margin: 5px 0;">
                  <strong>📅 Fecha:</strong> ${fechaNueva}
                </p>
                <p style="color: #666; font-size: 16px; margin: 5px 0;">
                  <strong>⏰ Hora:</strong> ${horaInicioNueva} - ${horaFinNueva}
                </p>
              </div>

              ${motivo ? `
              <!-- Motivo -->
              <div style="background-color: #FFF3E0; padding: 15px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #FF9800;">
                <p style="color: #E65100; font-size: 14px; margin: 0 0 5px; font-weight: 600;">
                  💬 Motivo del reagendamiento:
                </p>
                <p style="color: #666; font-size: 15px; margin: 5px 0; line-height: 1.5;">
                  ${motivo}
                </p>
              </div>
              ` : ''}

              <p style="color: #999999; font-size: 13px; line-height: 1.5; margin: 25px 0 0;">
                Por favor, confirma tu asistencia en la aplicación móvil. 
              </p>
            </div>

            <!-- Footer -->
            <div style="background-color: #F5F5F5; padding: 20px 30px; border-top: 1px solid #E0E0E0;">
              <p style="color: #999999; font-size: 12px; margin: 0; text-align: center; line-height: 1.5;">
                © 2025 <strong>ESFOT Tutorías</strong>. Todos los derechos reservados.
              </p>
            </div>
          </div>
        </body>
        </html>
      `,
    };

    await sgMail.send(msg);
    console.log(`✅ Email de reagendamiento enviado al estudiante: ${emailEstudiante}`);
  } catch (error) {
    console.error('❌ Error enviando email de reagendamiento:', error);
    throw error;
  }
};

const sendMailReagendamientoEstudiante = async (emailDocente, nombreDocente, nombreEstudiante, datosReagendamiento) => {
  try {
    const { fechaAnterior, horaInicioAnterior, horaFinAnterior, fechaNueva, horaInicioNueva, horaFinNueva, motivo } = datosReagendamiento;

    const msg = {
      to: emailDocente,
      from: 'maehdros863@gmail.com',
      subject: '📅 Un estudiante ha reagendado una tutoría - Tutorías ESFOT',
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
            <div style="background: linear-gradient(135deg, #FF9800 0%, #F57C00 100%); padding: 40px 20px; text-align: center;">
              <div style="background-color: white; width: 80px; height: 80px; margin: 0 auto 20px; border-radius: 50%; display: flex; align-items: center; justify-content: center; box-shadow: 0 4px 8px rgba(0,0,0,0.1);">
                <span style="font-size: 40px;">📅</span>
              </div>
              <h1 style="color: #ffffff; margin: 0; font-size: 28px; font-weight: 600;">Tutoría Reagendada</h1>
              <p style="color: #FFF3E0; margin: 10px 0 0; font-size: 16px;">Tutorías ESFOT</p>
            </div>

            <!-- Body -->
            <div style="padding: 40px 30px;">
              <p style="color: #333333; font-size: 16px; line-height: 1.6; margin: 0 0 20px;">
                Hola <strong>${nombreDocente}</strong>,
              </p>
              <p style="color: #333333; font-size: 16px; line-height: 1.6; margin: 0 0 30px;">
                El estudiante <strong>${nombreEstudiante}</strong> ha reagendado su tutoría a un nuevo horario.
              </p>

              <!-- Horario Anterior -->
              <div style="background-color: #FFEBEE; border-left: 4px solid #EF5350; padding: 20px; margin: 20px 0; border-radius: 8px;">
                <p style="color: #C62828; font-size: 14px; margin: 0 0 10px; font-weight: 600;">
                  ❌ HORARIO ANTERIOR (cancelado)
                </p>
                <p style="color: #666; font-size: 16px; margin: 5px 0;">
                  <strong>📅 Fecha:</strong> ${fechaAnterior}
                </p>
                <p style="color: #666; font-size: 16px; margin: 5px 0;">
                  <strong>⏰ Hora:</strong> ${horaInicioAnterior} - ${horaFinAnterior}
                </p>
              </div>

              <!-- Nuevo Horario -->
              <div style="background-color: #E8F5E9; border-left: 4px solid #4CAF50; padding: 20px; margin: 20px 0; border-radius: 8px;">
                <p style="color: #2E7D32; font-size: 14px; margin: 0 0 10px; font-weight: 600;">
                  ✅ NUEVO HORARIO (pendiente tu confirmación)
                </p>
                <p style="color: #666; font-size: 16px; margin: 5px 0;">
                  <strong>📅 Fecha:</strong> ${fechaNueva}
                </p>
                <p style="color: #666; font-size: 16px; margin: 5px 0;">
                  <strong>⏰ Hora:</strong> ${horaInicioNueva} - ${horaFinNueva}
                </p>
              </div>

              ${motivo ? `
              <!-- Motivo -->
              <div style="background-color: #FFF3E0; padding: 15px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #FF9800;">
                <p style="color: #E65100; font-size: 14px; margin: 0 0 5px; font-weight: 600;">
                  💬 Motivo del reagendamiento:
                </p>
                <p style="color: #666; font-size: 15px; margin: 5px 0; line-height: 1.5;">
                  ${motivo}
                </p>
              </div>
              ` : ''}

              <p style="color: #999999; font-size: 13px; line-height: 1.5; margin: 25px 0 0;">
                Por favor, confirma o rechaza esta solicitud en la aplicación web.
              </p>
            </div>

            <!-- Footer -->
            <div style="background-color: #F5F5F5; padding: 20px 30px; border-top: 1px solid #E0E0E0;">
              <p style="color: #999999; font-size: 12px; margin: 0; text-align: center; line-height: 1.5;">
                © 2025 <strong>ESFOT Tutorías</strong>. Todos los derechos reservados.
              </p>
            </div>
          </div>
        </body>
        </html>
      `,
    };

    await sgMail.send(msg);
    console.log(`✅ Email de reagendamiento enviado al docente: ${emailDocente}`);
  } catch (error) {
    console.error('❌ Error enviando email de reagendamiento:', error);
    throw error;
  }
};

const sendMailCancelacionParaDocente = async (emailDocente, nombreDocente, nombreEstudiante, datosTutoria, motivo) => {
  try {
    const msg = {
      to: emailDocente,
      from: 'maehdros863@gmail.com',
      subject: '❌ Tutoría cancelada - Tutorías ESFOT',
      html: `<p>Hola ${nombreDocente}, el estudiante ${nombreEstudiante} ha cancelado la tutoría.</p>
             <p>Fecha: ${datosTutoria.fecha} (${datosTutoria.horaInicio} - ${datosTutoria.horaFin})</p>
             ${motivo ? `<p>Motivo: ${motivo}</p>` : ''}`,
    };

    await sgMail.send(msg);
    console.log(`✅ Email de cancelación enviado al docente: ${emailDocente}`);
  } catch (error) {
    console.error('❌ Error enviando email de cancelación:', error);
    throw error;
  }
};

const sendMailCancelacionParaEstudiante = async (emailEstudiante, nombreEstudiante, nombreDocente, datosTutoria, motivo) => {
  try {
    const msg = {
      to: emailEstudiante,
      from: 'maehdros863@gmail. com',
      subject: '❌ Tutoría cancelada - Tutorías ESFOT',
      html: `<p>Hola ${nombreEstudiante}, el docente ${nombreDocente} ha cancelado la tutoría.</p>
             <p>Fecha:  ${datosTutoria.fecha} (${datosTutoria.horaInicio} - ${datosTutoria.horaFin})</p>
             ${motivo ? `<p>Motivo: ${motivo}</p>` : ''}`,
    };

    await sgMail.send(msg);
    console.log(`✅ Email de cancelación enviado al estudiante:  ${emailEstudiante}`);
  } catch (error) {
    console.error('❌ Error enviando email de cancelación:', error);
    throw error;
  }
};

const sendMailRecordatorioTutoria = async (emailDestinatario, nombreDestinatario, esDocente, datosTutoria) => {
  try {
    const nombreOtraParte = esDocente ? datosTutoria.nombreEstudiante : datosTutoria.nombreDocente;

    const msg = {
      to: emailDestinatario,
      from: 'maehdros863@gmail.com',
      subject: '⏰ Recordatorio de tutoría - Tutorías ESFOT',
      html: `<p>Hola ${nombreDestinatario}, te recordamos que tienes una tutoría ${datosTutoria.tiempoRestante} con ${nombreOtraParte}.</p>
             <p>Fecha: ${datosTutoria.fecha} (${datosTutoria.horaInicio} - ${datosTutoria.horaFin})</p>`,
    };

    await sgMail.send(msg);
    console.log(`✅ Email de recordatorio enviado a:  ${emailDestinatario}`);
  } catch (error) {
    console.error('❌ Error enviando email de recordatorio:', error);
    throw error;
  }
};

export {
  sendMailToRegister,
  sendMailToRecoveryPassword,
  sendMailToOwner,
  sendMailWithCredentials,
  sendMailReagendamientoDocente,
  sendMailReagendamientoEstudiante,
  sendMailCancelacionParaDocente,
  sendMailCancelacionParaEstudiante,
  sendMailRecordatorioTutoria,
};