# Domino Lwa3rin — Flutter

Full port of the Domino Lwa3rin web game to Flutter with local Wi-Fi/Bluetooth multiplayer.

## Project Structure

```
lib/
├── main.dart                   # App entry point
├── models/
│   ├── tile.dart               # DominoTile, PlacedTile, deck helpers
│   ├── player.dart             # Player model (human / AI / network)
│   └── game_state.dart         # Immutable game state
├── logic/
│   ├── game_logic.dart         # Place tile, draw, end round (ported from app.js)
│   └── ai_logic.dart           # Easy / Medium / Hard AI (ported from app.js)
├── widgets/
│   ├── pip_grid.dart           # 3×3 pip dot grid
│   ├── domino_tile.dart        # Single tile widget (H/V, hidden, playable)
│   └── board_widget.dart       # Snake layout board (anchor-based, ported from app.js)
├── screens/
│   ├── game_provider.dart      # ChangeNotifier — all game state & actions
│   ├── menu_screen.dart        # Menu, mode select, difficulty, player names
│   ├── game_screen.dart        # Main game UI
│   └── nearby_screen.dart      # Wi-Fi/Bluetooth multiplayer lobby
├── networking/
│   └── nearby_service.dart     # nearby_connections wrapper — send/receive moves
└── i18n/
    └── translations.dart       # EN / FR / AR translations
```

## Setup

### 1. Install Flutter
```
https://docs.flutter.dev/get-started/install
```

### 2. Get dependencies
```bash
flutter pub get
```

### 3. Run
```bash
flutter run
```

## How multiplayer works

Both devices send only moves (not the full board):

```json
{ "tile": [6, 4], "tileId": 22, "side": "right", "type": "place" }
{ "type": "draw" }
{ "type": "pass" }
```

Both devices apply the same rules locally → boards stay perfectly in sync.

## Permissions required

### Android
- `BLUETOOTH_SCAN`, `BLUETOOTH_ADVERTISE`, `BLUETOOTH_CONNECT`
- `NEARBY_WIFI_DEVICES`
- `ACCESS_FINE_LOCATION`

### iOS
- `NSBluetoothAlwaysUsageDescription`
- `NSLocalNetworkUsageDescription`
- `NSLocationWhenInUseUsageDescription`

See `android/app/src/main/AndroidManifest.xml` and `ios/Runner/Info_additions.plist`.

## Features

- ✅ vs AI (Easy / Medium / Hard)
- ✅ Local multiplayer (2–4 players, pass the phone)
- ✅ Nearby multiplayer (Wi-Fi / Bluetooth P2P via `nearby_connections`)
- ✅ Draw Mode & Block Mode
- ✅ 2v2 Team Mode
- ✅ Snake board layout (same algorithm as web version)
- ✅ Turn timer
- ✅ Trilingual: English / French / Arabic
- ✅ Pip exhaustion rule
- ✅ Winner starts next round
