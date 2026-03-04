# Test Strategy

## Objectives

- Catch protocol breakages before runtime.
- Protect simulation correctness against regressions.
- Validate core multiplayer journey in realistic conditions.

## Test Pyramid

1. Unit Tests (mandatory)
- Wire serialization/deserialization
- Snapshot ordering/filtering
- Interpolation/extrapolation math

2. Integration Tests (near-term target)
- Transport callback sequencing
- Session lifecycle transitions

3. Manual Device Tests (mandatory for multiplayer changes)
- Host/Join success
- Bidirectional movement
- Disconnect/reconnect behavior

## Required Manual Matrix

- Device A hosts / B joins
- Device B hosts / A joins
- Simultaneous movement 30s
- One device background/foreground
- Temporary network interruption

## Failure Severity Levels

- P0: crash, deadlock, unrecoverable session break
- P1: incorrect remote state sync
- P2: UX/status inconsistency without state loss

P0/P1 block merge.

## CI Direction (Planned)

- Run unit tests on simulator destination.
- Add protocol compatibility checks.
- Enforce lint/style gate when introduced.

## Exit Checklist Before Merge

- Unit tests pass
- Manual matrix executed
- Any known deviations documented in PR notes
