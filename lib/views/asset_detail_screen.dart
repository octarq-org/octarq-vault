import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/field.dart';
import '../providers/assets_provider.dart';
import '../providers/asset_types_provider.dart';
import '../providers/service_providers.dart';
import '../providers/relations_provider.dart';
import '../utils/icon_helper.dart';
import '../main.dart';

const _relationTypes = [
  'Hosted On',
  'Depends On',
  'Uses',
  'Managed By',
  'Related To',
  'Linked Account',
];

class AssetDetailScreen extends ConsumerStatefulWidget {
  final String assetId;
  const AssetDetailScreen({super.key, required this.assetId});

  @override
  ConsumerState<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends ConsumerState<AssetDetailScreen> {
  bool _showSecrets = false;

  void _deleteAsset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Delete Asset'),
        content: const Text(
          'Are you sure you want to permanently delete this asset?',
          style: TextStyle(color: kTextMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(assetsProvider.notifier).deleteAsset(widget.assetId);
      if (mounted) context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final assets = ref.watch(assetsProvider);
    final assetTypes = ref.watch(assetTypesProvider);

    final asset = assets.firstWhere(
      (a) => a.id == widget.assetId,
      orElse: () => throw StateError('Item missing'),
    );

    final assetType = assetTypes.firstWhere(
      (t) => t.id == asset.typeId,
      orElse: () => assetTypes.first,
    );
    final encryptionService = ref.read(encryptionServiceProvider);
    final relationsAsync = ref.watch(assetRelationsProvider(widget.assetId));
    final typeColor = getTypeColor(assetType.id);
    final typeIcon = getIconData(assetType.icon);

    final now = DateTime.now();
    bool isExpiring = false;
    if (asset.expireAt != null) {
      final days = DateTime.fromMillisecondsSinceEpoch(
        asset.expireAt!,
      ).difference(now).inDays;
      isExpiring = days <= 30;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(asset.name),
        actions: [
          IconButton(
            icon: Icon(
              _showSecrets
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 20,
            ),
            tooltip: _showSecrets ? 'Hide secrets' : 'Reveal secrets',
            onPressed: () => setState(() => _showSecrets = !_showSecrets),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              size: 20,
              color: Colors.redAccent,
            ),
            tooltip: 'Delete asset',
            onPressed: _deleteAsset,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── Hero header ──────────────────────────────────────────
          _HeroHeader(
            asset: asset,
            assetType: assetType,
            typeColor: typeColor,
            typeIcon: typeIcon,
            isExpiring: isExpiring,
          ),
          const SizedBox(height: 24),

          // ── Details ──────────────────────────────────────────────
          _SectionTitle('Details'),
          const SizedBox(height: 10),
          _DetailCard(
            children: [
              _DetailRow(
                label: 'Type',
                value: assetType.name,
                icon: typeIcon,
                iconColor: typeColor,
              ),
              if (asset.expireAt != null)
                _DetailRow(
                  label: 'Expiration Date',
                  value: DateTime.fromMillisecondsSinceEpoch(
                    asset.expireAt!,
                  ).toLocal().toString().split(' ')[0],
                  icon: Icons.calendar_today_outlined,
                  iconColor: isExpiring ? const Color(0xFFFFB74D) : kTextMuted,
                  valueColor: isExpiring ? const Color(0xFFFFB74D) : null,
                ),
              _DetailRow(
                label: 'Added',
                value: DateTime.fromMillisecondsSinceEpoch(
                  asset.createdAt,
                ).toLocal().toString().split('.')[0],
                icon: Icons.access_time_outlined,
                iconColor: kTextMuted,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Fields ───────────────────────────────────────────────
          if (assetType.fieldSchema.isNotEmpty) ...[
            _SectionTitle('Fields'),
            const SizedBox(height: 10),
            _DetailCard(
              children: assetType.fieldSchema.map((schema) {
                final AssetField? fieldData = asset.fields
                    .where((f) => f.key == schema.key)
                    .cast<AssetField?>()
                    .firstOrNull;

                if (fieldData == null) return const SizedBox.shrink();

                String displayValue = '••••••••';
                if (fieldData.isSensitive && _showSecrets) {
                  try {
                    displayValue = encryptionService.decryptField(
                      fieldData.valueEnc,
                      fieldData.iv,
                    );
                  } catch (_) {
                    displayValue = 'Error decrypting';
                  }
                } else if (!fieldData.isSensitive) {
                  displayValue = fieldData.valueEnc;
                }

                return _FieldRow(
                  label: schema.label,
                  value: displayValue,
                  isSecret: fieldData.isSensitive,
                  onCopy: !fieldData.isSensitive
                      ? () {
                          Clipboard.setData(
                            ClipboardData(text: fieldData.valueEnc),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${schema.label} copied'),
                              duration: const Duration(seconds: 1),
                              backgroundColor: kSurfaceColor,
                            ),
                          );
                        }
                      : null,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // ── Linked Assets ────────────────────────────────────────
          Row(
            children: [
              const Expanded(child: _SectionTitle('Linked Assets')),
              TextButton.icon(
                onPressed: () =>
                    _showLinkDialog(context, assets, widget.assetId, ref),
                icon: const Icon(Icons.add_link, size: 16),
                label: const Text('Link', style: TextStyle(fontSize: 13)),
                style: TextButton.styleFrom(
                  foregroundColor: kPrimaryGreen,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          relationsAsync.when(
            data: (relations) {
              if (relations.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kSurfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kBorderColor),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.link_off, color: kTextMuted, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        'No linked assets.',
                        style: const TextStyle(color: kTextMuted, fontSize: 13),
                      ),
                    ],
                  ),
                );
              }

              return _DetailCard(
                children: relations.map((rel) {
                  final isFromMe = rel['from_asset_id'] == widget.assetId;
                  final otherId = isFromMe
                      ? rel['to_asset_id']
                      : rel['from_asset_id'];
                  final relType = rel['relation_type'] as String;

                  final otherAsset = assets.firstWhere(
                    (a) => a.id == otherId,
                    orElse: () => assets.first,
                  );
                  final otherType = (ref.watch(assetTypesProvider)).firstWhere(
                    (t) => t.id == otherAsset.typeId,
                    orElse: () => ref.watch(assetTypesProvider).first,
                  );
                  final otherColor = getTypeColor(otherType.id);

                  return _RelationRow(
                    name: otherAsset.name,
                    relType: relType,
                    isFromMe: isFromMe,
                    color: otherColor,
                    onTap: () => context.push('/asset/$otherId'),
                    onRemove: () async {
                      final del = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: kSurfaceColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          title: const Text('Remove Link?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text(
                                'Remove',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (del == true) {
                        await ref
                            .read(relationsControllerProvider)
                            .removeRelation(rel['id'], widget.assetId, otherId);
                      }
                    },
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text(
              'Error loading relations: $err',
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showLinkDialog(
    BuildContext context,
    List<dynamic> allAssets,
    String currentId,
    WidgetRef ref,
  ) {
    String? selectedAssetId;
    String? selectedRelationType;
    final availableAssets = allAssets.where((a) => a.id != currentId).toList();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: kSurfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: Text(
            'Link Asset',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Target asset dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Target Asset'),
                initialValue: selectedAssetId,
                dropdownColor: kSurfaceColor,
                style: const TextStyle(fontSize: 14, color: Colors.white),
                items: availableAssets
                    .map(
                      (a) => DropdownMenuItem<String>(
                        value: a.id as String,
                        child: Text(a.name as String),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setDlgState(() => selectedAssetId = val),
              ),
              const SizedBox(height: 16),
              // Relation type dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Relation Type'),
                initialValue: selectedRelationType,
                dropdownColor: kSurfaceColor,
                style: const TextStyle(fontSize: 14, color: Colors.white),
                items: _relationTypes
                    .map((rt) => DropdownMenuItem(value: rt, child: Text(rt)))
                    .toList(),
                onChanged: (val) =>
                    setDlgState(() => selectedRelationType = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: selectedAssetId != null && selectedRelationType != null
                  ? () async {
                      await ref
                          .read(relationsControllerProvider)
                          .linkAssets(
                            currentId,
                            selectedAssetId!,
                            selectedRelationType!,
                          );
                      if (ctx.mounted) Navigator.pop(ctx);
                    }
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: kPrimaryGreen,
                foregroundColor: Colors.black,
                disabledBackgroundColor: kBorderColor,
              ),
              child: Text(
                'Link',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hero Header ───────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.asset,
    required this.assetType,
    required this.typeColor,
    required this.typeIcon,
    required this.isExpiring,
  });

  final dynamic asset;
  final dynamic assetType;
  final Color typeColor;
  final IconData typeIcon;
  final bool isExpiring;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorderColor),
      ),
      child: Row(
        children: [
          // Large avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(typeIcon, color: typeColor, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset.name as String,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  assetType.name as String,
                  style: const TextStyle(color: kTextMuted, fontSize: 13),
                ),
                if ((asset.tags as List).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: (asset.tags as List)
                        .map(
                          (t) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: kBorderColor,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              t.name as String,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          if (isExpiring)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB74D).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFFB74D).withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 14,
                    color: Color(0xFFFFB74D),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Expiring soon',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFFB74D),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Section Title ──────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: kTextMuted,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ─── Detail Card / Row ──────────────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final nonEmpty = children
        .where((c) => c is! SizedBox || (c).height != 0)
        .toList();
    if (nonEmpty.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColor),
      ),
      child: Column(
        children: children
            .where((c) => c is! SizedBox)
            .toList()
            .asMap()
            .entries
            .map(
              (e) => Column(
                children: [
                  if (e.key > 0)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                  e.value,
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: kTextMuted, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.label,
    required this.value,
    required this.isSecret,
    this.onCopy,
  });

  final String label;
  final String value;
  final bool isSecret;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isSecret)
            const Padding(
              padding: EdgeInsets.only(right: 10, top: 1),
              child: Icon(Icons.lock_outline, size: 14, color: kTextMuted),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: kTextMuted, fontSize: 11),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFeatures: isSecret && value == '••••••••' ? null : null,
                  ),
                ),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              icon: const Icon(Icons.copy, size: 14, color: kTextMuted),
              onPressed: onCopy,
              tooltip: 'Copy',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
        ],
      ),
    );
  }
}

// ─── Relation Row ───────────────────────────────────────────────────────────

class _RelationRow extends StatelessWidget {
  const _RelationRow({
    required this.name,
    required this.relType,
    required this.isFromMe,
    required this.color,
    required this.onTap,
    required this.onRemove,
  });

  final String name;
  final String relType;
  final bool isFromMe;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final initials = name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name.toUpperCase();

    return InkWell(
      onTap: onTap,
      onLongPress: onRemove,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 12,
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
                    name,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        isFromMe ? Icons.arrow_forward : Icons.arrow_back,
                        size: 12,
                        color: kPrimaryGreen,
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: kPrimaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: kPrimaryGreen.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          relType,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: kPrimaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: kTextMuted, size: 18),
          ],
        ),
      ),
    );
  }
}
