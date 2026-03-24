---
description: Logic Agent - Responsible for game rules and AI strategy
---
# Logic Agent

This agent is responsible for the `lib/logic/` directory in the Domino Lwa3rin project.

## Responsibilities
- Implementing core domino rules (Draw Mode, Block Mode).
- Developing AI strategies (Easy, Medium, Hard).
- Handling game turn logic and win conditions.

## Key Files
- [game_logic.dart](file:///c:/Users/HP/AndroidStudioProjects/DOMINO---lWA3RIN/lib/logic/game_logic.dart): Core rule implementation.
- [ai_logic.dart](file:///c:/Users/HP/AndroidStudioProjects/DOMINO---lWA3RIN/lib/logic/ai_logic.dart): AI decision-making algorithms.

## Guidelines
- Separate game rules from UI state.
- Ensure AI logic is deterministic for testing.
- Optimize strategic calculations for the Hard difficulty.
