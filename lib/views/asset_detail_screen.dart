import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/field.dart';
import '../providers/assets_provider.dart';
import '../providers/asset_types_provider.dart';
import '../providers/service_providers.dart';
import '../providers/relations_provider.dart';

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
      builder: (context) => AlertDialog(
        title: const Text('Delete Asset'),
        content: const Text('Are you sure you want to permanently delete this asset?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(assetsProvider.notifier).deleteAsset(widget.assetId);
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final assets = ref.watch(assetsProvider);
    final assetTypes = ref.watch(assetTypesProvider);
    
    final asset = assets.firstWhere((a) => a.id == widget.assetId, orElse: () => throw StateError('Item missing'));
    
    final assetType = assetTypes.firstWhere((t) => t.id == asset.typeId, orElse: () => assetTypes.first);
    final encryptionService = ref.read(encryptionServiceProvider);
    final relationsAsync = ref.watch(assetRelationsProvider(widget.assetId));

    return Scaffold(
      appBar: AppBar(
        title: Text(asset.name),
        actions: [
          IconButton(
            icon: Icon(_showSecrets ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() {
                _showSecrets = !_showSecrets;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteAsset,
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: const Text('Type'),
            subtitle: Text(assetType.name),
          ),
          ListTile(
            title: const Text('Created'),
            subtitle: Text(DateTime.fromMillisecondsSinceEpoch(asset.createdAt).toLocal().toString().split('.')[0]),
          ),
          if (asset.expireAt != null)
            ListTile(
              title: const Text('Expiration Date', style: TextStyle(color: Colors.redAccent)),
              subtitle: Text(DateTime.fromMillisecondsSinceEpoch(asset.expireAt!).toLocal().toString().split(' ')[0]),
            ),
          if (asset.tags.isNotEmpty) 
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Wrap(
                spacing: 8.0,
                children: asset.tags.map((t) => Chip(
                  label: Text(t.name), 
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                )).toList(),
              ),
            ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Fields:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ...assetType.fieldSchema.map((schema) {
            final AssetField? fieldData = asset.fields
                .where((f) => f.key == schema.key)
                .cast<AssetField?>()
                .firstOrNull;

            // Field was optional and skipped during creation
            if (fieldData == null) return const SizedBox.shrink();

            String displayValue = '********';
            if (fieldData.isSensitive && _showSecrets) {
               try {
                 displayValue = encryptionService.decryptField(fieldData.valueEnc, fieldData.iv);
               } catch (e) {
                 displayValue = 'Error Decrypting';
               }
            } else if (!fieldData.isSensitive) {
               displayValue = fieldData.valueEnc;
            }

            return ListTile(
              title: Text(schema.label),
              subtitle: Text(displayValue),
              trailing: fieldData.isSensitive ? const Icon(Icons.lock, size: 16) : null,
            );
          }),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('Linked Assets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              TextButton.icon(
                icon: const Icon(Icons.link),
                label: const Text('Link'),
                onPressed: () => _showLinkDialog(context, assets, widget.assetId, ref),
              )
            ],
          ),
          relationsAsync.when(
            data: (relations) {
              if (relations.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('No linked assets.', style: TextStyle(color: Colors.grey)),
                );
              }
              return Column(
                children: relations.map((rel) {
                  final isFromMe = rel['from_asset_id'] == widget.assetId;
                  final otherId = isFromMe ? rel['to_asset_id'] : rel['from_asset_id'];
                  final relType = rel['relation_type'];
                  
                  final otherAsset = assets.firstWhere((a) => a.id == otherId, orElse: () => assets.first);
                  final directionText = isFromMe ? '→ $relType →' : '← $relType ←';

                  return ListTile(
                    leading: const Icon(Icons.compare_arrows),
                    title: Text(otherAsset.name),
                    subtitle: Text(directionText),
                    trailing: const Icon(Icons.chevron_right),
                    onLongPress: () async {
                      final del = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Remove Link?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove', style: TextStyle(color: Colors.red))),
                          ],
                        )
                      );
                      if (del == true) {
                        await ref.read(relationsControllerProvider).removeRelation(rel['id'], widget.assetId, otherId);
                      }
                    },
                    onTap: () => context.push('/asset/$otherId'),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('Error loading relations: $err'),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showLinkDialog(BuildContext context, List<dynamic> allAssets, String currentId, WidgetRef ref) {
    String? selectedAssetId;
    final typeController = TextEditingController();
    
    final availableAssets = allAssets.where((a) => a.id != currentId).toList();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Link Asset'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Target Asset'),
                    initialValue: selectedAssetId,
                    items: availableAssets.map((a) => DropdownMenuItem<String>(value: a.id, child: Text(a.name))).toList(),
                    onChanged: (val) => setState(() => selectedAssetId = val),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: typeController,
                    decoration: const InputDecoration(labelText: 'Relation Type (e.g. Hosted On, Depends On)'),
                  )
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedAssetId != null && typeController.text.isNotEmpty) {
                      await ref.read(relationsControllerProvider).linkAssets(currentId, selectedAssetId!, typeController.text);
                      if (context.mounted) Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Link'),
                )
              ]
            );
          }
        );
      }
    );
  }
}
