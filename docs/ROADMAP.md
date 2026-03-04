# Roadmap

## Phase 1: Multiplayer Trust (Current)

Goal:
- Prove stable two-player nearby sync.

Deliverables:
- Host/Join
- Movement sync + interpolation
- Disconnect handling
- Core diagnostics

Exit Criteria:
- Reproducible two-device session success
- No critical crash in smoke tests

## Phase 2: Shared Interaction Loop

Goal:
- Add first cooperative objective loop.

Deliverables:
- Simple interactive objects
- Shared state mutation events
- Conflict-safe interaction rules

Exit Criteria:
- Players can complete repeatable co-op objective
- State stays consistent under jitter/disconnect

## Phase 3: Persistence + Progression

Goal:
- Make sessions meaningful over time.

Deliverables:
- Save system
- Basic economy/progression state
- Session resume behavior

Exit Criteria:
- Progress survives restarts
- Sync + persistence consistency verified

## Phase 4: Content + Polish

Goal:
- Increase retention via content depth and craft.

Deliverables:
- Pixel-art character/environment pipeline
- Audio/feedback polish
- Expanded co-op activities

Exit Criteria:
- Retention and session metrics improve against baseline

## Cross-Phase Rules

- Do not advance phase with unresolved P0 networking issues.
- Keep docs/specs updated each phase transition.
- Every phase must have measurable acceptance gates.
