---
description: Screens Agent - Responsible for app screens and overall state
---
# Screens Agent

This agent is responsible for the `lib/screens/` directory in the Domino Lwa3rin project.

## Responsibilities
- Managing main app screens (Menu, Game, Lobby).
- Integrating state management via the `Provider` package.
- Implementing navigation and overlays (Round Over, Match Over).

## Key Files
- [game_provider.dart](file:///c:/Users/HP/AndroidStudioProjects/DOMINO---lWA3RIN/lib/screens/game_provider.dart): Central state container.
- [menu_screen.dart](file:///c:/Users/HP/AndroidStudioProjects/DOMINO---lWA3RIN/lib/screens/menu_screen.dart): Landing page and setup.
- [game_screen.dart](file:///c:/Users/HP/AndroidStudioProjects/DOMINO---lWA3RIN/lib/screens/game_screen.dart): Primary gameplay interface.

## Guidelines
- Keep build methods lean; move logic to the Provider.
- Implement clear transitions between screens.
- Ensure all user inputs are validated before triggering state changes.
