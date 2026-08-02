import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/recipe_service.dart';
import '../../../core/theme/app_colors.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;
  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late Future<Recipe> _recipeDetailsFuture;
  bool _isStarred = false;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();
    _recipeDetailsFuture = RecipeService.instance.fetchRecipeDetails(widget.recipe);
    _checkStarredStatus();
  }

  Future<void> _checkStarredStatus() async {
    final starred = await RecipeService.instance.isStarred(widget.recipe.id);
    if (mounted) {
      setState(() {
        _isStarred = starred;
      });
    }
  }

  Future<void> _toggleStar(Recipe fullRecipe) async {
    if (_isToggling) return;
    setState(() => _isToggling = true);
    await RecipeService.instance.toggleStarRecipe(fullRecipe);
    await _checkStarredStatus();
    setState(() => _isToggling = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isStarred
                ? "${widget.recipe.title} added to favorites!"
                : "${widget.recipe.title} removed from favorites.",
          ),
          duration: const Duration(seconds: 1),
          backgroundColor: AppColors.secondary,
        ),
      );
    }
  }

  List<String> _parseInstructions(String instructions) {
    if (instructions.isEmpty) return [];
    return instructions
        .split(RegExp(r'\r?\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e.length > 3)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: FutureBuilder<Recipe>(
        future: _recipeDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.secondary),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Scaffold(
              appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
              body: Center(
                child: Text(
                  "Failed to load recipe details. Please try again.",
                  style: GoogleFonts.poppins(color: AppColors.textSecondary),
                ),
              ),
            );
          }

          final fullRecipe = snapshot.data!;
          final steps = _parseInstructions(fullRecipe.instructions);

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Beautiful Sliver App Bar with Image
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                stretch: true,
                backgroundColor: isDark ? const Color(0xFF121212) : AppColors.secondary,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withValues(alpha: 0.5),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withValues(alpha: 0.5),
                      child: IconButton(
                        icon: Icon(
                          _isStarred ? Icons.star_rounded : Icons.star_border_rounded,
                          color: _isStarred ? Colors.amber : Colors.white,
                        ),
                        onPressed: () => _toggleStar(fullRecipe),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        fullRecipe.imageUrl,
                        fit: BoxFit.cover,
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black38,
                              Colors.transparent,
                              Colors.black54,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],
                ),
              ),

              // Detail Content
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF121212) : AppColors.background,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Align(
                          alignment: Alignment.center,
                          child: Text(
                            fullRecipe.title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ).animate().fade().slideY(begin: 0.1, end: 0),
                        
                        const SizedBox(height: 8),

                        // Tags
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                fullRecipe.category,
                                style: GoogleFonts.poppins(
                                  color: AppColors.secondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                fullRecipe.isDrink ? "Smoothie / Drink" : "Healthy Food",
                                style: GoogleFonts.poppins(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ).animate().fade(delay: 100.ms),

                        const Divider(height: 32, thickness: 1.5),

                        // Ingredients (gradients)
                        Align(
                          alignment: Alignment.center,
                          child: Text(
                            "Ingredients",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ).animate().fade(delay: 150.ms),
                        
                        const SizedBox(height: 12),

                        if (fullRecipe.ingredients.isEmpty)
                          Text(
                            "No ingredients listed.",
                            style: GoogleFonts.poppins(color: AppColors.textSecondary),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            itemCount: fullRecipe.ingredients.length,
                            itemBuilder: (context, index) {
                              final ingredient = fullRecipe.ingredients[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6.0),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 10,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        ingredient,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: isDark ? Colors.white.withValues(alpha: 0.9) : AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate().fade(delay: (200 + index * 30).ms).slideX(begin: -0.05, end: 0);
                            },
                          ),

                        const Divider(height: 32, thickness: 1.5),

                        // Instructions
                        Align(
                          alignment: Alignment.center,
                          child: Text(
                            "How to Make",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ).animate().fade(delay: 250.ms),
                        
                        const SizedBox(height: 12),

                        if (steps.isEmpty)
                          Text(
                            fullRecipe.instructions.isNotEmpty
                                ? fullRecipe.instructions
                                : "No instructions available.",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              height: 1.6,
                              color: isDark ? Colors.white.withValues(alpha: 0.9) : AppColors.textPrimary,
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            itemCount: steps.length,
                            itemBuilder: (context, index) {
                              final step = steps[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: AppColors.secondary,
                                      child: Text(
                                        "${index + 1}",
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        step,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          height: 1.5,
                                          color: isDark ? Colors.white.withValues(alpha: 0.9) : AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate().fade(delay: (300 + index * 40).ms).slideY(begin: 0.05, end: 0);
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
