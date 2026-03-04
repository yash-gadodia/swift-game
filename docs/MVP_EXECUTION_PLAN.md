# MVP Execution Plan

## Purpose
Ship a production-intent MVP for a 2-player co-op mobile game with multiplayer stability first, then input feel, then quality gates.

## Scope Decision Gate (Required Before Feature Work)
Current repository docs conflict with current implementation direction:
- `docs/PDD.md` + `docs/TDD.md`: nearby Host/Join flow.
- `README.md` + code: backend room-code + WebSocket flow.

Before any protocol or transport refactor, Agent 0 must choose one and align docs in a dedicated change:
1. Nearby-only MVP (Multipeer).
2. Room-code internet MVP (WebSocket backend).

No mixed-mode architecture for MVP unless explicitly scoped and documented.

## Acceptance Criteria (MVP)
1. Two players connect through in-app UI only.
2. Player A movement appears on Player B in near real time.
3. Player B movement appears on Player A in near real time.
4. Disconnect does not crash app.
5. App can return to lobby and reattempt session.
6. Session status text is visible for key lifecycle states.
7. Basic metrics visible in-game (RTT/PPS).

## Non-Functional Targets
1. No critical crash in primary connect/sync/disconnect flows.
2. Movement remains usable under jitter with interpolation and bounded extrapolation.
3. Send cadence is explicit and configurable.
4. Protocol and simulation remain isolated modules.

## Work Breakdown Structure

### Phase 0: Alignment + Gap Audit (Day 0)
Deliverables:
1. Transport decision PR (or docs alignment PR).
2. Gap matrix AC-1..AC-7 with pass/fail evidence by file/test/manual run.
3. Updated architecture/data-flow diagram in `docs/TDD.md` if changed.

Exit gate:
1. Scope and architecture mismatch resolved.
2. Agent lanes unblocked.

### Phase 1: Multiplayer Correctness (Week 1)
Deliverables:
1. Session lifecycle correctness (connect/disconnect/reconnect-safe states).
2. Sequence/out-of-order handling guarantees on movement snapshots.
3. No duplicate scene presentation or UI dead-end on state transitions.

Exit gate:
1. Zero P0/P1 in multiplayer manual matrix.

### Phase 2: Input + Movement Feel (Week 2)
Deliverables:
1. D-pad responsiveness tuning.
2. Stable remote interpolation under packet jitter.
3. Bounded extrapolation clamp and scene-bound clamping.

Exit gate:
1. Simultaneous 30s movement run passes both directions.

### Phase 3: Quality Gates + Observability (Week 3)
Deliverables:
1. Unit tests for protocol encode/decode, ordering, interpolation/extrapolation.
2. Integration tests for session lifecycle callback sequencing.
3. Telemetry events: host/join/discovered/connected/disconnected/duration.

Exit gate:
1. Green tests + manual matrix completed and recorded.

### Phase 4: Release Hardening (Week 4)
Deliverables:
1. Release notes + known limitations.
2. Rollback/fallback plan for transport/session failures.
3. RC checklist complete on two physical devices.

Exit gate:
1. Release standards satisfied.

## Dependency and Merge Order
1. Scope decision and docs alignment.
2. Protocol/transport safety changes.
3. Simulation smoothing + movement updates.
4. UI lifecycle/status polishing.
5. Testing/CI and observability.
6. Release docs.

## Mandatory Checks per PR
1. `xcodebuild -project SwiftGame.xcodeproj -scheme SwiftGame -destination 'platform=iOS Simulator,name=iPhone 17' test`
2. Manual matrix impact noted (`docs/TEST_STRATEGY.md`).
3. Docs updated if behavior/architecture changed.
4. Regression review for networking + input loop.

## Risk Register
1. Scope mismatch causing churn and rework.
Mitigation: resolve in Phase 0 before feature work.
2. Out-of-order/duplicate updates causing remote jitter spikes.
Mitigation: sequence guards + tests.
3. Reconnect lifecycle creating UI dead-end.
Mitigation: explicit state machine and manual matrix.
4. Hidden frame-loop allocations causing performance regressions.
Mitigation: profiling pass on `update(_:)` path before RC.
