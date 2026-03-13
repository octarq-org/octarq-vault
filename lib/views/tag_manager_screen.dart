import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../l10n/app_localizations.dart';
import '../models/tag.dart';
import '../providers/assets_provider.dart';
import '../main.dart';

const _tagColors = [
  '#00C896',
  '#4FC3F7',
  '#FFB74D',
  '#FF5252',
  '#BA68C8',
  '#81C784',
  '#F06292',
  '#90A4AE',
  '#FFD54F',
  '#7986CB',
];

class TagManagerScreen extends ConsumerStatefulWidget {
  const TagManagerScreen({super.key});

  @override
  ConsumerState<TagManagerScreen> createState() => _TagManagerScreenState();
}

class _TagManagerScreenState extends ConsumerState<TagManagerScreen> {
  List<Tag> _getAllTags() {
    final assets = ref.watch(assetsProvider);
    final Map<String, Tag> tagMap = {};
    for (final asset in assets) {
      for (final tag in asset.tags) {
        tagMap[tag.id] = tag;
      }
    }
    return tagMap.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  int _getTagUsageCount(String tagId) {
    return ref
        .read(assetsProvider)
        .where((a) => a.tags.any((t) => t.id == tagId))
        .length;
  }

  void _addTag() {
    final nameController = TextEditingController();
    String selectedColor = _tagColors[0];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: kSurfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: Text(
            AppLocalizations.of(ctx)!.newTag,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(ctx)!.tagName,
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(ctx)!.color,
                style: GoogleFonts.inter(fontSize: 12, color: kTextMuted),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tagColors.map((hex) {
                  final color = _parseColor(hex);
                  final isSelected = hex == selectedColor;
                  return GestureDetector(
                    onTap: () => setDlgState(() => selectedColor = hex),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 2.5)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(ctx)!.cancel),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                Navigator.pop(
                  ctx,
                  Tag(
                    id: const Uuid().v4(),
                    name: nameController.text.trim(),
                    color: selectedColor,
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: kPrimaryGreen,
                foregroundColor: Colors.black,
              ),
              child: Text(AppLocalizations.of(ctx)!.create),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteTag(Tag tag) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(l10n.deleteTag),
        content: Text(
          l10n.deleteTagConfirmation(tag.name),
          style: const TextStyle(color: kTextMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.delete,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final notifier = ref.read(assetsProvider.notifier);
    final assets = ref.read(assetsProvider);
    for (final asset in assets) {
      if (asset.tags.any((t) => t.id == tag.id)) {
        final newTags = asset.tags.where((t) => t.id != tag.id).toList();
        await notifier.updateAsset(asset.copyWith(tags: newTags));
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tags = _getAllTags();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageTags),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: kPrimaryGreen),
            onPressed: _addTag,
            tooltip: l10n.addTag,
          ),
        ],
      ),
      body: tags.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.label_off_outlined,
                    size: 48,
                    color: kTextMuted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.noTagsYet,
                    style: GoogleFonts.inter(color: kTextMuted, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.tagsCreatedWhenAdded,
                    style: const TextStyle(color: kTextMuted, fontSize: 13),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: tags.length,
              itemBuilder: (context, index) {
                final tag = tags[index];
                final color = _parseColor(tag.color);
                final count = _getTagUsageCount(tag.id);
                return ListTile(
                  leading: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  title: Text(tag.name),
                  subtitle: Text(
                    l10n.assetCount(count),
                    style: const TextStyle(color: kTextMuted, fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.redAccent,
                    ),
                    onPressed: () => _deleteTag(tag),
                  ),
                );
              },
            ),
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
