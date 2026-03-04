# Agent Kickoff Prompts

Use each block in a separate Codex session.

## Agent 0 - Program Lead
You are Agent 0 (Program Lead) for SwiftGame MVP.
Tasks:
1. Resolve scope gate between nearby-host/join docs and room-code websocket implementation.
2. Produce a scope decision record and align `docs/PDD.md`, `docs/TDD.md`, `README.md`.
3. Create an AC gap matrix (AC-1..AC-5 minimum) with current pass/fail and evidence links.
Constraints:
- Follow AGENTS.md mandatory workflow.
- Escalate before any protocol-breaking change.
Done when:
- Scope mismatch is resolved in docs and merge order for all agents is published.

## Agent 1 - Transport Lifecycle
You are Agent 1 (Transport Lifecycle).
Tasks:
1. Audit `SessionTransport` lifecycle correctness for connect/disconnect/reconnect paths.
2. Prevent stale callbacks and state leaks when stopping/reconnecting.
3. Ensure UI status updates are deterministic and user-visible.
Deliver:
- Code changes + tests + manual matrix notes.
Done when:
- No crash/dead-end in connect/disconnect/reconnect manual flows.

## Agent 2 - Protocol Safety
You are Agent 2 (Protocol Safety).
Tasks:
1. Add protocol versioning strategy to message envelope/schema.
2. Keep backward-compatible decoding for additive evolution.
3. Add tests for out-of-order/duplicate sequence handling.
Deliver:
- Updated `NetMessages` + tests + TDD protocol note.
Done when:
- Protocol changes are tested and migration/compat notes are documented.

## Agent 3 - Simulation and Smoothing
You are Agent 3 (Simulation and Smoothing).
Tasks:
1. Validate interpolation and extrapolation behavior under missing snapshots.
2. Keep bounded snapshot buffer and bounded extrapolation.
3. Review frame-loop operations for avoidable allocations/churn.
Deliver:
- `GameState` improvements + deterministic unit tests.
Done when:
- Remote movement remains stable under jitter simulation tests.

## Agent 4 - Lobby/UI Flow
You are Agent 4 (Lobby/UI Flow).
Tasks:
1. Clarify status text for key lifecycle states and errors.
2. Eliminate duplicate game scene presentation risk.
3. Ensure return-to-lobby + reattempt flow remains smooth.
Deliver:
- UI flow hardening + manual UX test notes.
Done when:
- Lobby/game transitions are deterministic and non-blocking.

## Agent 5 - Input and Scene Loop
You are Agent 5 (Input + Scene Loop).
Tasks:
1. Tune D-pad movement feel and transition behavior.
2. Keep send cadence explicit and easy to tune.
3. Verify input/network interplay does not regress sync quality.
Deliver:
- Scene/input changes + rationale for tuning constants.
Done when:
- Local input feels responsive while remote remains stable.

## Agent 6 - Tests and CI Gates
You are Agent 6 (Tests + Gates).
Tasks:
1. Expand unit tests for protocol and simulation critical paths.
2. Add integration coverage for transport callback sequencing where possible.
3. Create a concise, repeatable local check command list.
Deliver:
- Test additions + updated test strategy docs.
Done when:
- P0/P1 regressions are blocked by tests/manual gates.

## Agent 7 - Observability and Release
You are Agent 7 (Observability + Release).
Tasks:
1. Implement and document MVP telemetry events.
2. Ensure lifecycle status diagnostics are visible to users/devs.
3. Prepare release notes + known limitations + fallback plan.
Deliver:
- Telemetry map + release artifact updates.
Done when:
- RC checklist can be completed with evidence.
