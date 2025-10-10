import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// Simple grocery item model
class GroceryItem {
  final String id;
  final String name;
  final double price;
  final String barcode;
  final String? imageUrl;

  GroceryItem({
    required this.id,
    required this.name,
    required this.price,
    required this.barcode,
    this.imageUrl,
  });
}

String makeId() => DateTime.now().millisecondsSinceEpoch.toString();

class BarcodePage extends StatefulWidget {
  const BarcodePage({super.key});

  @override
  State<BarcodePage> createState() => _BarcodePageState();
}

class _BarcodePageState extends State<BarcodePage> {
  final ImagePicker _picker = ImagePicker();
  String? _barcode;
  bool _scanning = false;
  final MobileScannerController _scannerController = MobileScannerController();

  /// Opens fullscreen camera scanner
  void _openCameraScanner() async {
    setState(() => _scanning = true);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            MobileScanner(
              controller: _scannerController,
              onDetect: (capture) {
                final barcode = capture.barcodes.first.rawValue;
                if (barcode != null && barcode.isNotEmpty) {
                  Navigator.pop(context); // Close scanner
                  setState(() {
                    _scanning = false;
                    _barcode = barcode;
                  });
                  _handleNewBarcode(barcode);
                }
              },
            ),
            // Scanner overlay similar to GCash style
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            Positioned(
              top: 40,
              left: 16,
              child: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => _scanning = false);
                },
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Upload barcode image from gallery
  void _uploadBarcode() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      final result = await _scannerController.analyzeImage(image.path);
      if (result?.barcodes.isNotEmpty ?? false) {
        final code = result!.barcodes.first.rawValue ?? '';
        if (code.isNotEmpty) {
          setState(() => _barcode = code);
          _handleNewBarcode(code);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No barcode found in image')),
          );
        }
      }
    }
  }

  void _handleNewBarcode(String code) async {
    final newItem = await showBarcodeDialog(context, code);
    if (newItem != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added ${newItem.name} (${newItem.barcode})')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grocery List'),
        backgroundColor: Colors.green[300],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.qr_code_2, size: 100, color: Colors.black54),
            const SizedBox(height: 30),

            // Upload barcode
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildButton(
                  icon: Icons.image_search,
                  label: 'Upload Barcode',
                  onTap: _uploadBarcode,
                ),
                const SizedBox(width: 30),
                _buildButton(
                  icon: Icons.keyboard,
                  label: 'Input Barcode',
                  onTap: () async {
                    final codeController = TextEditingController();
                    final code = await showDialog<String>(
                      context: context,
                      builder: (dialogContext) {
                        return AlertDialog(
                          title: const Text('Enter Barcode'),
                          content: TextField(
                            controller: codeController,
                            decoration: const InputDecoration(
                              hintText: 'Enter barcode manually',
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(
                                  dialogContext,
                                  codeController.text,
                                );
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        );
                      },
                    );
                    if (code != null && code.isNotEmpty) {
                      _handleNewBarcode(code);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _openCameraScanner,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan Barcode'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[300],
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 14,
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.black),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ],
        ),
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
  final ImagePicker _picker = ImagePicker();
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
                        color: theme.colorScheme.surface.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.5),
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
                          : const Icon(Icons.add_a_photo, size: 40),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Item Name'),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      prefixText: '₱ ',
                      labelText: 'Default Price',
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
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
                  final price =
                      double.tryParse(priceCtrl.text.replaceAll(',', '')) ?? 0;
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
              child: const Text('Save'),
            ),
          ],
        );
      },
    ),
  );
  return result;
}
