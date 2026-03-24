import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'game_provider.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import '../i18n/translations.dart';
import 'game_screen.dart';
import 'nearby_screen.dart';
import 'profile_screen.dart';
import 'tutorial_screen.dart';
import 'online_lobby_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _step = 'main'; 
  GameRule _rule = GameRule.draw;
  AIDifficulty _diff = AIDifficulty.medium;
  int _playerCount = 2;
  bool _isTurbo = false;
  bool _teamMode = false;
  List<TextEditingController> _nameControllers = [];
  final TextEditingController _aiNameCtrl = TextEditingController(text: 'You');

  @override
  void dispose() {
    for (final c in _nameControllers) c.dispose();
    _aiNameCtrl.dispose();
    super.dispose();
  }

  String _t(String key) => tr(context.read<GameProvider>().lang, key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0c1018),
      body: SafeArea(child: _buildStep()),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 'mode':
        return _buildModeSelect();
      case 'gameRule':
        return _buildGameRule();
      case 'diff':
        return _buildDifficulty();
      case 'playerCount':
        return _buildPlayerCount();
      case 'names':
        return _buildNames();
      case 'howto':
        return _buildHowTo();
      case 'settings':
        return _buildSettings();
      default:
        return _buildMain();
    }
  }

  // ── MAIN MENU ────────────────────────────────────────────────
  
  Widget _buildMain() {
    final gp = context.watch<GameProvider>();
    final profile = gp.userProfile;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFd4a843).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFd4a843).withOpacity(0.2),
                    radius: 20,
                    child: Text(profile?.avatarUrl ?? '👤', style: const TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(profile?.name ?? 'SETUP PROFILE', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
                      Text('${profile?.wins ?? 0} WINS', style: const TextStyle(color: Color(0xFFd4a843), fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.edit, color: Color(0xFFd4a843), size: 14),
                ],
              ),
            ),
          ),
          const Spacer(),
          Text('DOMINO', style: TextStyle(
            fontSize: 52,
            fontWeight: FontWeight.w900,
            color: const Color(0xFFd4a843),
            letterSpacing: 4,
            shadows: [Shadow(color: Colors.black54, blurRadius: 20)],
          )),
          const SizedBox(height: 6),
          Text('LWA3RIN', style: TextStyle(
            fontSize: 14,
            color: Colors.white38,
            letterSpacing: 6,
            fontWeight: FontWeight.w600,
          )),
          const Spacer(),
          _menuBtn(_t('play'), icon: '▶', onTap: () => setState(() => _step = 'mode')),
          const SizedBox(height: 12),
          _menuBtn('LEARNING CENTER', icon: '🎓', onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (c) => TutorialScreen(lang: context.read<GameProvider>().lang)));
          }),
          const SizedBox(height: 12),
          _menuBtn(_t('settings'), icon: '⚙️', onTap: () => setState(() => _step = 'settings')),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _menuBtn(String label, {required VoidCallback onTap, String? icon}) {
    return SizedBox(
      width: 260,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFd4a843),
          foregroundColor: const Color(0xFF0c1018),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        child: Text(icon != null ? '$icon  $label' : label),
      ),
    );
  }

  // ── MODE SELECT ──────────────────────────────────────────────

  Widget _buildModeSelect() {
    return _scaffold(
      title: _t('selectMode'),
      child: Column(
        children: [
          _modeCard('🤖', _t('vsAI'), _t('vsAIDesc'), () => setState(() => _step = 'gameRule')),
          _modeCard('👥', _t('localMulti'), _t('localMultiDesc'), () => setState(() => _step = 'playerCount')),
          _modeCard('📡', _t('nearby'), _t('nearbyDesc'), () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const NearbyScreen()));
          }),
          _modeCard('🌐', 'Online Multiplayer', 'Real-time matches via Firebase', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const OnlineLobbyScreen()));
          }),
        ],
      ),
    );
  }

  Widget _modeCard(String icon, String title, String desc, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF253550)),
          color: Colors.white.withOpacity(0.04),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 36)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(desc, style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            const Text('›', style: TextStyle(color: Color(0xFFd4a843), fontSize: 20)),
          ],
        ),
      ),
    );
  }

  // ── GAME RULE ────────────────────────────────────────────────

  Widget _buildGameRule() {
    return _scaffold(
      title: _t('selectRules'),
      child: Column(
        children: [
          _ruleCard(GameRule.draw, '🃏', _t('drawMode'), _t('drawModeDesc')),
          const SizedBox(height: 12),
          _ruleCard(GameRule.block, '🛑', _t('blockMode'), _t('blockModeDesc')),
          const SizedBox(height: 24),
          _menuBtn(_t('difficulty'), onTap: () => setState(() => _step = 'diff')),
        ],
      ),
    );
  }

  Widget _ruleCard(GameRule rule, String icon, String title, String desc) {
    final active = _rule == rule;
    return GestureDetector(
      onTap: () => setState(() => _rule = rule),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? const Color(0xFFd4a843) : const Color(0xFF253550), width: active ? 2 : 1),
          color: active ? const Color(0xFFd4a843).withOpacity(0.1) : Colors.white.withOpacity(0.03),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: active ? const Color(0xFFd4a843) : Colors.white, fontWeight: FontWeight.w800)),
                  Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── DIFFICULTY ───────────────────────────────────────────────

  Widget _buildDifficulty() {
    return _scaffold(
      title: _t('difficulty'),
      child: Column(
        children: [
          _diffBtn(AIDifficulty.easy, _t('easy'), _t('easyDesc'), '😊'),
          const SizedBox(height: 10),
          _diffBtn(AIDifficulty.medium, _t('medium'), _t('mediumDesc'), '🎯'),
          const SizedBox(height: 10),
          _diffBtn(AIDifficulty.hard, _t('hard'), _t('hardDesc'), '🔥'),
          const SizedBox(height: 10),
          _diffBtn(AIDifficulty.expert, _t('expert'), _t('expertDesc'), '🧠'),
          const SizedBox(height: 24),
          _settingRow(_t('turbo'), Switch(
            value: _isTurbo,
            onChanged: (v) => setState(() => _isTurbo = v),
            activeColor: const Color(0xFFd4a843),
          )),
          const SizedBox(height: 24),
          _menuBtn(_t('startGame'), onTap: _startVsAI),
        ],
      ),
    );
  }

  Widget _diffBtn(AIDifficulty d, String label, String desc, String icon) {
    final active = _diff == d;
    return GestureDetector(
      onTap: () => setState(() => _diff = d),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? const Color(0xFFd4a843) : const Color(0xFF253550), width: active ? 2 : 1),
          color: active ? const Color(0xFFd4a843).withOpacity(0.1) : Colors.transparent,
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: active ? const Color(0xFFd4a843) : Colors.white, fontWeight: FontWeight.w800)),
                  Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── PLAYER COUNT ─────────────────────────────────────────────

  Widget _buildPlayerCount() {
    return _scaffold(
      title: _t('howManyPlayers'),
      child: Column(
        children: [
          Row(
            children: [2, 3, 4].map((n) {
              final active = _playerCount == n;
              return Expanded(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => setState(() => _playerCount = n),
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFFd4a843).withOpacity(0.2) : Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: active ? const Color(0xFFd4a843) : Colors.white12),
                    ),
                    child: Center(child: Text(n.toString(), style: TextStyle(color: active ? const Color(0xFFd4a843) : Colors.white54, fontSize: 22, fontWeight: FontWeight.bold))),
                  ),
                ),
              ));
            }).toList(),
          ),
          if (_playerCount == 4) ...[
            const SizedBox(height: 20),
            _settingRow(_t('team2v2'), Switch(
              value: _teamMode,
              onChanged: (v) => setState(() => _teamMode = v),
              activeColor: const Color(0xFFd4a843),
            )),
          ],
          const SizedBox(height: 28),
          _menuBtn(_t('next') ?? 'NEXT', onTap: () {
            final gp = context.read<GameProvider>();
            _nameControllers = List.generate(_playerCount, (i) => TextEditingController(text: i == 0 ? (gp.userProfile?.name ?? 'Player') : 'Player ${i + 1}'));
            setState(() => _step = 'names');
          }),
        ],
      ),
    );
  }

  // ── NAMES ──────────────────────────────────────────────────

  Widget _buildNames() {
    return _scaffold(
      title: _t('enterNames'),
      child: Column(
        children: [
          for (int i = 0; i < _playerCount; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  CircleAvatar(backgroundColor: const Color(0xFF253550), radius: 18, child: Text((i + 1).toString(), style: const TextStyle(fontSize: 12, color: Color(0xFFd4a843)))),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextField(
                      controller: _nameControllers[i],
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.07),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          _menuBtn(_t('startGame'), onTap: _startLocalMulti),
        ],
      ),
    );
  }

  // ── HOW TO PLAY ──────────────────────────────────────────────

  Widget _buildHowTo() {
    final rules = ['rule1', 'rule2', 'rule3', 'rule4', 'rule5', 'rule6'];
    return _scaffold(
      title: _t('howToPlay'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rules.map((k) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('•', style: TextStyle(color: Color(0xFFd4a843), fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(width: 10),
              Expanded(child: Text(_t(k), style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5))),
            ],
          ),
        )).toList(),
      ),
    );
  }

  // ── SETTINGS ────────────────────────────────────────────────

  Widget _buildSettings() {
    final gp = context.watch<GameProvider>();
    return _scaffold(
      title: _t('settings'),
      child: Column(
        children: [
          _settingRow(_t('soundLbl'), Switch(
            value: gp.soundEnabled,
            onChanged: (v) => gp.setSoundEnabled(v),
            activeColor: const Color(0xFFd4a843),
          )),
          _settingRow(_t('languageLbl'), Row(
            children: ['en', 'fr', 'ar'].map((l) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: GestureDetector(
                onTap: () => gp.setLang(l),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: gp.lang == l ? const Color(0xFFd4a843) : const Color(0xFF1e2e44)),
                    color: gp.lang == l ? const Color(0xFFd4a843).withOpacity(0.2) : Colors.transparent,
                  ),
                  child: Text(l.toUpperCase(), style: TextStyle(color: gp.lang == l ? const Color(0xFFd4a843) : Colors.white54, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ),
            )).toList(),
          )),
          _settingRow('TILE SKIN', Row(
            children: ['classic', 'algerian', 'ivory', 'gold', 'wood', 'neon'].map((s) => Padding(
              padding: const EdgeInsets.only(left: 4),
              child: GestureDetector(
                onTap: () => gp.setTileSkin(s),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: gp.tileSkin == s ? const Color(0xFFd4a843) : Colors.white24),
                    color: gp.tileSkin == s ? const Color(0xFFd4a843).withOpacity(0.2) : Colors.transparent,
                  ),
                  child: Center(
                    child: Text(
                      {
                        'classic': '⚪',
                        'algerian': '🇩🇿',
                        'ivory': '🦴',
                        'gold': '🟡',
                        'wood': '🪵',
                        'neon': '⚛️',
                      }[s] ?? '',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ),
            )).toList(),
          )),
          _settingRow('TABLE COLOR', Row(
            children: ['green', 'navy', 'maroon', 'slate', 'purple'].map((c) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: GestureDetector(
                onTap: () => gp.setBoardColor(c),
                child: Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getColor(c),
                    border: Border.all(color: (gp.state?.boardColor ?? 'green') == c ? Colors.white : Colors.transparent, width: 2),
                  ),
                ),
              ),
            )).toList(),
          )),
        ],
      ),
    );
  }

  Color _getColor(String c) {
    switch (c) {
      case 'navy': return const Color(0xFF1a2a52);
      case 'maroon': return const Color(0xFF521820);
      case 'slate': return const Color(0xFF283040);
      case 'purple': return const Color(0xFF2d1b4e);
      default: return const Color(0xFF1d5c38);
    }
  }

  Widget _settingRow(String label, Widget control) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF182030)))),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14))),
          control,
        ],
      ),
    );
  }

  // ── Scaffold wrapper ─────────────────────────────────────────

  Widget _scaffold({required String title, required Widget child}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF182030)))),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _step = 'main'),
                child: const Icon(Icons.arrow_back_ios, color: Color(0xFFd4a843), size: 20),
              ),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2)),
            ],
          ),
        ),
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: child)),
      ],
    );
  }

  // ── Start game ───────────────────────────────────────────────

  void _startVsAI() {
    final gp = context.read<GameProvider>();
    gp.startVsAI(difficulty: _diff, rule: _rule, boardColor: gp.state?.boardColor ?? 'green', isTurbo: _isTurbo);
    _goToGame();
  }

  void _startLocalMulti() {
    final names = _nameControllers.map((c) => c.text.trim().isEmpty ? 'Player' : c.text.trim()).toList();
    final gp = context.read<GameProvider>();
    gp.startLocalMulti(names: names, rule: _rule, boardColor: gp.state?.boardColor ?? 'green', teamMode: _teamMode, isTurbo: _isTurbo);
    _goToGame();
  }

  void _goToGame() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const GameScreen()));
  }
}
