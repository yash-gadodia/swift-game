# SwiftGame - Daily Duo MVP

SwiftGame is a viral-ready co-op ritual MVP:
- 2 players connect with a room code.
- One UTC daily level is active.
- Roles are asymmetric (`Anchor` + `Dash`).
- Duo streaks and grace token logic are tracked.
- Completion triggers a postcard share flow.

## Current Implementation

Client (iOS):
- Swift + SpriteKit side-view puzzle scene
- WebSocket room transport
- Duo create/join flow
- Room create/join flow (4-digit code)
- Daily level fetch + fallback-compatible payload handling
- Basic streak UI and completion/postcard integration

Backend (Node.js):
- REST APIs for duo, room, daily level, completion, postcard payload
- WebSocket relay for real-time state sync
- Room expiry (10 min idle)
- Manual daily level content files (`backend/levels/*.json`)
- Streak + grace token bookkeeping

## Architecture

- `SwiftGame/Networking/`: transport, API client, protocol models
- `SwiftGame/Scenes/`: gameplay simulation and cooperative puzzle loop
- `SwiftGame/UI/`: lobby + in-game overlays
- `backend/src/server.js`: API + WebSocket room relay
- `backend/levels/`: manually-authored daily levels

## Run Backend

```bash
cd backend
npm install
npm run dev
```

Backend defaults:
- Port: `8080`
- Admin key for level publishing: `dev-admin-key`

## Run iOS App

1. Open `SwiftGame.xcodeproj`.
2. Run on simulator or device.
3. In lobby, keep server URL as `http://127.0.0.1:8080` for simulator-on-same-mac.
4. Player A creates duo + room.
5. Player B joins duo + room.
6. Both enter scene and complete puzzle cooperatively.

## API Summary

- `POST /duo/create`
- `POST /duo/join`
- `GET /duo/state`
- `POST /rooms/create`
- `POST /rooms/join`
- `GET /daily-level?date=YYYY-MM-DD`
- `POST /daily-level` (admin publish)
- `POST /daily-completion`
- `GET /postcard-payload?duoId=...`
- `WS /ws?roomCode=....&playerId=...`

## Notes

- Redis support can be added via `REDIS_URL`; in-memory store is used by default for local MVP testing.
- Daily fallback behavior currently resolves to the most recent available previous level.
- Internal archive is the `backend/levels` store and server memory map (no public replay route).
