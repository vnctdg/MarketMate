import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:math' as math;

import 'app_state.dart';
import 'models.dart';
import 'storage.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with TickerProviderStateMixin {
  late AnimationController _chartAnimationController;
  late Animation<double> _chartAnimation;

  @override
  void initState() {
    super.initState();
    _chartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _chartAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _chartAnimationController, curve: Curves.easeInOut),
    );
    _chartAnimationController.forward();
  }

  @override
  void dispose() {
    _chartAnimationController.dispose();
    super.dispose();
  }

  void _showDetails(BuildContext context, GroceryListSnapshot s) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.receipt_long, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(s.title)),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Budget', style: Theme.of(context).textTheme.bodyLarge),
                  Text(peso(s.budget), style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Total Spent', style: Theme.of(context).textTheme.bodyLarge),
                  Text(peso(s.total), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                ]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Items Count', style: Theme.of(context).textTheme.bodyLarge),
                  Text('${s.items.length}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Items in this list:', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          SizedBox(
            height: 250,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: s.items.length,
              itemBuilder: (_, i) {
                final e = s.items[i];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                      backgroundImage: e.imageUrl != null && File(e.imageUrl!).existsSync()
                          ? FileImage(File(e.imageUrl!))
                          : null,
                      child: e.imageUrl == null || !File(e.imageUrl!).existsSync()
                          ? Icon(Icons.image_outlined, color: Theme.of(context).colorScheme.onSecondaryContainer, size: 20)
                          : null,
                    ),
                    title: Text(e.name, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Qty: ${e.quantity} × ${peso(e.price)} = ${peso(e.totalPrice)}', 
                             style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        if (e.barcode != null)
                          Text('Barcode: ${e.barcode}', 
                               style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ],
                    ),
                    trailing: Text(peso(e.totalPrice), 
                                   style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: const Text('Close')
        )
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (context, app, _) {
      return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Hero(
                tag: 'history-icon',
                child: Icon(Icons.history, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 8),
              const Text('Shopping History'),
            ],
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              onPressed: () async {
                final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                  title: const Text('Clear All History?'),
                  content: const Text('This action cannot be undone. All your past shopping lists will be permanently deleted.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false), 
                      child: const Text('Cancel')
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true), 
                      child: const Text('Clear All')
                    )
                  ],
                ));
                if (ok == true) {
                  await Storage.setHistory([]);
                  await app.loadAll();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All history cleared!')));
                }
              }, 
              icon: const Icon(Icons.delete_sweep), 
              tooltip: 'Clear all history'
            ),
          ]
        ),
        body: app.history.isEmpty
            ? Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 80, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 24),
                  Text('No Shopping History Yet.', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text('Complete a grocery list from the "Grocery" tab to save it here for future reference.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              )))
            : Column(
                children: [
                  // Statistics Cards
                  AnimatedBuilder(
                    animation: _chartAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _chartAnimation.value,
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(child: _buildStatCard('Total Trips', '${app.history.length}', Icons.shopping_cart, Colors.blue)),
                              const SizedBox(width: 8),
                              Expanded(child: _buildStatCard('Total Spent', peso(_calculateTotalSpent(app.history)), Icons.attach_money, Colors.green)),
                              const SizedBox(width: 8),
                              Expanded(child: _buildStatCard('Avg. Trip', peso(_calculateAverageSpent(app.history)), Icons.trending_up, Colors.orange)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  // History List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: app.history.length,
                      itemBuilder: (context, i) {
                        final s = app.history[i];
                        return AnimatedBuilder(
                          animation: _chartAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, (1 - _chartAnimation.value) * 50),
                              child: Opacity(
                                opacity: _chartAnimation.value,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _showDetails(context, s),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.surface,
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                          gradient: LinearGradient(
                                            colors: [
                                              Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.6),
                                              Theme.of(context).colorScheme.surface,
                                            ],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                            stops: const [0.0, 0.7],
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 25,
                                              backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                                              child: Icon(Icons.receipt_long, color: Theme.of(context).colorScheme.onTertiaryContainer, size: 28),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(s.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    s.createdAt.toLocal().toString().substring(0, 16),
                                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text('${s.items.length} items', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.secondary)),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(peso(s.total), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                                                Text('Budget: ${peso(s.budget)}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                                const SizedBox(height: 8),
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      onPressed: () async {
                                                        final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                                                          title: const Text('Re-add This List?'),
                                                          content: Text('This will add all ${s.items.length} items from "${s.title}" back to your current grocery list.'),
                                                          actions: [
                                                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                                            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Re-add')),
                                                          ],
                                                        ));
                                                        if (ok == true) {
                                                          await app.reAddHistory(s.id);
                                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Re-added ${s.items.length} items to your current list!')));
                                                        }
                                                      },
                                                      icon: const Icon(Icons.add_shopping_cart),
                                                      iconSize: 20,
                                                      tooltip: 'Re-add to current list',
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
      );
    });
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  double _calculateTotalSpent(List<GroceryListSnapshot> history) {
    return history.fold(0.0, (sum, snapshot) => sum + snapshot.total);
  }

  double _calculateAverageSpent(List<GroceryListSnapshot> history) {
    if (history.isEmpty) return 0.0;
    return _calculateTotalSpent(history) / history.length;
  }
}
