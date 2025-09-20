import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'app_state.dart';
import 'budget_card.dart';
import 'models.dart';

class GroceryPage extends StatefulWidget {
  const GroceryPage({super.key});
  @override
  State<GroceryPage> createState() => _GroceryPageState();
}

class _GroceryPageState extends State<GroceryPage> {
  final ImagePicker _picker = ImagePicker();
  String? _pickedImagePath;

  Future<void> _showAddDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final barcodeCtrl = TextEditingController();
    bool saveToCatalog = true;
    _pickedImagePath = null;

    final item = await showDialog<GroceryItem?>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (stfContext, setStfState) {
          return AlertDialog(
            title: const Text('Add New Item'),
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
                    decoration: const InputDecoration(labelText: 'Item Name', hintText: 'e.g., Milk, Eggs'),
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
                    decoration: const InputDecoration(prefixText: '₱ ', labelText: 'Price', hintText: 'e.g., 125.00'),
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
                  const SizedBox(height: 20),
                  Row(children: [
                    Checkbox(
                      value: saveToCatalog,
                      onChanged: (v) => setStfState(() => saveToCatalog = v ?? true),
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Save to my saved items for future use', style: Theme.of(context).textTheme.bodyLarge)),
                  ]),
                ]),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('Cancel', style: Theme.of(context).textButtonTheme.style?.textStyle?.resolve(MaterialState.values.toSet())?.copyWith(color: Theme.of(context).colorScheme.primary))),
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
              }, child: Text('Add Item', style: Theme.of(context).filledButtonTheme.style?.textStyle?.resolve(MaterialState.values.toSet())?.copyWith(color: Theme.of(context).colorScheme.onPrimary))),
            ],
          );
        }
      ),
    );

    if (item != null) {
      final app = context.read<AppState>();
      final newTotal = app.total + item.price;
      if (app.budget > 0 && newTotal > app.budget) {
        final cont = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
          title: const Text('Over Budget Warning'),
          content: Text('Adding this item will exceed your budget by ${peso(newTotal - app.budget)}. Do you still want to add it?'),
          actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: Theme.of(context).textButtonTheme.style?.textStyle?.resolve(MaterialState.values.toSet())?.copyWith(color: Theme.of(context).colorScheme.primary))),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text('Add Anyway', style: Theme.of(context).filledButtonTheme.style?.textStyle?.resolve(MaterialState.values.toSet())?.copyWith(color: Theme.of(context).colorScheme.onPrimary)))],
        ));
        if (cont != true) return;
      }
      await app.addItem(item);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item.name} added to list')));
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added ${found.first.name} from barcode')));
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
      await context.read<AppState>().addItem(result);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${result.name} added')));
    }
  }

  Future<void> _editPrice(BuildContext context, GroceryItem item) async {
    final formKey = GlobalKey<FormState>();
    final ctrl = TextEditingController(text: item.price.toStringAsFixed(2));
    final v = await showDialog<double>(context: context, builder: (_) => AlertDialog(
      title: const Text('Edit Item Price'),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(prefixText: '₱ ', labelText: 'New Price'),
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
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: Theme.of(context).textButtonTheme.style?.textStyle?.resolve(MaterialState.values.toSet())?.copyWith(color: Theme.of(context).colorScheme.primary))),
      FilledButton(onPressed: () {
        if (formKey.currentState?.validate() ?? false) {
          final parsed = double.tryParse(ctrl.text.replaceAll(',', ''));
          Navigator.pop(context, parsed);
        }
      }, child: Text('Update', style: Theme.of(context).filledButtonTheme.style?.textStyle?.resolve(MaterialState.values.toSet())?.copyWith(color: Theme.of(context).colorScheme.onPrimary)))],
    ));
    if (v != null) {
      final app = context.read<AppState>();
      await app.removeCurrentItem(item.id);
      await app.addItem(item.copyWith(id: makeId(), price: v), persistSaved: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (context, app, _) {
      return Scaffold(
        appBar: AppBar(
            title: const Text('Your Grocery List'),
            actions: [
              IconButton(
                onPressed: () => _mockScan(context),
                icon: Icon(Icons.barcode_reader, size: 28, color: Theme.of(context).colorScheme.onSurfaceVariant),
                tooltip: 'Scan / Add Item by Barcode',
              ),
            ]),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: "addItemFab",
          onPressed: () => _showAddDialog(context),
          label: const Text('Add New Item'),
          icon: const Icon(Icons.add_shopping_cart_outlined),
        ),
        body: RefreshIndicator(
          onRefresh: () => app.loadAll(),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              const BudgetCard(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Current Items', style: Theme.of(context).textTheme.titleLarge),
                  Text('${app.currentItems.length} item(s)', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ]),
              ),
              if (app.currentItems.isEmpty)
                Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(children: [
                  Icon(Icons.shopping_basket_outlined, size: 80, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 24),
                  Text('Your list is empty!', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text('Start by adding items using the "Add New Item" button below.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ]))),
              ...app.currentItems.map((e) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Dismissible(
                    key: ValueKey(e.id),
                    direction: DismissDirection.endToStart,
                    // Red gradient on swipe
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Theme.of(context).colorScheme.error.withOpacity(0.8), Theme.of(context).colorScheme.error],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      child: Icon(Icons.delete_forever, color: Theme.of(context).colorScheme.onError, size: 30),
                    ),
                    secondaryBackground: Container( // For consistent swipe-left animation
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Theme.of(context).colorScheme.error.withOpacity(0.8), Theme.of(context).colorScheme.error],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      child: Icon(Icons.delete_forever, color: Theme.of(context).colorScheme.onError, size: 30),
                    ),
                    onDismissed: (direction) async {
                      await app.removeCurrentItem(e.id);
                      final snack = SnackBar(
                        content: Text('Removed "${e.name}"'),
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () async {
                            await app.addItem(e, persistSaved: false);
                          },
                          textColor: Theme.of(context).colorScheme.inversePrimary,
                        ),
                        backgroundColor: Theme.of(context).colorScheme.onSurface,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(snack);
                    },
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
                                    Theme.of(listTileContext).colorScheme.primaryContainer.withOpacity(0.6), // Stronger color on left
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
                                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                  backgroundImage: e.imageUrl != null && File(e.imageUrl!).existsSync()
                                      ? FileImage(File(e.imageUrl!))
                                      : null,
                                  child: e.imageUrl == null || !File(e.imageUrl!).existsSync()
                                      ? Icon(Icons.image_outlined, color: Theme.of(context).colorScheme.onPrimaryContainer, size: 30)
                                      : null,
                                ),
                                title: Text(e.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                subtitle: e.barcode != null
                                    ? Text('Barcode: ${e.barcode}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant))
                                    : null,
                                trailing: InkWell(
                                  onTap: () => _editPrice(context, e),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.secondaryContainer,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Theme.of(context).colorScheme.secondary.withOpacity(0.3))
                                    ),
                                    child: Text(
                                      peso(e.price),
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSecondaryContainer),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 80),
            ]),
        ),
      );
    });
  }
}