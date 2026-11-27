import { defineConfig } from 'vitest/config';

// Lancer avec `npm test` (scripts/vitest.mjs), pas `npx vitest` : voir ce script.
export default defineConfig({
  test: {
    // Variables lues par src/config/env.ts (aucun secret réel : environnement de test).
    env: {
      NODE_ENV: 'test',
      MONGODB_URI: 'mongodb://placeholder', // remplacée par la base en mémoire (test/setup.ts)
      JWT_ACCESS_SECRET: 'test-secret-test-secret-test-secret-123',
      AUTH_RATE_LIMIT_MAX: '1000',
    },
    setupFiles: ['./test/setup.ts'],
    // Le premier lancement télécharge le binaire MongoDB.
    hookTimeout: 120_000,
    testTimeout: 30_000,
  },
});
