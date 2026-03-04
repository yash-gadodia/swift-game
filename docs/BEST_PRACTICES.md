# Best Practices

## Workflow Practices

- Define acceptance criteria before implementation and keep them in the task/PR notes.
- Implement the smallest viable change that satisfies acceptance criteria.
- Run unit tests before merge; if a suite is not runnable, document the reason and risk.
- Update docs and tests in the same change when behavior or architecture shifts.

## Product Practices

- Validate risky assumptions with smallest shippable experiment.
- Prioritize player trust (stability, responsiveness, clarity).
- Define objective success metrics before implementation.

## Engineering Practices

- Keep state transitions explicit.
- Fail loudly in development, fail gracefully in production.
- Prefer composition over monolithic classes.
- Write tests for behavior, not implementation details.
- Keep hot-path (`update(_:)`) logic allocation-light and deterministic.
- Centralize network cadence constants so gameplay tuning is explicit and reversible.

## Multiplayer Practices

- Treat network as unreliable by default.
- Assume packets can arrive late, duplicated, or out of order.
- Separate local simulation from remote representation.
- Keep reconciliation strategy documented and deterministic.
- Ignore self-relayed movement messages and stale sequence numbers.
- Bound extrapolation windows so missing packets do not cause teleport-like drift.
- Keep disconnect/reconnect UX explicit (status text + non-crashing recovery path).

## Testing Practices

- Cover protocol compatibility with encode/decode roundtrip and backward-compatible decode tests.
- Add simulation edge-case tests for interpolation, extrapolation caps, and bounds clamping.
- Use descriptive test names that read as behavior contracts.
- Treat multiplayer regression cases (`connect`, `sync`, `disconnect`, `reconnect`) as release blockers when broken.

## Collaboration Practices

- No ambiguous tickets; acceptance criteria required.
- No “drive-by” refactors in feature PRs without scope alignment.
- Keep PRs focused and reviewable.
- Capture rationale for architectural decisions.

## Delivery Practices

- Demo frequently on physical devices.
- Maintain a running known-issues list.
- Ship vertical slices with measurable outcomes.
