import { describe, it, expect, beforeAll } from 'vitest';
import request from 'supertest';

beforeAll(() => {
  process.env.MONGODB_URI ??= 'mongodb://localhost:27017/quizarena-test';
  process.env.JWT_ACCESS_SECRET ??= 'test-secret-test-secret-test-secret-123';
});

async function app() {
  const { createApp } = await import('../src/app.js');
  return createApp();
}

// A5 : un seul format d'erreur { error: { code, message } } et des codes HTTP pertinents
describe("format d'erreur", () => {
  it('route inconnue -> 404 NOT_FOUND', async () => {
    const res = await request(await app()).get('/nope');
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe('NOT_FOUND');
  });

  it('JSON malformé -> 400 INVALID_JSON (pas 500)', async () => {
    const res = await request(await app())
      .post('/health')
      .set('Content-Type', 'application/json')
      .send('{pas du json');
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('INVALID_JSON');
  });

  it('corps > 100 kb -> 413 PAYLOAD_TOO_LARGE (pas 500)', async () => {
    const res = await request(await app())
      .post('/health')
      .set('Content-Type', 'application/json')
      .send(JSON.stringify({ a: 'x'.repeat(200_000) }));
    expect(res.status).toBe(413);
    expect(res.body.error.code).toBe('PAYLOAD_TOO_LARGE');
  });
});
