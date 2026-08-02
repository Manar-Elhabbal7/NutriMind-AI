import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/recipe_service.dart';
import 'recipe_detail_screen.dart';
import '../../../core/theme/app_colors.dart';

class StarredRecipesScreen extends StatefulWidget {
  const StarredRecipesScreen({super.key});

  @override
  State<StarredRecipesScreen> createState() => _StarredRecipesScreenState();
}

class _StarredRecipesScreenState extends State<StarredRecipesScreen> {
  List<Recipe> _starredRecipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStarredRecipes();
  }

  Future<void> _loadStarredRecipes() async {
    setState(() => _isLoading = true);
    final recipes = await RecipeService.instance.getStarredRecipes();
    if (mounted) {
      setState(() {
        _starredRecipes = recipes;
        _isLoading = false;
      });
    }
  }

  Future<void> _removeStarred(Recipe recipe) async {
    await RecipeService.instance.toggleStarRecipe(recipe);
    await _loadStarredRecipes();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${recipe.title} removed from favorites."),
          duration: const Duration(seconds: 1),
          backgroundColor: AppColors.secondary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Favorite Recipes",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF121212), Color(0xFF1E1E1E)],
                )
              : AppColors.backgroundGradient,
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
            : _starredRecipes.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.star_outline_rounded,
                            size: 80,
                            color: isDark ? Colors.white24 : AppColors.hint,
                          ).animate().scale(duration: 400.ms),
                          const SizedBox(height: 20),
                          Text(
                            "No Favorites Yet",
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Browse categories on the Home tab and tap the star icon to save your favorite recipes here.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: isDark ? Colors.white70 : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.45,
                    ),
                    itemCount: _starredRecipes.length,
                    itemBuilder: (context, index) {
                      final recipe = _starredRecipes[index];

                      return GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RecipeDetailScreen(recipe: recipe),
                            ),
                          );
                          _loadStarredRecipes();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              children: [
                                // Background Image
                                Positioned.fill(
                                  child: Image.network(
                                    recipe.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: isDark ? Colors.white12 : AppColors.fill,
                                      child: const Icon(Icons.broken_image_rounded, color: AppColors.secondary),
                                    ),
                                  ),
                                ),
                                // Dark Gradient Overlay for readability
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withValues(alpha: 0.75),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                // Recipe Title
                                Positioned(
                                  bottom: 8,
                                  left: 10,
                                  right: 10,
                                  child: Text(
                                    recipe.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                // Unstar button (in top right)
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: GestureDetector(
                                    onTap: () => _removeStarred(recipe),
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.star_rounded,
                                        color: Colors.amber,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ).animate().fade(delay: (index * 50).ms).slideY(begin: 0.1, end: 0);
                    },
                  ),
      ),
    );
  }
}
