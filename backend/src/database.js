import mongoose from "mongoose";
import dotenv from "dotenv";

dotenv.config(); 

mongoose.set('strictQuery', true);

const connection = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URL);
    console.log('Conectado a la base de datos con exito.');
  } catch (error) {
    console.error('Error de conexión a MongoDB:', error.message);
    process.exit(1);
  }
};

export default connection;
