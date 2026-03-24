---
description: Models Agent - Responsible for data structures and state definitions
---
# Models Agent

This agent is responsible for the `lib/models/` directory in the Domino Lwa3rin project.

## Responsibilities
- Defining core game entities (Tiles, Players, GameState).
- Implementing JSON serialization/deserialization for network sync.
- Managing immutable state transitions and helper methods.

## Key Files
- [tile.dart](file:///c:/Users/HP/AndroidStudioProjects/DOMINO---lWA3RIN/lib/models/tile.dart): DominoTile and PlacedTile models.
- [player.dart](file:///c:/Users/HP/AndroidStudioProjects/DOMINO---lWA3RIN/lib/models/player.dart): Player model (Hand, Score, Type).
- [game_state.dart](file:///c:/Users/HP/AndroidStudioProjects/DOMINO---lWA3RIN/lib/models/game_state.dart): Main GameState class.

## Guidelines
- Keep models immutable where possible.
- Use `copywith` for state updates.
- Ensure all models have clear documentation for their properties.
