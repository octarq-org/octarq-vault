import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/asset.dart';
import '../models/asset_type.dart';
import '../models/field.dart';
import '../models/tag.dart';
import '../providers/assets_provider.dart';
import '../providers/asset_types_provider.dart';
import '../providers/service_providers.dart';
import '../main.dart';

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

  // For 'text'/'password'/'number' fields
  final Map<String, TextEditingController> _fieldControllers = {};
  // For 'select' fields — current selected value
  final Map<String, String?> _selectValues = {};

  final List<Tag> _selectedTags = [];

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
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: kPrimaryGreen),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _expireAt = picked);
  }

  Future<void> _saveAsset() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null) return;

    setState(() => _isSaving = true);

    try {
      final encryptionService = ref.read(encryptionServiceProvider);
      final assetId = const Uuid().v4();
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

      if (mounted) context.go('/');
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
        title: const Text('Add Asset'),
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
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                    ),
                    child: Text('Save',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
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
              // ── Type + Name ─────────────────────────────────────────
              _SectionLabel('Basic Info'),
              const SizedBox(height: 12),
              _FormCard(
                children: [
                  // Type dropdown
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
                    onChanged: _onTypeChanged,
                    validator: (val) =>
                        val == null ? 'Please select a type' : null,
                  ),
                  const SizedBox(height: 16),
                  // Name field
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

              // ── Tags ────────────────────────────────────────────────
              _SectionLabel('Tags'),
              const SizedBox(height: 12),
              _FormCard(
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ..._selectedTags.map((tag) => _TagChip(
                            label: tag.name,
                            onDelete: () =>
                                setState(() => _selectedTags.remove(tag)),
                          )),
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
                            prefixIcon: Icon(Icons.add_circle_outline,
                                size: 16, color: kPrimaryGreen),
                          ),
                          onSubmitted: (val) {
                            if (val.trim().isNotEmpty) {
                              setState(() {
                                _selectedTags.add(Tag(
                                  id: const Uuid().v4(),
                                  name: val.trim(),
                                  color: '#00C896',
                                ));
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

              // ── Expiration ─────────────────────────────────────────
              _SectionLabel('Expiration'),
              const SizedBox(height: 12),
              _FormCard(
                children: [
                  InkWell(
                    onTap: _selectExpireDate,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 18, color: kTextMuted),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Expiration Date',
                                    style: const TextStyle(
                                        color: kTextMuted, fontSize: 12)),
                                const SizedBox(height: 2),
                                Text(
                                  _expireAt == null
                                      ? 'None — tap to set'
                                      : _expireAt!
                                          .toLocal()
                                          .toString()
                                          .split(' ')[0],
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
                              icon: const Icon(Icons.close,
                                  size: 16, color: kTextMuted),
                              onPressed: () =>
                                  setState(() => _expireAt = null),
                              tooltip: 'Clear date',
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Type-specific fields ────────────────────────────────
              if (_selectedType != null && _selectedType!.fieldSchema.isNotEmpty) ...[
                _SectionLabel('Details'),
                const SizedBox(height: 12),
                _FormCard(
                  children: _selectedType!.fieldSchema
                      .asMap()
                      .entries
                      .map((entry) {
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
  const _TagChip({required this.label, required this.onDelete});
  final String label;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 4, 6, 4),
      decoration: BoxDecoration(
        color: kPrimaryGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: kPrimaryGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: kPrimaryGreen)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(Icons.close, size: 14, color: kPrimaryGreen),
          ),
        ],
      ),
    );
  }
}
