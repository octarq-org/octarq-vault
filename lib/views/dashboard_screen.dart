import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/assets_provider.dart';
import '../providers/asset_types_provider.dart';
import '../providers/sync_conflicts_provider.dart';
import '../providers/sync_settings_provider.dart';
import '../utils/icon_helper.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';

String _dashboardFormatSyncTime(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  String pad(int n) => n.toString().padLeft(2, '0');
  return '${dt.year}-${pad(dt.month)}-${pad(dt.day)} ${pad(dt.hour)}:${pad(dt.minute)}';
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final assets = ref.watch(assetsProvider);
    final assetTypes = ref.watch(assetTypesProvider);

    final now = DateTime.now();
    final approachingExpirations = assets.where((a) {
      if (a.expireAt == null) return false;
      final diff = DateTime.fromMillisecondsSinceEpoch(
        a.expireAt!,
      ).difference(now).inDays;
      return diff >= 0 && diff <= 30;
    }).toList()..sort((a, b) => a.expireAt!.compareTo(b.expireAt!));

    double totalMonthlyCost = 0;
    for (var asset in assets) {
      final costField = asset.fields.where((f) => f.key == 'cost').firstOrNull;
      final cycleField = asset.fields
          .where((f) => f.key == 'billing_cycle')
          .firstOrNull;
      if (costField != null &&
          !costField.isSensitive &&
          costField.valueEnc.isNotEmpty) {
        final val = double.tryParse(costField.valueEnc) ?? 0;
        final cycle = cycleField != null && !cycleField.isSensitive
            ? cycleField.valueEnc.toLowerCase()
            : '';
        if (cycle.contains('year') ||
            cycle.contains('年') ||
            cycle == 'yearly') {
          totalMonthlyCost += val / 12;
        } else {
          totalMonthlyCost += val;
        }
      }
    }

    final recentAssets = [...assets]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recentSlice = recentAssets.take(5).toList();

    final pendingConflicts = ref.watch(pendingSyncConflictsProvider);
    final syncMethods = ref.watch(syncSettingsProvider);
    final lastSync = ref.watch(lastSyncAtProvider);
    final String syncStatusValue;
    if (syncMethods.isEmpty) {
      syncStatusValue = l10n.syncStatusNotConfigured;
    } else {
      syncStatusValue = lastSync.when(
        data: (dt) =>
            dt == null ? l10n.syncStatusNever : _dashboardFormatSyncTime(dt),
        loading: () => '…',
        error: (_, _) => l10n.syncStatusNever,
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: assets.isEmpty
          ? _EmptyState(onAddAsset: () => context.go('/add-asset'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Stat cards ──────────────────────────────────
                  Row(
                    children: [
                      _StatCard(
                        title: l10n.totalAssets,
                        value: '${assets.length}',
                        icon: Icons.inventory_2_outlined,
                        iconColor: kPrimaryGreen,
                      ),
                      const SizedBox(width: 16),
                      _StatCard(
                        title: l10n.expiringWithin30Days,
                        value: '${approachingExpirations.length}',
                        icon: Icons.warning_amber_rounded,
                        iconColor: const Color(0xFFFFB74D),
                        valueColor: approachingExpirations.isNotEmpty
                            ? const Color(0xFFFFB74D)
                            : null,
                        onTap: () =>
                            context.go('/all-assets?filter=expiring-soon'),
                      ),
                      const SizedBox(width: 16),
                      _StatCard(
                        title: l10n.estMonthlyCost,
                        value: '\$${totalMonthlyCost.toStringAsFixed(2)}',
                        icon: Icons.trending_up_rounded,
                        iconColor: const Color(0xFF4FC3F7),
                      ),
                      const SizedBox(width: 16),
                      _StatCard(
                        title: l10n.syncStatusTitle,
                        value: syncStatusValue,
                        icon: Icons.cloud_sync_outlined,
                        iconColor: pendingConflicts.isNotEmpty
                            ? const Color(0xFFFF5252)
                            : const Color(0xFF90CAF9),
                        valueColor: pendingConflicts.isNotEmpty
                            ? const Color(0xFFFF8A80)
                            : null,
                        badgeCount: pendingConflicts.isNotEmpty
                            ? pendingConflicts.length
                            : null,
                        onTap: () => context.go(
                          pendingConflicts.isNotEmpty
                              ? '/settings/sync-conflicts'
                              : '/settings/webdav',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Two-column section ───────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Action Required
                      if (approachingExpirations.isNotEmpty)
                        Expanded(
                          child: _SectionCard(
                            header: Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  size: 16,
                                  color: Color(0xFFFFB74D),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.actionRequired,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFFFB74D),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: () => context.go('/all-assets'),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    l10n.viewAll,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: kPrimaryGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            child: Column(
                              children: approachingExpirations.take(4).map((a) {
                                final daysLeft =
                                    DateTime.fromMillisecondsSinceEpoch(
                                      a.expireAt!,
                                    ).difference(now).inDays;
                                final expStr =
                                    DateTime.fromMillisecondsSinceEpoch(
                                      a.expireAt!,
                                    ).toLocal().toString().split(' ')[0];
                                final assetType = assetTypes.firstWhere(
                                  (t) => t.id == a.typeId,
                                  orElse: () => assetTypes.first,
                                );
                                return _ExpiryRow(
                                  name: a.name,
                                  subtitle: assetType.name,
                                  dateStr: expStr,
                                  daysLeft: daysLeft,
                                  onTap: () => context.go('/asset/${a.id}'),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      if (approachingExpirations.isNotEmpty)
                        const SizedBox(width: 16),
                      // Recently Added
                      Expanded(
                        child: _SectionCard(
                          header: Text(
                            l10n.recentlyAdded,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: kTextMuted,
                              letterSpacing: 0.8,
                            ),
                          ),
                          child: Column(
                            children: recentSlice.map((asset) {
                              final assetType = assetTypes.firstWhere(
                                (t) => t.id == asset.typeId,
                                orElse: () => assetTypes.first,
                              );
                              return _AssetRow(
                                asset: asset,
                                assetType: assetType,
                                onTap: () => context.go('/asset/${asset.id}'),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.valueColor,
    this.onTap,
    this.badgeCount,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color? valueColor;
  final VoidCallback? onTap;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    Widget iconWidget = Icon(icon, color: iconColor, size: 28);
    if (badgeCount != null && badgeCount! > 0) {
      iconWidget = Badge(
        label: Text(
          '$badgeCount',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.redAccent,
        child: iconWidget,
      );
    }
    final content = Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: kTextMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? Colors.white,
                ),
              ),
            ],
          ),
        ),
        iconWidget,
      ],
    );
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: kSurfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kBorderColor),
          ),
          child: content,
        ),
      ),
    );
  }
}

// ─── Section Card ──────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.header, required this.child});
  final Widget header;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: header,
          ),
          const Divider(height: 1),
          child,
        ],
      ),
    );
  }
}

// ─── Expiry Row ────────────────────────────────────────────────────────────

class _ExpiryRow extends StatelessWidget {
  const _ExpiryRow({
    required this.name,
    required this.subtitle,
    required this.dateStr,
    required this.daysLeft,
    required this.onTap,
  });

  final String name;
  final String subtitle;
  final String dateStr;
  final int daysLeft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final urgentColor = daysLeft <= 7
        ? const Color(0xFFFF5252)
        : const Color(0xFFFFB74D);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: kTextMuted),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  dateStr,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: urgentColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.of(context)!.expiringSoon,
                  style: TextStyle(
                    fontSize: 11,
                    color: urgentColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Asset Row ─────────────────────────────────────────────────────────────

class _AssetRow extends StatelessWidget {
  const _AssetRow({
    required this.asset,
    required this.assetType,
    required this.onTap,
  });

  final dynamic asset;
  final dynamic assetType;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initials = asset.name.length >= 2
        ? asset.name.substring(0, 2).toUpperCase()
        : asset.name.toUpperCase();
    final color = getTypeColor(assetType.id);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.name,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  if (asset.tags.isNotEmpty) const SizedBox(height: 4),
                  if (asset.tags.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      children: (asset.tags as List)
                          .take(3)
                          .map((t) => _TagChip(name: t.name))
                          .toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: kBorderColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        name,
        style: const TextStyle(fontSize: 11, color: Colors.white70),
      ),
    );
  }
}

// ─── Empty State ────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAddAsset});
  final VoidCallback onAddAsset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: kSurfaceColor,
              shape: BoxShape.circle,
              border: Border.all(color: kBorderColor),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 40,
              color: kTextMuted,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)!.noAssetsYet,
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.addFirstAssetHint,
            style: const TextStyle(color: kTextMuted, fontSize: 14),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAddAsset,
            style: FilledButton.styleFrom(
              backgroundColor: kPrimaryGreen,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: Text(
              AppLocalizations.of(context)!.addAsset,
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
