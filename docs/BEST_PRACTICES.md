# Best Practices

## Product Practices

- Validate risky assumptions with smallest shippable experiment.
- Prioritize player trust (stability, responsiveness, clarity).
- Define objective success metrics before implementation.

## Engineering Practices

- Keep state transitions explicit.
- Fail loudly in development, fail gracefully in production.
- Prefer composition over monolithic classes.
- Write tests for behavior, not implementation details.

## Multiplayer Practices

- Treat network as unreliable by default.
- Assume packets can arrive late, duplicated, or out of order.
- Separate local simulation from remote representation.
- Keep reconciliation strategy documented and deterministic.

## Collaboration Practices

- No ambiguous tickets; acceptance criteria required.
- No “drive-by” refactors in feature PRs without scope alignment.
- Keep PRs focused and reviewable.
- Capture rationale for architectural decisions.

## Delivery Practices

- Demo frequently on physical devices.
- Maintain a running known-issues list.
- Ship vertical slices with measurable outcomes.
