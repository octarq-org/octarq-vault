import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/assets_provider.dart';
import '../providers/asset_types_provider.dart';
import '../providers/search_provider.dart';
import '../utils/icon_helper.dart';
import '../main.dart';

class AssetListScreen extends ConsumerStatefulWidget {
  final String? filterTypeId;
  const AssetListScreen({super.key, this.filterTypeId});

  @override
  ConsumerState<AssetListScreen> createState() => _AssetListScreenState();
}

class _AssetListScreenState extends ConsumerState<AssetListScreen> {
  String _sortMode = 'added'; // 'added' | 'name' | 'expiry'

  @override
  Widget build(BuildContext context) {
    final assets = ref.watch(assetsProvider);
    final assetTypes = ref.watch(assetTypesProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    var filtered = assets.where((a) {
      final matchType = widget.filterTypeId == null || a.typeId == widget.filterTypeId;
      final matchSearch = searchQuery.isEmpty ||
          a.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          a.tags.any((t) => t.name.toLowerCase().contains(searchQuery.toLowerCase()));
      return matchType && matchSearch;
    }).toList();

    // Sort
    switch (_sortMode) {
      case 'name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
      case 'expiry':
        filtered.sort((a, b) {
          if (a.expireAt == null && b.expireAt == null) return 0;
          if (a.expireAt == null) return 1;
          if (b.expireAt == null) return -1;
          return a.expireAt!.compareTo(b.expireAt!);
        });
      default: // added
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    final filterTypeName = widget.filterTypeId != null
        ? assetTypes.firstWhere((t) => t.id == widget.filterTypeId, orElse: () => assetTypes.first).name
        : null;

    return Scaffold(
      body: Column(
        children: [
          _ListHeader(
            sortMode: _sortMode,
            onSortChanged: (v) => setState(() => _sortMode = v),
            count: filtered.length,
            typeName: filterTypeName,
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text('No matches found.',
                        style: GoogleFonts.inter(color: kTextMuted, fontSize: 14)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final asset = filtered[index];
                      final assetType = assetTypes.firstWhere(
                        (t) => t.id == asset.typeId,
                        orElse: () => assetTypes.first,
                      );
                      return _AssetTile(
                        asset: asset,
                        assetType: assetType,
                        onTap: () => context.go('/asset/${asset.id}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── List Header ────────────────────────────────────────────────────────────

class _ListHeader extends StatelessWidget {
  const _ListHeader({
    required this.sortMode,
    required this.onSortChanged,
    required this.count,
    this.typeName,
  });

  final String sortMode;
  final ValueChanged<String> onSortChanged;
  final int count;
  final String? typeName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: kBorderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      typeName ?? 'All Assets',
                      style: GoogleFonts.inter(
                          fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    Text('$count items',
                        style: const TextStyle(color: kTextMuted, fontSize: 13)),
                  ],
                ),
              ),
              // Sort dropdown
              _SortDropdown(value: sortMode, onChanged: onSortChanged),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  const _SortDropdown({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  static const _labels = {
    'added': 'Sort by: Added',
    'name': 'Sort by: Name',
    'expiry': 'Sort by: Expiry',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBorderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          dropdownColor: kSurfaceColor,
          style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
          icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: kTextMuted),
          items: _labels.entries
              .map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value),
                  ))
              .toList(),
          onChanged: (v) => v != null ? onChanged(v) : null,
        ),
      ),
    );
  }
}

// ─── Asset Tile ─────────────────────────────────────────────────────────────

class _AssetTile extends StatelessWidget {
  const _AssetTile({
    required this.asset,
    required this.assetType,
    required this.onTap,
  });

  final dynamic asset;
  final dynamic assetType;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initials = (asset.name as String).length >= 2
        ? (asset.name as String).substring(0, 2).toUpperCase()
        : (asset.name as String).toUpperCase();
    final color = getTypeColor(assetType.id);
    final expireAt = asset.expireAt as int?;
    String? dateStr;
    if (expireAt != null) {
      dateStr = DateTime.fromMillisecondsSinceEpoch(expireAt)
          .toLocal()
          .toString()
          .split(' ')[0]
          .replaceAll('-', '–');
    }

    return InkWell(
      onTap: onTap,
      hoverColor: Colors.white.withValues(alpha: 0.03),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Name + type + tags
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(asset.name as String,
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w500, fontSize: 14)),
                      const SizedBox(width: 8),
                      Text('• ${assetType.name}',
                          style: const TextStyle(
                              color: kTextMuted, fontSize: 12)),
                    ],
                  ),
                  if ((asset.tags as List).isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children: (asset.tags as List)
                          .take(4)
                          .map((t) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: kBorderColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(t.name as String,
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.white70)),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            // Date & chevron
            if (dateStr != null) ...[
              const SizedBox(width: 12),
              Text(dateStr,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: kTextMuted)),
            ],
            const SizedBox(width: 8),
            const Icon(Icons.more_horiz, color: kTextMuted, size: 18),
          ],
        ),
      ),
    );
  }
}
