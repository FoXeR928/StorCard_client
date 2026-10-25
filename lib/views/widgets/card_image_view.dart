import 'package:flutter/material.dart';
import 'card_image.dart';
import 'fullscreen_image.dart';

class CardImageView extends StatelessWidget {
  const CardImageView({super.key, required this.raw});
  final String raw;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => FullscreenImage(raw: raw))),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 140,
              width: double.infinity,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: CardImage(raw: raw, fit: BoxFit.cover),
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.zoom_in, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }
}