export const PROTOCOL_VERSION = 1;

export function normalizeRelayPayload(payload, roomCode, playerId) {
  if (!payload || payload.type !== 'relay' || typeof payload !== 'object') {
    return null;
  }

  return {
    version: Number.isInteger(payload.version) ? payload.version : PROTOCOL_VERSION,
    type: 'relay',
    senderId: playerId,
    role: null,
    roomCode,
    message: payload.message ?? null
  };
}
