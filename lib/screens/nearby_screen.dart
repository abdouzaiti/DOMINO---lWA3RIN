import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'game_provider.dart';
import '../networking/nearby_service.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import 'game_screen.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});
  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  bool _isHost = false;
  bool _searching = false;
  String _status = '';
  final _nameCtrl = TextEditingController(text: 'Player 1');

  @override
  void initState() {
    super.initState();
    final ns = context.read<GameProvider>().nearbyService;
    ns.onConnectionChanged = (connected, name) {
      if (!mounted) return;
      if (connected) {
        setState(() => _status = 'Connected to $name!');
        Future.delayed(const Duration(seconds: 1), _startNetworkGame);
      } else {
        setState(() => _status = 'Disconnected from $name');
      }
    };
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _host() async {
    final ns = context.read<GameProvider>().nearbyService;
    await ns.requestPermissions();
    await ns.startAdvertising(_nameCtrl.text.trim());
    setState(() {
      _isHost = true;
      _searching = true;
      _status = 'Waiting for opponent…';
    });
  }

  Future<void> _discover() async {
    final ns = context.read<GameProvider>().nearbyService;
    await ns.requestPermissions();
    await ns.startDiscovery();
    setState(() {
      _isHost = false;
      _searching = true;
      _status = 'Searching for games…';
    });
  }

  Future<void> _connect(DiscoveredEndpoint ep) async {
    final ns = context.read<GameProvider>().nearbyService;
    setState(() => _status = 'Connecting to ${ep.name}…');
    await ns.requestConnection(ep.id, _nameCtrl.text.trim());
  }

  void _startNetworkGame() {
    final gp = context.read<GameProvider>();
    final ns = gp.nearbyService;
    gp.startLocalMulti(
      names: [_nameCtrl.text.trim(), ns.connectedEndpointName ?? 'Player 2'],
      rule: GameRule.draw,
      boardColor: 'green',
      teamMode: false,
    );
    // Wire up incoming moves
    ns.onMoveReceived = (move) => gp.applyNetworkMove(move);
    if (mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const GameScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ns = context.watch<GameProvider>().nearbyService;

    return Scaffold(
      backgroundColor: const Color(0xFF0c1018),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0a1018),
        iconTheme: const IconThemeData(color: Color(0xFFd4a843)),
        title: const Text('NEARBY MULTIPLAYER',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 15,
                letterSpacing: 2)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Name field
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Your name',
                labelStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withOpacity(0.07),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),

            if (!_searching) ...[
              // Host / Join buttons
              Row(
                children: [
                  Expanded(
                    child: _bigBtn('📡 Host Game', const Color(0xFFd4a843), _host),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _bigBtn('🔍 Join Game', const Color(0xFF2ecc71), _discover),
                  ),
                ],
              ),
            ] else ...[
              // Status
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white.withOpacity(0.05),
                  border: Border.all(color: const Color(0xFF253550)),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFFd4a843)),
                    ),
                    const SizedBox(width: 12),
                    Text(_status,
                        style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),

              // Discovered endpoints (guest mode)
              if (!_isHost && ns.discoveredEndpoints.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('FOUND GAMES',
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2)),
                const SizedBox(height: 10),
                ...ns.discoveredEndpoints.map((ep) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        tileColor: Colors.white.withOpacity(0.05),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        title: Text(ep.name,
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w700)),
                        trailing: ElevatedButton(
                          onPressed: () => _connect(ep),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFd4a843),
                            foregroundColor: const Color(0xFF0c1018),
                          ),
                          child: const Text('Connect',
                              style: TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ),
                    )),
              ],

              const SizedBox(height: 20),
              TextButton(
                onPressed: () async {
                  await ns.stop();
                  setState(() => _searching = false);
                },
                child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
              ),
            ],

            const SizedBox(height: 32),
            // Info box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xFF1a2a40),
                border: Border.all(color: const Color(0xFF253550)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('HOW IT WORKS',
                      style: TextStyle(
                          color: Color(0xFFd4a843),
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 2)),
                  SizedBox(height: 8),
                  Text(
                    '• Both devices must be on the same Wi-Fi network, or have Bluetooth on.\n'
                    '• One player hosts, the other joins.\n'
                    '• Moves are sent as JSON messages — boards stay in sync automatically.',
                    style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.7),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bigBtn(String label, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: const Color(0xFF0c1018),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
      ),
      child: Text(label),
    );
  }
}
