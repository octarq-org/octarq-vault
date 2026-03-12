import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/asset.dart';
import '../models/asset_type.dart';
import '../models/field.dart';
import '../models/tag.dart';
import '../models/reminder.dart';
import '../providers/assets_provider.dart';
import '../providers/asset_types_provider.dart';
import '../providers/relations_provider.dart';
import '../providers/service_providers.dart';
import '../main.dart';

const _relationTypes = [
  'Hosted On',
  'Depends On',
  'Uses',
  'Managed By',
  'Related To',
  'Linked Account',
];

class AssetFormScreen extends ConsumerStatefulWidget {
  final Asset? editingAsset;
  final String? defaultTypeId;
  const AssetFormScreen({super.key, this.editingAsset, this.defaultTypeId});

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
  final Map<String, String?> _selectValues = {};
  final List<Tag> _selectedTags = [];
  final List<Reminder> _reminders = [];
  final List<({String assetId, String relationType})> _pendingLinks = [];

  bool get _isEditing => widget.editingAsset != null;

  @override
  void initState() {
    super.initState();
    if (widget.editingAsset != null) {
      _initForEditing();
    } else if (widget.defaultTypeId != null) {
      _initWithDefaultType();
    }
  }

  void _initForEditing() {
    final asset = widget.editingAsset!;
    _nameController.text = asset.name;
    _selectedTags.addAll(asset.tags);
    _reminders.addAll(asset.reminders);
    if (asset.expireAt != null) {
      _expireAt = DateTime.fromMillisecondsSinceEpoch(asset.expireAt!);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final assetTypes = ref.read(assetTypesProvider);
      final type = assetTypes.firstWhere(
        (t) => t.id == asset.typeId,
        orElse: () => assetTypes.first,
      );
      _onTypeChanged(type);
      final encryptionService = ref.read(encryptionServiceProvider);
      for (final field in asset.fields) {
        if (field.isSensitive) {
          try {
            final plaintext = encryptionService.decryptField(
              field.valueEnc,
              field.iv,
            );
            if (_fieldControllers.containsKey(field.key)) {
              _fieldControllers[field.key]!.text = plaintext;
            } else if (_selectValues.containsKey(field.key)) {
              _selectValues[field.key] = plaintext;
            }
          } catch (_) {}
        } else {
          if (_fieldControllers.containsKey(field.key)) {
            _fieldControllers[field.key]!.text = field.valueEnc;
          } else if (_selectValues.containsKey(field.key)) {
            _selectValues[field.key] = field.valueEnc;
          }
        }
      }
      setState(() {});
    });
  }

  void _initWithDefaultType() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final assetTypes = ref.read(assetTypesProvider);
      final type = assetTypes.firstWhere(
        (t) => t.id == widget.defaultTypeId,
        orElse: () => assetTypes.first,
      );
      _onTypeChanged(type);
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tagInputController.dispose();
    for (var c in _fieldControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _onTypeChanged(AssetType? newType) {
    if (newType == null) return;
    setState(() {
      _selectedType = newType;
      _fieldControllers.clear();
      _selectValues.clear();
      for (final schema in newType.fieldSchema) {
        if (schema.type == 'select') {
          _selectValues[schema.key] = null;
        } else {
          _fieldControllers[schema.key] = TextEditingController();
        }
      }
    });
  }

  Future<void> _selectExpireDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expireAt ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(
          ctx,
        ).copyWith(colorScheme: const ColorScheme.dark(primary: kPrimaryGreen)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _expireAt = picked);
  }

  void _addReminder() {
    showDialog(
      context: context,
      builder: (ctx) {
        int offsetDays = 7;
        String triggerType = 'expiration';
        return StatefulBuilder(
          builder: (context, setDlgState) => AlertDialog(
            backgroundColor: kSurfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            title: Text(
              'Add Reminder',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Trigger Type'),
                  initialValue: triggerType,
                  dropdownColor: kSurfaceColor,
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                  items: const [
                    DropdownMenuItem(
                      value: 'expiration',
                      child: Text('Before Expiration'),
                    ),
                    DropdownMenuItem(
                      value: 'recurring',
                      child: Text('Recurring'),
                    ),
                  ],
                  onChanged: (val) =>
                      setDlgState(() => triggerType = val ?? triggerType),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Days Before'),
                  initialValue: offsetDays,
                  dropdownColor: kSurfaceColor,
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                  items: [3, 7, 14, 30, 60, 90]
                      .map(
                        (d) =>
                            DropdownMenuItem(value: d, child: Text('$d days')),
                      )
                      .toList(),
                  onChanged: (val) =>
                      setDlgState(() => offsetDays = val ?? offsetDays),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _reminders.add(
                      Reminder(
                        id: const Uuid().v4(),
                        assetId: '',
                        triggerType: triggerType,
                        offsetDays: offsetDays,
                        channels: ['push'],
                        isRecurring: triggerType == 'recurring',
                      ),
                    );
                  });
                  Navigator.pop(ctx);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: kPrimaryGreen,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Add'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveAsset() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null) return;

    setState(() => _isSaving = true);

    try {
      final encryptionService = ref.read(encryptionServiceProvider);
      final assetId = widget.editingAsset?.id ?? const Uuid().v4();
      final now = DateTime.now().millisecondsSinceEpoch;

      final List<AssetField> fields = [];
      for (final schema in _selectedType!.fieldSchema) {
        final String value;
        if (schema.type == 'select') {
          value = _selectValues[schema.key] ?? '';
        } else {
          value = _fieldControllers[schema.key]?.text ?? '';
        }
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

        fields.add(
          AssetField(
            id: const Uuid().v4(),
            assetId: assetId,
            key: schema.key,
            valueEnc: valEnc,
            iv: iv,
            isSensitive: schema.isEncrypted,
          ),
        );
      }

      final remindersWithAssetId = _reminders
          .map((r) => r.copyWith(assetId: assetId))
          .toList();

      final asset = Asset(
        id: assetId,
        typeId: _selectedType!.id,
        name: _nameController.text,
        createdAt: widget.editingAsset?.createdAt ?? now,
        updatedAt: now,
        expireAt: _expireAt?.millisecondsSinceEpoch,
        fields: fields,
        tags: _selectedTags,
        reminders: remindersWithAssetId,
      );

      if (_isEditing) {
        await ref.read(assetsProvider.notifier).updateAsset(asset);
      } else {
        await ref.read(assetsProvider.notifier).addAsset(asset);
        for (final p in _pendingLinks) {
          await ref
              .read(relationsControllerProvider)
              .linkAssets(asset.id, p.assetId, p.relationType);
        }
      }

      // Schedule notifications in background so save/navigation are not blocked
      if (_expireAt != null) {
        final notifService = ref.read(notificationServiceProvider);
        final expireAt = _expireAt!;
        final assetName = asset.name;
        final assetId = asset.id;
        final reminders = remindersWithAssetId.toList();
        Future(() async {
          try {
            for (final reminder in reminders) {
              if (reminder.triggerType == 'expiration') {
                await notifService.scheduleExpirationNotification(
                  reminder.id.hashCode,
                  assetName,
                  expireAt,
                  reminder.offsetDays,
                );
              }
            }
            if (reminders.isEmpty) {
              await notifService.scheduleExpirationNotification(
                assetId.hashCode,
                assetName,
                expireAt,
                7,
              );
            }
          } catch (e) {
            debugPrint('Notification scheduling failed (non-critical): $e');
          }
        });
      }

      if (mounted) {
        final returnPath = widget.defaultTypeId != null
            ? '/category/${widget.defaultTypeId}'
            : '/';
        context.go(returnPath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save asset: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final assetTypes = ref.watch(assetTypesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Asset' : 'Add Asset'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: kPrimaryGreen,
                    ),
                  )
                : FilledButton(
                    onPressed: _saveAsset,
                    style: FilledButton.styleFrom(
                      backgroundColor: kPrimaryGreen,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                    ),
                    child: Text(
                      'Save',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel('Basic Info'),
              const SizedBox(height: 12),
              _FormCard(
                children: [
                  DropdownButtonFormField<AssetType>(
                    decoration: const InputDecoration(
                      labelText: 'Asset Type',
                      prefixIcon: Icon(Icons.category_outlined, size: 18),
                    ),
                    initialValue: _selectedType,
                    dropdownColor: kSurfaceColor,
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                    items: assetTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.name),
                      );
                    }).toList(),
                    onChanged: _isEditing ? null : _onTypeChanged,
                    validator: (val) =>
                        val == null ? 'Please select a type' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Asset Name',
                      prefixIcon: Icon(Icons.label_outline, size: 18),
                    ),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Required' : null,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _SectionLabel('Tags'),
              const SizedBox(height: 12),
              _FormCard(
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ..._selectedTags.map(
                        (tag) => _TagChip(
                          label: tag.name,
                          color: _parseColor(tag.color),
                          onDelete: () =>
                              setState(() => _selectedTags.remove(tag)),
                        ),
                      ),
                      SizedBox(
                        width: 160,
                        child: TextField(
                          controller: _tagInputController,
                          style: const TextStyle(fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'Add tag...',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            prefixIcon: Icon(
                              Icons.add_circle_outline,
                              size: 16,
                              color: kPrimaryGreen,
                            ),
                          ),
                          onSubmitted: (val) {
                            if (val.trim().isNotEmpty) {
                              setState(() {
                                _selectedTags.add(
                                  Tag(
                                    id: const Uuid().v4(),
                                    name: val.trim(),
                                    color: '#00C896',
                                  ),
                                );
                                _tagInputController.clear();
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _SectionLabel('Expiration'),
              const SizedBox(height: 12),
              _FormCard(
                children: [
                  InkWell(
                    onTap: _selectExpireDate,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: kTextMuted,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Expiration Date',
                                  style: TextStyle(
                                    color: kTextMuted,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _expireAt == null
                                      ? 'None — tap to set'
                                      : _expireAt!.toLocal().toString().split(
                                          ' ',
                                        )[0],
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: _expireAt != null
                                        ? Colors.white
                                        : kTextMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_expireAt != null)
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                size: 16,
                                color: kTextMuted,
                              ),
                              onPressed: () => setState(() => _expireAt = null),
                              tooltip: 'Clear date',
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Reminders
              Row(
                children: [
                  Expanded(child: _SectionLabel('Reminders')),
                  IconButton(
                    icon: const Icon(
                      Icons.add_alarm,
                      size: 18,
                      color: kPrimaryGreen,
                    ),
                    onPressed: _addReminder,
                    tooltip: 'Add reminder',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_reminders.isEmpty)
                _FormCard(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.notifications_none,
                          size: 18,
                          color: kTextMuted,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _expireAt != null
                              ? 'Default: 7 days before expiry'
                              : 'Set expiration to enable reminders',
                          style: const TextStyle(
                            color: kTextMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              else
                _FormCard(
                  children: _reminders.asMap().entries.map((entry) {
                    final r = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.alarm,
                            size: 16,
                            color: kPrimaryGreen,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${r.triggerType == 'expiration' ? 'Before Expiration' : 'Recurring'}: ${r.offsetDays} days',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 14,
                              color: kTextMuted,
                            ),
                            onPressed: () =>
                                setState(() => _reminders.removeAt(entry.key)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 24,
                              minHeight: 24,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 24),

              // ── Linked Assets ────────────────────────────────────────
              Row(
                children: [
                  const Expanded(child: _SectionLabel('Linked Assets')),
                  TextButton.icon(
                    onPressed: () => _isEditing
                        ? _showLinkDialog(ref, widget.editingAsset!.id)
                        : _showAddPendingLinkDialog(ref),
                    icon: const Icon(Icons.add_link, size: 16),
                    label: const Text(
                      'Add Link',
                      style: TextStyle(fontSize: 13),
                    ),
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
              const SizedBox(height: 12),
              _isEditing
                  ? _buildLinkedAssetsEdit(ref)
                  : _buildPendingLinks(ref),
              const SizedBox(height: 24),

              if (_selectedType != null &&
                  _selectedType!.fieldSchema.isNotEmpty) ...[
                _SectionLabel('Details'),
                const SizedBox(height: 12),
                _FormCard(
                  children: _selectedType!.fieldSchema.asMap().entries.map((
                    entry,
                  ) {
                    final idx = entry.key;
                    final schema = entry.value;
                    return Column(
                      children: [
                        if (idx > 0) const SizedBox(height: 16),
                        _buildFieldWidget(schema),
                      ],
                    );
                  }).toList(),
                ),
                const SizedBox(height: 40),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLinkedAssetsEdit(WidgetRef ref) {
    final relationsAsync = ref.watch(
      assetRelationsProvider(widget.editingAsset!.id),
    );
    final assets = ref.watch(assetsProvider);
    return relationsAsync.when(
      data: (relations) {
        if (relations.isEmpty) {
          return _FormCard(
            children: [
              Row(
                children: [
                  const Icon(Icons.link_off, color: kTextMuted, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    'No linked assets.',
                    style: const TextStyle(color: kTextMuted, fontSize: 13),
                  ),
                ],
              ),
            ],
          );
        }
        return _FormCard(
          children: relations.map((rel) {
            final isFromMe = rel['from_asset_id'] == widget.editingAsset!.id;
            final otherId = isFromMe
                ? rel['to_asset_id'] as String
                : rel['from_asset_id'] as String;
            final otherAsset = assets.where((a) => a.id == otherId).firstOrNull;
            final name = otherAsset?.name ?? otherId;
            final relType = rel['relation_type'] as String;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.link, size: 16, color: kPrimaryGreen),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$name — $relType',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 14, color: kTextMuted),
                    onPressed: () async {
                      await ref
                          .read(relationsControllerProvider)
                          .removeRelation(
                            rel['id'] as String,
                            widget.editingAsset!.id,
                            otherId,
                          );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
      loading: () => _FormCard(
        children: [
          const Center(
            child: SizedBox(
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ],
      ),
      error: (e, _) => _FormCard(
        children: [
          Text(
            'Error: $e',
            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingLinks(WidgetRef ref) {
    final assets = ref.watch(assetsProvider);
    if (_pendingLinks.isEmpty) {
      return _FormCard(
        children: [
          Row(
            children: [
              const Icon(Icons.link_off, color: kTextMuted, size: 18),
              const SizedBox(width: 10),
              Text(
                'No links. Add links to create after save.',
                style: const TextStyle(color: kTextMuted, fontSize: 13),
              ),
            ],
          ),
        ],
      );
    }
    return _FormCard(
      children: _pendingLinks.asMap().entries.map((entry) {
        final p = entry.value;
        final name =
            assets.where((a) => a.id == p.assetId).firstOrNull?.name ??
            p.assetId;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.link, size: 16, color: kPrimaryGreen),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$name — ${p.relationType}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 14, color: kTextMuted),
                onPressed: () =>
                    setState(() => _pendingLinks.removeAt(entry.key)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showLinkDialog(WidgetRef ref, String currentId) {
    final assets = ref.read(assetsProvider);
    final available = assets.where((a) => a.id != currentId).toList();
    if (available.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No other assets to link.')));
      return;
    }
    String? selectedAssetId;
    String? selectedRelationType;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setDlgState) => AlertDialog(
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
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Target Asset'),
                initialValue: selectedAssetId,
                dropdownColor: kSurfaceColor,
                style: const TextStyle(fontSize: 14, color: Colors.white),
                items: available
                    .map(
                      (a) => DropdownMenuItem(value: a.id, child: Text(a.name)),
                    )
                    .toList(),
                onChanged: (v) => setDlgState(() => selectedAssetId = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Relation Type'),
                initialValue: selectedRelationType,
                dropdownColor: kSurfaceColor,
                style: const TextStyle(fontSize: 14, color: Colors.white),
                items: _relationTypes
                    .map((rt) => DropdownMenuItem(value: rt, child: Text(rt)))
                    .toList(),
                onChanged: (v) => setDlgState(() => selectedRelationType = v),
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

  void _showAddPendingLinkDialog(WidgetRef ref) {
    final assets = ref.read(assetsProvider);
    if (assets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No assets to link. Save this asset first, then add links on its detail page.',
          ),
        ),
      );
      return;
    }
    String? selectedAssetId;
    String? selectedRelationType;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setDlgState) => AlertDialog(
          backgroundColor: kSurfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: Text(
            'Link to Asset',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Target Asset'),
                initialValue: selectedAssetId,
                dropdownColor: kSurfaceColor,
                style: const TextStyle(fontSize: 14, color: Colors.white),
                items: assets
                    .map(
                      (a) => DropdownMenuItem(value: a.id, child: Text(a.name)),
                    )
                    .toList(),
                onChanged: (v) => setDlgState(() => selectedAssetId = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Relation Type'),
                initialValue: selectedRelationType,
                dropdownColor: kSurfaceColor,
                style: const TextStyle(fontSize: 14, color: Colors.white),
                items: _relationTypes
                    .map((rt) => DropdownMenuItem(value: rt, child: Text(rt)))
                    .toList(),
                onChanged: (v) => setDlgState(() => selectedRelationType = v),
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
                  ? () {
                      setState(
                        () => _pendingLinks.add((
                          assetId: selectedAssetId!,
                          relationType: selectedRelationType!,
                        )),
                      );
                      Navigator.pop(ctx);
                    }
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: kPrimaryGreen,
                foregroundColor: Colors.black,
                disabledBackgroundColor: kBorderColor,
              ),
              child: Text(
                'Add',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldWidget(AssetTypeFieldSchema schema) {
    if (schema.type == 'select') {
      return DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: schema.label + (schema.isRequired ? ' *' : ''),
        ),
        initialValue: _selectValues[schema.key],
        dropdownColor: kSurfaceColor,
        style: const TextStyle(fontSize: 14, color: Colors.white),
        items: schema.options
            .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
            .toList(),
        onChanged: (val) => setState(() => _selectValues[schema.key] = val),
        validator: (val) {
          if (schema.isRequired && (val == null || val.isEmpty)) {
            return 'Required';
          }
          return null;
        },
      );
    }
    return TextFormField(
      controller: _fieldControllers[schema.key],
      obscureText: schema.type == 'password',
      keyboardType: schema.type == 'number'
          ? TextInputType.number
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: schema.label + (schema.isRequired ? ' *' : ''),
        suffixIcon: schema.isEncrypted
            ? const Icon(Icons.lock, size: 16, color: kTextMuted)
            : null,
      ),
      validator: (val) {
        if (schema.isRequired && (val == null || val.isEmpty)) {
          return 'Required';
        }
        return null;
      },
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return kPrimaryGreen;
    }
  }
}

// ─── Small Shared Widgets ───────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
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

class _FormCard extends StatelessWidget {
  const _FormCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.onDelete, this.color});
  final String label;
  final VoidCallback onDelete;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? kPrimaryGreen;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 4, 6, 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: c,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDelete,
            child: Icon(Icons.close, size: 14, color: c),
          ),
        ],
      ),
    );
  }
}
