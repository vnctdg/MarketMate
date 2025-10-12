import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'models.dart';
import 'services/ai_service.dart';
import 'gradient_progress.dart';

class BudgetCard extends StatefulWidget {
  const BudgetCard({super.key});
  @override
  State<BudgetCard> createState() => _BudgetCardState();
}

class _BudgetCardState extends State<BudgetCard> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<double?> _showSetBudgetDialog(BuildContext context, double current) {
    final formKey = GlobalKey<FormState>();
    final ctrl = TextEditingController(text: current > 0 ? current.toStringAsFixed(2) : '');
    return showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Set Budget'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(prefixText: '₱ ', hintText: 'e.g. 1500.00'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Budget cannot be empty';
              }
              final parsed = double.tryParse(value.replaceAll(',', ''));
              if (parsed == null || parsed < 0) {
                return 'Enter a valid positive number (or 0 for no budget)';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: Theme.of(context).textButtonTheme.style?.textStyle?.resolve(MaterialState.values.toSet())?.copyWith(color: Theme.of(context).colorScheme.primary))),
          FilledButton(onPressed: () {
            if (formKey.currentState?.validate() ?? false) {
              final parsed = double.tryParse(ctrl.text.replaceAll(',', ''));
              Navigator.pop(context, parsed);
            }
          }, child: Text('Save', style: Theme.of(context).filledButtonTheme.style?.textStyle?.resolve(MaterialState.values.toSet())?.copyWith(color: Theme.of(context).colorScheme.onPrimary))),
        ],
      ),
    );
  }

  Color _colorForPercent(BuildContext ctx, double pct) {
    if (pct >= 1.0) return Theme.of(ctx).colorScheme.error;
    if (pct >= 0.75) return Colors.orange.shade600;
    return Theme.of(ctx).colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (context, app, _) {
      final pct = app.progress;
      final over = app.isOverBudget;

      if (over) {
        if (!_pulseController.isAnimating) _pulseController.repeat(reverse: true);
      } else {
        if (_pulseController.isAnimating) _pulseController.stop();
      }

      final Color localColorFrom = _colorForPercent(context, pct);
      final Color localColorTo = localColorFrom.withOpacity(0.65);

      final cardGradient = LinearGradient(
        colors: [
          Theme.of(context).colorScheme.primaryContainer,
          Theme.of(context).colorScheme.surface,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0.0, 0.8],
      );

      return AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
        decoration: BoxDecoration(
          gradient: over ? LinearGradient(
            colors: [Theme.of(context).colorScheme.errorContainer.withOpacity(0.8), Theme.of(context).colorScheme.surface],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            stops: const [0.0, 0.8],
          ) : cardGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow,
              blurRadius: over ? 16 : 8,
              offset: const Offset(0, 6),
            ),
          ],
          border: over ? Border.all(color: Theme.of(context).colorScheme.error, width: 2) : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column( // Main Column for Budget Card content
            mainAxisAlignment: MainAxisAlignment.center, // Vertically center content within the card
            children: [
              Row( // This Row now holds the progress bar and budget details side-by-side
                crossAxisAlignment: CrossAxisAlignment.center, // Vertically align items at center
                children: [
                  // Progress Bar Section (Left side, bigger circle)
                  SizedBox(
                    width: 180, // INCREASED SIZE
                    height: 180, // INCREASED SIZE
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: pct),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) => CustomPaint(
                            size: const Size(180, 180), // INCREASED SIZE
                            painter: GradientArcPainter(
                              progress: value,
                              colorFrom: localColorFrom,
                              colorTo: localColorTo,
                              strokeWidth: 20, // Adjusted stroke to fit new size better
                            ),
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: over ? (1 + _pulseController.value * 0.05) : 1,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${(pct * 100).toStringAsFixed(0)}%',
                                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: over ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'used',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24), // Spacing between circle and details

                  // Budget Details and Set Budget Button (Right side, aligned with circle)
                  Expanded( // Allows budget details to take available space
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, // Align text to start
                      mainAxisAlignment: MainAxisAlignment.center, // Vertically center content of this column within the row
                      children: [
                        Row( // Row for "Your Budget" text, value, and edit button
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.baseline, // Align text baselines
                          textBaseline: TextBaseline.alphabetic, // Required for crossAxisAlignment.baseline
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Your Budget', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                const SizedBox(height: 4),
                                Text(peso(app.budget), style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                )),
                              ],
                            ),
                            IconButton(
                              onPressed: () async {
                                final v = await _showSetBudgetDialog(context, app.budget);
                                if (v != null) await app.setBudget(v);
                              },
                              icon: Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.primary),
                              tooltip: 'Set Budget',
                              iconSize: 28,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16), // Spacing between budget and totals
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Total Spent', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                Text(peso(app.total), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Remaining', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                Text(
                                  peso(app.remaining),
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: over ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.tertiary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // AI Budget Optimization Hint
                        if (over)
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Theme.of(context).colorScheme.error.withOpacity(0.5)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.psychology, size: 16, color: Theme.of(context).colorScheme.error),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'AI suggests checking Insights for budget optimization tips',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.error,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24), // Spacing between top section and checkout button

              // BOTTOM SECTION: Checkout Button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    if (app.currentItems.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: const Text('Your list is empty! Add items before checking out.'),
                        backgroundColor: Theme.of(context).colorScheme.error,
                        duration: const Duration(seconds: 3),
                      ));
                      return;
                    }
                    if (app.budget <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: const Text('Please set a budget first! Tap the "Edit" icon.'),
                        backgroundColor: Theme.of(context).colorScheme.tertiary,
                        duration: const Duration(seconds: 3),
                      ));
                      return;
                    }

                    if (app.isOverBudget) {
                      final cont = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                        title: const Text('Over budget Warning'),
                        content: Text('You are ${peso(app.total - app.budget)} over the budget. Save anyway?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: Theme.of(context).textButtonTheme.style?.textStyle?.resolve(MaterialState.values.toSet())?.copyWith(color: Theme.of(context).colorScheme.primary))),
                          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text('Save anyway', style: Theme.of(context).filledButtonTheme.style?.textStyle?.resolve(MaterialState.values.toSet())?.copyWith(color: Theme.of(context).colorScheme.onPrimary))),
                        ],
                      ));
                      if (cont != true) return;
                      await app.checkout(force: true);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to history (over budget)')));
                    } else {
                      await app.checkout();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to history')));
                    }
                  },
                  icon: const Icon(Icons.shopping_cart_checkout_outlined),
                  label: const Text('Checkout Current List'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
