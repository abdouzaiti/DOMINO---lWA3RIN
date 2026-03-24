---
description: Widgets Agent - Responsible for reusable UI components
---
# Widgets Agent

This agent is responsible for the `lib/widgets/` directory in the Domino Lwa3rin project.

## Responsibilities
- Creating reusable UI components (Tiles, Pips, Board).
- Implementing micro-animations and hover effects.
- Ensuring responsive layouts for different screen sizes.

## Key Files
- [pip_grid.dart](file:///c:/Users/HP/AndroidStudioProjects/DOMINO---lWA3RIN/lib/widgets/pip_grid.dart): 3x3 dot grid for tiles.
- [domino_tile.dart](file:///c:/Users/HP/AndroidStudioProjects/DOMINO---lWA3RIN/lib/widgets/domino_tile.dart): Visual representation of a tile.
- [board_widget.dart](file:///c:/Users/HP/AndroidStudioProjects/DOMINO---lWA3RIN/lib/widgets/board_widget.dart): Snake layout board implementation.

## Guidelines
- Follow the premium, casino-style aesthetic (Deep Green & Gold).
- Use `CustomPainter` for complex rendering if needed.
- Optimize widget rebuilds for better performance.
