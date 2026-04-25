import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../widgets/floating_bottom_nav.dart';
import 'profile_screen.dart';
import 'smart_guide_screen.dart';
import 'terhal_home_screen.dart';

/// Main app shell: Smart Guide (grid), Terhal map home (pin), Profile.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, 2);
  }

  @override
  Widget build(BuildContext context) {
    final pages = const [
      SmartGuideScreen(),
      TerhalHomeScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: pages,
      ),
      bottomNavigationBar: FloatingBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
