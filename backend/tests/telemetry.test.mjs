import test from 'node:test';
import assert from 'node:assert/strict';
import { sanitizeTelemetryEvent } from '../src/telemetry.js';

test('sanitizeTelemetryEvent normalizes valid payload', () => {
  const result = sanitizeTelemetryEvent(
    {
      event: 'session_connected',
      ts: '2026-03-04T13:22:10.000Z',
      fields: {
        transport: 'websocket',
        role: 'anchor'
      }
    },
    '127.0.0.1'
  );

  assert.equal(result.error, undefined);
  assert.equal(result.value.event, 'session_connected');
  assert.equal(result.value.ts, '2026-03-04T13:22:10.000Z');
  assert.equal(result.value.ipAddress, '127.0.0.1');
  assert.equal(result.value.fields.transport, 'websocket');
  assert.equal(result.value.fields.role, 'anchor');
});

test('sanitizeTelemetryEvent rejects invalid event and ts', () => {
  assert.equal(sanitizeTelemetryEvent({ event: '', ts: '2026-03-04T13:22:10.000Z' }).error, 'invalid_event');
  assert.equal(sanitizeTelemetryEvent({ event: 'session_connected', ts: 'not-a-date' }).error, 'invalid_ts');
});

test('sanitizeTelemetryEvent enforces fields object and count', () => {
  assert.equal(
    sanitizeTelemetryEvent({ event: 'session_connected', ts: '2026-03-04T13:22:10.000Z', fields: [] }).error,
    'invalid_fields'
  );

  const tooManyFields = {};
  for (let idx = 0; idx < 33; idx += 1) {
    tooManyFields[`k${idx}`] = String(idx);
  }
  assert.equal(
    sanitizeTelemetryEvent({ event: 'session_connected', ts: '2026-03-04T13:22:10.000Z', fields: tooManyFields }).error,
    'too_many_fields'
  );
});
