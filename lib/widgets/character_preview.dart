import 'package:flame/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';
import 'package:flame/extensions.dart';
import '../game/config/game_config.dart';

class CharacterPreview extends StatefulWidget {
  final String skinId;
  final double size;
  final String animationType;

  const CharacterPreview({
    super.key,
    required this.skinId,
    this.size = 64,
    this.animationType = 'run',
  });

  @override
  State<CharacterPreview> createState() => _CharacterPreviewState();
}

class _CharacterPreviewState extends State<CharacterPreview> {
  late Future<SpriteAnimation> _animationFuture;

  @override
  void initState() {
    super.initState();
    _animationFuture = _loadAnimation();
  }

  @override
  void didUpdateWidget(CharacterPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.skinId != widget.skinId ||
        oldWidget.animationType != widget.animationType) {
      _animationFuture = _loadAnimation();
    }
  }

  Future<SpriteAnimation> _loadAnimation() async {
    final image = await Flame.images.load('player/${widget.animationType}_${widget.skinId}.png');

    int amount = 12;
    if (widget.animationType == 'idle') amount = 11;
    if (widget.animationType == 'jump' || widget.animationType == 'slide') amount = 1;

    return SpriteAnimation.fromFrameData(
      image,
      SpriteAnimationData.sequenced(
        amount: amount,
        stepTime: 0.08,
        textureSize: Vector2(32, 32),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SpriteAnimation>(
      future: _animationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          final animation = snapshot.data!;
          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: SpriteAnimationWidget(
              animation: animation,
              animationTicker: animation.createTicker(),
              playing: true,
            ),
          );
        } else if (snapshot.hasError) {
          // Fallback to emoji if asset fails to load
          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: Center(
              child: Text(
                _skinEmoji(widget.skinId),
                style: TextStyle(fontSize: widget.size * 0.6),
              ),
            ),
          );
        }

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
    );
  }

  String _skinEmoji(String id) {
    switch (id) {
      case 'golden': return '🏃';
      case 'dark': return '🎭';
      case 'rainbow': return '💃';
      case 'ninja': return '🐸';
      default: return '🐸';
    }
  }
}
