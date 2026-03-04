# AGENTS.md

This file is the operating contract for humans and AI agents working in this repository.

## Mission

Build a commercially viable multiplayer pixel-art life/adventure game by enforcing production discipline from prototype stage.

## Product Priorities (In Order)

1. Multiplayer correctness and stability
2. Input responsiveness and movement feel
3. Reproducible build/test quality gates
4. UX clarity and onboarding
5. Content breadth

Do not trade (1) for (5).

## Engineering Principles

- Keep architecture simple until complexity is required by measured constraints.
- Prefer deterministic behavior over cleverness.
- Minimize hidden coupling between UI, networking, and simulation.
- Design for observability early (status text, metrics, logs, diagnostics).
- Every behavior change should be explainable in one sentence.

## Mandatory Workflow

1. Read relevant docs before coding:
   - `docs/PDD.md`
   - `docs/TDD.md`
   - `docs/ENGINEERING_STANDARDS.md`
2. Define acceptance criteria for the change.
3. Implement smallest viable delta.
4. Run local checks.
5. Update docs/tests in same change.

## Definition Of Done

A task is done only when all are true:
- Acceptance criteria met.
- Build passes.
- Tests pass or documented why not runnable.
- Regressions considered for networking + input loop.
- Docs updated if behavior/architecture changed.

## Multiplayer Guardrails

- Never introduce non-versioned wire-protocol breaking changes without migration plan.
- Keep packet format compact and explicit.
- Guard against out-of-order or duplicate state updates.
- All remote movement rendering must tolerate jitter.
- Disconnect/reconnect paths must fail gracefully (no crash, no UI dead-end).

## Performance Guardrails

- No frame-loop allocations in hot path unless justified.
- Avoid excessive object churn in `update(_:)`.
- Keep network send frequency explicit and configurable.
- Measure first, optimize second.

## Security And Privacy

- Only request required permissions.
- Keep network scope transparent in UX (nearby vs internet).
- Never log sensitive user identifiers unnecessarily.

## Branching + Commits

- Branch naming: `codex/<scope>-<short-description>`
- Commit style:
  - `feat(network): add snapshot interpolation clamp`
  - `fix(ui): prevent duplicate game scene presentation`
  - `docs(pdd): define reconnect acceptance criteria`

## Required Artifacts For Significant Features

Any medium/large feature must include:
- Product impact note (user-facing outcome)
- Technical design note (data flow + interfaces)
- Test plan update
- Rollback/fallback plan

## Escalation Triggers

Stop and escalate before coding when:
- Requirement conflicts with PDD priorities
- Behavior changes protocol compatibility
- Change risks destabilizing multiplayer loop
- Unclear ownership of critical system decisions

## Anti-Patterns (Do Not Do)

- Building content systems before network core is reliable
- Mixing simulation state with UIKit view state
- Silent retries without user-visible status
- Feature creep in MVP milestones
- Merging untested protocol changes

## Source Of Truth

If docs conflict:
1. `docs/PDD.md` (what we build)
2. `docs/TDD.md` (how we build it)
3. `docs/ENGINEERING_STANDARDS.md` (quality bar)
4. README (execution quickstart)
