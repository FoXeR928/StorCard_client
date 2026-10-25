import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/services/auth_service.dart';

class FullscreenImage extends StatelessWidget {
  const FullscreenImage({super.key, required this.raw});

  final String raw;

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

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 5.0,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: url,
                    cacheKey: raw,
                    httpHeaders: headers,
                    fit: BoxFit.contain,
                    placeholder: (_, _) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorWidget: (_, _, _) => const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white38,
                        size: 64,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  tooltip: 'Закрыть',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
