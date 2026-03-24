import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/game_provider.dart';
import '../widgets/domino_tile.dart';
import '../widgets/dynamic_background.dart';

class OnlineLobbyScreen extends StatefulWidget {
  const OnlineLobbyScreen({super.key});

  @override
  State<OnlineLobbyScreen> createState() => _OnlineLobbyScreenState();
}

class _OnlineLobbyScreenState extends State<OnlineLobbyScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String _status = 'INITIALIZING...';
  String? _error;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _startMatchmaking();
  }

  Future<void> _startMatchmaking() async {
    final gp = context.read<GameProvider>();
    setState(() {
      _searching = true;
      _error = null;
      _status = 'SEARCHING FOR OPPONENTS...';
    });

    try {
      await gp.startOnlineMatchmaking();
      if (mounted) {
         Navigator.pop(context); 
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searching = false;
          _error = e.toString();
          _status = 'CONNECTION FAILED';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0c1018),
      body: Stack(
        children: [
          const DynamicBackground(),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('DOMINO LWA3RIN', style: TextStyle(
                      fontSize: 14, color: Colors.white.withOpacity(0.5), letterSpacing: 4, fontWeight: FontWeight.bold
                    )),
                    const SizedBox(height: 20),
                    // Animated Domino
                    RotationTransition(
                      turns: _controller,
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [BoxShadow(color: const Color(0xFFd4a843).withOpacity(0.3), blurRadius: 30)],
                        ),
                        child: const DominoTileWidget(
                          sideA: 6, sideB: 6,
                          orientation: TileOrientation.vertical,
                          halfSize: 35,
                          tileSkin: 'ivory',
                        ),
                      ),
                    ),
                    const SizedBox(height: 60),
                    Text(
                      _status,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFd4a843),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_searching)
                      Column(
                        children: [
                          const SizedBox(
                            width: 240,
                            child: LinearProgressIndicator(
                              backgroundColor: Colors.white12,
                              color: Color(0xFFd4a843),
                              minHeight: 2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text('PEER-TO-PEER LOBBY', style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 1.5)),
                        ],
                      ),
                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(top: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 28),
                            const SizedBox(height: 12),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    const Spacer(),
                    if (!_searching)
                      ElevatedButton(
                        onPressed: _startMatchmaking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFd4a843),
                          foregroundColor: Colors.black,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 8,
                        ),
                        child: const Text('RETRY MATCHMAKING', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        context.read<GameProvider>().cancelMatchmaking();
                        Navigator.pop(context);
                      },
                      child: const Text('RETURN TO MENU', style: TextStyle(color: Colors.white54, letterSpacing: 1)),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
