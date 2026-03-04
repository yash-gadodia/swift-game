# SwiftGame

A native Swift + SpriteKit multiplayer game foundation focused on one hard proof first: two devices discover each other and render synchronized movement in real time.

## Why This Exists

Most game projects fail by overbuilding before proving core technical risk. This project takes the opposite approach:
- Prove real-time multiplayer reliability first.
- Build a disciplined product + engineering system around that proof.
- Expand gameplay only after the networked core is stable.

This repository is intentionally structured to support a long-term product, not just a prototype.

## Current MVP Status

Implemented:
- Native iOS app using SpriteKit.
- Nearby peer discovery/connection via `MultipeerConnectivity`.
- Host/Join lobby flow.
- Two-player movement sync at fixed tick rate.
- Remote interpolation smoothing.
- Basic disconnect handling.
- Unit tests for message codec and interpolation.

Not implemented yet:
- Internet relay/server architecture.
- Combat/progression/economy loops.
- World persistence.
- Content pipeline and production art system.

## Fast Start

### Prerequisites
- macOS with Xcode 26+
- iOS simulator runtime installed
- Apple developer signing configured in Xcode for physical device runs

### Build
```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project SwiftGame.xcodeproj \
-scheme SwiftGame \
-destination 'generic/platform=iOS Simulator' build
```

### Test
```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project SwiftGame.xcodeproj \
-scheme SwiftGame \
-destination 'platform=iOS Simulator,name=iPhone 17' test
```

## Two-Instance Simulation Test

For local multiplayer sanity checks with two simulators:
1. Open two simulator devices (for example `iPhone 17` and `iPhone 17 Pro`).
2. Launch app on simulator A.
3. Launch app on simulator B.
4. In A: `Host Game`.
5. In B: `Join Game` and select A.
6. Confirm both players can move and see each other.

If Xcode prompts `Replace "SwiftGame"`, enable multiple instances in scheme Run settings.

## Two-Physical-Device Test

1. Install app on iPhone A and iPhone B.
2. Ensure both devices allow Local Network permissions for SwiftGame.
3. On A: tap `Host Game`.
4. On B: tap `Join Game` and select A.
5. Validate bidirectional movement sync and disconnect behavior.

## Project Layout

- `SwiftGame/`
  - `App/` lifecycle, scene bootstrap, plist
  - `Networking/` transport + wire protocol
  - `Game/` deterministic shared state + interpolation
  - `Scenes/` SpriteKit simulation/render loop
  - `UI/` lobby, controls, game container
- `SwiftGameTests/` unit tests
- `docs/` strategy, product and engineering specs
- `AGENTS.md` operating contract for engineers/agents

## Documentation Index

- [AGENTS.md](/Users/yash/Documents/Voltade/Code/swift-game/AGENTS.md)
- [Product Vision](/Users/yash/Documents/Voltade/Code/swift-game/docs/PRODUCT_VISION.md)
- [Product Requirements (PDD)](/Users/yash/Documents/Voltade/Code/swift-game/docs/PDD.md)
- [Technical Design (TDD)](/Users/yash/Documents/Voltade/Code/swift-game/docs/TDD.md)
- [Engineering Standards](/Users/yash/Documents/Voltade/Code/swift-game/docs/ENGINEERING_STANDARDS.md)
- [Best Practices](/Users/yash/Documents/Voltade/Code/swift-game/docs/BEST_PRACTICES.md)
- [Test Strategy](/Users/yash/Documents/Voltade/Code/swift-game/docs/TEST_STRATEGY.md)
- [Roadmap](/Users/yash/Documents/Voltade/Code/swift-game/docs/ROADMAP.md)

## Non-Negotiables

- No gameplay feature ships without measurable acceptance criteria.
- No networking behavior changes without deterministic test coverage updates.
- No visual/content expansion before stability gates remain green.
- Every change must preserve MVP multiplayer reliability.
