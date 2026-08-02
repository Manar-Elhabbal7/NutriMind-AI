import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/recipe_service.dart';
import 'recipe_detail_screen.dart';
import '../../../core/theme/app_colors.dart';

class RecipeListScreen extends StatefulWidget {
  final String category;
  const RecipeListScreen({super.key, required this.category});

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  late Future<List<Recipe>> _recipesFuture;
  final List<String> _starredIds = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _recipesFuture = RecipeService.instance.fetchRecipesByCategory(
        widget.category,
      );
    });
    _loadStarredStatus();
  }

  Future<void> _loadStarredStatus() async {
    final starred = await RecipeService.instance.getStarredRecipes();
    if (mounted) {
      setState(() {
        _starredIds.clear();
        _starredIds.addAll(starred.map((r) => r.id));
      });
    }
  }

  Future<void> _toggleStar(Recipe recipe) async {
    await RecipeService.instance.toggleStarRecipe(recipe);
    await _loadStarredStatus();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _starredIds.contains(recipe.id)
                ? "${recipe.title} saved to favorites!"
                : "${recipe.title} removed from favorites.",
          ),
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
          widget.category,
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
        child: FutureBuilder<List<Recipe>>(
          future: _recipesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.secondary),
              );
            }

            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.restaurant_menu_rounded,
                      size: 64,
                      color: isDark ? Colors.white24 : AppColors.hint,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No recipes found for ${widget.category}",
                      style: GoogleFonts.poppins(
                        color: isDark
                            ? Colors.white70
                            : AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _loadData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              );
            }

            final recipes = snapshot.data!;

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.45,
              ),
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                final isStarred = _starredIds.contains(recipe.id);

                return GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                RecipeDetailScreen(recipe: recipe),
                          ),
                        );
                        _loadStarredStatus();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.3 : 0.08,
                              ),
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
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Container(
                                          color: isDark
                                              ? Colors.white12
                                              : AppColors.fill,
                                          child: const Center(
                                            child: SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(AppColors.secondary),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        color: isDark
                                            ? Colors.white12
                                            : AppColors.fill,
                                        child: const Icon(
                                          Icons.broken_image_rounded,
                                          color: AppColors.secondary,
                                        ),
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
                              // Star Button
                              Positioned(
                                top: 6,
                                right: 6,
                                child: GestureDetector(
                                  onTap: () => _toggleStar(recipe),
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.5,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isStarred
                                          ? Icons.star_rounded
                                          : Icons.star_border_rounded,
                                      color: isStarred
                                          ? Colors.amber
                                          : Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .animate()
                    .fade(delay: (index * 50).ms)
                    .slideY(begin: 0.1, end: 0);
              },
            );
          },
        ),
      ),
    );
  }
}
