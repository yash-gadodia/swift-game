# Product Definition Document (PDD)

## 1. Problem Statement

Co-op mobile games often fail early due to unstable session setup and inconsistent real-time feedback, causing users to churn before engaging core gameplay.

## 2. Product Goal

Deliver a dependable co-op foundation where two players can discover, connect, and observe each other's movement in real time with clear session state and graceful recovery.

## 3. MVP Scope

In Scope:
- Nearby two-player session setup (Host/Join)
- Bidirectional movement sync
- Visible connection status
- Basic disconnect handling

Out of Scope:
- Combat/content systems
- >2 players
- Internet matchmaking/relay
- Persistence/progression

## 4. Personas

- Host Player: starts session quickly and expects others to join without friction.
- Join Player: discovers host and enters session with minimal taps.

## 5. Core User Stories

- As a host, I can create a nearby session and wait for one player.
- As a joiner, I can discover a host and connect.
- As either player, I can move and see remote movement in near real time.
- As either player, I receive clear feedback when connection drops.

## 6. Functional Requirements

FR-1 Lobby supports Host and Join paths.
FR-2 Join path presents discoverable peers.
FR-3 Session supports exactly two peers.
FR-4 Local movement input updates local avatar each frame.
FR-5 Local state is transmitted at fixed interval.
FR-6 Remote movement is smoothed to reduce jitter.
FR-7 Disconnect state is visible and non-crashing.
FR-8 App remains portrait-oriented for MVP.

## 7. Non-Functional Requirements

NFR-1 Stability: no critical crashes in primary session flow.
NFR-2 Latency: target <200ms local nearby conditions.
NFR-3 Clarity: status text available for key session states.
NFR-4 Maintainability: protocol and simulation logic are isolated modules.

## 8. UX Requirements

- Lobby includes:
  - Host button
  - Join button
  - Peer list
  - Connection status
- In-game includes:
  - D-pad movement
  - Local + remote player visibility
  - Basic metrics (RTT/PPS)
  - Disconnect indication

## 9. Acceptance Criteria

AC-1 Two devices connect through UI only.
AC-2 Player A movement appears on B.
AC-3 Player B movement appears on A.
AC-4 Disconnect does not crash app.
AC-5 App can return to lobby and reattempt session.

## 10. Telemetry Requirements (Near-Term)

Capture at minimum:
- `session_host_started`
- `session_peer_discovered`
- `session_connected`
- `session_disconnected`
- `session_duration_seconds`

## 11. Risks

- Nearby discovery inconsistency across environments.
- User confusion around network permissions.
- Movement jitter under variable network conditions.

## 12. Risk Mitigations

- Explicit host/join flow and clear status text.
- Permission-aware onboarding messaging.
- Interpolation + bounded extrapolation.

## 13. Release Gate

MVP is release-candidate only if:
- All acceptance criteria pass on two physical devices.
- Regression checklist passes for connect/disconnect/reconnect paths.
