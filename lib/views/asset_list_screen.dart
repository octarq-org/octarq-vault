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
  final bool filterExpiringSoon;
  const AssetListScreen({
    super.key,
    this.filterTypeId,
    this.filterExpiringSoon = false,
  });

  @override
  ConsumerState<AssetListScreen> createState() => _AssetListScreenState();
}

class _AssetListScreenState extends ConsumerState<AssetListScreen> {
  String _sortMode = 'added';
  bool _showArchived = false;

  /// 'all' | 'expiring-soon' (0-30 days) | 'expired'
  String _expiryFilter = 'all';

  @override
  void initState() {
    super.initState();
    if (widget.filterExpiringSoon) {
      _sortMode = 'expiry';
      _expiryFilter = 'expiring-soon';
    }
  }

  @override
  void didUpdateWidget(covariant AssetListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filterExpiringSoon && _expiryFilter != 'expiring-soon') {
      _sortMode = 'expiry';
      _expiryFilter = 'expiring-soon';
    }
  }

  final Set<String> _selectedIds = {};
  bool get _isSelectMode => _selectedIds.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final assets = ref.watch(assetsProvider);
    final assetTypes = ref.watch(assetTypesProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final now = DateTime.now();

    var filtered = assets.where((a) {
      if (_expiryFilter == 'expiring-soon') {
        if (a.expireAt == null) return false;
        final diff = DateTime.fromMillisecondsSinceEpoch(
          a.expireAt!,
        ).difference(now).inDays;
        if (diff < 0 || diff > 30) {
          return false;
        }
      } else if (_expiryFilter == 'expired') {
        if (a.expireAt == null) {
          return false;
        }
        if (DateTime.fromMillisecondsSinceEpoch(a.expireAt!).isAfter(now)) {
          return false;
        }
      }
      if (a.isArchived && widget.filterTypeId == null && !_showArchived) {
        return false;
      }
      final matchType =
          widget.filterTypeId == null || a.typeId == widget.filterTypeId;
      if (searchQuery.isEmpty) return matchType;
      final q = searchQuery.toLowerCase();
      final matchName = a.name.toLowerCase().contains(q);
      final matchTag = a.tags.any((t) => t.name.toLowerCase().contains(q));
      final matchField = a.fields.any(
        (f) => !f.isSensitive && f.valueEnc.toLowerCase().contains(q),
      );
      return matchType && (matchName || matchTag || matchField);
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

    final filterTypeName = _expiryFilter == 'expiring-soon'
        ? 'Expiring in 30 days'
        : _expiryFilter == 'expired'
        ? 'Expired'
        : (widget.filterTypeId != null
              ? assetTypes
                    .firstWhere(
                      (t) => t.id == widget.filterTypeId,
                      orElse: () => assetTypes.first,
                    )
                    .name
              : null);

    return Scaffold(
      body: Column(
        children: [
          _ListHeader(
            sortMode: _sortMode,
            onSortChanged: (v) => setState(() => _sortMode = v),
            expiryFilter: _expiryFilter,
            onExpiryFilterChanged: (v) => setState(() => _expiryFilter = v),
            count: filtered.length,
            typeName: filterTypeName,
            showArchived: _showArchived,
            onToggleArchived: () =>
                setState(() => _showArchived = !_showArchived),
          ),
          if (_isSelectMode)
            _BatchActionBar(
              selectedCount: _selectedIds.length,
              onArchive: () async {
                await ref
                    .read(assetsProvider.notifier)
                    .batchArchive(_selectedIds.toList());
                setState(() => _selectedIds.clear());
              },
              onDelete: () async {
                await ref
                    .read(assetsProvider.notifier)
                    .batchDelete(_selectedIds.toList());
                setState(() => _selectedIds.clear());
              },
              onClear: () => setState(() => _selectedIds.clear()),
            ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No matches found.',
                      style: GoogleFonts.inter(color: kTextMuted, fontSize: 14),
                    ),
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
                      final isSelected = _selectedIds.contains(asset.id);
                      return _AssetTile(
                        asset: asset,
                        assetType: assetType,
                        isSelected: isSelected,
                        onTap: () {
                          if (_isSelectMode) {
                            setState(() {
                              if (isSelected) {
                                _selectedIds.remove(asset.id);
                              } else {
                                _selectedIds.add(asset.id);
                              }
                            });
                          } else {
                            context.go('/asset/${asset.id}');
                          }
                        },
                        onLongPress: () {
                          setState(() => _selectedIds.add(asset.id));
                        },
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

class _BatchActionBar extends StatelessWidget {
  const _BatchActionBar({
    required this.selectedCount,
    required this.onArchive,
    required this.onDelete,
    required this.onClear,
  });
  final int selectedCount;
  final VoidCallback onArchive;
  final VoidCallback onDelete;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      color: kSurfaceColor,
      child: Row(
        children: [
          Text(
            '$selectedCount selected',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: onArchive,
            icon: const Icon(Icons.archive_outlined, size: 16),
            label: const Text('Archive', style: TextStyle(fontSize: 13)),
            style: TextButton.styleFrom(foregroundColor: kPrimaryGreen),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 16),
            label: const Text('Delete', style: TextStyle(fontSize: 13)),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onClear,
            child: const Text('Cancel', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader({
    required this.sortMode,
    required this.onSortChanged,
    required this.expiryFilter,
    required this.onExpiryFilterChanged,
    required this.count,
    this.typeName,
    required this.showArchived,
    required this.onToggleArchived,
  });

  final String sortMode;
  final ValueChanged<String> onSortChanged;
  final String expiryFilter;
  final ValueChanged<String> onExpiryFilterChanged;
  final int count;
  final String? typeName;
  final bool showArchived;
  final VoidCallback onToggleArchived;

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
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$count items',
                      style: const TextStyle(color: kTextMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              _ExpiryFilterDropdown(
                value: expiryFilter,
                onChanged: onExpiryFilterChanged,
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onToggleArchived,
                icon: Icon(
                  showArchived
                      ? Icons.visibility_off_outlined
                      : Icons.archive_outlined,
                  size: 16,
                ),
                label: Text(
                  showArchived ? 'Hide Archived' : 'Show Archived',
                  style: const TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(foregroundColor: kTextMuted),
              ),
              const SizedBox(width: 8),
              _SortDropdown(value: sortMode, onChanged: onSortChanged),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _ExpiryFilterDropdown extends StatelessWidget {
  const _ExpiryFilterDropdown({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  static const _labels = {
    'all': 'All',
    'expiring-soon': 'Expiring in 30d',
    'expired': 'Expired',
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
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: kTextMuted,
          ),
          items: _labels.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: (v) => v != null ? onChanged(v) : null,
        ),
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
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: kTextMuted,
          ),
          items: _labels.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
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
    this.onLongPress,
    this.isSelected = false,
  });

  final dynamic asset;
  final dynamic assetType;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final initials = (asset.name as String).length >= 2
        ? (asset.name as String).substring(0, 2).toUpperCase()
        : (asset.name as String).toUpperCase();
    final color = getTypeColor(assetType.id);
    final expireAt = asset.expireAt as int?;
    final bool isArchived = asset.isArchived as bool;
    String? dateStr;
    if (expireAt != null) {
      dateStr = DateTime.fromMillisecondsSinceEpoch(
        expireAt,
      ).toLocal().toString().split(' ')[0].replaceAll('-', '–');
    }

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      hoverColor: Colors.white.withValues(alpha: 0.03),
      child: Container(
        color: isSelected ? kPrimaryGreen.withValues(alpha: 0.08) : null,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Icon(Icons.check_circle, size: 20, color: kPrimaryGreen),
              ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isArchived ? 0.06 : 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isArchived ? kTextMuted : color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        asset.name as String,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: isArchived ? kTextMuted : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• ${assetType.name}',
                        style: const TextStyle(color: kTextMuted, fontSize: 12),
                      ),
                      if (isArchived) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: kBorderColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Archived',
                            style: TextStyle(fontSize: 10, color: kTextMuted),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if ((asset.tags as List).isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children: (asset.tags as List)
                          .take(4)
                          .map(
                            (t) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: kBorderColor,
                                borderRadius: BorderRadius.circular(4),
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
            if (dateStr != null) ...[
              const SizedBox(width: 12),
              Text(
                dateStr,
                style: GoogleFonts.inter(fontSize: 12, color: kTextMuted),
              ),
            ],
            const SizedBox(width: 8),
            const Icon(Icons.more_horiz, color: kTextMuted, size: 18),
          ],
        ),
      ),
    );
  }
}
