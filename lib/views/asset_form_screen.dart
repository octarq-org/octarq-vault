import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';

import '../models/asset.dart';
import '../models/asset_type.dart';
import '../models/field.dart';
import '../models/tag.dart';
import '../providers/assets_provider.dart';
import '../providers/asset_types_provider.dart';
import '../providers/service_providers.dart';

class AssetFormScreen extends ConsumerStatefulWidget {
  const AssetFormScreen({super.key});

  @override
  ConsumerState<AssetFormScreen> createState() => _AssetFormScreenState();
}

class _AssetFormScreenState extends ConsumerState<AssetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _tagInputController = TextEditingController();
  
  AssetType? _selectedType;
  DateTime? _expireAt;
  bool _isSaving = false;
  
  final Map<String, TextEditingController> _fieldControllers = {};
  final List<Tag> _selectedTags = [];

  @override
  void dispose() {
    _nameController.dispose();
    _tagInputController.dispose();
    for (var controller in _fieldControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onTypeChanged(AssetType? newType) {
    if (newType == null) return;
    setState(() {
      _selectedType = newType;
      _fieldControllers.clear();
      for (var schema in newType.fieldSchema) {
        _fieldControllers[schema.key] = TextEditingController();
      }
    });
  }

  Future<void> _selectExpireDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expireAt ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _expireAt = picked;
      });
    }
  }

  Future<void> _saveAsset() async {
    if (_isSaving) return; // Prevent duplicate clicks
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null) return;

    setState(() => _isSaving = true);

    try {
      final encryptionService = ref.read(encryptionServiceProvider);
      final assetId = const Uuid().v4();
      final now = DateTime.now().millisecondsSinceEpoch;

      final List<AssetField> fields = [];
      
      for (var schema in _selectedType!.fieldSchema) {
        final value = _fieldControllers[schema.key]!.text;
        if (value.isEmpty && !schema.isRequired) continue;
        
        String valEnc = '';
        String iv = '';
        
        if (schema.isEncrypted) {
          final encResult = encryptionService.encryptField(value);
          valEnc = encResult['valueEnc']!;
          iv = encResult['iv']!;
        } else {
          valEnc = value;
        }

        fields.add(AssetField(
          id: const Uuid().v4(),
          assetId: assetId,
          key: schema.key,
          valueEnc: valEnc,
          iv: iv,
          isSensitive: schema.isEncrypted,
        ));
      }

      final asset = Asset(
        id: assetId,
        typeId: _selectedType!.id,
        name: _nameController.text,
        createdAt: now,
        updatedAt: now,
        expireAt: _expireAt?.millisecondsSinceEpoch,
        fields: fields,
        tags: _selectedTags,
      );

      await ref.read(assetsProvider.notifier).addAsset(asset);
      
      // Schedule notification (non-blocking — don't let notification failures block save)
      if (_expireAt != null) {
        try {
          final notifService = ref.read(notificationServiceProvider);
          await notifService.scheduleExpirationNotification(
            asset.id.hashCode,
            asset.name,
            _expireAt!,
            7,
          );
        } catch (e) {
          debugPrint('Notification scheduling failed (non-critical): $e');
        }
      }
      
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save asset: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final assetTypes = ref.watch(assetTypesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Asset'),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            onPressed: _isSaving ? null : _saveAsset,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<AssetType>(
                decoration: const InputDecoration(labelText: 'Asset Type'),
                initialValue: _selectedType,
                items: assetTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.name),
                  );
                }).toList(),
                onChanged: _onTypeChanged,
                validator: (val) => val == null ? 'Please select a type' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Asset Name (Title)'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Tags',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ..._selectedTags.map((tag) => Chip(
                          label: Text(tag.name),
                          backgroundColor: Colors.blue.withValues(alpha: 0.1),
                          onDeleted: () {
                            setState(() {
                              _selectedTags.remove(tag);
                            });
                          },
                        )),
                    SizedBox(
                      width: 150,
                      child: TextField(
                        controller: _tagInputController,
                        decoration: const InputDecoration(
                          hintText: 'Add a tag...',
                          border: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onSubmitted: (val) {
                          if (val.trim().isNotEmpty) {
                            setState(() {
                              _selectedTags.add(Tag(id: const Uuid().v4(), name: val.trim(), color: '#2196F3'));
                              _tagInputController.clear();
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Expiration Date'),
                subtitle: Text(_expireAt == null ? 'None' : _expireAt!.toLocal().toString().split(' ')[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectExpireDate,
              ),
              if (_expireAt != null)
                TextButton(
                  onPressed: () => setState(() => _expireAt = null),
                  child: const Text('Clear Expiration Date'),
                ),
              const Divider(),
              if (_selectedType != null) ..._selectedType!.fieldSchema.map((schema) {
                return Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: TextFormField(
                    controller: _fieldControllers[schema.key],
                    obscureText: schema.type == 'password',
                    keyboardType: schema.type == 'number' ? TextInputType.number : TextInputType.text,
                    decoration: InputDecoration(
                      labelText: schema.label + (schema.isRequired ? ' *' : ''),
                      suffixIcon: schema.isEncrypted ? const Icon(Icons.lock, size: 16) : null,
                    ),
                    validator: (val) {
                      if (schema.isRequired && (val == null || val.isEmpty)) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                );
              }),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
