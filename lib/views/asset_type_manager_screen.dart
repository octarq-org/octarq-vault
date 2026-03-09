import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../models/asset_type.dart';
import '../providers/asset_types_provider.dart';
import '../utils/icon_helper.dart';

class AssetTypeManagerScreen extends ConsumerStatefulWidget {
  const AssetTypeManagerScreen({super.key});

  @override
  ConsumerState<AssetTypeManagerScreen> createState() =>
      _AssetTypeManagerScreenState();
}

class _AssetTypeManagerScreenState
    extends ConsumerState<AssetTypeManagerScreen> {
  @override
  Widget build(BuildContext context) {
    final assetTypes = ref.watch(assetTypesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Asset Types'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/settings/asset-types/add'),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: assetTypes.length,
        itemBuilder: (context, index) {
          final type = assetTypes[index];
          return ListTile(
            leading: Icon(getIconData(type.icon)),
            title: Text(type.name),
            subtitle: Text(
              '${type.fieldSchema.length} fields ${type.isBuiltIn ? '(Built-in)' : '(Custom)'}',
            ),
            trailing: type.isBuiltIn
                ? null
                : IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Custom Type'),
                          content: const Text(
                            'Are you sure? Existing assets of this type might lose their template mappings.',
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
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await ref
                            .read(assetTypesProvider.notifier)
                            .deleteCustomType(type.id);
                      }
                    },
                  ),
          );
        },
      ),
    );
  }
}

class AssetTypeFormScreen extends ConsumerStatefulWidget {
  const AssetTypeFormScreen({super.key});

  @override
  ConsumerState<AssetTypeFormScreen> createState() =>
      _AssetTypeFormScreenState();
}

class _AssetTypeFormScreenState extends ConsumerState<AssetTypeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedIcon = 'widgets';

  final List<AssetTypeFieldSchema> _fields = [];

  void _addField() {
    setState(() {
      _fields.add(
        AssetTypeFieldSchema(
          key: 'field_${DateTime.now().millisecondsSinceEpoch}',
          label: 'New Field',
          type: 'text',
          isEncrypted: false,
          isRequired: false,
        ),
      );
    });
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final newType = AssetType(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      icon: _selectedIcon,
      isBuiltIn: false,
      fieldSchema: _fields,
    );

    await ref.read(assetTypesProvider.notifier).addCustomType(newType);
    if (mounted) context.go('/settings/asset-types');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Asset Type'),
        actions: [IconButton(icon: const Icon(Icons.check), onPressed: _save)],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Asset Type Name (e.g., Crypto Wallet)',
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Icon'),
              initialValue: _selectedIcon,
              items:
                  [
                        'widgets',
                        'language',
                        'storage',
                        'email',
                        'person',
                        'credit_card',
                        'vpn_key',
                        'cloud',
                        'security',
                      ]
                      .map(
                        (icon) => DropdownMenuItem(
                          value: icon,
                          child: Row(
                            children: [
                              Icon(getIconData(icon)),
                              const SizedBox(width: 8),
                              Text(icon),
                            ],
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (val) => setState(() => _selectedIcon = val!),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Fields Configuration',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Field'),
                  onPressed: _addField,
                ),
              ],
            ),
            const Divider(),
            ..._fields.asMap().entries.map((entry) {
              final idx = entry.key;
              final field = entry.value;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: field.label,
                              decoration: const InputDecoration(
                                labelText: 'Field Label (e.g., Private Key)',
                              ),
                              onChanged: (v) => _fields[idx] = field.copyWith(
                                label: v,
                                key: v.toLowerCase().replaceAll(' ', '_'),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                setState(() => _fields.removeAt(idx)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Data Type',
                              ),
                              initialValue: field.type,
                              items: ['text', 'password', 'number', 'date']
                                  .map(
                                    (t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(t.toUpperCase()),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  _fields[idx] = field.copyWith(type: v!),
                            ),
                          ),
                        ],
                      ),
                      SwitchListTile(
                        title: const Text('AES-256-GCM Encrypted'),
                        subtitle: const Text('Fields like passwords, keys'),
                        value: field.isEncrypted,
                        onChanged: (v) => setState(
                          () => _fields[idx] = field.copyWith(isEncrypted: v),
                        ),
                      ),
                      SwitchListTile(
                        title: const Text('Required Input'),
                        value: field.isRequired,
                        onChanged: (v) => setState(
                          () => _fields[idx] = field.copyWith(isRequired: v),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
