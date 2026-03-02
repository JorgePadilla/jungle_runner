import 'dart:ui';
import 'package:flame/components.dart';
import '../config/game_config.dart';

class Ground extends Component {
  final List<GroundTile> _tiles = [];
  double _gameSpeed = 1.0;

  /// Single scroll offset — all tile positions derived from this.
  double _scrollOffset = 0;

  // 4 tiles, each 1/3 of world width, with overlap
  static const int _tileCount = 4;
  static const double _bleed = 8.0;

  double get groundY => GameConfig.worldHeight - GameConfig.groundHeight;

  @override
  Future<void> onLoad() async {
    // Use an integer tile width to prevent sub-pixel seams when flooring
    final tileWidth = (GameConfig.worldWidth / 3).ceilToDouble();
    final crisp = Paint()..filterQuality = FilterQuality.none;

    for (int i = 0; i < _tileCount; i++) {
      final tile = GroundTile();
      tile.position = Vector2(i * tileWidth - _bleed, groundY);
      tile.size = Vector2(tileWidth + _bleed * 2, GameConfig.groundHeight.toDouble());
      tile.paint = crisp;
      await add(tile);
      _tiles.add(tile);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    final tileWidth = (GameConfig.worldWidth / 3).ceilToDouble();
    final totalLength = tileWidth * _tileCount; // distance before wrap
    final moveSpeed = _gameSpeed * GameConfig.baseScrollSpeed;

    // Advance single offset and wrap
    _scrollOffset += moveSpeed * dt;
    _scrollOffset %= totalLength;

    // Derive every tile position from one offset — zero drift
    // Shift by -bleed so tiles extend past viewport edges
    for (int i = 0; i < _tileCount; i++) {
      double x = i * tileWidth - _scrollOffset - _bleed;
      // Wrap tiles only when they are completely off-screen (including bleed)
      // A tile is at x. Its right edge is at x + width.
      // Width is tileWidth + 2*bleed.
      // So right edge is at x + tileWidth + 2*bleed.
      // It is off-screen when x + tileWidth + 2*bleed < 0  => x < -tileWidth - 2*bleed.
      if (x < -tileWidth - 2 * _bleed) x += totalLength;
      _tiles[i].position.x = x.floorToDouble();
    }
  }

  void updateSpeed(double speed) {
    _gameSpeed = speed;
    for (final tile in _tiles) {
      tile.updateSpeed(speed);
    }
  }
}

class GroundTile extends SpriteComponent {
  double _gameSpeed = 1.0;

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('ground/ground_tile.png');
    anchor = Anchor.topLeft;
  }

  void updateSpeed(double speed) {
    _gameSpeed = speed;
  }
}