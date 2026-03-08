import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/assets_provider.dart';
import '../providers/asset_types_provider.dart';
import '../utils/icon_helper.dart';

class AssetListScreen extends ConsumerStatefulWidget {
  const AssetListScreen({super.key});

  @override
  ConsumerState<AssetListScreen> createState() => _AssetListScreenState();
}

class _AssetListScreenState extends ConsumerState<AssetListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final assets = ref.watch(assetsProvider);
    final assetTypes = ref.watch(assetTypesProvider);
    
    final filteredAssets = assets.where((a) {
      if (_searchQuery.isEmpty) return true;
      return a.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: const InputDecoration(
            hintText: 'Search assets...',
            border: InputBorder.none,
          ),
          onChanged: (val) {
            setState(() {
              _searchQuery = val;
            });
          },
        ),
      ),
      body: filteredAssets.isEmpty
        ? const Center(child: Text('No matches found.'))
        : ListView.builder(
            itemCount: filteredAssets.length,
            itemBuilder: (context, index) {
              final asset = filteredAssets[index];
              final assetType = assetTypes.firstWhere((t) => t.id == asset.typeId, orElse: () => assetTypes.first);
              return Tooltip(
                message: 'View details for ${asset.name}',
                child: ListTile(
                  hoverColor: Colors.deepPurple.withValues(alpha: 0.1),
                  leading: Icon(getIconData(assetType.icon)),
                  title: Text(asset.name),
                  subtitle: Text(assetType.name),
                  onTap: () => context.go('/asset/${asset.id}'),
                ),
              );
            },
          ),
    );
  }
}
