import 'package:dramacircle/src/features/auth/providers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final isPremium = user?.isPremium ?? false;
    return Scaffold(
      appBar: AppBar(title: const Text('Premium')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(colors: [Color(0xFF5B5CFF), Color(0xFF8A35FF)]),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DramaCircle Premium', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Text('Unlock all episodes'),
                  Text('No ads (future)'),
                  Text('Priority video loading'),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(isPremium ? 'You are currently Premium' : 'Upgrade to start unlimited watching'),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => ref.read(authControllerProvider.notifier).setPremium(!isPremium),
                child: Text(isPremium ? 'Set as Regular' : 'Upgrade Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
