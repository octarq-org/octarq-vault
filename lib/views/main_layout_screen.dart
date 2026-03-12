import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../main.dart';
import '../providers/assets_provider.dart';
import '../providers/asset_types_provider.dart';
import '../providers/search_provider.dart';
import '../utils/icon_helper.dart';

class MainLayoutScreen extends ConsumerWidget {
  const MainLayoutScreen({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Row(
        children: [
          // ─── Sidebar ───────────────────────────────────────────────────────
          const _Sidebar(),
          // ─── Main Content Area ─────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // ─── Global Top Bar ─────────────────────────────────────────
                const _GlobalTopBar(),
                // ─── Routed Content ─────────────────────────────────────────
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Global Top Bar ──────────────────────────────────────────────────────────

class _GlobalTopBar extends ConsumerWidget {
  const _GlobalTopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: kBgColor,
        border: Border(bottom: BorderSide(color: kBorderColor)),
      ),
      child: Row(
        children: [
          // Search Field
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: kSurfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kBorderColor),
              ),
              child: TextField(
                style: const TextStyle(fontSize: 14),
                onChanged: (val) {
                  ref.read(searchQueryProvider.notifier).updateQuery(val);
                },
                decoration: const InputDecoration(
                  hintText: 'Search assets, tags, or fields...',
                  hintStyle: TextStyle(color: kTextMuted, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: kTextMuted, size: 18),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          _NotificationBell(),
          const SizedBox(width: 16),
          // Add Asset Button (pass type when on category page)
          FilledButton.icon(
            onPressed: () {
              final location = GoRouterState.of(context).matchedLocation;
              final typeId = location.startsWith('/category/')
                  ? location.replaceFirst('/category/', '')
                  : null;
              context.go(
                typeId != null ? '/add-asset?type=$typeId' : '/add-asset',
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: kPrimaryGreen,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: Text(
              'New Asset',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sidebar ─────────────────────────────────────────────────────────────────

class _Sidebar extends ConsumerWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetTypes = ref.watch(assetTypesProvider);
    final location = GoRouterState.of(context).matchedLocation;

    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: kBgColor,
        border: Border(right: BorderSide(color: kBorderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kPrimaryGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.health_and_safety,
                    color: kPrimaryGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'AssetVault',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Main Nav
          _SidebarItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            isSelected: location == '/',
            onTap: () => context.go('/'),
          ),
          const SizedBox(height: 4),
          _SidebarItem(
            icon: Icons.inventory_2_outlined,
            label: 'All Assets',
            isSelected: location == '/all-assets',
            onTap: () => context.go('/all-assets'),
          ),

          const SizedBox(height: 32),

          // Categories Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              'CATEGORIES',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: kTextMuted,
                letterSpacing: 1.2,
              ),
            ),
          ),

          // Categories List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: assetTypes.length,
              itemBuilder: (context, index) {
                final type = assetTypes[index];
                final targetPath = '/category/${type.id}';
                return _SidebarItem(
                  icon: getIconData(type.icon),
                  label: type.name,
                  iconColor: getTypeColor(type.id),
                  isSelected: location == targetPath,
                  onTap: () => context.go(targetPath),
                );
              },
            ),
          ),

          // Bottom Settings Nav
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: _SidebarItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              isSelected: location.startsWith('/settings'),
              onTap: () => context.go('/settings'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationBell extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets = ref.watch(assetsProvider);
    final now = DateTime.now();
    final expiringSoon = assets.where((a) {
      if (a.expireAt == null || a.isArchived) return false;
      final days = DateTime.fromMillisecondsSinceEpoch(
        a.expireAt!,
      ).difference(now).inDays;
      return days >= 0 && days <= 30;
    }).toList()..sort((a, b) => a.expireAt!.compareTo(b.expireAt!));

    return Stack(
      children: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.notifications_none_rounded, color: kTextMuted),
          tooltip: 'Notifications',
          color: kSurfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          offset: const Offset(0, 40),
          itemBuilder: (ctx) {
            if (expiringSoon.isEmpty) {
              return [
                const PopupMenuItem(
                  enabled: false,
                  child: Text(
                    'No upcoming expirations',
                    style: TextStyle(color: kTextMuted, fontSize: 13),
                  ),
                ),
              ];
            }
            return expiringSoon.take(8).map((a) {
              final days = DateTime.fromMillisecondsSinceEpoch(
                a.expireAt!,
              ).difference(now).inDays;
              final dateStr = DateTime.fromMillisecondsSinceEpoch(
                a.expireAt!,
              ).toLocal().toString().split(' ')[0];
              return PopupMenuItem<String>(
                value: a.id,
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: days <= 7
                          ? const Color(0xFFFF5252)
                          : const Color(0xFFFFB74D),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.name,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Expires $dateStr ($days days)',
                            style: const TextStyle(
                              fontSize: 11,
                              color: kTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList();
          },
          onSelected: (id) => context.go('/asset/$id'),
        ),
        if (expiringSoon.isNotEmpty)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color:
                    expiringSoon.any(
                      (a) =>
                          DateTime.fromMillisecondsSinceEpoch(
                            a.expireAt!,
                          ).difference(now).inDays <=
                          7,
                    )
                    ? const Color(0xFFFF5252)
                    : const Color(0xFFFFB74D),
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    this.iconColor,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color? iconColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? kSurfaceColor : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? (iconColor ?? kPrimaryGreen) : kTextMuted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? (iconColor ?? kPrimaryGreen)
                          : kTextMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
