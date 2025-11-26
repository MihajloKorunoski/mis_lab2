import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../models/meal.dart';
import '../models/meal_detail.dart';

class MealApiService {
  static const String _baseUrl = "https://www.themealdb.com/api/json/v1/1";

  Future<List<Category>> getCategories() async {
    final response = await http.get(Uri.parse('$_baseUrl/categories.php'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> categoriesJson = data['categories'];
      return categoriesJson.map((json) => Category.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load categories');
    }
  }

  Future<List<Meal>> getMealsByCategory(String categoryName) async {
    final response = await http.get(Uri.parse('$_baseUrl/filter.php?c=$categoryName'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> mealsJson = data['meals'];
      if (mealsJson == null) return [];
      return mealsJson.map((json) => Meal.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load meals for category $categoryName');
    }
  }

  Future<List<Meal>> searchMeals(String query) async {
    final response = await http.get(Uri.parse('$_baseUrl/search.php?s=$query'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> mealsJson = data['meals'];
      if (mealsJson == null) return [];
      return mealsJson.map((json) => Meal.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search meals with query $query');
    }
  }

  Future<MealDetail> getMealDetail(String id) async {
    final response = await http.get(Uri.parse('$_baseUrl/lookup.php?i=$id'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> mealsJson = data['meals'];
      if (mealsJson != null && mealsJson.isNotEmpty) {
        return MealDetail.fromJson(mealsJson[0]);
      } else {
        throw Exception('Meal with ID $id not found');
      }
    } else {
      throw Exception('Failed to load meal details for ID $id');
    }
  }

  Future<MealDetail> getRandomMeal() async {
    final response = await http.get(Uri.parse('$_baseUrl/random.php'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> mealsJson = data['meals'];
      if (mealsJson != null && mealsJson.isNotEmpty) {
        return MealDetail.fromJson(mealsJson[0]);
      } else {
        throw Exception('Failed to get random meal');
      }
    } else {
      throw Exception('Failed to load random meal');
    }
  }
}
