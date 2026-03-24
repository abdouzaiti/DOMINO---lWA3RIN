/// A single domino tile
class DominoTile {
  final int id;
  final int sideA;
  final int sideB;

  const DominoTile({required this.id, required this.sideA, required this.sideB});

  bool get isDouble => sideA == sideB;
  int get total => sideA + sideB;

  /// Can this tile connect to either open end?
  bool canPlay(int? leftEnd, int? rightEnd) {
    if (leftEnd == null) return true; // first tile
    return sideA == leftEnd ||
        sideB == leftEnd ||
        sideA == rightEnd ||
        sideB == rightEnd;
  }

  /// Returns 'left', 'right', or null if it can't connect
  List<String> getPlayableSides(int? leftEnd, int? rightEnd) {
    if (leftEnd == null) return ['right'];
    final sides = <String>[];
    if (sideA == leftEnd || sideB == leftEnd) sides.add('left');
    if (sideA == rightEnd || sideB == rightEnd) sides.add('right');
    return sides;
  }

  /// Return a new tile oriented correctly to connect to [end]
  PlacedTile orientFor(int end) {
    if (sideB == end) return PlacedTile(id: id, sideA: sideA, sideB: sideB);
    return PlacedTile(id: id, sideA: sideB, sideB: sideA);
  }

  DominoTile copyWith({int? id, int? sideA, int? sideB}) => DominoTile(
        id: id ?? this.id,
        sideA: sideA ?? this.sideA,
        sideB: sideB ?? this.sideB,
      );

  Map<String, dynamic> toJson() => {'id': id, 'a': sideA, 'b': sideB};

  @override
  String toString() => '[$sideA|$sideB]';
}

/// A tile placed on the board — sideA is the connecting end toward the chain
class PlacedTile {
  final int id;
  final int sideA; // connects to previous tile / left end
  final int sideB; // exposes to next tile / right end
  final double x;  // Optional: stored coordinate
  final double y;  // Optional: stored coordinate
  final bool? _isDoubleOverride; // Optional: forced double status

  const PlacedTile({
    this.id = -1,
    required this.sideA,
    required this.sideB,
    this.x = 0,
    this.y = 0,
    bool? isDouble,
  }) : _isDoubleOverride = isDouble;

  bool get isDouble => _isDoubleOverride ?? (sideA == sideB);
  int get total => sideA + sideB;

  Map<String, dynamic> toJson() => {
        'id': id,
        'a': sideA,
        'b': sideB,
        'x': x,
        'y': y,
        'isD': _isDoubleOverride
      };

  factory PlacedTile.fromJson(Map<String, dynamic> j) => PlacedTile(
        id: j['id'] ?? -1,
        sideA: j['a'],
        sideB: j['b'],
        x: (j['x'] ?? 0).toDouble(),
        y: (j['y'] ?? 0).toDouble(),
        isDouble: j['isD'],
      );

  @override
  String toString() => '[$sideA|$sideB]';
}

/// Generate and shuffle a full double-6 deck
List<DominoTile> makeDeck() {
  final deck = <DominoTile>[];
  int id = 0;
  for (int a = 0; a <= 6; a++) {
    for (int b = a; b <= 6; b++) {
      deck.add(DominoTile(id: id++, sideA: a, sideB: b));
    }
  }
  return deck;
}

List<DominoTile> shuffleDeck(List<DominoTile> deck) {
  final d = List<DominoTile>.from(deck);
  d.shuffle();
  return d;
}
