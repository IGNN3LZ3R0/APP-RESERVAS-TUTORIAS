import app from './server.js';
import connection from './database.js';
import { marcarTutoriasExpiradas } from './controllers/tutorias_controller.js';
import { 
  enviarRecordatoriosTutorias, 
  limpiarFlagsRecordatorios 
} from './utils/recordatorios.js';

connection();

const PORT = process.env.PORT || 3000;

app.listen(PORT, '0.0.0.0', async () => {
  console.log(`✅ Server ok on http://0.0.0.0:${PORT}`);
  
  // Marcar tutorías expiradas al iniciar
  await marcarTutoriasExpiradas();
  
  // Enviar recordatorios pendientes al iniciar
  await enviarRecordatoriosTutorias(24);
  await enviarRecordatoriosTutorias(3);
  
  // TAREAS PROGRAMADAS CADA 5 MINUTOS
  setInterval(async () => {
    console.log('\n🔄 Ejecutando tareas programadas...');
    await marcarTutoriasExpiradas();
    await enviarRecordatoriosTutorias(24);
    await enviarRecordatoriosTutorias(3);
  }, 5 * 60 * 1000);
  
  // Limpieza diaria a las 2 AM
  const programarLimpiezaDiaria = () => {
    const ahora = new Date();
    const proximaLimpieza = new Date();
    proximaLimpieza.setHours(2, 0, 0, 0);
    
    if (ahora > proximaLimpieza) {
      proximaLimpieza.setDate(proximaLimpieza.getDate() + 1);
    }
    
    const tiempoHastaLimpieza = proximaLimpieza - ahora;
    
    setTimeout(async () => {
      await limpiarFlagsRecordatorios();
      setInterval(limpiarFlagsRecordatorios, 24 * 60 * 60 * 1000);
    }, tiempoHastaLimpieza);
    
    console.log(`🧹 Limpieza programada para: ${proximaLimpieza.toLocaleString()}`);
  };
  
  programarLimpiezaDiaria();
  
  console.log('\n📅 Sistema de recordatorios activado:');
  console.log('   ⏰ Recordatorios 24h antes');
  console.log('   ⏰ Recordatorios 3h antes');
  console.log('   🔄 Verificación cada 5 minutos');
  console.log('   🧹 Limpieza diaria a las 2 AM\n');
});