import 'package:flutter/material.dart';

import '../models/asset.dart';

/// Card summarising one version of an asset for conflict resolution.
class ConflictVersionCard extends StatelessWidget {
  const ConflictVersionCard({
    super.key,
    required this.label,
    required this.asset,
  });

  final String label;
  final Asset asset;

  @override
  Widget build(BuildContext context) {
    final updated = DateTime.fromMillisecondsSinceEpoch(asset.updatedAt);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'Updated: ${updated.toLocal()}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Text(
            '${asset.fields.length} field(s)',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
