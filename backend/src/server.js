import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import { fileURLToPath } from 'node:url';
import express from 'express';
import cors from 'cors';
import { WebSocketServer } from 'ws';
import Redis from 'ioredis';
import { normalizeRelayPayload } from './protocol.js';

const PORT = Number(process.env.PORT || 8080);
const REDIS_URL = process.env.REDIS_URL || '';
const ADMIN_KEY = process.env.ADMIN_KEY || 'dev-admin-key';

const app = express();
app.use(cors());
app.use(express.json());

const redis = REDIS_URL ? new Redis(REDIS_URL) : null;
if (redis) {
  redis.on('error', (err) => console.error('redis error', err.message));
}

const memory = {
  duos: new Map(),
  duoByCode: new Map(),
  duoByPlayers: new Map(),
  rooms: new Map(),
  completions: new Set(),
  duoCompletionAwards: new Set(),
  roomCompletionMembers: new Map(),
  dailyLevels: new Map()
};

const wsRooms = new Map();
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

function isoDateUTC(date = new Date()) {
  return date.toISOString().slice(0, 10);
}

function dayDiff(a, b) {
  const ms = 24 * 60 * 60 * 1000;
  const da = new Date(a + 'T00:00:00Z').getTime();
  const db = new Date(b + 'T00:00:00Z').getTime();
  return Math.floor((da - db) / ms);
}

function generateCode(length = 4) {
  let out = '';
  for (let i = 0; i < length; i += 1) {
    out += String(Math.floor(Math.random() * 10));
  }
  return out;
}

function pairKey(playerAId, playerBId) {
  return [playerAId, playerBId].sort().join(':');
}

function isRoomCodeValid(roomCode) {
  return /^[0-9]{4}$/.test(roomCode);
}

function applyStreakUpdate(profile, dateUTC) {
  if (profile.lastCompletedDateUTC) {
    const diff = dayDiff(dateUTC, profile.lastCompletedDateUTC);
    if (diff === 1) {
      profile.currentStreak += 1;
    } else if (diff > 1) {
      if (profile.graceTokens > 0) {
        profile.graceTokens -= 1;
        profile.currentStreak += 1;
      } else {
        profile.currentStreak = 1;
      }
    }
  } else {
    profile.currentStreak = 1;
  }

  profile.lastCompletedDateUTC = dateUTC;
  if (profile.currentStreak >= 3 && !profile.milestonesUnlocked.includes(3)) profile.milestonesUnlocked.push(3);
  if (profile.currentStreak >= 7 && !profile.milestonesUnlocked.includes(7)) profile.milestonesUnlocked.push(7);
  if (profile.currentStreak >= 14 && !profile.milestonesUnlocked.includes(14)) profile.milestonesUnlocked.push(14);
}

function ensureDuoForPair(memberA, memberB) {
  const key = pairKey(memberA.playerId, memberB.playerId);
  const existingId = memory.duoByPlayers.get(key);
  if (existingId && memory.duos.has(existingId)) {
    return memory.duos.get(existingId);
  }

  let duoCode = generateCode(6);
  while (memory.duoByCode.has(duoCode)) {
    duoCode = generateCode(6);
  }

  const duoId = `duo_${Date.now()}_${Math.floor(Math.random() * 10000)}`;
  const profile = {
    duoId,
    duoCode,
    duoName: `${memberA.playerName} + ${memberB.playerName}`,
    memberA: memberA.playerName,
    memberB: memberB.playerName,
    currentStreak: 0,
    lastCompletedDateUTC: null,
    graceTokens: 1,
    milestonesUnlocked: []
  };

  memory.duos.set(duoId, profile);
  memory.duoByCode.set(duoCode, duoId);
  memory.duoByPlayers.set(key, duoId);
  return profile;
}

function getActiveRoom(roomCode) {
  const room = memory.rooms.get(roomCode);
  if (!room) return null;
  if (room.expiresAt < Date.now()) {
    memory.rooms.delete(roomCode);
    wsRooms.delete(roomCode);
    return null;
  }
  return room;
}

function loadInitialLevels() {
  const levelsDir = path.resolve(__dirname, '../levels');
  if (!fs.existsSync(levelsDir)) return;

  for (const file of fs.readdirSync(levelsDir)) {
    if (!file.endsWith('.json')) continue;
    const fullPath = path.join(levelsDir, file);
    const level = JSON.parse(fs.readFileSync(fullPath, 'utf8'));
    memory.dailyLevels.set(level.dateUTC, level);
  }
}

loadInitialLevels();

function getLevelForDate(dateUTC) {
  if (memory.dailyLevels.has(dateUTC)) {
    return { level: memory.dailyLevels.get(dateUTC), fallbackUsed: false };
  }

  const dates = [...memory.dailyLevels.keys()].sort();
  const previous = dates.filter((d) => d <= dateUTC).at(-1);
  if (!previous) {
    return null;
  }

  return { level: memory.dailyLevels.get(previous), fallbackUsed: true };
}

function validateLevelPayload(level) {
  const required = [
    'levelId', 'dateUTC', 'theme', 'version', 'objective',
    'spawnAnchor', 'spawnDash', 'winZoneX', 'gateX', 'switchX', 'dashPlateX'
  ];

  for (const field of required) {
    if (!(field in level)) {
      return `missing_${field}`;
    }
  }
  return null;
}

function roomState(roomCode) {
  const room = getActiveRoom(roomCode);
  if (!room) return null;
  return {
    roomCode,
    duoId: room.duoId,
    players: room.players,
    expiresAt: room.expiresAt,
    dailyDateUTC: room.dailyDateUTC
  };
}

app.get('/health', (_req, res) => {
  res.json({ ok: true, ts: new Date().toISOString() });
});

app.post('/duo/create', (req, res) => {
  const duoName = String(req.body?.duoName || '').trim() || 'Forest Duo';
  const playerName = String(req.body?.playerName || '').trim() || 'Player A';

  let duoCode = generateCode(6);
  while (memory.duoByCode.has(duoCode)) {
    duoCode = generateCode(6);
  }

  const duoId = `duo_${Date.now()}_${Math.floor(Math.random() * 10000)}`;
  const profile = {
    duoId,
    duoCode,
    duoName,
    memberA: playerName,
    memberB: null,
    currentStreak: 0,
    lastCompletedDateUTC: null,
    graceTokens: 1,
    milestonesUnlocked: []
  };

  memory.duos.set(duoId, profile);
  memory.duoByCode.set(duoCode, duoId);

  res.json(profile);
});

app.post('/duo/join', (req, res) => {
  const duoCode = String(req.body?.duoCode || '').trim();
  const playerName = String(req.body?.playerName || '').trim() || 'Player B';

  const duoId = memory.duoByCode.get(duoCode);
  if (!duoId) {
    return res.status(404).json({ error: 'duo_not_found' });
  }

  const profile = memory.duos.get(duoId);
  if (!profile) {
    return res.status(404).json({ error: 'duo_not_found' });
  }

  profile.memberB = playerName;
  memory.duos.set(duoId, profile);
  res.json(profile);
});

app.get('/duo/state', (req, res) => {
  const duoId = String(req.query.duoId || '');
  const profile = memory.duos.get(duoId);
  if (!profile) {
    return res.status(404).json({ error: 'duo_not_found' });
  }
  res.json(profile);
});

app.post('/rooms/create', (req, res) => {
  const duoId = String(req.body?.duoId || '');
  const playerId = String(req.body?.playerId || '');
  const playerName = String(req.body?.playerName || 'Host');

  if (!memory.duos.has(duoId)) {
    return res.status(404).json({ error: 'duo_not_found' });
  }

  let roomCode = generateCode(4);
  while (memory.rooms.has(roomCode)) {
    roomCode = generateCode(4);
  }

  const room = {
    roomCode,
    duoId,
    players: [{ playerId, playerName, role: 'anchor' }],
    expiresAt: Date.now() + 10 * 60 * 1000,
    createdAt: Date.now()
  };

  memory.rooms.set(roomCode, room);
  res.json({ roomCode, role: 'anchor' });
});

app.post('/rooms/enter', (req, res) => {
  const roomCode = String(req.body?.roomCode || '').trim();
  const playerId = String(req.body?.playerId || '');
  const playerName = String(req.body?.playerName || 'Player');

  if (!isRoomCodeValid(roomCode)) {
    return res.status(400).json({ error: 'invalid_room_code' });
  }
  if (!playerId) {
    return res.status(400).json({ error: 'missing_player_id' });
  }

  let room = getActiveRoom(roomCode);
  if (!room) {
    room = {
      roomCode,
      duoId: null,
      players: [{ playerId, playerName, role: 'anchor' }],
      expiresAt: Date.now() + 10 * 60 * 1000,
      createdAt: Date.now(),
      dailyDateUTC: isoDateUTC()
    };
    memory.rooms.set(roomCode, room);
    return res.json({
      roomCode,
      role: 'anchor',
      state: 'created',
      duoId: null,
      partnerConnected: false
    });
  }

  const existing = room.players.find((p) => p.playerId === playerId);
  if (existing) {
    room.expiresAt = Date.now() + 10 * 60 * 1000;
    memory.rooms.set(roomCode, room);

    const other = room.players.find((p) => p.playerId !== playerId);
    const duoId = other ? memory.duoByPlayers.get(pairKey(playerId, other.playerId)) || null : null;

    return res.json({
      roomCode,
      role: existing.role,
      state: 'rejoined',
      duoId,
      partnerConnected: room.players.length > 1
    });
  }

  if (room.players.length >= 2) {
    return res.status(409).json({ error: 'room_full' });
  }

  room.players.push({ playerId, playerName, role: 'dash' });
  room.expiresAt = Date.now() + 10 * 60 * 1000;
  memory.rooms.set(roomCode, room);

  const other = room.players.find((p) => p.playerId !== playerId);
  const duoId = other ? memory.duoByPlayers.get(pairKey(playerId, other.playerId)) || null : null;

  return res.json({
    roomCode,
    role: 'dash',
    state: 'joined',
    duoId,
    partnerConnected: true
  });
});

app.post('/rooms/join', (req, res) => {
  const roomCode = String(req.body?.roomCode || '').trim();
  const duoId = String(req.body?.duoId || '');
  const playerId = String(req.body?.playerId || '');
  const playerName = String(req.body?.playerName || 'Guest');

  const room = memory.rooms.get(roomCode);
  if (!room) {
    return res.status(404).json({ error: 'room_not_found' });
  }

  if (room.duoId !== duoId) {
    return res.status(403).json({ error: 'duo_mismatch' });
  }

  if (room.players.length >= 2) {
    return res.status(409).json({ error: 'room_full' });
  }

  room.players.push({ playerId, playerName, role: 'dash' });
  room.expiresAt = Date.now() + 10 * 60 * 1000;
  memory.rooms.set(roomCode, room);

  res.json({ roomCode, role: 'dash' });
});

app.get('/daily-level', (req, res) => {
  const dateUTC = String(req.query.date || isoDateUTC());
  const resolved = getLevelForDate(dateUTC);
  if (!resolved) {
    return res.status(404).json({ error: 'daily_level_not_found' });
  }
  res.json(resolved);
});

app.post('/daily-level', (req, res) => {
  const adminKey = req.header('x-admin-key') || '';
  if (adminKey !== ADMIN_KEY) {
    return res.status(401).json({ error: 'unauthorized' });
  }

  const level = req.body;
  const validation = validateLevelPayload(level);
  if (validation) {
    return res.status(400).json({ error: validation });
  }

  memory.dailyLevels.set(level.dateUTC, level);
  res.json({ ok: true, dateUTC: level.dateUTC, levelId: level.levelId });
});

app.post('/daily-completion', (req, res) => {
  const roomCode = String(req.body?.roomCode || '').trim();
  const playerId = String(req.body?.playerId || '');
  const levelId = String(req.body?.levelId || '');
  const completedAt = String(req.body?.completedAt || new Date().toISOString());
  const dateUTC = isoDateUTC(new Date(completedAt));

  const room = getActiveRoom(roomCode);
  if (!room) {
    return res.status(404).json({ error: 'room_not_found' });
  }
  const player = room.players.find((member) => member.playerId === playerId);
  if (!player) {
    return res.status(403).json({ error: 'player_not_in_room' });
  }

  const eventKey = `${roomCode}:${dateUTC}:${levelId}:${playerId}`;
  if (memory.completions.has(eventKey)) {
    const partner = room.players.find((member) => member.playerId !== playerId);
    const duoId = partner ? memory.duoByPlayers.get(pairKey(playerId, partner.playerId)) || null : null;
    return res.json({ ok: true, idempotent: true, duoId, status: 'already_recorded', profile: duoId ? memory.duos.get(duoId) : null });
  }

  memory.completions.add(eventKey);

  const roomCompletionKey = `${roomCode}:${dateUTC}:${levelId}`;
  const completedMembers = memory.roomCompletionMembers.get(roomCompletionKey) || new Set();
  completedMembers.add(playerId);
  memory.roomCompletionMembers.set(roomCompletionKey, completedMembers);

  if (completedMembers.size < 2 || room.players.length < 2) {
    return res.json({
      ok: true,
      idempotent: false,
      duoId: null,
      status: 'awaiting_partner_completion',
      profile: null
    });
  }

  const [memberA, memberB] = room.players;
  const profile = ensureDuoForPair(memberA, memberB);
  room.duoId = profile.duoId;
  memory.rooms.set(roomCode, room);

  const awardKey = `${profile.duoId}:${dateUTC}:${levelId}`;
  if (!memory.duoCompletionAwards.has(awardKey)) {
    applyStreakUpdate(profile, dateUTC);
    memory.duos.set(profile.duoId, profile);
    memory.duoCompletionAwards.add(awardKey);
  }

  res.json({
    ok: true,
    idempotent: false,
    duoId: profile.duoId,
    status: 'duo_completion_recorded',
    profile
  });
});

app.get('/postcard-payload', (req, res) => {
  const duoId = String(req.query.duoId || '');
  const profile = memory.duos.get(duoId);
  if (!profile) {
    return res.status(404).json({ error: 'duo_not_found' });
  }

  res.json({
    duoName: profile.duoName,
    dateUTC: isoDateUTC(),
    stamp: 'Completed together',
    bgTheme: 'mossy_dawn',
    sanctuaryPreviewSeed: profile.currentStreak
  });
});

setInterval(() => {
  const now = Date.now();
  for (const [code, room] of memory.rooms.entries()) {
    if (room.expiresAt < now) {
      memory.rooms.delete(code);
      wsRooms.delete(code);
    }
  }
}, 30_000);

const server = http.createServer(app);
const wss = new WebSocketServer({ server, path: '/ws' });

function broadcast(roomCode, payload, exceptSocket = null) {
  const members = wsRooms.get(roomCode) || [];
  const data = JSON.stringify(payload);
  for (const socket of members) {
    if (socket === exceptSocket || socket.readyState !== socket.OPEN) continue;
    socket.send(data);
  }
}

wss.on('connection', (ws, req) => {
  const url = new URL(req.url, `http://${req.headers.host}`);
  const roomCode = url.searchParams.get('roomCode') || '';
  const playerId = url.searchParams.get('playerId') || '';
  const room = memory.rooms.get(roomCode);

  if (!room || !playerId) {
    ws.close();
    return;
  }

  if (!wsRooms.has(roomCode)) wsRooms.set(roomCode, new Set());
  wsRooms.get(roomCode).add(ws);

  const player = room.players.find((p) => p.playerId === playerId);
  if (!player) {
    ws.close();
    return;
  }

  room.expiresAt = Date.now() + 10 * 60 * 1000;

  ws.send(JSON.stringify({ type: 'role_assigned', role: player.role }));
  ws.send(JSON.stringify({ type: 'room_state', room: roomState(roomCode) }));
  for (const other of room.players) {
    if (other.playerId === playerId) continue;
    ws.send(JSON.stringify({ type: 'peer_joined', senderId: other.playerId }));
  }
  broadcast(roomCode, { type: 'peer_joined', senderId: playerId }, ws);

  ws.on('message', (raw) => {
    room.expiresAt = Date.now() + 10 * 60 * 1000;

    try {
      const payload = JSON.parse(raw.toString('utf8'));
      const relayPayload = normalizeRelayPayload(payload, roomCode, playerId);
      if (relayPayload) {
        broadcast(roomCode, relayPayload, ws);
      }
    } catch (error) {
      console.error('ws_message_error', error.message);
    }
  });

  ws.on('close', () => {
    const set = wsRooms.get(roomCode);
    if (set) {
      set.delete(ws);
      if (set.size === 0) {
        wsRooms.delete(roomCode);
      }
    }
    broadcast(roomCode, { type: 'peer_left', senderId: playerId }, null);
  });
});

server.listen(PORT, () => {
  console.log(`swiftgame backend listening on :${PORT}`);
});
