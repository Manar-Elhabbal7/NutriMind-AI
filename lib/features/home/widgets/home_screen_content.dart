import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../recipes/recipe_list_screen.dart';

class HomeScreenContent extends StatefulWidget {
  final GlobalKey waterTrackerKey;
  final GlobalKey recipesKey;
  const HomeScreenContent({
    super.key,
    required this.waterTrackerKey,
    required this.recipesKey,
  });

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  int _waterCups = 0; // Each cup is 250ml
  final int _targetCups = 10; // Target is 2.5L (10 cups)

  @override
  void initState() {
    super.initState();
    _loadWaterIntake();
  }

  Future<void> _loadWaterIntake() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _waterCups = prefs.getInt('daily_water_cups') ?? 0;
    });
  }

  Future<void> _addWater() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_waterCups < _targetCups) {
        _waterCups++;
        prefs.setInt('daily_water_cups', _waterCups);
      }
    });
  }

  Future<void> _resetWater() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _waterCups = 0;
      prefs.setInt('daily_water_cups', 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentIntakeLiters = (_waterCups * 0.25).toStringAsFixed(2);
    final targetIntakeLiters = (_targetCups * 0.25).toStringAsFixed(2);
    final progress = _waterCups / _targetCups;

    return Container(
      color: isDark ? null : Colors.white,
      decoration: isDark
          ? const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF121212), Color(0xFF1E1E1E)],
              ),
            )
          : null,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Safe spacing for the tall AppBar
            const SizedBox(height: 165),

            Container(
                  key: widget.waterTrackerKey,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: isDark ? Colors.white12 : AppColors.border,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.textPrimary.withValues(
                          alpha: isDark ? 0.01 : 0.04,
                        ),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Water Tracker",
                                style: GoogleFonts.poppins(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Track your hydration intake",
                                style: GoogleFonts.poppins(
                                  color: isDark
                                      ? Colors.white54
                                      : AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.water_drop_rounded,
                              color: AppColors.secondary,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Progress display
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${currentIntakeLiters}L / ${targetIntakeLiters}L",
                            style: GoogleFonts.poppins(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "${(progress * 100).toInt()}%",
                            style: GoogleFonts.poppins(
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),

                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: isDark
                              ? Colors.white12
                              : AppColors.secondary.withValues(alpha: 0.1),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.secondary,
                          ),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Buttons Row
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _addWater,
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text(
                              "Add 250 ml",
                              style: TextStyle(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: _resetWater,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark
                                  ? Colors.white70
                                  : AppColors.textSecondary,
                              side: BorderSide(
                                color: isDark
                                    ? Colors.white24
                                    : AppColors.border,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                            ),
                            child: const Text(
                              "Reset",
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
                .animate()
                .fade(delay: 150.ms)
                .slideY(begin: 0.1, end: 0, duration: 400.ms),

            const SizedBox(height: 20),
            Text(
              key: widget.recipesKey,
              "Recipes Ideas",
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            GridView.count(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.4,
              children: [
                _buildCategoryCard(
                  "Breakfast",
                  "assets/images/breakfast.jpg",
                  context,
                ),
                _buildCategoryCard(
                  "Lunch",
                  "assets/images/launch.jpg",
                  context,
                ),
                _buildCategoryCard(
                  "Dinner",
                  "assets/images/dinner.jpg",
                  context,
                ),
                _buildCategoryCard(
                  "Smoothies",
                  "assets/images/juice.jpg",
                  context,
                ),
              ],
            ),

            const SizedBox(height: 96), // clearance for bottom navigation bar
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    String title,
    String imagePath,
    BuildContext context,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeListScreen(category: title),
          ),
        );
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
              Positioned.fill(child: Image.asset(imagePath, fit: BoxFit.cover)),
              // Dark Gradient Overlay for readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
              ),
              // Category Title and Icon
              Positioned(
                bottom: 8,
                left: 10,
                right: 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getCategoryIcon(title),
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ).animate().scale(delay: 200.ms, duration: 300.ms),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case "Breakfast":
        return Icons.wb_sunny_rounded;
      case "Lunch":
        return Icons.lunch_dining_rounded;
      case "Dinner":
        return Icons.dinner_dining_rounded;
      case "Smoothies":
        return Icons.local_drink_rounded;
      default:
        return Icons.restaurant_menu_rounded;
    }
  }
}
