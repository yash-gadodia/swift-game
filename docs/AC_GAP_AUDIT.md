# AC Gap Audit (Phase 0)

Date: 2026-03-04
Scope baseline: Room-code + WebSocket MVP

## Summary

- AC-1: Partial pass (simulator/dev environment path verified in code; physical-device evidence pending)
- AC-2: Pass in code path, manual physical-device evidence pending
- AC-3: Pass in code path, manual physical-device evidence pending
- AC-4: Partial pass (disconnect handling exists; reconnect edge-state hardening pending)
- AC-5: Partial pass (retry path exists; explicit recovery matrix evidence pending)

## AC-1: Two clients connect through UI-only room-code flow

Status: Partial pass

Evidence:
- Lobby play path calls room entry + socket connect: `SwiftGame/UI/LobbyViewController.swift`
- Transport emits room/peer callbacks: `SwiftGame/Networking/MultipeerSessionManager.swift`
- Scene presentation gated on role/level/peer presence: `SwiftGame/UI/LobbyViewController.swift`

Gap:
- No recorded two-physical-device evidence in docs/RC checklist yet.

Action:
- Agent 1 + Agent 6 execute matrix and log evidence in `docs/RC_CHECKLIST.md`.

## AC-2: Player A movement appears on B

Status: Pass in implementation, evidence pending

Evidence:
- Send cadence + player state packet emission: `SwiftGame/Scenes/GameScene.swift`
- Inbound remote snapshot application: `SwiftGame/Scenes/GameScene.swift`
- Snapshot ordering and interpolation logic: `SwiftGame/Game/GameState.swift`

Gap:
- Need documented physical-device run result and timing observations.

Action:
- Agent 3 validates under jitter/background transitions and records behavior.

## AC-3: Player B movement appears on A

Status: Pass in implementation, evidence pending

Evidence:
- Symmetric packet handling in `GameScene.handle(message:)`: `SwiftGame/Scenes/GameScene.swift`
- Protocol roundtrip tests exist: `SwiftGameTests/NetMessagesTests.swift`

Gap:
- No explicit bidirectional manual evidence bundle yet.

Action:
- Agent 6 records bidirectional matrix execution and outcomes.

## AC-4: Disconnect does not crash app

Status: Partial pass (improved)

Evidence:
- Transport failure and peer-left callbacks update status text: `SwiftGame/Networking/MultipeerSessionManager.swift`
- Scene updates disconnect status safely: `SwiftGame/Scenes/GameScene.swift`

Gap:
- Need physical-device evidence that bounded reconnect backoff converges correctly under repeated network drops and app background/foreground transitions.

Action:
- Agent 1 added transport reconnect hardening with bounded exponential backoff + stale-attempt cancellation in `WebSocketSessionManager`.
- Agent 6 validates repeated disconnect/reconnect matrix on two physical devices and records outcome in `docs/RC_CHECKLIST.md`.

## AC-5: App can return to lobby and reattempt session

Status: Partial pass

Evidence:
- Lobby remains active and can retry Play.
- `hasPresentedGame` reset on peer disconnect path: `SwiftGame/UI/LobbyViewController.swift`

Gap:
- Need explicit end-to-end proof for return from active game, retry, and successful reconnect.

Action:
- Agent 4 + Agent 6 add manual runbook steps and evidence capture in RC checklist.

## Cross-Cutting Gaps

1. Protocol versioning rollout and compatibility verification.
- Status: Implemented in `RoomEnvelope.version` with backward-compatible decoding.
- Status update: Backend now normalizes relay envelope `version` and authoritative `senderId`/`roomCode` fields before broadcast.
- Verification: `cd backend && npm test` passes (`normalizeRelayPayload` test suite).
- Owner: Agent 2 (follow-up: compatibility rollout tests across mixed app versions)
2. Integration tests for transport callback ordering are limited.
- Status update: Added deterministic peer lifecycle transition tests in `SessionLifecycleTrackerTests`.
- Owner: Agent 6 (follow-up: full manager callback sequencing integration tests with transport/socket stubs)
3. Telemetry persistence and backend ingestion are not yet implemented.
- Status update: Client now emits required lobby events to backend `POST /telemetry`, and backend stores recent telemetry in bounded memory + optional Redis list (`swiftgame:telemetry`).
- Verification: `cd backend && npm test` passes telemetry sanitization tests.
- Owner: Agent 7 (follow-up: production analytics sink, dashboards, and alerting)

## Phase 0 Exit Criteria

1. PDD/TDD/Test Strategy aligned to room-code scope. (Done)
2. AC audit created with owners and actions. (Done)
3. Physical-device evidence capture started in RC checklist. (Pending)
4. Local `xcodebuild test` command currently blocked in this environment by signing configuration (`Signing for "SwiftGame" requires a development team`).
