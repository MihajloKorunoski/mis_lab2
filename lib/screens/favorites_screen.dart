import 'package:flutter/material.dart';
import '../models/meal.dart';
import '../models/meal_detail.dart';
import '../services/favorite_service.dart';
import '../services/meal_api_service.dart';
import '../widgets/meal_item_card.dart';
import './meal_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoriteService _favoriteService = FavoriteService();
  final MealApiService _apiService = MealApiService();
  Map<String, MealDetail> _favoriteMealDetails = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _favoriteService.favoriteMealIds.addListener(_onFavoritesChanged);
    _onFavoritesChanged();
  }

  @override
  void dispose() {
    _favoriteService.favoriteMealIds.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _onFavoritesChanged() async {
    setState(() {
      _isLoading = true;
    });

    final currentFavoriteIds = _favoriteService.favoriteMealIds.value;
    Map<String, MealDetail> newMealDetails = {};

    for (String mealId in currentFavoriteIds) {
      if (_favoriteMealDetails.containsKey(mealId)) {
        newMealDetails[mealId] = _favoriteMealDetails[mealId]!;
      } else {
        try {
          final detail = await _apiService.getMealDetail(mealId);
          newMealDetails[mealId] = detail;
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to load favorite meal $mealId: $e')),
            );
          }
        }
      }
    }

    setState(() {
      _favoriteMealDetails = newMealDetails;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Recipes'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ValueListenableBuilder<Set<String>>(
              valueListenable: _favoriteService.favoriteMealIds,
              builder: (context, favoriteIds, child) {
                if (favoriteIds.isEmpty) {
                  return const Center(
                    child: Text('No favorite recipes yet. Add some from the meal lists!'),
                  );
                }

                final mealsToDisplay = favoriteIds
                    .map((id) => _favoriteMealDetails[id])
                    .where((meal) => meal != null)
                    .map((mealDetail) => Meal(
                          idMeal: mealDetail!.idMeal,
                          strMeal: mealDetail.strMeal,
                          strMealThumb: mealDetail.strMealThumb,
                        ))
                    .toList();

                return GridView.builder(
                  padding: const EdgeInsets.all(8.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: mealsToDisplay.length,
                  itemBuilder: (context, index) {
                    final meal = mealsToDisplay[index];
                    return MealItemCard(
                      meal: meal,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MealDetailScreen(mealId: meal.idMeal),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
