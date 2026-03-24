import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/player.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  late final DatabaseReference _db = FirebaseDatabase.instance.ref();
  late final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _gameId;
  
  User? _currentUser;
  User? get currentUser => _currentUser;

  Future<void> init() async {
    await Firebase.initializeApp();
    _currentUser = (await _auth.signInAnonymously()).user;
  }

  // ── Matchmaking ──────────────────────────────────────────────

  Future<String> findMatch(Player localProfile) async {
    final uid = _currentUser?.uid;
    if (uid == null) throw Exception('Not authenticated');

    // 1. Join Lobby
    final lobbyRef = _db.child('lobby').child(uid);
    await lobbyRef.set({
      'uid': uid,
      'name': localProfile.name,
      'avatarUrl': localProfile.avatarUrl,
      'stats': {
        'wins': localProfile.wins,
        'losses': localProfile.losses,
      },
      'status': 'searching',
      'timestamp': ServerValue.timestamp,
    });

    // 2. Listen for a game assignment
    final completer = Completer<String>();
    
    // Check if there's an existing match we can join
    _db.child('lobby').limitToFirst(5).onValue.listen((event) async {
      final data = event.snapshot.value as Map?;
      if (data == null) return;

      for (var entry in data.entries) {
        final otherUid = entry.key;
        if (otherUid == uid) continue;
        
        final otherData = entry.value as Map;
        if (otherData['status'] == 'searching') {
           // We found an opponent! Create a game.
           final gameId = 'game_${uid}_$otherUid';
           _gameId = gameId;
           
           // Host creates the game
           await _db.child('games').child(gameId).set({
             'host': uid,
             'guest': otherUid,
             'status': 'starting',
             'lastMove': null,
           });
           
           // Notify both in lobby
           await _db.child('lobby').child(uid).update({'status': 'matched', 'gameId': gameId});
           await _db.child('lobby').child(otherUid).update({'status': 'matched', 'gameId': gameId});
           
           if (!completer.isCompleted) completer.complete(gameId);
           return;
        }
      }
    });

    // Also listen for our own lobby entry being updated by someone else
    _db.child('lobby').child(uid).onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null && data['gameId'] != null) {
        _gameId = data['gameId'];
        if (!completer.isCompleted) completer.complete(_gameId);
      }
    });

    return completer.future.timeout(const Duration(seconds: 30), onTimeout: () {
       lobbyRef.remove();
       throw Exception('Matchmaking timeout');
    });
  }

  // ── Game Sync ────────────────────────────────────────────────

  void syncMove(String gameId, Map<String, dynamic> move) {
    _db.child('games').child(gameId).child('lastMove').set({
      ...move,
      'sender': _currentUser?.uid,
      'timestamp': ServerValue.timestamp,
    });
  }

  void listenForMoves(String gameId, Function(Map<String, dynamic>) onMove) {
    _db.child('games').child(gameId).child('lastMove').onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return;
      if (data['sender'] == _currentUser?.uid) return; // Ignore our own moves
      onMove(data.cast<String, dynamic>());
    });
  }

  Future<void> leaveLobby() async {
    if (_currentUser != null) {
      await _db.child('lobby').child(_currentUser!.uid).remove();
    }
  }
}
