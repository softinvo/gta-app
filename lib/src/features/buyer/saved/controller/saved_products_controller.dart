import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gta_app/src/models/product_collection_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Persisted mini-model ─────────────────────────────────────────────────────

/// Lightweight snapshot of a product stored locally.
/// Only the fields needed to render a saved-product card.
class SavedProduct {
  final String id;
  final String name;
  final String? shortDescription;
  final String? thumbnailUrl;
  final double price;
  final double discountPercent;

  const SavedProduct({
    required this.id,
    required this.name,
    this.shortDescription,
    this.thumbnailUrl,
    required this.price,
    this.discountPercent = 0,
  });

  double get discountedPrice {
    if (discountPercent <= 0) return price;
    return price * (1 - discountPercent / 100);
  }

  factory SavedProduct.fromCollectionItem(ProductCollectionItem item) =>
      SavedProduct(
        id: item.id,
        name: item.name,
        shortDescription: item.shortDescription,
        thumbnailUrl: item.thumbnailUrl,
        price: item.price,
        discountPercent: item.discountPercent,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (shortDescription != null) 'shortDescription': shortDescription,
        if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
        'price': price,
        'discountPercent': discountPercent,
      };

  factory SavedProduct.fromJson(Map<String, dynamic> json) => SavedProduct(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        shortDescription: json['shortDescription'],
        thumbnailUrl: json['thumbnailUrl'],
        price: (json['price'] ?? 0).toDouble(),
        discountPercent: (json['discountPercent'] ?? 0).toDouble(),
      );
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final savedProductsProvider =
    AsyncNotifierProvider<SavedProductsNotifier, List<SavedProduct>>(
  SavedProductsNotifier.new,
);

/// Convenience provider — returns just the set of saved IDs for fast lookup.
final savedProductIdsProvider = Provider<Set<String>>((ref) {
  final state = ref.watch(savedProductsProvider);
  return state.value?.map((p) => p.id).toSet() ?? {};
});

// ─── Notifier ─────────────────────────────────────────────────────────────────

class SavedProductsNotifier extends AsyncNotifier<List<SavedProduct>> {
  static const _key = 'saved_products_v1';

  @override
  Future<List<SavedProduct>> build() => _load();

  Future<List<SavedProduct>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => SavedProduct.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _persist(List<SavedProduct> products) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(products.map((p) => p.toJson()).toList()),
    );
  }

  bool isSaved(String productId) =>
      state.value?.any((p) => p.id == productId) ?? false;

  Future<void> toggle(ProductCollectionItem item) async {
    final current = state.value ?? [];
    final exists = current.any((p) => p.id == item.id);

    final updated = exists
        ? current.where((p) => p.id != item.id).toList()
        : [...current, SavedProduct.fromCollectionItem(item)];

    state = AsyncData(updated);
    await _persist(updated);
  }

  Future<void> remove(String productId) async {
    final current = state.value ?? [];
    final updated = current.where((p) => p.id != productId).toList();
    state = AsyncData(updated);
    await _persist(updated);
  }
}
