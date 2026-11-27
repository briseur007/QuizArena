import mongoose from 'mongoose';
import { env } from './config/env.js';
import { createApp } from './app.js';

async function main() {
  await mongoose.connect(env.MONGODB_URI);
  console.log('MongoDB connecté');

  const app = createApp();
  app.listen(env.PORT, () => {
    console.log(`API QuizArena sur http://localhost:${env.PORT}`);
  });
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
