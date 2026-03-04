# Engineering Standards

## 1. Quality Bar

This codebase is run with production intent. "Prototype" is not a waiver for poor engineering.

## 2. Coding Standards

- Use clear, explicit naming over abbreviation.
- Keep methods focused and single-purpose.
- Prefer value semantics for message/data models.
- Keep side effects localized and traceable.

## 3. Architecture Standards

- UI must not own networking rules.
- Networking must not mutate SpriteKit nodes directly.
- Simulation logic should remain testable outside rendering.
- New modules require clear ownership boundary.

## 4. Networking Standards

- Message format changes require test updates.
- Sequence handling required for state packets.
- Avoid silent packet drops without diagnostics.
- Keep send cadence constants centralized.

## 5. Testing Standards

Minimum for feature merge:
- Relevant unit tests added/updated
- Existing tests pass
- Manual multiplayer sanity flow executed

Test names should describe behavior and expected outcome.

## 6. Observability Standards

- User-visible status for connection lifecycle.
- Developer-facing logs for transport failures.
- Metrics fields remain stable across versions when possible.

## 7. Documentation Standards

When behavior changes, update:
- `docs/PDD.md` if product behavior changes
- `docs/TDD.md` if architecture/data flow changes
- `README.md` if run/test instructions change

## 8. Performance Standards

- Keep frame update allocations minimal.
- Prefer preallocated or bounded buffers in simulation paths.
- Benchmark before and after optimization changes.

## 9. Security/Privacy Standards

- Only request permissions needed for current feature set.
- Use minimum network scope required.
- Do not persist sensitive identifiers without explicit reason.

## 10. Release Standards

A release candidate requires:
- Crash-free primary flows in manual two-device run
- Green tests
- No known blocker in connect/join/sync/disconnect paths
- Updated release notes + known limitations
