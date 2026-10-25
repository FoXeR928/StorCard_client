import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/services/admin_service.dart';
import '../../data/services/auth_service.dart';
import '../cards/cards_screen.dart'; // <-- Изменен путь
import 'login_screen.dart'; // <-- Тот же уровень

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _restored = false;

  AuthService? _auth;

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthService>();
    _restore();
  }

  Future<void> _restore() async {
    final auth = context.read<AuthService>();
    await auth.restore();

    auth.sessionExpired.addListener(_onSessionExpired);

    if (auth.isLoggedIn && mounted) {
      await context.read<AdminService>().checkRole();
    }
    if (mounted) setState(() => _restored = true);
  }

  void _onSessionExpired() {
    final message = context.read<AuthService>().sessionExpired.value;
    if (message == null || !mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.lock_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 5),
          ),
        );
      context.read<AuthService>().sessionExpired.value = null;
    });
  }

  @override
  void dispose() {
    _auth?.sessionExpired.removeListener(_onSessionExpired);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_restored) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final auth = context.watch<AuthService>();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: auth.isReady
          ? const CardsScreen(key: ValueKey('cards'))
          : const LoginScreen(key: ValueKey('login')),
    );
  }
}
