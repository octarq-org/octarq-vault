import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../main.dart';
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
          // Notification Bell
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded, color: kTextMuted),
            splashRadius: 20,
          ),
          const SizedBox(width: 16),
          // Add Asset Button
          FilledButton.icon(
            onPressed: () => context.go('/add-asset'),
            style: FilledButton.styleFrom(
              backgroundColor: kPrimaryGreen,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: Text('New Asset', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
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
                  child: const Icon(Icons.health_and_safety, color: kPrimaryGreen),
                ),
                const SizedBox(width: 12),
                Text(
                  'AssetVault',
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
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
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? (iconColor ?? kPrimaryGreen) : kTextMuted,
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
