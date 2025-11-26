import 'package:flutter/material.dart';
import '../models/meal.dart';
import '../services/meal_api_service.dart';
import './meal_detail_screen.dart';

class MealListScreen extends StatefulWidget {
  final String categoryName;

  const MealListScreen({super.key, required this.categoryName});

  @override
  State<MealListScreen> createState() => _MealListScreenState();
}

class _MealListScreenState extends State<MealListScreen> {
  late Future<List<Meal>> _mealsFuture;
  final MealApiService _apiService = MealApiService();
  TextEditingController _searchController = TextEditingController();
  List<Meal> _allMeals = [];
  List<Meal> _filteredMeals = [];

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  void _loadMeals() {
    _mealsFuture = _apiService.getMealsByCategory(widget.categoryName);
    _mealsFuture.then((meals) {
      setState(() {
        _allMeals = meals;
        _filteredMeals = meals;
      });
    });
  }

  void _filterMeals(String query) {
    setState(() {
      _filteredMeals = _allMeals
          .where((meal) => meal.strMeal.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _searchAndFilterMeals(String query) async {
    if (query.isEmpty) {
      _filterMeals(''); // Reset to category meals if search is empty
    } else {
      try {
        final searchedMeals = await _apiService.searchMeals(query);
        setState(() {
          _filteredMeals = searchedMeals;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to search meals: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.categoryName} Meals'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Meals',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _searchAndFilterMeals,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Meal>>(
              future: _mealsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No meals found.'));
                } else {
                  return GridView.builder(
                    padding: const EdgeInsets.all(8.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _filteredMeals.length,
                    itemBuilder: (context, index) {
                      final meal = _filteredMeals[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MealDetailScreen(mealId: meal.idMeal),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 4.0,
                          child: Column(
                            children: [
                              Expanded(
                                child: Image.network(
                                  meal.strMealThumb,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
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
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
