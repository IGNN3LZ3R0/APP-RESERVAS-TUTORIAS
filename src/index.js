import app from './server.js';
import connection from './database.js';

connection();

const PORT = process.env.PORT || 3000;

app.listen(PORT, '0.0.0.0', () => {
  console.log(`✅ Server ok on http://0.0.0.0:${PORT}`);
});
