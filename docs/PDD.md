# Product Definition Document (PDD)

## 1. Problem Statement

Co-op mobile games often fail early due to unstable session setup and inconsistent real-time feedback, causing users to churn before engaging core gameplay.

## 2. Product Goal

Deliver a dependable co-op foundation where two players can connect with minimal friction, observe each other's movement in real time, and recover cleanly from disconnects.

## 3. MVP Scope

In Scope:
- Two-player room-code session setup (Create/Join)
- Bidirectional movement sync
- Visible connection status
- Basic disconnect handling and lobby recovery

Out of Scope:
- Combat/content systems beyond MVP scene loop
- More than 2 players
- Matchmaking beyond direct room-code flow
- Persistence/progression systems

## 4. Personas

- Room Creator: starts a room quickly and expects one partner to join with a code.
- Join Player: enters a room code and joins with minimal taps.

## 5. Core User Stories

- As a room creator, I can create or enter a 4-digit room and wait for one partner.
- As a joiner, I can enter a room code and connect quickly.
- As either player, I can move and see remote movement in near real time.
- As either player, I receive clear feedback when connection drops and can reattempt.

## 6. Functional Requirements

FR-1 Lobby supports room-code play flow and clear status messages.
FR-2 Session supports exactly two peers.
FR-3 Local movement input updates local avatar each frame.
FR-4 Local state is transmitted at fixed interval.
FR-5 Remote movement is smoothed to reduce jitter.
FR-6 Disconnect state is visible and non-crashing.
FR-7 Player can return to lobby and reattempt session.
FR-8 App remains portrait-oriented for MVP.

## 7. Non-Functional Requirements

NFR-1 Stability: no critical crashes in primary session flow.
NFR-2 Latency: target <200ms under normal local network conditions.
NFR-3 Clarity: status text available for key session states.
NFR-4 Maintainability: protocol and simulation logic are isolated modules.

## 8. UX Requirements

- Lobby includes:
  - Server URL input (dev)
  - Room code input
  - Play action
  - Connection status
  - High-contrast status card and clear primary/secondary action hierarchy
- In-game includes:
  - D-pad movement
  - Local + remote player visibility
  - Basic metrics (RTT/PPS)
  - Disconnect indication
  - Top HUD with room/role context and objective copy
  - Theme-reactive scene palette driven by daily level metadata
  - Optional ambient audio with in-session sound toggle
  - Theme-aware soundtrack profile (forest/ember/twilight tonal variants)
  - Lightweight in-session tuning panel for FX intensity and haptics
  - Movement and connection feedback effects (visual + audio) that do not block gameplay

## 9. Acceptance Criteria

AC-1 Two clients connect through UI-only room-code flow.
AC-2 Player A movement appears on B.
AC-3 Player B movement appears on A.
AC-4 Disconnect does not crash app.
AC-5 App can return to lobby and reattempt session.

## 10. Telemetry Requirements (Near-Term)

Capture at minimum:
- `session_room_join_started`
- `session_connected`
- `session_disconnected`
- `session_duration_seconds`
- `session_reconnect_attempted`

## 11. Risks

- Room-code connection failures due to backend or network environment issues.
- User confusion around server URL in development builds.
- Movement jitter under variable network conditions.

## 12. Risk Mitigations

- Clear room-code entry and connection status text.
- Friendly error messaging and retry path.
- Interpolation + bounded extrapolation.

## 13. Release Gate

MVP is release-candidate only if:
- All acceptance criteria pass on two physical devices.
- Regression checklist passes for connect/disconnect/reconnect paths.
