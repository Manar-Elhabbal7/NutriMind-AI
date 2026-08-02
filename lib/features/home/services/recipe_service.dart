import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Recipe {
  final String id;
  final String title;
  final String imageUrl;
  final String category;
  final List<String> ingredients;
  final String instructions;
  final bool isDrink;

  Recipe({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.category,
    this.ingredients = const [],
    this.instructions = '',
    this.isDrink = false,
  });

  factory Recipe.fromJson(
    Map<String, dynamic> json,
    String category, {
    bool isDrink = false,
  }) {
    List<String> ingredientsList = [];
    if (isDrink) {
      for (int i = 1; i <= 15; i++) {
        final ingredient = json['strIngredient$i'];
        final measure = json['strMeasure$i'];
        if (ingredient != null && ingredient.toString().trim().isNotEmpty) {
          final mStr = (measure != null && measure.toString().trim().isNotEmpty)
              ? '${measure.toString().trim()} '
              : '';
          ingredientsList.add('$mStr${ingredient.toString().trim()}');
        }
      }
    } else {
      for (int i = 1; i <= 20; i++) {
        final ingredient = json['strIngredient$i'];
        final measure = json['strMeasure$i'];
        if (ingredient != null && ingredient.toString().trim().isNotEmpty) {
          final mStr = (measure != null && measure.toString().trim().isNotEmpty)
              ? '${measure.toString().trim()} '
              : '';
          ingredientsList.add('$mStr${ingredient.toString().trim()}');
        }
      }
    }

    return Recipe(
      id: isDrink ? (json['idDrink'] ?? '') : (json['idMeal'] ?? ''),
      title: isDrink ? (json['strDrink'] ?? '') : (json['strMeal'] ?? ''),
      imageUrl: isDrink
          ? (json['strDrinkThumb'] ?? '')
          : (json['strMealThumb'] ?? ''),
      category: category,
      ingredients: ingredientsList,
      instructions: json['strInstructions'] ?? '',
      isDrink: isDrink,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'category': category,
      'ingredients': ingredients,
      'instructions': instructions,
      'isDrink': isDrink,
    };
  }

  factory Recipe.fromSavedJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      category: json['category'] ?? '',
      ingredients: List<String>.from(json['ingredients'] ?? []),
      instructions: json['instructions'] ?? '',
      isDrink: json['isDrink'] ?? false,
    );
  }
}

class RecipeService {
  RecipeService._();
  static final RecipeService instance = RecipeService._();

  final Dio _dio = Dio();
  static const String _starredKey = 'starred_recipes_key_v1';

  // Fetch recipe list for category
  Future<List<Recipe>> fetchRecipesByCategory(String category) async {
    try {
      if (category == 'Smoothies') {
        // Fetch non-alcoholic drinks from CocktailDB
        final response = await _dio.get(
          'https://www.thecocktaildb.com/api/json/v1/1/filter.php?a=Non_Alcoholic',
        );
        if (response.data != null && response.data['drinks'] != null) {
          final List drinks = response.data['drinks'];
          // limit to 10 for better UI performance
          return drinks.take(12).map((d) {
            return Recipe(
              id: d['idDrink'] ?? '',
              title: d['strDrink'] ?? '',
              imageUrl: d['strDrinkThumb'] ?? '',
              category: category,
              isDrink: true,
            );
          }).toList();
        }
      } else {
        // Fetch meals from MealDB
        String dbCategory = 'Breakfast';
        if (category == 'Lunch') {
          dbCategory = 'Pasta'; // Excellent choice for lunch
        } else if (category == 'Dinner') {
          dbCategory = 'Seafood'; // Delicious dinner meals
        }

        final response = await _dio.get(
          'https://www.themealdb.com/api/json/v1/1/filter.php?c=$dbCategory',
        );
        if (response.data != null && response.data['meals'] != null) {
          final List meals = response.data['meals'];
          return meals.take(12).map((m) {
            return Recipe(
              id: m['idMeal'] ?? '',
              title: m['strMeal'] ?? '',
              imageUrl: m['strMealThumb'] ?? '',
              category: category,
              isDrink: false,
            );
          }).toList();
        }
      }
      return [];
    } catch (e) {
      // Return empty list on failure
      return [];
    }
  }

  // Fetch complete details of a single recipe (ingredients, instructions)
  Future<Recipe> fetchRecipeDetails(Recipe recipe) async {
    try {
      if (recipe.isDrink) {
        final response = await _dio.get(
          'https://www.thecocktaildb.com/api/json/v1/1/lookup.php?i=${recipe.id}',
        );
        if (response.data != null && response.data['drinks'] != null) {
          final drinks = response.data['drinks'] as List;
          if (drinks.isNotEmpty) {
            return Recipe.fromJson(
              drinks.first,
              recipe.category,
              isDrink: true,
            );
          }
        }
      } else {
        final response = await _dio.get(
          'https://www.themealdb.com/api/json/v1/1/lookup.php?i=${recipe.id}',
        );
        if (response.data != null && response.data['meals'] != null) {
          final meals = response.data['meals'] as List;
          if (meals.isNotEmpty) {
            return Recipe.fromJson(
              meals.first,
              recipe.category,
              isDrink: false,
            );
          }
        }
      }
      return recipe;
    } catch (e) {
      return recipe;
    }
  }

  // Local storage of Starred / Favorite recipes
  Future<List<Recipe>> getStarredRecipes() async {
    final prefs = await SharedPreferences.getInstance();
    final starredString = prefs.getString(_starredKey);
    if (starredString == null) return [];
    try {
      final List decoded = jsonDecode(starredString);
      return decoded.map((item) => Recipe.fromSavedJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> toggleStarRecipe(Recipe recipe) async {
    final prefs = await SharedPreferences.getInstance();
    final starred = await getStarredRecipes();
    final index = starred.indexWhere((r) => r.id == recipe.id);
    if (index >= 0) {
      starred.removeAt(index);
    } else {
      // Before starring, make sure we have ingredients and instructions
      Recipe fullRecipe = recipe;
      if (recipe.ingredients.isEmpty || recipe.instructions.isEmpty) {
        fullRecipe = await fetchRecipeDetails(recipe);
      }
      starred.add(fullRecipe);
    }
    await prefs.setString(
      _starredKey,
      jsonEncode(starred.map((r) => r.toJson()).toList()),
    );
  }

  Future<bool> isStarred(String id) async {
    final starred = await getStarredRecipes();
    return starred.any((r) => r.id == id);
  }
}
