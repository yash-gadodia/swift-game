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
- Backend relay payload normalization/anti-spoofing behavior
- Reconnect retry policy bounds/backoff math

2. Integration Tests (near-term target)
- Transport callback sequencing
- Session lifecycle transitions (including repeated disconnect/reconnect loops)

3. Manual Device Tests (mandatory for multiplayer changes)
- Room create/join success
- Bidirectional movement
- Disconnect/reconnect behavior

## Required Manual Matrix

- Device A creates/enters room, B joins same room
- Device B creates/enters room, A joins same room
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

## Local Commands

- iOS/unit path: `xcodebuild -project SwiftGame.xcodeproj -scheme SwiftGame -destination 'platform=iOS Simulator,name=iPhone 17' test`
- Backend protocol tests: `cd backend && npm test`
