import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'models.dart';

final ImagePicker _picker = ImagePicker();

class BarcodePage extends StatefulWidget {
  const BarcodePage({super.key});

  @override
  State<BarcodePage> createState() => _BarcodePageState();
}

class _BarcodePageState extends State<BarcodePage> {
  bool _isProcessing = false;
  String? _lastScannedCode;

  Future<int?> _askForQuantity(BuildContext context, String itemName) async {
    final formKey = GlobalKey<FormState>();
    final quantityCtrl = TextEditingController(text: '1');

    return showDialog<int?>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          title: Text('How many $itemName?'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: quantityCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                hintText: 'Enter number of items',
                prefixIcon: Icon(Icons.numbers),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Quantity cannot be empty';
                }
                final parsed = int.tryParse(value);
                if (parsed == null || parsed <= 0) {
                  return 'Enter a valid positive number';
                }
                return null;
              },
              autofocus: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: theme.textButtonTheme.style?.textStyle
                    ?.resolve(WidgetState.values.toSet())
                    ?.copyWith(color: theme.colorScheme.primary),
              ),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  final quantity = int.tryParse(quantityCtrl.text) ?? 1;
                  Navigator.pop(dialogContext, quantity);
                }
              },
              child: Text(
                'Add',
                style: theme.filledButtonTheme.style?.textStyle
                    ?.resolve(WidgetState.values.toSet())
                    ?.copyWith(color: theme.colorScheme.onPrimary),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _startManualScan() async {
    final formKey = GlobalKey<FormState>();
    final ctrl = TextEditingController();

    final code = await showDialog<String?>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Barcode Scan'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: 'Enter barcode value',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Barcode cannot be empty';
                }
                return null;
              },
              autofocus: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(dialogContext, ctrl.text.trim());
                }
              },
              child: const Text('Scan'),
            ),
          ],
        );
      },
    );

    if (code == null || code.isEmpty || !mounted) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final app = context.read<AppState>();
      final matches = app.savedItems
          .where((item) => item.barcode != null && item.barcode == code)
          .toList();

      if (matches.isNotEmpty) {
        final match = matches.first;
        final quantity = await _askForQuantity(context, match.name);
        if (quantity != null && mounted) {
          await app.addItem(
            match.copyWith(
              id: makeId(),
              quantity: quantity,
            ),
          );
          if (!mounted) return;
          setState(() {
            _lastScannedCode = code;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added ${quantity}x ${match.name} to your list'),
            ),
          );
        }
      } else {
        final newItem = await showBarcodeDialog(context, code);
        if (newItem != null && mounted) {
          await app.addItem(newItem);
          if (!mounted) return;
          setState(() {
            _lastScannedCode = code;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${newItem.name} saved and added to your list'),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, app, _) {
        final savedWithBarcode = app.savedItems
            .where((item) => item.barcode != null && item.barcode!.isNotEmpty)
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Icon(
                  Icons.qr_code_scanner,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text('Barcode Scanner'),
              ],
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scan a barcode to quickly add items to your grocery list.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _isProcessing ? null : _startManualScan,
                          icon: const Icon(Icons.qr_code_scanner),
                          label: Text(
                            _isProcessing ? 'Scanning…' : 'Scan / Enter Barcode',
                          ),
                        ),
                        if (_lastScannedCode != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Last scanned: $_lastScannedCode',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: savedWithBarcode.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'No saved items with barcodes yet. Scan an item to save it for future trips.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: savedWithBarcode.length,
                        itemBuilder: (context, index) {
                          final item = savedWithBarcode[index];
                          return Card(
                            child: ListTile(
                              leading: _buildItemThumbnail(item),
                              title: Text(item.name),
                              subtitle: Text(
                                'Barcode: ${item.barcode}\nDefault price: ${peso(item.price)}',
                              ),
                              isThreeLine: true,
                              trailing: IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                tooltip: 'Add to grocery list',
                                onPressed: () async {
                                  final quantity = await _askForQuantity(context, item.name);
                                  if (quantity != null && context.mounted) {
                                    final appState = context.read<AppState>();
                                    await appState.addItem(
                                      item.copyWith(
                                        id: makeId(),
                                        quantity: quantity,
                                      ),
                                    );
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Added ${quantity}x ${item.name} to your list',
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItemThumbnail(GroceryItem item) {
    if (item.imageUrl == null || item.imageUrl!.isEmpty) {
      return const CircleAvatar(child: Icon(Icons.inventory_2));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(
        File(item.imageUrl!),
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const CircleAvatar(child: Icon(Icons.inventory_2)),
      ),
    );
  }
}

Future<GroceryItem?> showBarcodeDialog(
  BuildContext context,
  String code,
) async {
  final newFormKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  String? pickedImagePath;

  final result = await showDialog<GroceryItem?>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (stfContext, setStfState) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          title: Text('New Item for Barcode: $code'),
          content: SingleChildScrollView(
            child: Form(
              key: newFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Barcode: $code',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      final XFile? image = await _picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 50,
                      );
                      if (image != null) {
                        setStfState(() => pickedImagePath = image.path);
                      }
                    },
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: pickedImagePath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                File(pickedImagePath!),
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(
                              Icons.add_a_photo,
                              size: 48,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
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
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      prefixText: '₱ ',
                      labelText: 'Default Price',
                    ),
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
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (newFormKey.currentState?.validate() ?? false) {
                  final name = nameCtrl.text.trim();
                  final price = double.parse(
                    priceCtrl.text.replaceAll(',', ''),
                  );
                  Navigator.pop(
                    dialogContext,
                    GroceryItem(
                      id: makeId(),
                      name: name,
                      price: price,
                      barcode: code,
                      imageUrl: pickedImagePath,
                    ),
                  );
                }
              },
              child: const Text('Save Item'),
            ),
          ],
        );
      },
    ),
  );

  return result;
}
