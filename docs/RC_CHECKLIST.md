# Release Candidate Checklist (MVP)

Date:
Build:
Coordinator:

## Scope Lock
1. [ ] Transport scope decision resolved and documented.
2. [ ] `docs/PDD.md` and `docs/TDD.md` aligned with implementation.
3. [ ] Out-of-scope features explicitly deferred.

## Core Acceptance Criteria
1. [ ] AC-1: Two players connect via UI only.
Evidence:
2. [ ] AC-2: Player A movement visible on B.
Evidence:
3. [ ] AC-3: Player B movement visible on A.
Evidence:
4. [ ] AC-4: Disconnect does not crash app.
Evidence:
5. [ ] AC-5: App returns to lobby and can reattempt session.
Evidence:

## Multiplayer Regression Matrix
1. [ ] A hosts / B joins.
2. [ ] B hosts / A joins.
3. [ ] Simultaneous movement for 30 seconds.
4. [ ] One device background/foreground.
5. [ ] Temporary network interruption.

## Quality Gates
1. [ ] Unit tests pass.
Command:
Result:
2. [ ] Integration tests pass (if available).
Command:
Result:
3. [ ] No unresolved P0/P1 issues.
Issue list:

## Observability + UX
1. [ ] Lifecycle status text visible for connect/disconnect/errors.
2. [ ] RTT and PPS metrics visible in-game.
3. [ ] Required telemetry events emitted and documented.

## Performance + Stability
1. [ ] No known frame-loop allocation regressions in hot paths.
2. [ ] Packet cadence is explicit and configurable.
3. [ ] No critical crash in primary user journey.

## Documentation
1. [ ] Behavior changes reflected in docs.
2. [ ] Architecture/data-flow changes reflected in TDD.
3. [ ] Run/test instructions current in README.
4. [ ] Known limitations documented.

## Release Decision
1. [ ] Promote to RC.
2. [ ] Hold RC.
Reason:

## Rollback Plan
1. [ ] Rollback path verified for transport/session changes.
2. [ ] Recovery steps documented for support/dev team.
