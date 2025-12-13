import 'package:flutter/foundation.dart';

class FavoriteService {
  static final FavoriteService _instance = FavoriteService._internal();

  factory FavoriteService() {
    return _instance;
  }

  FavoriteService._internal();

  final ValueNotifier<Set<String>> _favoriteMealIds = ValueNotifier({});

  ValueListenable<Set<String>> get favoriteMealIds => _favoriteMealIds;

  bool isFavorite(String mealId) {
    return _favoriteMealIds.value.contains(mealId);
  }

  void toggleFavorite(String mealId) {
    final currentFavorites = Set<String>.from(_favoriteMealIds.value);
    if (currentFavorites.contains(mealId)) {
      currentFavorites.remove(mealId);
    } else {
      currentFavorites.add(mealId);
    }
    _favoriteMealIds.value = currentFavorites;
  }
}
