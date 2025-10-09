// lib/barcode_dialog.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'models.dart'; // <-- adjust if your models.dart is in another folder

final ImagePicker _picker = ImagePicker();

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
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      final XFile? image = await _picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 50,
                      );
                      if (image != null)
                        setStfState(() => pickedImagePath = image.path);
                    },
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withOpacity(0.5),
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
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Item Name'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Item name cannot be empty'
                        : null,
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
                      if (value == null || value.isEmpty)
                        return 'Price cannot be empty';
                      final parsed = double.tryParse(value.replaceAll(',', ''));
                      if (parsed == null || parsed <= 0)
                        return 'Enter a valid positive price';
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
              child: Text('Cancel'),
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
              child: Text('Save Item'),
            ),
          ],
        );
      },
    ),
  );

  return result;
}
