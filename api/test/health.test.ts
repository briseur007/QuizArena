import { describe, it, expect, beforeAll } from 'vitest';
import request from 'supertest';

beforeAll(() => {
  process.env.MONGODB_URI ??= 'mongodb://localhost:27017/quizarena-test';
  process.env.JWT_ACCESS_SECRET ??= 'test-secret-test-secret-test-secret-123';
});

describe('GET /health', () => {
  it('répond 200', async () => {
    const { createApp } = await import('../src/app.js');
    const res = await request(createApp()).get('/health');
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ status: 'ok' });
  });
});
