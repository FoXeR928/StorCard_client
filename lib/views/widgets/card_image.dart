import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/services/auth_service.dart';

class CardImage extends StatelessWidget {
  const CardImage({super.key, required this.raw, this.fit = BoxFit.contain});

  final String raw;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();

    String url = raw;
    if (!raw.startsWith('http')) {
      final base = auth.serverUrl ?? '';
      final cleanBase = base.endsWith('/')
          ? base.substring(0, base.length - 1)
          : base;
      final cleanRaw = raw.startsWith('/') ? raw.substring(1) : raw;
      url = '$cleanBase/$cleanRaw';
    }

    final token = auth.token;
    final headers = token != null ? {'Authorization': 'Bearer $token'} : null;

    return CachedNetworkImage(
      imageUrl: url,
      cacheKey: raw,
      httpHeaders: headers,
      fit: fit,
      // Убрали width/height: double.infinity, чтобы не ломать Stack
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (_, _) => const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (_, _, _) => Container(
        alignment: Alignment.center,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.broken_image_outlined,
          size: 48,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}
