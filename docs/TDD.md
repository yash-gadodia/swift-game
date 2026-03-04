# Technical Design Document (TDD)

## 1. System Overview

The app is a native iOS SpriteKit client with three core layers:
- UI Layer: lobby and controls
- Simulation Layer: local/remote state and interpolation
- Transport Layer: room WebSocket networking and message dispatch

A lightweight backend provides room entry and daily level APIs used before gameplay starts.

Backend protocol helpers:
- `backend/src/protocol.js`
  - Relay envelope normalization and protocol defaults for WebSocket broadcast safety

## 2. Architectural Goals

- Keep simulation deterministic and independent from transport details.
- Keep networking serialization explicit and versionable.
- Keep frame loop lean and observable.

## 3. Module Breakdown

### `Networking/`
- `NetMessages.swift`
  - Wire-level message schema (`NetMessage`, `RoomEnvelope`, packets)
- `MultipeerSessionManager.swift`
  - Session transport protocol + `WebSocketSessionManager`
- `APIClient.swift` / `APIModels.swift`
  - Room entry and daily level fetch models

### `Game/`
- `GameState.swift`
  - Local position/velocity
  - Remote snapshot buffer
  - Interpolation/extrapolation

### `Scenes/`
- `GameScene.swift`
  - Per-frame update loop
  - Local simulation step
  - Network send cadence
  - Remote render update
  - RTT/PPS HUD metrics
  - Theme-derived scene palette + lightweight movement/connection effects

### `UI/`
- `LobbyViewController.swift`
  - Server URL + room code flow
  - Session startup and game presentation gating
  - Styled status-first lobby layout
- `GameViewController.swift`
  - Scene container + control overlays
  - Top HUD controls and in-session sound toggle
  - Runtime-generated audio engine (ambient bed + movement + event cues)
  - Theme-profiled synthesis and live tune controls (FX intensity + haptics)
- `VirtualDPad.swift`
  - Direction vector input component
  - Haptic-assisted analog control surface

## 4. Data Flow

1. User enters room code in lobby and taps Play.
2. API layer enters room and fetches daily level.
3. Transport layer opens WebSocket session and emits lifecycle callbacks.
4. On partner connection, game scene starts and sends `hello`.
5. Each frame:
   - Local input -> local velocity/position
   - At fixed tick (~20Hz), send `playerState`
   - Apply inbound remote snapshots
   - Render interpolated remote position

## 5. Wire Protocol

`NetMessage` (Codable enum):
- `hello(playerId: UUID)`
- `playerState(PlayerStatePacket)`
- `gameEvent(GameEventPacket)`
- `ping(ts: TimeInterval)`
- `pong(ts: TimeInterval)`

`PlayerStatePacket`:
- `playerId`
- `seq`
- `ts`
- `position`
- `velocity`

`RoomEnvelope`:
- `version`
- `type`
- `senderId`
- `role`
- `roomCode`
- `message`

### Protocol Rules

- Ignore out-of-order snapshots by `seq`.
- Keep envelope/message fields explicit and compact.
- Preserve backward compatibility for additive changes.
- Breaking changes require migration strategy and coordinated rollout.
- Server normalizes relay envelopes (`version`, `senderId`, `roomCode`) before broadcast to prevent client spoofing.

## 6. Simulation Strategy

- Local is authoritative for local player.
- Remote uses interpolation delay buffer.
- Extrapolation is bounded for missing future snapshots.
- Position is clamped to scene bounds.

## 7. Error Handling

- Transport failures update status text and avoid crash.
- Decode failures are surfaced in status diagnostics.
- Disconnect resets remote-connected state safely.
- WebSocket transport performs bounded reconnect attempts with exponential backoff and stale-attempt cancellation to avoid callback leaks after stop/new connect.
- Lobby flow returns users to a retriable state.
- Lobby flow emits session telemetry events for connect/disconnect/duration/reconnect-attempt tracking.

## 8. Performance Constraints

- Avoid heavy allocations in per-frame path.
- Keep packet payload compact.
- Keep send interval explicit and adjustable.

## 9. Testing Strategy

Unit tests:
- Wire encode/decode roundtrip
- Snapshot ordering/filtering
- Interpolation/extrapolation correctness
- Peer lifecycle callback transition sequencing
- Session envelope reduction (join/leave/role/relay callback outcomes)

Manual tests:
- Room create/join success
- Bidirectional movement
- Simultaneous movement stress
- Background/foreground reconnect behavior
- Network interruption behavior

## 10. Extension Plan

Near term:
- Add deterministic replay test harness for movement snapshots.
- Add reconnect handshake state machine.

Mid term:
- Add alternative transports behind `SessionTransport` if required.
- Add authoritative conflict resolution options (host-authoritative model).
