import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/assets_provider.dart';

class AssetListScreen extends ConsumerWidget {
  const AssetListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets = ref.watch(assetsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Assets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          )
        ],
      ),
      body: ListView.builder(
        itemCount: assets.length,
        itemBuilder: (context, index) {
          final asset = assets[index];
          return ListTile(
            title: Text(asset.name),
            subtitle: Text(asset.typeId),
            onTap: () {},
          );
        },
      ),
    );
  }
}
