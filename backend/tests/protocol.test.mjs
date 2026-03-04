import test from 'node:test';
import assert from 'node:assert/strict';
import { normalizeRelayPayload, PROTOCOL_VERSION } from '../src/protocol.js';

test('normalizeRelayPayload returns null for non-relay payload', () => {
  assert.equal(normalizeRelayPayload(null, '1234', 'p1'), null);
  assert.equal(normalizeRelayPayload({ type: 'ping' }, '1234', 'p1'), null);
});

test('normalizeRelayPayload enforces authoritative sender and room fields', () => {
  const normalized = normalizeRelayPayload(
    {
      type: 'relay',
      version: 9,
      senderId: 'spoofed',
      roomCode: '9999',
      role: 'anchor',
      message: { type: 'ping', ping: 1 }
    },
    '1234',
    'actual-player'
  );

  assert.deepEqual(normalized, {
    version: 9,
    type: 'relay',
    senderId: 'actual-player',
    role: null,
    roomCode: '1234',
    message: { type: 'ping', ping: 1 }
  });
});

test('normalizeRelayPayload defaults protocol version when missing', () => {
  const normalized = normalizeRelayPayload(
    {
      type: 'relay',
      message: { type: 'hello', hello: 'ignored' }
    },
    '1234',
    'p1'
  );

  assert.equal(normalized.version, PROTOCOL_VERSION);
});

test('normalizeRelayPayload defaults protocol version when version is wrong type', () => {
  const normalized = normalizeRelayPayload(
    {
      type: 'relay',
      version: '2',
      message: { type: 'pong', pong: 2 }
    },
    '1234',
    'p1'
  );

  assert.equal(normalized.version, PROTOCOL_VERSION);
});
