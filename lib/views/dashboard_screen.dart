import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/assets_provider.dart';
import '../providers/asset_types_provider.dart';
import '../utils/icon_helper.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets = ref.watch(assetsProvider);
    final assetTypes = ref.watch(assetTypesProvider);

    final now = DateTime.now();
    final approachingExpirations = assets.where((a) {
      if (a.expireAt == null) return false;
      final diffDays = DateTime.fromMillisecondsSinceEpoch(a.expireAt!).difference(now).inDays;
      return diffDays >= 0 && diffDays <= 30; // within 30 days
    }).toList();
    
    approachingExpirations.sort((a, b) => a.expireAt!.compareTo(b.expireAt!));

    double totalMonthlyCost = 0;
    for (var asset in assets) {
      final costField = asset.fields.where((f) => f.key == 'cost').firstOrNull;
      final cycleField = asset.fields.where((f) => f.key == 'billing_cycle').firstOrNull;
      if (costField != null && !costField.isSensitive && costField.valueEnc.isNotEmpty) {
        final val = double.tryParse(costField.valueEnc) ?? 0;
        final cycle = cycleField != null && !cycleField.isSensitive ? cycleField.valueEnc.toLowerCase() : '';
        if (cycle.contains('year') || cycle.contains('年')) {
          totalMonthlyCost += val / 12;
        } else {
          totalMonthlyCost += val;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'), // Assuming /settings exists or will be added
          )
        ],
      ),
      body: assets.isEmpty
          ? const Center(child: Text('No assets yet. Add one!'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: Row(
                    children: [
                      Expanded(
                        child: Card(
                          color: Colors.deepPurple.shade900,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Total Assets', style: TextStyle(color: Colors.white70)),
                              Text('${assets.length}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Card(
                          color: Colors.orange.shade900,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Expiring soon', style: TextStyle(color: Colors.white70)),
                              Text('${approachingExpirations.length}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Card(
                          color: Colors.teal.shade900,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Monthly Cost', style: TextStyle(color: Colors.white70)),
                              Text('\$${totalMonthlyCost.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Expiring within 30 days:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (approachingExpirations.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('All good! No immediate expirations.', style: TextStyle(color: Colors.green)),
                  )
                else
                  ...approachingExpirations.map((a) {
                    final daysLeft = DateTime.fromMillisecondsSinceEpoch(a.expireAt!).difference(now).inDays;
                    return Tooltip(
                      message: 'View details for ${a.name}',
                      child: ListTile(
                        hoverColor: Colors.deepPurple.withOpacity(0.1),
                        leading: const Icon(Icons.warning, color: Colors.orange),
                        title: Text(a.name),
                        subtitle: Text('Expires in $daysLeft days'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go('/asset/${a.id}'),
                      ),
                    );
                  }),
                const Divider(),
                const Text('All Assets:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ...assets.map((asset) {
                  final assetType = assetTypes.firstWhere((t) => t.id == asset.typeId, orElse: () => assetTypes.first);
                  return Tooltip(
                    message: 'View details for ${asset.name}',
                    child: ListTile(
                      hoverColor: Colors.deepPurple.withOpacity(0.1),
                      leading: Icon(getIconData(assetType.icon)),
                      title: Text(asset.name),
                      subtitle: Text(assetType.name),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/asset/${asset.id}'),
                    ),
                  );
                }),
              ],
            ),
      floatingActionButton: Tooltip(
        message: 'Add New Asset (Cmd+N)',
        child: FloatingActionButton(
          onPressed: () => context.go('/add-asset'),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
