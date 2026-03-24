import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import '../models/tile.dart';
import '../models/player.dart';
import '../models/game_state.dart';
import '../logic/game_logic.dart';
import '../logic/ai_logic.dart';
import '../logic/profile_service.dart';
import '../networking/nearby_service.dart';
import '../networking/firebase_service.dart';

class GameProvider extends ChangeNotifier {
  GameState? _state;
  GameState? get state => _state;

  String _lang = 'en';
  String get lang => _lang;

  bool _soundEnabled = true;
  bool get soundEnabled => _soundEnabled;

  String _tileSkin = 'classic';
  String get tileSkin => _tileSkin;

  String _boardColor = 'green';
  String get boardColor => _boardColor;

  // Timer
  Timer? _timer;
  int _timerRemaining = 30;
  int get timerRemaining => _timerRemaining;

  // Chat
  final List<ChatMessage> chatMessages = [];

  // Persistence
  final ProfileService _profileService = ProfileService();
  Player? _userProfile;
  Player? get userProfile => _userProfile;

  // Audio & Feedback
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Network
  final NearbyService nearbyService = NearbyService();
  final FirebaseService firebaseService = FirebaseService();
  bool get isNetworkGame =>
      _state?.players.any((p) => p.isNetwork) ?? false;

  bool _isOnlineMatch = false;
  bool get isOnlineMatch => _isOnlineMatch;
  String? _onlineGameId;

  void _triggerFeedback() async {
    if (!_soundEnabled) return;
    try {
      // Play a real tile sound
      await _audioPlayer.play(AssetSource('sounds/tile_place.mp3'));
      // Haptic vibration
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: 50);
      }
    } catch (e) {
      debugPrint('Feedback error: $e');
    }
  }

  GameProvider() {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    _userProfile = await _profileService.loadProfile();
    final settings = await _profileService.loadSettings();
    _tileSkin = settings['tileSkin'] ?? 'classic';
    _boardColor = settings['boardColor'] ?? 'green';
    notifyListeners();
  }

  Future<void> saveUserProfile(Player p) async {
    _userProfile = p;
    await _profileService.saveProfile(p);
    notifyListeners();
  }

  void setLang(String l) {
    _lang = l;
    notifyListeners();
  }

  void setSoundEnabled(bool v) {
    _soundEnabled = v;
    notifyListeners();
  }

  // ── Game setup ──────────────────────────────────────────────

  void startVsAI({
    required AIDifficulty difficulty,
    required GameRule rule,
    String? boardColor,
    bool isTurbo = false,
  }) {
    final players = [
      _userProfile?.copyWith(index: 0, type: PlayerType.human) ??
          Player(index: 0, name: 'Player', type: PlayerType.human),
      Player(index: 1, name: 'AI', type: PlayerType.ai, difficulty: difficulty),
    ];
    _initGame(players: players, rule: rule, boardColor: boardColor ?? _boardColor, isTurbo: isTurbo);
  }

  void startLocalMulti({
    required List<String> names,
    required GameRule rule,
    required String boardColor,
    required bool teamMode,
    bool isTurbo = false,
  }) {
    final players = List.generate(
      names.length,
      (i) => Player(
        index: i,
        name: names[i],
        type: PlayerType.human,
        team: i % 2,
      ),
    );
    _initGame(players: players, rule: rule, boardColor: boardColor, teamMode: teamMode, isTurbo: isTurbo);
  }

  void _initGame({
    required List<Player> players,
    required GameRule rule,
    required String boardColor,
    bool teamMode = false,
    bool isTurbo = false,
  }) {
    final deck = shuffleDeck(makeDeck());
    final tilesEach = players.length == 4 ? 5 : 7;
    int offset = 0;
    final dealtPlayers = players.map((p) {
      final hand = deck.sublist(offset, offset + tilesEach);
      offset += tilesEach;
      return p.copyWith(hand: hand, score: 0);
    }).toList();
    final boneyard = deck.sublist(offset);

    // Find best starting player (highest double)
    int firstIdx = 0;
    DominoTile? bestTile;
    for (int i = 0; i < dealtPlayers.length; i++) {
      final t = GameLogic.bestStartTile(dealtPlayers[i].hand);
      if (t != null && (bestTile == null || t.total > bestTile.total)) {
        bestTile = t;
        firstIdx = i;
      }
    }

    _state = GameState(
      players: dealtPlayers,
      board: [],
      boneyard: boneyard,
      currentPlayerIndex: firstIdx,
      rule: rule,
      phase: GamePhase.playing,
      teamMode: teamMode,
      teamScores: [0, 0],
      boardColor: boardColor,
      timerEnabled: true,
      timerDuration: isTurbo ? 10 : 30,
      isTurbo: isTurbo,
    );

    _isOnlineMatch = false; // Reset for local games
    _onlineGameId = null;

    _startTurn();
    notifyListeners();
  }

  void startOnlineGame({
    required List<Player> players,
    required String gameId,
  }) {
    _isOnlineMatch = true;
    _onlineGameId = gameId;
    
    // For Wave 3, we'll use a simplified online start.
    // In a full sync, the Host would share the deck.
    _initGame(
      players: players,
      rule: GameRule.draw,
      boardColor: 'green',
    );
    
    _isOnlineMatch = true; // Set again as _initGame resets it
    _onlineGameId = gameId;

    firebaseService.listenForMoves(gameId, (move) {
      if (move['type'] == 'place') {
        final tile = DominoTile(id: move['tileId'], sideA: move['sideA'], sideB: move['sideB']);
        final newState = GameLogic.placeTile(_state!, tile, move['side']);
        if (newState != null) {
          _state = newState;
          _triggerFeedback();
          notifyListeners();
          _afterPlace(newState.currentPlayerIndex);
        }
      }
    });
  }

  // ── Turn management ──────────────────────────────────────────

  void _startTurn() {
    _stopTimer();
    final s = _state;
    if (s == null) return;

    if (s.timerEnabled) {
      _timerRemaining = s.timerDuration;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        _timerRemaining--;
        if (_timerRemaining <= 0) {
          _stopTimer();
          _autoPass();
        }
        notifyListeners();
      });
    }

    // Trigger AI move after short delay
    if (s.currentPlayer.isAI) {
      Future.delayed(const Duration(milliseconds: 700), _doAITurn);
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _autoPass() {
    final s = _state;
    if (s == null) return;
    if (s.rule == GameRule.draw && s.boneyard.isNotEmpty) {
      playerDraw();
    } else {
      playerPass();
    }
  }

  // ── Player actions ───────────────────────────────────────────

  void playerPlace(DominoTile tile, String side) {
    var s = _state;
    if (s == null || s.phase != GamePhase.playing) return;
    if (s.currentPlayer.isAI) return;

    final newState = GameLogic.placeTile(s, tile, side);
    if (newState == null) return;

    _state = newState;
    _triggerFeedback();
    notifyListeners();

    if (_isOnlineMatch && _onlineGameId != null) {
      firebaseService.syncMove(_onlineGameId!, {
        'type': 'place',
        'tileId': tile.id,
        'sideA': tile.sideA,
        'sideB': tile.sideB,
        'side': side,
      });
    }

    if (isNetworkGame) {
      nearbyService.sendMove(NetworkMove.place(tile.id, tile.sideA, tile.sideB, side));
    }

    _afterPlace(newState.currentPlayerIndex);
  }

  void playerDraw() {
    var s = _state;
    if (s == null || s.phase != GamePhase.playing) return;
    if (s.currentPlayer.isAI) return;
    if (s.rule == GameRule.block) return;
    if (s.boneyard.isEmpty) return;

    final newState = GameLogic.drawTile(s);
    if (newState == null) return;
    _state = newState;
    notifyListeners();

    if (isNetworkGame) nearbyService.sendMove(NetworkMove.draw());

    _checkAfterDraw();
  }

  void playerPass() {
    var s = _state;
    if (s == null || s.phase != GamePhase.playing) return;

    _state = GameLogic.nextTurn(s);
    notifyListeners();
    _checkGameBlocked();
    _startTurn();
  }

  void _checkAfterDraw() {
    final s = _state;
    if (s == null) return;
    final playable = s.playableTiles(s.currentPlayerIndex);
    if (playable.isNotEmpty) return; // player can now play, wait for input
    if (s.boneyard.isNotEmpty && s.rule == GameRule.draw) return; // can draw more

    // Auto-pass
    _state = GameLogic.nextTurn(s);
    notifyListeners();
    _startTurn();
  }

  void _afterPlace(int playerIdx) {
    final s = _state!;

    // Check pip exhaustion
    final exhausted = GameLogic.checkPipExhaustion(s);
    if (exhausted != null) {
      _endRoundBlocked(exhausted: exhausted);
      return;
    }

    // Player emptied hand?
    if (s.players[playerIdx].hand.isEmpty) {
      _endRound(playerIdx);
      return;
    }

    _state = GameLogic.nextTurn(s);
    notifyListeners();
    _checkGameBlocked();
    _startTurn();
  }

  void _checkGameBlocked() {
    final s = _state;
    if (s == null || s.phase != GamePhase.playing) return;
    if (s.isBlocked && (s.rule == GameRule.block || s.boneyard.isEmpty)) {
      final winIdx = GameLogic.blockModeWinner(s);
      _endRoundBlocked(winnerIdx: winIdx);
    }
  }

  void _endRound(int winnerIdx) {
    _stopTimer();
    final s = _state!;
    if (s.rule == GameRule.draw) {
      final earned = GameLogic.calcEarned(s, winnerIdx);
      var newState = GameLogic.applyRoundScore(s, winnerIdx, earned);
      // Check match win
      final winner = newState.players[winnerIdx];
      final matchScore = newState.teamMode
          ? newState.teamScores[winner.team]
          : winner.score;
      if (matchScore >= newState.matchWinScore) {
        _state = newState.copyWith(phase: GamePhase.matchOver, pendingWinIndex: winnerIdx);
      } else {
        _state = newState.copyWith(phase: GamePhase.roundOver, pendingWinIndex: winnerIdx);
      }
    } else {
      _state = s.copyWith(phase: GamePhase.roundOver, pendingWinIndex: winnerIdx);
    }
    notifyListeners();
  }

  void _endRoundBlocked({int? winnerIdx, int? exhausted}) {
    _stopTimer();
    final s = _state!;
    final w = winnerIdx ?? GameLogic.blockModeWinner(s);
    _endRound(w);
  }

  void startNextRound() {
    final s = _state;
    if (s == null) return;
    final nextFirst = s.lastRoundWinnerIndex ?? 0;
    _state = GameLogic.startNewRound(s, nextFirst).copyWith(
      lastRoundWinnerIndex: nextFirst,
    );
    _startTurn();
    notifyListeners();
  }

  // ── AI turn ──────────────────────────────────────────────────

  void _doAITurn() {
    final s = _state;
    if (s == null || s.phase != GamePhase.playing) return;
    if (!s.currentPlayer.isAI) return;

    final move = AILogic.getBestMove(s);
    if (move == null) {
      // AI can't play
      if (s.rule == GameRule.draw && s.boneyard.isNotEmpty) {
        final drawn = GameLogic.drawTile(s);
        if (drawn != null) {
          _state = drawn;
          notifyListeners();
          Future.delayed(const Duration(milliseconds: 500), _doAITurn);
          return;
        }
      }
      // Pass
      _state = GameLogic.nextTurn(s);
      notifyListeners();
      _checkGameBlocked();
      _startTurn();
      return;
    }

    final newState = GameLogic.placeTile(s, move.tile, move.side);
    if (newState == null) {
      _state = GameLogic.nextTurn(s);
      notifyListeners();
      _startTurn();
      return;
    }
    _state = newState;
    _triggerFeedback();
    notifyListeners();
    _afterPlace(newState.currentPlayerIndex);
  }

  // ── Network move handler ─────────────────────────────────────

  void applyNetworkMove(NetworkMove move) {
    final s = _state;
    if (s == null) return;

    if (move.type == 'place') {
      final tile = DominoTile(id: move.tileId, sideA: move.sideA, sideB: move.sideB);
      final newState = GameLogic.placeTile(s, tile, move.side);
      if (newState != null) {
        _state = newState;
        notifyListeners();
        _afterPlace(newState.currentPlayerIndex);
      }
    } else if (move.type == 'draw') {
      final drawn = GameLogic.drawTile(s);
      if (drawn != null) {
        _state = drawn;
        notifyListeners();
      }
    } else if (move.type == 'pass') {
      _state = GameLogic.nextTurn(s);
      notifyListeners();
      _startTurn();
    }
  }

  // ── Chat ─────────────────────────────────────────────────────

  void sendChatMessage(String text, int playerIdx) {
    chatMessages.add(ChatMessage(
      text: text,
      playerIndex: playerIdx,
      time: DateTime.now(),
    ));
    notifyListeners();
  }

  // ── Settings ────────────────────────────────────────────────

  void setBoardColor(String color) {
    _boardColor = color;
    if (_state != null) {
      _state = _state!.copyWith(boardColor: color);
    }
    _profileService.saveSettings(_tileSkin, color);
    notifyListeners();
  }

  void setTileSkin(String skin) {
    _tileSkin = skin;
    String boardColor = _state?.boardColor ?? 'green';
    _profileService.saveSettings(skin, boardColor);
    notifyListeners();
  }

  // ── Online Matchmaking ────────────────────────────────────────

  Future<String> startOnlineMatchmaking() async {
    try {
      await firebaseService.init();
      final gameId = await firebaseService.findMatch(_userProfile ?? Player(index: 0, name: 'Player', type: PlayerType.human));
      
      // Start as a guest/host with a simple setup
      final p1 = _userProfile ?? Player(index: 0, name: 'Player', type: PlayerType.human);
      final p2 = Player(index: 1, name: 'Opponent', type: PlayerType.network);
      
      startOnlineGame(players: [p1, p2], gameId: gameId);
      
      return gameId;
    } catch (e) {
      rethrow;
    }
  }

  void cancelMatchmaking() {
    firebaseService.leaveLobby();
  }

  @override
  void dispose() {
    _stopTimer();
    nearbyService.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final int playerIndex;
  final DateTime time;
  const ChatMessage({required this.text, required this.playerIndex, required this.time});
}
