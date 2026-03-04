# Agent Swarm Playbook

## Goal
Run parallel implementation lanes for MVP while preserving multiplayer correctness and release discipline.

## Agent Topology

### Agent 0 - Program Lead
Branch: `codex/program-mvp-orchestration`

Responsibilities:
1. Resolve transport scope gate and update docs.
2. Maintain global dependency graph and merge queue.
3. Enforce release gate and block risky merges.

Outputs:
1. Scope decision record.
2. Daily status dashboard.
3. Final release readiness sign-off.

### Agent 1 - Transport Lifecycle
Branch: `codex/network-session-lifecycle`

Responsibilities:
1. Connect/disconnect/reconnect-safe state handling.
2. Two-player cap enforcement.
3. User-visible error/status transitions.

Outputs:
1. Session state transition table.
2. Lifecycle tests + manual matrix notes.

### Agent 2 - Protocol Safety
Branch: `codex/network-protocol-safety`

Responsibilities:
1. Add explicit protocol version field.
2. Preserve backward-compatible decoding for additive changes.
3. Sequence and duplicate handling tests.

Outputs:
1. Protocol schema change note in TDD.
2. Compatibility test coverage.

### Agent 3 - Simulation and Smoothing
Branch: `codex/game-remote-smoothing`

Responsibilities:
1. Harden interpolation/extrapolation behavior.
2. Keep bounded snapshot buffers.
3. Keep hot path allocation-free where possible.

Outputs:
1. Deterministic tests for interpolation/extrapolation.
2. Performance notes for frame loop.

### Agent 4 - Lobby/UI Flow
Branch: `codex/ui-lobby-flow-hardening`

Responsibilities:
1. Clear Host/Join or Create/Join flow text.
2. Prevent duplicate game presentation.
3. Ensure dead-end-free return-to-lobby behavior.

Outputs:
1. UI state diagram.
2. Manual UX sanity notes.

### Agent 5 - Input and Scene Loop
Branch: `codex/game-input-feel-tuning`

Responsibilities:
1. Tune D-pad responsiveness and velocity transitions.
2. Keep send cadence explicit and configurable.
3. Maintain deterministic local movement behavior.

Outputs:
1. Input-feel tuning constants with rationale.
2. Regression notes for input/network interaction.

### Agent 6 - Tests and CI Gates
Branch: `codex/qa-multiplayer-gates`

Responsibilities:
1. Expand unit test coverage (wire format, sequence, interpolation).
2. Add integration tests for lifecycle callback ordering.
3. Standardize local verification command set.

Outputs:
1. Updated `docs/TEST_STRATEGY.md` where needed.
2. Merge-blocking checklist script/notes.

### Agent 7 - Observability and Release
Branch: `codex/release-observability`

Responsibilities:
1. Implement required telemetry events.
2. Ensure user-visible status for lifecycle transitions.
3. Prepare release notes and known limitations.

Outputs:
1. Telemetry dictionary and event trigger map.
2. RC evidence bundle.

## Parallelization Rules
1. Agents may not modify the same file without explicit coordination from Agent 0.
2. Protocol changes merge before transport consumers.
3. Simulation changes merge before input tuning.
4. UI wording changes must track actual runtime states.

## Handoff Rules
1. Every PR includes:
- Acceptance criteria impact.
- Tests run + result.
- Manual matrix delta.
- Docs touched.
2. Every PR includes rollback statement:
- How to disable or revert behavior safely.

## Daily Cadence
1. Start of day:
- Agent 0 publishes merge order and blockers.
2. Midday:
- Agents rebase and report conflicts early.
3. End of day:
- RC checklist delta and P0/P1 status update.

## Merge Policy
1. P0/P1 defects block merge.
2. Untested protocol changes block merge.
3. Docs drift from behavior blocks merge.
4. Any reconnect regression blocks release candidate promotion.
