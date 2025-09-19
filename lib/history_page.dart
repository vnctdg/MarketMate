import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../app_state.dart';
import '../models.dart';
import '../storage.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  void _showDetails(BuildContext context, GroceryListSnapshot s) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text(s.title),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Budget', style: Theme.of(context).textTheme.bodyLarge),
            Text(peso(s.budget), style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Total Spent', style: Theme.of(context).textTheme.bodyLarge),
            Text(peso(s.total), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
          ]),
          const Divider(height: 24),
          Text('Items in this list:', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          SizedBox(
            height: 250,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: s.items.length,
              itemBuilder: (_, i) {
                final e = s.items[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                      backgroundImage: e.imageUrl != null && File(e.imageUrl!).existsSync()
                          ? FileImage(File(e.imageUrl!))
                          : null,
                      child: e.imageUrl == null || !File(e.imageUrl!).existsSync()
                          ? Icon(Icons.image_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20)
                          : null,
                    ),
                    title: Text(e.name, style: Theme.of(context).textTheme.bodyLarge),
                    trailing: Text(peso(e.price), style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                    subtitle: e.barcode != null
                        ? Text('Barcode: ${e.barcode}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant))
                        : null,
                  ),
                );
              },
            ),
          ),
        ]),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Close', style: Theme.of(context).textButtonTheme.style?.textStyle?.resolve(MaterialState.values.toSet())?.copyWith(color: Theme.of(context).colorScheme.primary)))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (context, app, _) {
      return Scaffold(
        appBar: AppBar(title: const Text('Shopping History'), actions: [
          IconButton(onPressed: () async {
            final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
              title: const Text('Clear All History?'),
              content: const Text('This action cannot be undone. All your past shopping lists will be permanently deleted.'),
              actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: Theme.of(context).textButtonTheme.style?.textStyle?.resolve(MaterialState.values.toSet())?.copyWith(color: Theme.of(context).colorScheme.primary))),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: Text('Clear All', style: Theme.of(context).filledButtonTheme.style?.textStyle?.resolve(MaterialState.values.toSet())?.copyWith(color: Theme.of(context).colorScheme.onPrimary)))],
            ));
            if (ok == true) {
              await Storage.setHistory([]);
              await app.loadAll();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All history cleared!')));
            }
          }, icon: const Icon(Icons.delete_sweep), tooltip: 'Clear all history'),
        ]),
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
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: app.history.length,
                itemBuilder: (context, i) {
                  final s = app.history[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Material( // Wrap in Material for InkWell splash
                      color: Colors.transparent, // Important for InkWell
                      child: InkWell(
                        onTap: () => _showDetails(context, s),
                        borderRadius: BorderRadius.circular(16),
                        onHover: (isHovering) {
                          // Example: Visual feedback on hover (for web/desktop)
                          // You might use setState to change color/elevation
                        },
                        child: AnimatedContainer( // Animated for smooth transitions of background/border
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8), // Padding inside the card
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            gradient: LinearGradient( // Subtle gradient background
                              colors: [
                                Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.6), // Stronger tertiary color on left
                                Theme.of(context).colorScheme.surface, // Blends to surface on right
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              stops: const [0.0, 0.5], // Gradient ends halfway
                            ),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                              child: Icon(Icons.receipt_long, color: Theme.of(context).colorScheme.onTertiaryContainer, size: 28),
                            ),
                            title: Text(s.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              s.createdAt.toLocal().toString().substring(0, 16),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(peso(s.total), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                                Text('Budget: ${peso(s.budget)}', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                              ],
                            ),
                            onTap: () => _showDetails(context, s), // Still keep onTap for detail view
                            onLongPress: () async {
                              final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                                title: const Text('Re-add This List?'),
                                content: Text('This will add all ${s.items.length} items from "${s.title}" back to your current grocery list.'),
                                actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: Theme.of(context).textButtonTheme.style?.textStyle?.resolve(MaterialState.values.toSet())?.copyWith(color: Theme.of(context).colorScheme.primary))),
                                FilledButton(onPressed: () => Navigator.pop(context, true), child: Text('Re-add', style: Theme.of(context).filledButtonTheme.style?.textStyle?.resolve(MaterialState.values.toSet())?.copyWith(color: Theme.of(context).colorScheme.onPrimary)))],
                              ));
                              if (ok == true) {
                                await app.reAddHistory(s.id);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Re-added ${s.items.length} items to your current list!')));
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      );
    });
  }
}