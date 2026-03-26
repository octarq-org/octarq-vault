import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final assetTypes = ref.watch(assetTypesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageAssetTypes),
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
              '${type.fieldSchema.length} ${l10n.fields} ${type.isBuiltIn ? '(Built-in)' : '(Custom)'}',
            ),
            trailing: type.isBuiltIn
                ? null
                : Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => context.push(
                          '/settings/asset-types/${type.id}/edit',
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(l10n.deleteCustomType),
                              content: Text(l10n.deleteCustomTypeConfirmation),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text(l10n.cancel),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: Text(
                                    l10n.delete,
                                    style: const TextStyle(color: Colors.red),
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
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class AssetTypeFormScreen extends ConsumerStatefulWidget {
  final AssetType? editingType;
  const AssetTypeFormScreen({super.key, this.editingType});

  @override
  ConsumerState<AssetTypeFormScreen> createState() =>
      _AssetTypeFormScreenState();
}

class _AssetTypeFormScreenState extends ConsumerState<AssetTypeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedIcon = 'widgets';

  final List<AssetTypeFieldSchema> _fields = [];
  bool get _isEditing => widget.editingType != null;
  String? _loadedEditingTypeId;

  @override
  void initState() {
    super.initState();
    _applyEditingType(widget.editingType);
  }

  @override
  void didUpdateWidget(covariant AssetTypeFormScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.editingType?.id != widget.editingType?.id ||
        oldWidget.editingType?.updatedAt != widget.editingType?.updatedAt) {
      _applyEditingType(widget.editingType);
    }
  }

  void _applyEditingType(AssetType? type) {
    if (type == null) return;
    if (_loadedEditingTypeId == type.id && _fields.isNotEmpty) return;
    _nameController.text = type.name;
    _selectedIcon = type.icon;
    _fields
      ..clear()
      ..addAll(type.fieldSchema.map((f) => f.copyWith()));
    _loadedEditingTypeId = type.id;
  }

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

    final now = DateTime.now().millisecondsSinceEpoch;
    final newType = AssetType(
      id: widget.editingType?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      icon: _selectedIcon,
      isBuiltIn: false,
      fieldSchema: _fields,
      updatedAt: now,
    );

    if (_isEditing) {
      await ref.read(assetTypesProvider.notifier).updateCustomType(newType);
    } else {
      await ref.read(assetTypesProvider.notifier).addCustomType(newType);
    }
    if (mounted) context.go('/settings/asset-types');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.editAsset : l10n.newAssetType),
        actions: [IconButton(icon: const Icon(Icons.check), onPressed: _save)],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.assetTypeNameHint),
              validator: (v) => v == null || v.isEmpty ? l10n.required : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: l10n.icon),
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
                Text(
                  l10n.fieldsConfiguration,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addField),
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
                              decoration: InputDecoration(
                                labelText: l10n.fieldLabelHint,
                              ),
                              onChanged: (v) =>
                                  _fields[idx] = field.copyWith(label: v),
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
                              decoration: InputDecoration(
                                labelText: l10n.dataType,
                              ),
                              initialValue: field.type,
                              items:
                                  [
                                        'text',
                                        'password',
                                        'number',
                                        'date',
                                        'select',
                                      ]
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
                      if (field.type == 'text' || field.type == 'select') ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          initialValue: field.options.join(', '),
                          decoration: const InputDecoration(
                            labelText: 'Common options (comma separated)',
                            hintText: 'e.g. Cloudflare, Namecheap, GoDaddy',
                          ),
                          onChanged: (v) {
                            final parsed = v
                                .split(',')
                                .map((e) => e.trim())
                                .where((e) => e.isNotEmpty)
                                .toList();
                            _fields[idx] = field.copyWith(options: parsed);
                          },
                        ),
                      ],
                      SwitchListTile(
                        title: Text(l10n.aesEncrypted),
                        subtitle: Text(l10n.aesEncryptedSubtitle),
                        value: field.isEncrypted,
                        onChanged: (v) => setState(
                          () => _fields[idx] = field.copyWith(isEncrypted: v),
                        ),
                      ),
                      SwitchListTile(
                        title: Text(l10n.requiredInput),
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
