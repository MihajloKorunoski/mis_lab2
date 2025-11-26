import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/meal_detail.dart';
import '../services/meal_api_service.dart';

class MealDetailScreen extends StatefulWidget {
  final String mealId;

  const MealDetailScreen({super.key, required this.mealId});

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  late Future<MealDetail> _mealDetailFuture;
  final MealApiService _apiService = MealApiService();

  @override
  void initState() {
    super.initState();
    _mealDetailFuture = _apiService.getMealDetail(widget.mealId);
  }

  Future<void> _launchYouTubeUrl(String? url) async {
    if (url != null && url.isNotEmpty) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch $url')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Details'),
      ),
      body: FutureBuilder<MealDetail>(
        future: _mealDetailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No meal details found.'));
          } else {
            final meal = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.network(
                    meal.strMealThumb,
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    meal.strMeal,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Category: ${meal.strCategory}',
                    style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Area: ${meal.strArea}',
                    style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 16.0),
                  const Text(
                    'Instructions:',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8.0),
                  Text(meal.strInstructions),
                  const SizedBox(height: 16.0),
                  const Text(
                    'Ingredients:',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8.0),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: meal.ingredients.length,
                    itemBuilder: (context, index) {
                      return Text(
                          '- ${meal.ingredients[index]} (${meal.measures[index]})');
                    },
                  ),
                  const SizedBox(height: 16.0),
                  if (meal.strYoutube != null && meal.strYoutube!.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: () => _launchYouTubeUrl(meal.strYoutube),
                      icon: const Icon(Icons.video_library),
                      label: const Text('Watch on YouTube'),
                    ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
