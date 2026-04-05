import 'package:dramacircle/src/core/providers.dart';
import 'package:dramacircle/src/features/auth/presentation/login_screen.dart';
import 'package:dramacircle/src/features/auth/providers/auth_controller.dart';
import 'package:dramacircle/src/features/auth/providers/guest_access_controller.dart';
import 'package:dramacircle/src/features/library/providers/library_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final history = ref.watch(localStoreProvider).history;
    final favorites = ref.watch(favoritesProvider);
    final continueWatching = ref.watch(localStoreProvider).continueWatching;
    final guestAccess = ref.watch(guestAccessProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(user?.name ?? 'Guest User', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(user?.email ?? 'Login untuk sinkronisasi akun'),
          const SizedBox(height: 6),
          Text(user?.isPremium == true ? 'Premium Member' : (user == null ? 'Guest Mode' : 'Regular Member')),
          if (user == null) ...[
            const SizedBox(height: 6),
            Text(guestAccess.used ? 'Free play guest sudah dipakai' : 'Kamu punya 1 free play sebagai guest'),
          ],
          const SizedBox(height: 22),
          _StatTile(title: 'Favorites', value: favorites.length.toString()),
          _StatTile(title: 'Continue Watching', value: continueWatching.length.toString()),
          _StatTile(title: 'History', value: history.length.toString()),
          const SizedBox(height: 22),
          if (user == null)
            FilledButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen())),
              child: const Text('Login'),
            )
          else
            FilledButton(
              onPressed: () => ref.read(authControllerProvider.notifier).logout(),
              child: const Text('Logout'),
            ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.title, required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
