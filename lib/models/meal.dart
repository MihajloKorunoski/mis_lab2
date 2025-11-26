class Meal {
  final String idMeal;
  final String strMeal;
  final String strMealThumb;

  Meal({
    required this.idMeal,
    required this.strMeal,
    required this.strMealThumb,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      idMeal: json['idMeal'] as String,
      strMeal: json['strMeal'] as String,
      strMealThumb: json['strMealThumb'] as String,
    );
  }
}
