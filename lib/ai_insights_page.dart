import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'models.dart';
import 'services/ai_service.dart';

class AIInsightsPage extends StatefulWidget {
  const AIInsightsPage({super.key});
  @override
  State<AIInsightsPage> createState() => _AIInsightsPageState();
}

class _AIInsightsPageState extends State<AIInsightsPage> with TickerProviderStateMixin {
  final AIService _aiService = AIService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (context, app, _) {
      final suggestions = _aiService.generateSmartSuggestions(
        app.history, app.currentItems, app.savedItems);
      final budgetOptimization = _aiService.optimizeBudget(
        app.budget, app.currentItems, app.history);

      return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Icon(Icons.psychology, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Text('AI Insights'),
            ],
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: RefreshIndicator(
            onRefresh: () async {
              setState(() {});
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSmartSuggestionsCard(suggestions, app),
                const SizedBox(height: 16),
                _buildBudgetOptimizationCard(budgetOptimization),
                const SizedBox(height: 16),
                _buildSpendingAnalyticsCard(app.history),
                const SizedBox(height: 16),
                _buildShoppingPatternsCard(app.history),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildSmartSuggestionsCard(List<SmartSuggestion> suggestions, AppState app) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('Smart Suggestions', 
                     style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            if (suggestions.isEmpty)
              const Text('No suggestions available. Add more items to get AI recommendations!')
            else
              ...suggestions.map((suggestion) => _buildSuggestionTile(suggestion, app)),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionTile(SmartSuggestion suggestion, AppState app) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getSuggestionColor(suggestion.type),
          child: Icon(_getSuggestionIcon(suggestion.type), color: Colors.white),
        ),
        title: Text(suggestion.item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(suggestion.reason),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: suggestion.confidence,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation(_getSuggestionColor(suggestion.type)),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.add_shopping_cart),
          onPressed: () async {
            final quantity = await _askForQuantity(context, suggestion.item.name);
            if (quantity != null) {
              final itemWithQuantity = suggestion.item.copyWith(id: makeId(), quantity: quantity);
              await app.addItem(itemWithQuantity, persistSaved: false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Added ${quantity}x ${suggestion.item.name} to list')),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildBudgetOptimizationCard(BudgetOptimization optimization) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.savings, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 8),
                Text('Budget Optimization', 
                     style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            if (!optimization.isOverBudget)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Your budget is on track!')),
                  ],
                ),
              )
            else
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Potential savings: ${peso(optimization.potentialSavings)}'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...optimization.suggestions.map((suggestion) => 
                    _buildBudgetSuggestionTile(suggestion)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetSuggestionTile(BudgetSuggestion suggestion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(width: 4, color: Colors.orange)),
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(suggestion.item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(suggestion.suggestion),
          Text('Save: ${peso(suggestion.potentialSavings)}', 
               style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSpendingAnalyticsCard(List<GroceryListSnapshot> history) {
    if (history.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('No spending data available yet'),
        ),
      );
    }

    final monthlySpending = <String, double>{};
    for (final snapshot in history) {
      final month = '${snapshot.createdAt.year}-${snapshot.createdAt.month.toString().padLeft(2, '0')}';
      monthlySpending[month] = (monthlySpending[month] ?? 0) + snapshot.total;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Theme.of(context).colorScheme.tertiary),
                const SizedBox(width: 8),
                Text('Spending Analytics', 
                     style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            ...monthlySpending.entries.map((entry) => 
              _buildSpendingRow(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingRow(String month, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(month),
          Text(peso(amount), style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildShoppingPatternsCard(List<GroceryListSnapshot> history) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pattern, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('Shopping Patterns', 
                     style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Text('Total shopping trips: ${history.length}'),
            if (history.isNotEmpty) ...[
              Text('Average spending: ${peso(history.map((h) => h.total).reduce((a, b) => a + b) / history.length)}'),
              Text('Most recent trip: ${history.first.createdAt.toString().substring(0, 10)}'),
            ],
          ],
        ),
      ),
    );
  }

  Future<int?> _askForQuantity(BuildContext context, String itemName) async {
    final formKey = GlobalKey<FormState>();
    final quantityCtrl = TextEditingController(text: '1');
    
    return await showDialog<int?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('How many $itemName?'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: quantityCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Quantity',
              prefixIcon: Icon(Icons.numbers),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Quantity cannot be empty';
              final parsed = int.tryParse(value);
              if (parsed == null || parsed <= 0) return 'Enter a valid positive number';
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
                final quantity = int.tryParse(quantityCtrl.text) ?? 1;
                Navigator.pop(dialogContext, quantity);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Color _getSuggestionColor(SuggestionType type) {
    switch (type) {
      case SuggestionType.frequentItem:
        return Colors.blue;
      case SuggestionType.complementary:
        return Colors.green;
      case SuggestionType.seasonal:
        return Colors.orange;
      case SuggestionType.trending:
        return Colors.purple;
    }
  }

  IconData _getSuggestionIcon(SuggestionType type) {
    switch (type) {
      case SuggestionType.frequentItem:
        return Icons.repeat;
      case SuggestionType.complementary:
        return Icons.link;
      case SuggestionType.seasonal:
        return Icons.wb_sunny;
      case SuggestionType.trending:
        return Icons.trending_up;
    }
  }
}
