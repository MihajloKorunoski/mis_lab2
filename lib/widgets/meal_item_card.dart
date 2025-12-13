import 'package:flutter/material.dart';
import '../models/meal.dart';
import '../services/favorite_service.dart';

class MealItemCard extends StatelessWidget {
  final Meal meal;
  final VoidCallback onTap;

  const MealItemCard({
    super.key,
    required this.meal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final favoriteService = FavoriteService();

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4.0,
        child: Column(
          children: [
            Expanded(
              child: Image.network(
                meal.strMealThumb,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 80),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      meal.strMeal,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ValueListenableBuilder<Set<String>>(
                    valueListenable: favoriteService.favoriteMealIds,
                    builder: (context, favoriteIds, child) {
                      final isFavorite = favoriteService.isFavorite(meal.idMeal);
                      return IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.grey,
                        ),
                        onPressed: () {
                          favoriteService.toggleFavorite(meal.idMeal);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isFavorite ? 'Removed from favorites' : 'Added to favorites',
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
