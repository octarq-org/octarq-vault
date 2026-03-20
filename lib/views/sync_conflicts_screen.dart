import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';
import '../providers/assets_provider.dart';
import '../providers/sync_conflicts_provider.dart';
import '../widgets/sync_conflict_widgets.dart';

class SyncConflictsScreen extends ConsumerWidget {
  const SyncConflictsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final pending = ref.watch(pendingSyncConflictsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(l10n.syncConflictsScreenTitle),
        backgroundColor: kSurfaceColor,
      ),
      body: pending.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.syncConflictsEmpty,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pending.length,
              itemBuilder: (context, index) {
                final c = pending[index];
                return Card(
                  color: kSurfaceColor,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          c.local.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.syncConflictSameTime,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ConflictVersionCard(
                          label: l10n.syncConflictVersionThisDevice,
                          asset: c.local,
                        ),
                        const SizedBox(height: 8),
                        ConflictVersionCard(
                          label: l10n.syncConflictVersionRemote,
                          asset: c.remote,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  ref
                                      .read(
                                        pendingSyncConflictsProvider.notifier,
                                      )
                                      .removeForAsset(c.local.id);
                                },
                                child: Text(l10n.keepThisDevice),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: () async {
                                  await ref
                                      .read(assetsProvider.notifier)
                                      .updateAsset(c.remote);
                                  ref
                                      .read(
                                        pendingSyncConflictsProvider.notifier,
                                      )
                                      .removeForAsset(c.local.id);
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: kPrimaryGreen,
                                  foregroundColor: Colors.black,
                                ),
                                child: Text(l10n.keepRemoteDevice),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
