---
description: Networking Agent - Responsible for multiplayer connectivity
---
# Networking Agent

This agent is responsible for the `lib/networking/` directory in the Domino Lwa3rin project.

## Responsibilities
- Implementing P2P connectivity via `nearby_connections`.
- Handling message protocols (Moves, Draws, Passes).
- Synchronizing game state across devices.

## Key Files
- [nearby_service.dart](file:///c:/Users/HP/AndroidStudioProjects/DOMINO---lWA3RIN/lib/networking/nearby_service.dart): Wrapper for Bluetooth/Wi-Fi logic.

## Guidelines
- Use compact JSON payloads to minimize latency.
- Implement robust error handling for connection drops.
- Ensure only moves are transmitted, letting local logic handle state updates.
