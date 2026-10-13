import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/services/auth_service.dart';

class CardImage extends StatelessWidget {
  const CardImage({super.key, required this.raw});
  final String raw;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final url = raw.startsWith('http') ? raw : '${auth.serverUrl ?? ''}$raw';

    return Image.network(
      url,
      fit: BoxFit.contain,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        );
      },
      errorBuilder: (_, _, _) => Container(
        height: 200,
        alignment: Alignment.center,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.broken_image_outlined, size: 48),
      ),
    );
  }
}
