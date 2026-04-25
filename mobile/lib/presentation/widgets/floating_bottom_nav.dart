import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Pill-shaped floating bar: grid (index 0), map pin (1), profile (2).
class FloatingBottomNav extends StatelessWidget {
  const FloatingBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Material(
        color: AppColors.lavender.withValues(alpha: 0.95),
        elevation: 8,
        shadowColor: AppColors.deepPurple.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(40),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.grid_view_rounded,
                selected: currentIndex == 0,
                onTap: () => onTap(0),
                elevated: false,
              ),
              _NavItem(
                icon: Icons.location_on_rounded,
                selected: currentIndex == 1,
                onTap: () => onTap(1),
                elevated: true,
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                selected: currentIndex == 2,
                onTap: () => onTap(2),
                elevated: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.elevated,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final child = Icon(
      icon,
      color: selected ? AppColors.deepPurple : AppColors.textMuted,
      size: elevated ? 28 : 26,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (elevated)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selected ? AppColors.white : Colors.transparent,
                shape: BoxShape.circle,
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.deepPurple.withValues(alpha: 0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: child,
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selected ? AppColors.white : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: child,
            ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 3,
            width: selected ? 22 : 0,
            decoration: BoxDecoration(
              color: AppColors.deepPurple,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
