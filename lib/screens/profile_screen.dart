import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'game_provider.dart';
import '../models/player.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  String? _selectedAvatar;

  final List<String> _avatars = [
    '👤', '🤴', '👸', '🧔', '👵', '👨‍🚀', '👩‍🚒', '🧙', '🧝', '🧛',
    '🐯', '🦁', '🦉', '🐲', '🌵', '⚔️', '🛡️', '👑', '💎', '🃏'
  ];

  @override
  void initState() {
    super.initState();
    final profile = context.read<GameProvider>().userProfile;
    if (profile != null) {
      _nameController.text = profile.name;
      _usernameController.text = profile.username ?? '';
      _selectedAvatar = profile.avatarUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final gp = context.read<GameProvider>();
    final current = gp.userProfile;
    
    final updated = (current ?? Player(index: 0, name: name, type: PlayerType.human)).copyWith(
      name: name,
      username: _usernameController.text.trim(),
      avatarUrl: _selectedAvatar,
    );
    
    await gp.saveUserProfile(updated);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0c1018),
      appBar: AppBar(
        title: const Text('PROFILE', style: TextStyle(letterSpacing: 4, fontWeight: FontWeight.w900, color: Color(0xFFd4a843))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFd4a843)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar Selector
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFd4a843), width: 3),
                      color: Colors.white.withOpacity(0.05),
                    ),
                    child: Center(
                      child: Text(_selectedAvatar ?? '👤', style: const TextStyle(fontSize: 60)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildField('Full Name', _nameController, hint: 'What should we call you?'),
            const SizedBox(height: 20),
            _buildField('Username', _usernameController, hint: '@username'),
            const SizedBox(height: 32),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('CHOOSE AVATAR', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _avatars.map((a) => GestureDetector(
                onTap: () => setState(() => _selectedAvatar = a),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _selectedAvatar == a ? const Color(0xFFd4a843).withOpacity(0.2) : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _selectedAvatar == a ? const Color(0xFFd4a843) : Colors.transparent, width: 2),
                  ),
                  child: Center(child: Text(a, style: const TextStyle(fontSize: 24))),
                ),
              )).toList(),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFd4a843),
                  foregroundColor: const Color(0xFF0c1018),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('SAVE PROFILE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
