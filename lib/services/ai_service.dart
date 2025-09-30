import 'dart:math';
import '../models.dart';

/// AI-powered service for intelligent shopping features
class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  // Simulated AI models - in a real app, these would connect to actual AI services
  final Random _random = Random();

  /// AI-powered smart suggestions based on purchase history and patterns
  List<SmartSuggestion> generateSmartSuggestions(
    List<GroceryListSnapshot> history,
    List<GroceryItem> currentItems,
    List<GroceryItem> savedItems,
  ) {
    final suggestions = <SmartSuggestion>[];
    
    // Analyze purchase patterns
    final itemFrequency = <String, int>{};
    final itemLastPurchased = <String, DateTime>{};
    
    for (final snapshot in history) {
      for (final item in snapshot.items) {
        final key = item.name.toLowerCase();
        itemFrequency[key] = (itemFrequency[key] ?? 0) + item.quantity;
        itemLastPurchased[key] = snapshot.createdAt;
      }
    }

    // Generate suggestions based on frequency and recency
    final currentItemNames = currentItems.map((e) => e.name.toLowerCase()).toSet();
    
    for (final entry in itemFrequency.entries) {
      if (!currentItemNames.contains(entry.key) && entry.value >= 2) {
        final lastPurchased = itemLastPurchased[entry.key]!;
        final daysSinceLastPurchase = DateTime.now().difference(lastPurchased).inDays;
        
        // Suggest items that are frequently bought and haven't been purchased recently
        if (daysSinceLastPurchase >= 7) {
          final savedItem = savedItems.firstWhere(
            (item) => item.name.toLowerCase() == entry.key,
            orElse: () => GroceryItem(
              id: makeId(),
              name: _capitalizeWords(entry.key),
              price: _predictPrice(entry.key),
            ),
          );
          
          suggestions.add(SmartSuggestion(
            item: savedItem,
            reason: _generateSuggestionReason(entry.value, daysSinceLastPurchase),
            confidence: _calculateConfidence(entry.value, daysSinceLastPurchase),
            type: SuggestionType.frequentItem,
          ));
        }
      }
    }

    // Add complementary item suggestions
    suggestions.addAll(_generateComplementarySuggestions(currentItems, savedItems));
    
    // Add seasonal suggestions
    suggestions.addAll(_generateSeasonalSuggestions(savedItems));

    // Sort by confidence and return top suggestions
    suggestions.sort((a, b) => b.confidence.compareTo(a.confidence));
    return suggestions.take(5).toList();
  }

  /// AI-powered price prediction based on historical data
  double predictOptimalPrice(String itemName, List<GroceryListSnapshot> history) {
    final prices = <double>[];
    
    for (final snapshot in history) {
      for (final item in snapshot.items) {
        if (item.name.toLowerCase() == itemName.toLowerCase()) {
          prices.add(item.price);
        }
      }
    }
    
    if (prices.isEmpty) return _predictPrice(itemName);
    
    // Calculate trend-adjusted average
    prices.sort();
    final median = prices[prices.length ~/ 2];
    final average = prices.reduce((a, b) => a + b) / prices.length;
    
    // Apply AI-like price prediction with market trends
    final trendFactor = 1.0 + (_random.nextDouble() - 0.5) * 0.1; // ±5% market variation
    return (median * 0.6 + average * 0.4) * trendFactor;
  }

  /// AI-powered budget optimization suggestions
  BudgetOptimization optimizeBudget(
    double currentBudget,
    List<GroceryItem> currentItems,
    List<GroceryListSnapshot> history,
  ) {
    final currentTotal = currentItems.fold(0.0, (sum, item) => sum + item.totalPrice);
    
    if (currentTotal <= currentBudget) {
      return BudgetOptimization(
        isOverBudget: false,
        suggestions: [],
        potentialSavings: 0.0,
        optimizedTotal: currentTotal,
      );
    }
    
    final suggestions = <BudgetSuggestion>[];
    double potentialSavings = 0.0;
    
    // Analyze each item for optimization opportunities
    for (final item in currentItems) {
      final historicalPrice = predictOptimalPrice(item.name, history);
      
      if (item.price > historicalPrice * 1.1) {
        final savings = (item.price - historicalPrice) * item.quantity;
        suggestions.add(BudgetSuggestion(
          item: item,
          suggestion: 'Consider shopping elsewhere - this item is ${((item.price / historicalPrice - 1) * 100).toStringAsFixed(0)}% above your usual price',
          potentialSavings: savings,
          type: BudgetSuggestionType.priceAlert,
        ));
        potentialSavings += savings;
      }
      
      if (item.quantity > 2) {
        final savings = item.price * (item.quantity - 1);
        suggestions.add(BudgetSuggestion(
          item: item,
          suggestion: 'Reduce quantity from ${item.quantity} to 1 to save money',
          potentialSavings: savings,
          type: BudgetSuggestionType.quantityReduction,
        ));
      }
    }
    
    return BudgetOptimization(
      isOverBudget: true,
      suggestions: suggestions,
      potentialSavings: potentialSavings,
      optimizedTotal: currentTotal - potentialSavings,
    );
  }

  /// AI-powered item categorization
  ItemCategory categorizeItem(String itemName) {
    final name = itemName.toLowerCase();
    
    // AI-like categorization based on keywords and patterns
    if (_containsAny(name, ['milk', 'cheese', 'yogurt', 'butter', 'cream'])) {
      return ItemCategory.dairy;
    } else if (_containsAny(name, ['apple', 'banana', 'orange', 'grape', 'berry'])) {
      return ItemCategory.fruits;
    } else if (_containsAny(name, ['carrot', 'potato', 'onion', 'tomato', 'lettuce'])) {
      return ItemCategory.vegetables;
    } else if (_containsAny(name, ['bread', 'rice', 'pasta', 'cereal', 'flour'])) {
      return ItemCategory.grains;
    } else if (_containsAny(name, ['chicken', 'beef', 'pork', 'fish', 'egg'])) {
      return ItemCategory.protein;
    } else if (_containsAny(name, ['soap', 'shampoo', 'toothpaste', 'detergent'])) {
      return ItemCategory.household;
    } else if (_containsAny(name, ['juice', 'soda', 'water', 'coffee', 'tea'])) {
      return ItemCategory.beverages;
    }
    
    return ItemCategory.other;
  }

  /// AI-powered smart search with fuzzy matching and suggestions
  List<GroceryItem> smartSearch(String query, List<GroceryItem> items) {
    if (query.isEmpty) return items;
    
    final results = <SearchResult>[];
    final queryLower = query.toLowerCase();
    
    for (final item in items) {
      final nameLower = item.name.toLowerCase();
      double score = 0.0;
      
      // Exact match gets highest score
      if (nameLower == queryLower) {
        score = 1.0;
      }
      // Starts with query gets high score
      else if (nameLower.startsWith(queryLower)) {
        score = 0.9;
      }
      // Contains query gets medium score
      else if (nameLower.contains(queryLower)) {
        score = 0.7;
      }
      // Fuzzy matching for typos
      else {
        score = _calculateFuzzyScore(queryLower, nameLower);
      }
      
      if (score > 0.3) {
        results.add(SearchResult(item: item, score: score));
      }
    }
    
    results.sort((a, b) => b.score.compareTo(a.score));
    return results.map((r) => r.item).toList();
  }

  // Helper methods
  List<SmartSuggestion> _generateComplementarySuggestions(
    List<GroceryItem> currentItems,
    List<GroceryItem> savedItems,
  ) {
    final suggestions = <SmartSuggestion>[];
    final complementaryPairs = {
      'milk': ['cereal', 'cookies'],
      'bread': ['butter', 'jam'],
      'pasta': ['sauce', 'cheese'],
      'coffee': ['sugar', 'cream'],
    };
    
    for (final item in currentItems) {
      final complements = complementaryPairs[item.name.toLowerCase()];
      if (complements != null) {
        for (final complement in complements) {
          final complementItem = savedItems.firstWhere(
            (saved) => saved.name.toLowerCase().contains(complement),
            orElse: () => GroceryItem(
              id: makeId(),
              name: _capitalizeWords(complement),
              price: _predictPrice(complement),
            ),
          );
          
          suggestions.add(SmartSuggestion(
            item: complementItem,
            reason: 'Goes well with ${item.name}',
            confidence: 0.7,
            type: SuggestionType.complementary,
          ));
        }
      }
    }
    
    return suggestions;
  }

  List<SmartSuggestion> _generateSeasonalSuggestions(List<GroceryItem> savedItems) {
    final suggestions = <SmartSuggestion>[];
    final month = DateTime.now().month;
    
    List<String> seasonalItems = [];
    if (month >= 3 && month <= 5) {
      seasonalItems = ['strawberries', 'asparagus', 'spring onions'];
    } else if (month >= 6 && month <= 8) {
      seasonalItems = ['watermelon', 'corn', 'tomatoes'];
    } else if (month >= 9 && month <= 11) {
      seasonalItems = ['pumpkin', 'apples', 'squash'];
    } else {
      seasonalItems = ['oranges', 'potatoes', 'cabbage'];
    }
    
    for (final seasonal in seasonalItems) {
      final item = savedItems.firstWhere(
        (saved) => saved.name.toLowerCase().contains(seasonal),
        orElse: () => GroceryItem(
          id: makeId(),
          name: _capitalizeWords(seasonal),
          price: _predictPrice(seasonal),
        ),
      );
      
      suggestions.add(SmartSuggestion(
        item: item,
        reason: 'In season now - fresh and affordable',
        confidence: 0.6,
        type: SuggestionType.seasonal,
      ));
    }
    
    return suggestions;
  }

  String _generateSuggestionReason(int frequency, int daysSince) {
    if (frequency >= 5) {
      return 'You buy this frequently - last purchased $daysSince days ago';
    } else if (daysSince >= 14) {
      return 'Haven\'t bought this in $daysSince days - might be running low';
    } else {
      return 'Based on your shopping pattern';
    }
  }

  double _calculateConfidence(int frequency, int daysSince) {
    final frequencyScore = (frequency / 10.0).clamp(0.0, 1.0);
    final recencyScore = (daysSince / 30.0).clamp(0.0, 1.0);
    return (frequencyScore * 0.7 + recencyScore * 0.3).clamp(0.0, 1.0);
  }

  double _predictPrice(String itemName) {
    // Simple AI-like price prediction based on item type
    final name = itemName.toLowerCase();
    if (_containsAny(name, ['milk', 'bread', 'egg'])) return 50.0 + _random.nextDouble() * 30.0;
    if (_containsAny(name, ['meat', 'fish', 'chicken'])) return 150.0 + _random.nextDouble() * 100.0;
    if (_containsAny(name, ['fruit', 'vegetable'])) return 30.0 + _random.nextDouble() * 40.0;
    return 25.0 + _random.nextDouble() * 75.0;
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  String _capitalizeWords(String text) {
    return text.split(' ').map((word) => 
      word.isEmpty ? word : word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  double _calculateFuzzyScore(String query, String target) {
    if (query.length > target.length) return 0.0;
    
    int matches = 0;
    int queryIndex = 0;
    
    for (int i = 0; i < target.length && queryIndex < query.length; i++) {
      if (target[i] == query[queryIndex]) {
        matches++;
        queryIndex++;
      }
    }
    
    return matches / query.length;
  }
}

// Supporting classes for AI features
class SmartSuggestion {
  final GroceryItem item;
  final String reason;
  final double confidence;
  final SuggestionType type;

  SmartSuggestion({
    required this.item,
    required this.reason,
    required this.confidence,
    required this.type,
  });
}

enum SuggestionType {
  frequentItem,
  complementary,
  seasonal,
  trending,
}

class BudgetOptimization {
  final bool isOverBudget;
  final List<BudgetSuggestion> suggestions;
  final double potentialSavings;
  final double optimizedTotal;

  BudgetOptimization({
    required this.isOverBudget,
    required this.suggestions,
    required this.potentialSavings,
    required this.optimizedTotal,
  });
}

class BudgetSuggestion {
  final GroceryItem item;
  final String suggestion;
  final double potentialSavings;
  final BudgetSuggestionType type;

  BudgetSuggestion({
    required this.item,
    required this.suggestion,
    required this.potentialSavings,
    required this.type,
  });
}

enum BudgetSuggestionType {
  priceAlert,
  quantityReduction,
  substitute,
}

enum ItemCategory {
  dairy,
  fruits,
  vegetables,
  grains,
  protein,
  household,
  beverages,
  other,
}

class SearchResult {
  final GroceryItem item;
  final double score;

  SearchResult({required this.item, required this.score});
}
