import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';
import '../models/asset_type.dart';
import '../providers/assets_provider.dart';
import '../providers/asset_types_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/search_provider.dart';
import '../utils/icon_helper.dart';
import '../providers/auto_lock_provider.dart';
import '../utils/auto_lock.dart';

class MainLayoutScreen extends ConsumerStatefulWidget {
  const MainLayoutScreen({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends ConsumerState<MainLayoutScreen>
    with WidgetsBindingObserver {
  final GlobalKey _searchBoxKey = GlobalKey();
  final GlobalKey _stackKey = GlobalKey();

  /// Timestamp recorded when the app enters the background (paused state).
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed && _pausedAt != null) {
      final limitMinutes = ref.read(autoLockMinutesProvider);
      if (shouldLockAfterBackground(
        pausedAt: _pausedAt!,
        now: DateTime.now(),
        limitMinutes: limitMinutes,
      )) {
        _pausedAt = null;
        ref.read(authProvider.notifier).lock();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const _Sidebar(),
          Expanded(
            key: _stackKey,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  children: [
                    _GlobalTopBar(searchBoxKey: _searchBoxKey),
                    Expanded(child: widget.child),
                  ],
                ),
                Consumer(
                  builder: (context, ref, _) {
                    if (!ref.watch(searchOverlayVisibleProvider)) {
                      return const SizedBox.shrink();
                    }
                    final box =
                        _searchBoxKey.currentContext?.findRenderObject()
                            as RenderBox?;
                    final stackBox =
                        _stackKey.currentContext?.findRenderObject()
                            as RenderBox?;
                    if (box == null ||
                        stackBox == null ||
                        !box.hasSize ||
                        !stackBox.hasSize) {
                      return const SizedBox.shrink();
                    }
                    void close() {
                      ref
                          .read(searchOverlayVisibleProvider.notifier)
                          .setVisible(false);
                    }

                    final localTopLeft = stackBox.globalToLocal(
                      box.localToGlobal(Offset.zero),
                    );
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: close,
                          ),
                        ),
                        Positioned(
                          top: localTopLeft.dy + box.size.height + 4,
                          left: localTopLeft.dx,
                          width: box.size.width,
                          child: _SearchDropdownOverlay(
                            onClose: close,
                            onTapItem: close,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Global Top Bar ──────────────────────────────────────────────────────────

class _GlobalTopBar extends ConsumerStatefulWidget {
  const _GlobalTopBar({required this.searchBoxKey});
  final GlobalKey searchBoxKey;

  @override
  ConsumerState<_GlobalTopBar> createState() => _GlobalTopBarState();
}

class _GlobalTopBarState extends ConsumerState<_GlobalTopBar> {
  final FocusNode _searchFocus = FocusNode();
  bool _unfocusingToShowOverlay = false;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(_onSearchFocusChange);
  }

  @override
  void dispose() {
    _searchFocus.removeListener(_onSearchFocusChange);
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchFocusChange() {
    if (!_searchFocus.hasFocus) {
      if (_unfocusingToShowOverlay) {
        _unfocusingToShowOverlay = false;
        return;
      }
      ref.read(searchOverlayVisibleProvider.notifier).setVisible(false);
    } else {
      _maybeShowSearchOverlay();
    }
  }

  void _maybeShowSearchOverlay() {
    final query = ref.read(searchQueryProvider).trim();
    if (query.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _unfocusingToShowOverlay = true;
      ref.read(searchOverlayVisibleProvider.notifier).setVisible(true);
      // Unfocus so macOS routes pointer events to the dropdown, not the TextField (root cause of "cannot tap").
      _searchFocus.unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(searchOverlayVisibleProvider, (prev, next) {
      if (next == false && _searchFocus.hasFocus) {
        _searchFocus.unfocus();
      }
    });
    ref.listen<String>(searchQueryProvider, (_, query) {
      if (!_searchFocus.hasFocus) return;
      if (query.trim().isEmpty) {
        ref.read(searchOverlayVisibleProvider.notifier).setVisible(false);
      } else {
        _maybeShowSearchOverlay();
      }
    });
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: kBgColor,
        border: Border(bottom: BorderSide(color: kBorderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            key: widget.searchBoxKey,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: kSurfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kBorderColor),
              ),
              child: TextField(
                focusNode: _searchFocus,
                style: const TextStyle(fontSize: 14),
                onChanged: (val) {
                  ref.read(searchQueryProvider.notifier).updateQuery(val);
                  if (_searchFocus.hasFocus && val.trim().isNotEmpty) {
                    _maybeShowSearchOverlay();
                  }
                },
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.searchHint,
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
              AppLocalizations.of(context)!.newAsset,
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

class _SearchDropdownOverlay extends ConsumerWidget {
  const _SearchDropdownOverlay({
    required this.onClose,
    required this.onTapItem,
  });

  final VoidCallback onClose;
  final VoidCallback onTapItem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(searchSuggestionsProvider);
    final total = ref.watch(searchSuggestionsTotalCountProvider);
    final categoryIds = ref.watch(searchMatchingCategoryIdsProvider);
    final assetTypes = ref.watch(assetTypesProvider);
    final l10n = AppLocalizations.of(context)!;

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      color: kSurfaceColor,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320),
          child: ListView(
            /// Use primary: false so the list doesn't take focus; improves desktop tap delivery.
            primary: false,
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              if (suggestions.isEmpty && categoryIds.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Text(
                    l10n.noMatchesFound,
                    style: const TextStyle(fontSize: 13, color: kTextMuted),
                  ),
                )
              else ...[
                ...categoryIds.take(3).map((id) {
                  AssetType? type;
                  try {
                    type = assetTypes.firstWhere((t) => t.id == id);
                  } catch (_) {
                    type = null;
                  }
                  if (type == null) return const SizedBox.shrink();
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      context.go('/category/$id');
                      onTapItem();
                    },
                    child: ListTile(
                      dense: true,
                      leading: Icon(
                        getIconData(type.icon),
                        size: 20,
                        color: getTypeColor(type.id),
                      ),
                      title: Text(
                        type.name,
                        style: GoogleFonts.inter(fontSize: 13),
                      ),
                      subtitle: Text(
                        l10n.categories,
                        style: const TextStyle(fontSize: 11, color: kTextMuted),
                      ),
                    ),
                  );
                }),
                if (categoryIds.isNotEmpty && suggestions.isNotEmpty)
                  const Divider(height: 1),
                ...suggestions.map((asset) {
                  final type = assetTypes.firstWhere(
                    (t) => t.id == asset.typeId,
                    orElse: () => assetTypes.first,
                  );
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      context.go('/asset/${asset.id}');
                      onTapItem();
                    },
                    child: ListTile(
                      dense: true,
                      leading: Icon(
                        getIconData(type.icon),
                        size: 20,
                        color: getTypeColor(type.id),
                      ),
                      title: Text(
                        asset.name,
                        style: GoogleFonts.inter(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                }),
                if (total > suggestions.length) ...[
                  const Divider(height: 1),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      context.go('/all-assets');
                      onTapItem();
                    },
                    child: ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.list,
                        size: 20,
                        color: kTextMuted,
                      ),
                      title: Text(
                        l10n.searchViewAllResults(total),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: kPrimaryGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
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
    final assets = ref.watch(assetsProvider);
    final location = GoRouterState.of(context).matchedLocation;
    final typeCounts = <String, int>{};
    for (final a in assets) {
      typeCounts[a.typeId] = (typeCounts[a.typeId] ?? 0) + 1;
    }

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
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/logo.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.appTitle,
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
            label: AppLocalizations.of(context)!.dashboard,
            isSelected: location == '/',
            onTap: () => context.go('/'),
          ),
          const SizedBox(height: 4),
          _SidebarItem(
            icon: Icons.inventory_2_outlined,
            label: AppLocalizations.of(context)!.allAssets,
            isSelected: location == '/all-assets',
            onTap: () => context.go('/all-assets'),
          ),

          const SizedBox(height: 32),

          // Categories Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              AppLocalizations.of(context)!.categories,
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
                  count: typeCounts[type.id] ?? 0,
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
              label: AppLocalizations.of(context)!.settings,
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
          tooltip: AppLocalizations.of(context)!.notifications,
          color: kSurfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          offset: const Offset(0, 40),
          itemBuilder: (ctx) {
            if (expiringSoon.isEmpty) {
              return [
                PopupMenuItem(
                  enabled: false,
                  child: Text(
                    AppLocalizations.of(ctx)!.noUpcomingExpirations,
                    style: const TextStyle(color: kTextMuted, fontSize: 13),
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
                            AppLocalizations.of(
                              ctx,
                            )!.expiresOnDays(dateStr, days),
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
    this.count,
    this.iconColor,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int? count;
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
                if (count != null)
                  Text(
                    '$count',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? (iconColor ?? kPrimaryGreen)
                          : kTextMuted,
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
