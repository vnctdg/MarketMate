import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../app_state.dart';
import '../models.dart';

class ItemsPage extends StatefulWidget {
  const ItemsPage({super.key});
  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  String _query = '';
  final ImagePicker _picker = ImagePicker();
  String? _pickedImagePath;

  Future<void> _addSaved(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final barcodeCtrl = TextEditingController();
    _pickedImagePath = null;

    final result = await showDialog<GroceryItem?>(context: context, builder: (dialogContext) => StatefulBuilder(
      builder: (stfContext, setStfState) {
        return AlertDialog(
          title: const Text('Save New Item'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                GestureDetector(
                  onTap: () async {
                    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
                    if (image != null) {
                      setStfState(() {
                        _pickedImagePath = image.path;
                      });
                    }
                  },
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5), width: 1.5),
                    ),
                    child: _pickedImagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              File(_pickedImagePath!),
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(Icons.add_a_photo, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Item Name', hintText: 'e.g., Apple, Bread'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Item name cannot be empty';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(prefixText: '₱ ', labelText: 'Default Price', hintText: 'e.g., 50.00'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Price cannot be empty';
                    }
                    final parsed = double.tryParse(value.replaceAll(',', ''));
                    if (parsed == null || parsed <= 0) {
                      return 'Enter a valid positive price';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextField(controller: barcodeCtrl, decoration: const InputDecoration(labelText: 'Barcode (optional)', hintText: 'Scan or type barcode')),
              ]),
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('Cancel', style: Theme.of(context).textButtonTheme.style?.textStyle?.resolve(MaterialState.values.toSet())?.copyWith(color: Theme.of(context).colorScheme.primary))),
          FilledButton(onPressed: () {
            if (formKey.currentState?.validate() ?? false) {
              final name = nameCtrl.text.trim();
              final price = double.tryParse(priceCtrl.text.replaceAll(',', ''));
              Navigator.pop(dialogContext, GroceryItem(
                id: makeId(),
                name: name,
                price: price!,
                barcode: barcodeCtrl.text.trim().isEmpty ? null : barcodeCtrl.text.trim(),
                imageUrl: _pickedImagePath,
              ));
            }
          }, child: Text('Save Item', style: Theme.of(context).filledButtonTheme.style?.textStyle?.resolve(MaterialState.values.toSet())?.copyWith(color: Theme.of(context).colorScheme.onPrimary)))],
        );
      }
    ));
    if (result != null) {
      await context.read<AppState>().addSavedItem(result);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${result.name} saved successfully!')));
    }
  }

  Future<void> _mockScan(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final ctrl = TextEditingController();
    final code = await showDialog<String?>(context: context, builder: (_) => AlertDialog(
      title: const Text('Mock Barcode Scan'),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Enter Barcode Value'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Barcode cannot be empty';
            }
            return null;
          },
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: Theme.of(context).textButtonTheme.style?.textStyle?.resolve(MaterialState.values.toSet())?.copyWith(color: Theme.of(context).colorScheme.primary))),
      FilledButton(onPressed: () {
        if (formKey.currentState?.validate() ?? false) {
          Navigator.pop(context, ctrl.text.trim());
        }
      }, child: Text('Scan', style: Theme.of(context).filledButtonTheme.style?.textStyle?.resolve(MaterialState.values.toSet())?.copyWith(color: Theme.of(context).colorScheme.onPrimary)))],
    ));
    if (code == null || code.isEmpty) return;
    final app = context.read<AppState>();
    final found = app.savedItems.where((e) => e.barcode == code).toList();
    if (found.isNotEmpty) {
      await app.addItem(found.first);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Found saved item: "${found.first.name}" (₱${found.first.price.toStringAsFixed(2)})')));
      return;
    }

    final newFormKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    _pickedImagePath = null;
    final result = await showDialog<GroceryItem?>(context: context, builder: (dialogContext) => StatefulBuilder(
      builder: (stfContext, setStfState) {
        return AlertDialog(
          title: Text('New Item for Barcode: $code'),
          content: SingleChildScrollView(
            child: Form(
              key: newFormKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('Barcode: $code', style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
                    if (image != null) {
                      setStfState(() {
                        _pickedImagePath = image.path;
                      });
                    }
                  },
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5), width: 1.5),
                    ),
                    child: _pickedImagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              File(_pickedImagePath!),
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(Icons.add_a_photo, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Item Name'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Item name cannot be empty';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(prefixText: '₱ ', labelText: 'Default Price'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Price cannot be empty';
                    }
                    final parsed = double.tryParse(value.replaceAll(',', ''));
                    if (parsed == null || parsed <= 0) {
                      return 'Enter a valid positive price';
                    }
                    return null;
                  },
                ),
              ]),
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('Cancel', style: Theme.of(context).textButtonTheme.style?.textStyle?.resolve(MaterialState.values.toSet())?.copyWith(color: Theme.of(context).colorScheme.primary))),
          FilledButton(onPressed: () {
            if (newFormKey.currentState?.validate() ?? false) {
              final name = nameCtrl.text.trim();
              final price = double.tryParse(priceCtrl.text.replaceAll(',', ''));
              Navigator.pop(dialogContext, GroceryItem(id: makeId(), name: name, price: price!, barcode: code, imageUrl: _pickedImagePath));
            }
          }, child: Text('Save Item', style: Theme.of(context).filledButtonTheme.style?.textStyle?.resolve(MaterialState.values.toSet())?.copyWith(color: Theme.of(context).colorScheme.onPrimary)))],
        );
      }
    ));
    if (result != null) {
      await context.read<AppState>().addSavedItem(result);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${result.name} saved successfully!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (context, app, _) {
      final items = app.savedItems.where((e) => e.name.toLowerCase().contains(_query.toLowerCase()) || (e.barcode ?? '').contains(_query)).toList();
      return Scaffold(
        appBar: AppBar(title: const Text('My Saved Items'), actions: [
          IconButton(
            onPressed: () => _mockScan(context),
            icon: Icon(Icons.barcode_reader, size: 28, color: Theme.of(context).colorScheme.onSurfaceVariant),
            tooltip: 'Scan Barcode for Item',
          ),
          IconButton(
            onPressed: () => _addSaved(context),
            icon: Icon(Icons.add_circle_outline, size: 28, color: Theme.of(context).colorScheme.onSurfaceVariant),
            tooltip: 'Add New Saved Item',
          ),
        ]),
        body: RefreshIndicator(
          onRefresh: () => app.loadAll(),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  hintText: 'Search saved items by name or barcode',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(
              child: items.isEmpty ? Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 80, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 24),
                  Text('No saved items yet.', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text('Add items to your catalog using the "+" icon above or scan a barcode.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ))) : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final e = items[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Builder( // Use Builder to get context for InkWell
                      builder: (listTileContext) {
                        return Material( // Wrap in Material for InkWell splash
                          color: Colors.transparent, // Important for InkWell
                          child: InkWell(
                            onTap: () { /* Handle tap/details view if needed */ },
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
                                    Theme.of(listTileContext).colorScheme.secondaryContainer.withOpacity(0.6), // Stronger secondary color on left
                                    Theme.of(listTileContext).colorScheme.surface, // Blends to surface on right
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  stops: const [0.0, 0.5], // Gradient ends halfway
                                ),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                                  backgroundImage: e.imageUrl != null && File(e.imageUrl!).existsSync()
                                      ? FileImage(File(e.imageUrl!))
                                      : null,
                                  child: e.imageUrl == null || !File(e.imageUrl!).existsSync()
                                      ? Icon(Icons.image_outlined, color: Theme.of(context).colorScheme.onSecondaryContainer, size: 30)
                                      : null,
                                ),
                                title: Text(e.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  '${peso(e.price)}${e.barcode != null ? ' • ${e.barcode}' : ''}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                ),
                                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                  IconButton(
                                    onPressed: () async {
                                      final copy = e.copyWith(id: makeId());
                                      await app.addItem(copy, persistSaved: false);
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added "${e.name}" to current list!')));
                                    },
                                    icon: Icon(Icons.add_shopping_cart, color: Theme.of(context).colorScheme.secondary),
                                    tooltip: 'Add to current list',
                                  ),
                                  IconButton(
                                    onPressed: () async {
                                      final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                                        title: const Text('Delete Saved Item?'),
                                        content: Text('Are you sure you want to permanently remove "${e.name}" from your saved items?'),
                                        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: Theme.of(context).textButtonTheme.style?.textStyle?.resolve(MaterialState.values.toSet())?.copyWith(color: Theme.of(context).colorScheme.primary))),
                                        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: Theme.of(context).filledButtonTheme.style?.textStyle?.resolve(MaterialState.values.toSet())?.copyWith(color: Theme.of(context).colorScheme.onPrimary)))],
                                      ));
                                      if (ok == true) {
                                        await app.deleteSaved(e.id);
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${e.name}" deleted.')));
                                      }
                                    },
                                    icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                                    tooltip: 'Delete saved item',
                                  ),
                                ]),
                              ),
                            ),
                          ),
                        );
                      }
                    ),
                  );
                },
              ),
            ),
          ])),
      );
    });
  }
}