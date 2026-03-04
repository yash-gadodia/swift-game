# Merge Split Plan (Parallel Agent Work)

Date: 2026-03-04

## Goal

Merge concurrent agent outputs with minimal conflicts by grouping changes into clear lanes.

## Lane A: Networking + Protocol Safety

Files:
- `SwiftGame/Networking/NetMessages.swift`
- `SwiftGame/Networking/MultipeerSessionManager.swift`
- `SwiftGameTests/NetMessagesTests.swift`
- `SwiftGameTests/GameStateTests.swift`
- `SwiftGameTests/SessionLifecycleTrackerTests.swift`

Validation:
- iOS unit tests (`NetMessagesTests`, `GameStateTests`, `SessionLifecycleTrackerTests`)
- Manual connect/disconnect/reconnect callback sanity

Suggested commands:
- `git add SwiftGame/Networking/NetMessages.swift SwiftGame/Networking/MultipeerSessionManager.swift SwiftGameTests/NetMessagesTests.swift SwiftGameTests/GameStateTests.swift SwiftGameTests/SessionLifecycleTrackerTests.swift SwiftGameTests/SessionEnvelopeReducerTests.swift`
- `git commit -m "feat(network): harden session lifecycle and protocol envelope compatibility"`

## Lane B: Backend Relay Safety

Files:
- `backend/src/protocol.js`
- `backend/src/server.js`
- `backend/tests/protocol.test.mjs`
- `backend/package.json`

Validation:
- `cd backend && npm test`
- `node --check src/server.js`

Suggested commands:
- `git add backend/src/protocol.js backend/src/server.js backend/tests/protocol.test.mjs backend/package.json`
- `git commit -m "feat(backend): normalize relay envelopes and add protocol safety tests"`

## Lane C: Product/Architecture/Test Docs

Files:
- `docs/PDD.md`
- `docs/TDD.md`
- `docs/TEST_STRATEGY.md`
- `docs/AC_GAP_AUDIT.md`
- `docs/MVP_EXECUTION_PLAN.md`
- `docs/AGENT_SWARM_PLAYBOOK.md`
- `docs/AGENT_KICKOFF_PROMPTS.md`
- `docs/RC_CHECKLIST.md`

Validation:
- Scope and architecture language consistent with room-code WebSocket MVP
- Gaps and owners mapped to active lanes

Suggested commands:
- `git add docs/PDD.md docs/TDD.md docs/TEST_STRATEGY.md docs/AC_GAP_AUDIT.md docs/MVP_EXECUTION_PLAN.md docs/AGENT_SWARM_PLAYBOOK.md docs/AGENT_KICKOFF_PROMPTS.md docs/RC_CHECKLIST.md docs/MERGE_SPLIT_PLAN.md`
- `git commit -m "docs(mvp): align scope, quality gates, and merge operations"`

## Lane D: UI/UX (Other Agent Session)

Files (owned by UI lane):
- `SwiftGame/UI/LobbyViewController.swift`
- `SwiftGame/UI/GameViewController.swift`
- `SwiftGame/UI/VirtualDPad.swift`
- `SwiftGame/Scenes/GameScene.swift`

Validation:
- UX/device pass
- No regressions in input responsiveness and session status visibility

## Suggested Merge Order

1. Lane B (backend relay safety)
2. Lane A (networking/protocol safety)
3. Lane D (UI/UX)
4. Lane C (final docs reconciliation)

## Conflict Notes

- `LobbyViewController.swift` is shared concern (UI + telemetry). Keep telemetry semantics stable if UI lane rebases.
- After Lane D merge, re-run AC matrix and update `docs/RC_CHECKLIST.md`.
