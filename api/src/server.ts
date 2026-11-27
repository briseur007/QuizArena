import mongoose from 'mongoose';
import { env } from './config/env.js';
import { createApp } from './app.js';

async function main() {
  await mongoose.connect(env.MONGODB_URI);
  console.log('MongoDB connecté');

  const app = createApp();
  // Express 5 passe l'erreur d'écoute (ex. EADDRINUSE) au callback : il faut la traiter.
  app.listen(env.PORT, (err?: Error) => {
    if (err) {
      console.error(`Impossible d'écouter sur le port ${env.PORT} :`, err.message);
      process.exit(1);
    }
    console.log(`API QuizArena sur http://localhost:${env.PORT}`);
  });
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
