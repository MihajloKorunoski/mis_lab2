import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/meal_api_service.dart';
import '../widgets/category_card.dart';
import './meal_list_screen.dart';
import './meal_detail_screen.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  late Future<List<Category>> _categoriesFuture;
  final MealApiService _apiService = MealApiService();
  TextEditingController _searchController = TextEditingController();
  List<Category> _allCategories = [];
  List<Category> _filteredCategories = [];

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _apiService.getCategories();
    _categoriesFuture.then((categories) {
      setState(() {
        _allCategories = categories;
        _filteredCategories = categories;
      });
    });
  }

  void _filterCategories(String query) {
    setState(() {
      _filteredCategories = _allCategories
          .where((category) =>
              category.strCategory.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _showRandomMeal() async {
    try {
      final mealDetail = await _apiService.getRandomMeal();
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MealDetailScreen(mealId: mealDetail.idMeal),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load random meal: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle),
            onPressed: _showRandomMeal,
            tooltip: 'Random Recipe',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Categories',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filterCategories,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Category>>(
              future: _categoriesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No categories found.'));
                } else {
                  return ListView.builder(
                    itemCount: _filteredCategories.length,
                    itemBuilder: (context, index) {
                      final category = _filteredCategories[index];
                      return CategoryCard(
                        category: category,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MealListScreen(
                                  categoryName: category.strCategory),
                            ),
                          );
                        },
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
