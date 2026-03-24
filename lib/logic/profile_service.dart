import 'package:shared_preferences/shared_preferences.dart';
import '../models/player.dart';

class ProfileService {
  static const String _keyName = 'user_name';
  static const String _keyUsername = 'user_username';
  static const String _keyAvatar = 'user_avatar';
  static const String _keyWins = 'user_wins';
  static const String _keyLosses = 'user_losses';
  static const String _keyMaxScore = 'user_max_score';
  static const String _keyTileSkin = 'user_tile_skin';
  static const String _keyBoardColor = 'user_board_color';

  Future<void> saveProfile(Player player) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, player.name);
    if (player.username != null) await prefs.setString(_keyUsername, player.username!);
    if (player.avatarUrl != null) await prefs.setString(_keyAvatar, player.avatarUrl!);
    await prefs.setInt(_keyWins, player.wins);
    await prefs.setInt(_keyLosses, player.losses);
    await prefs.setInt(_keyMaxScore, player.maxScore);
  }

  Future<Player?> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_keyName);
    if (name == null) return null;

    return Player(
      index: 0,
      name: name,
      username: prefs.getString(_keyUsername),
      avatarUrl: prefs.getString(_keyAvatar),
      type: PlayerType.human,
      wins: prefs.getInt(_keyWins) ?? 0,
      losses: prefs.getInt(_keyLosses) ?? 0,
      maxScore: prefs.getInt(_keyMaxScore) ?? 0,
    );
  }

  Future<void> updateStats({bool isWin = false, int score = 0}) async {
    final profile = await loadProfile();
    if (profile == null) return;

    final updated = profile.copyWith(
      wins: isWin ? profile.wins + 1 : profile.wins,
      losses: isWin ? profile.losses : profile.losses + 1,
      maxScore: score > profile.maxScore ? score : profile.maxScore,
    );
    await saveProfile(updated);
  }

  Future<void> saveSettings(String tileSkin, String boardColor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTileSkin, tileSkin);
    await prefs.setString(_keyBoardColor, boardColor);
  }

  Future<Map<String, String>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'tileSkin': prefs.getString(_keyTileSkin) ?? 'classic',
      'boardColor': prefs.getString(_keyBoardColor) ?? 'green',
    };
  }
}
