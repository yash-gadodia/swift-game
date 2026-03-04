# Technical Design Document (TDD)

## 1. System Overview

The app is a native iOS SpriteKit client with three core layers:
- UI Layer: lobby and controls
- Simulation Layer: local/remote state and interpolation
- Transport Layer: nearby peer networking and message dispatch

## 2. Architectural Goals

- Keep simulation deterministic and independent from transport details.
- Keep networking serialization explicit and versionable.
- Keep frame loop lean and observable.

## 3. Module Breakdown

### `Networking/`
- `NetMessages.swift`
  - Wire-level message schema
- `MultipeerSessionManager.swift`
  - Peer discovery, connection, send/receive callbacks

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

### `UI/`
- `LobbyViewController.swift`
  - Host/Join flow, peer list
- `GameViewController.swift`
  - Scene container + control overlays
- `VirtualDPad.swift`
  - Direction vector input component

## 4. Data Flow

1. User starts Host or Join in Lobby.
2. Transport layer establishes session and emits connection callbacks.
3. On connection, game scene starts and sends `hello`.
4. Each frame:
   - Local input -> local velocity/position
   - At fixed tick (20Hz), send `playerState`
   - Apply inbound remote snapshots
   - Render interpolated remote position

## 5. Wire Protocol

`NetMessage` (Codable enum):
- `hello(playerId: UUID)`
- `playerState(PlayerStatePacket)`
- `ping(ts: TimeInterval)`
- `pong(ts: TimeInterval)`

`PlayerStatePacket`:
- `playerId`
- `seq`
- `ts`
- `position`
- `velocity`

### Protocol Rules

- Ignore out-of-order snapshots by `seq`.
- Preserve backward compatibility for future protocol versions.
- Additive changes preferred; breaking changes require migration strategy.

## 6. Simulation Strategy

- Local is authoritative for local player.
- Remote uses interpolation delay buffer.
- Extrapolation bounded for missing future snapshots.
- Position clamped to scene bounds.

## 7. Error Handling

- Transport failures update status text and avoid crash.
- Decode failures are surfaced in status diagnostics.
- Disconnect resets remote-connected state safely.

## 8. Performance Constraints

- Avoid heavy allocations in per-frame path.
- Keep packet payload compact.
- Keep send interval explicit and adjustable.

## 9. Testing Strategy

Unit tests:
- Wire encode/decode roundtrip
- Interpolation/extrapolation correctness

Manual tests:
- Host/join discovery
- Bidirectional movement
- Simultaneous movement stress
- Background/foreground reconnect handling
- Network interruption behavior

## 10. Extension Plan

Near term:
- Add explicit protocol version field.
- Add deterministic replay test harness for movement snapshots.
- Add reconnect handshake state machine.

Mid term:
- Abstract transport for internet-backed mode.
- Add authoritative conflict resolution options (host-authoritative model).
