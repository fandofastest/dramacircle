import 'package:dramacircle/src/features/discover/presentation/discover_screen.dart';
import 'package:dramacircle/src/features/home/presentation/home_catalog_screen.dart';
import 'package:dramacircle/src/features/premium/presentation/premium_screen.dart';
import 'package:dramacircle/src/features/profile/presentation/profile_screen.dart';
import 'package:flutter/material.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _index = 0;

  final _pages = const [
    HomeCatalogScreen(),
    DiscoverScreen(),
    PremiumScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.travel_explore_outlined), label: 'Discover'),
          NavigationDestination(icon: Icon(Icons.workspace_premium_outlined), label: 'Premium'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
