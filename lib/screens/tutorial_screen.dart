import 'package:flutter/material.dart';
import '../widgets/board_widget.dart';
import '../models/tile.dart';

class TutorialScreen extends StatefulWidget {
  final String lang;
  const TutorialScreen({super.key, required this.lang});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  int _step = 0;

  final List<Map<String, dynamic>> _lessons = [
    {
      'title': 'The Basics',
      'content': 'Dominoes is played with a set of 28 tiles. Each tile has two sides with pips from 0 to 6. Match pips on your tiles to the open ends of the board.',
      'board': <PlacedTile>[],
    },
    {
      'title': 'Matching Tiles',
      'content': 'To place a tile, one of its sides must match the value of an open end. In this example, you can play a [6|X] or [X|1].',
      'board': [
        PlacedTile(sideA: 6, sideB: 1, x: 0, y: 0),
      ],
    },
    {
      'title': 'Doubles',
      'content': 'Doubles (like [6|6]) are placed crosswise. They are often used to change the direction of the snake or to gain control of a suit.',
      'board': [
        PlacedTile(sideA: 6, sideB: 1, x: 0, y: 0),
        PlacedTile(sideA: 6, sideB: 6, x: 0, y: 0, isDouble: true),
      ],
    },
    {
      'title': 'Strategic Blocking',
      'content': 'Professional players count tiles. If you know all the [6]s but one have been played, and you have the last one, you can "lock" that end of the board to force your opponent to pass.',
      'board': [
        PlacedTile(sideA: 2, sideB: 3, x: 0, y: 0),
        PlacedTile(sideA: 3, sideB: 4, x: 0, y: 0),
        PlacedTile(sideA: 4, sideB: 6, x: 0, y: 0),
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final lesson = _lessons[_step];
    
    return Scaffold(
      backgroundColor: const Color(0xFF0c1e38),
      appBar: AppBar(
        title: Text(lesson['title'], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFd4a843))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Lesson Content
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              lesson['content'],
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.6),
            ),
          ),
          
          // Example Board
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1d5c38),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFd4a843).withOpacity(0.3), width: 2),
                boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BoardWidget(
                  board: lesson['board'] as List<PlacedTile>,
                  lang: widget.lang,
                ),
              ),
            ),
          ),
          
          // Navigation
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_step > 0)
                  TextButton(
                    onPressed: () => setState(() => _step--),
                    child: const Text('PREVIOUS', style: TextStyle(color: Colors.white54)),
                  )
                else
                  const SizedBox(width: 80),
                  
                Row(
                  children: List.generate(_lessons.length, (i) => Container(
                    width: 8, height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _step ? const Color(0xFFd4a843) : Colors.white12,
                    ),
                  )),
                ),
                
                if (_step < _lessons.length - 1)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFd4a843),
                      foregroundColor: const Color(0xFF0c1e38),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => setState(() => _step++),
                    child: const Text('NEXT', style: TextStyle(fontWeight: FontWeight.bold)),
                  )
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('GOT IT!', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
