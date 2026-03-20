import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:octarq_vault/models/asset.dart';
import 'package:octarq_vault/providers/auth_provider.dart';
import 'package:octarq_vault/providers/sync_conflicts_provider.dart';
import 'package:octarq_vault/services/e2ee_sync_service.dart';

Asset _asset(String id, String name) {
  return Asset(
    id: id,
    typeId: 't',
    name: name,
    createdAt: 1,
    updatedAt: 100,
    fields: const [],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('mergeFrom dedupes by asset id', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    for (var i = 0; i < 80; i++) {
      await Future<void>.delayed(Duration.zero);
      if (container.read(authProvider) != AuthState.initializing) break;
    }

    final a = _asset('1', 'local');
    final c1 = AssetConflict(
      local: a,
      remote: a.copyWith(name: 'remote-v1'),
    );
    container.read(pendingSyncConflictsProvider.notifier).mergeFrom([c1]);
    expect(container.read(pendingSyncConflictsProvider), hasLength(1));
    expect(
      container.read(pendingSyncConflictsProvider).single.remote.name,
      'remote-v1',
    );

    final c2 = AssetConflict(
      local: a,
      remote: a.copyWith(name: 'remote-v2'),
    );
    container.read(pendingSyncConflictsProvider.notifier).mergeFrom([c2]);
    expect(container.read(pendingSyncConflictsProvider), hasLength(1));
    expect(
      container.read(pendingSyncConflictsProvider).single.remote.name,
      'remote-v2',
    );
  });

  test('removeForAsset drops one entry', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    for (var i = 0; i < 80; i++) {
      await Future<void>.delayed(Duration.zero);
      if (container.read(authProvider) != AuthState.initializing) break;
    }

    final c1 = AssetConflict(local: _asset('1', 'a'), remote: _asset('1', 'b'));
    final c2 = AssetConflict(local: _asset('2', 'c'), remote: _asset('2', 'd'));
    container.read(pendingSyncConflictsProvider.notifier).mergeFrom([c1, c2]);
    container.read(pendingSyncConflictsProvider.notifier).removeForAsset('1');
    final left = container.read(pendingSyncConflictsProvider);
    expect(left, hasLength(1));
    expect(left.single.local.id, '2');
  });
}
