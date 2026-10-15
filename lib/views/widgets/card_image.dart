import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/services/auth_service.dart';

class CardImage extends StatelessWidget {
  const CardImage({
    super.key,
    required this.raw,
    this.fit = BoxFit.contain,
  });

  final String raw;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final url = raw.startsWith('http') ? raw : '${auth.serverUrl ?? ''}$raw';

    return Image.network(
      url,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      },
      errorBuilder: (_, _, _) => Container(
        alignment: Alignment.center,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.broken_image_outlined, size: 48),
      ),
    );
  }
}