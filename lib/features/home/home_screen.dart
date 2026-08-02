import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../chat/chat_screen.dart';

import 'profile/profile_screen.dart';
import 'scan/screens/scan_screen.dart';
import 'recipes/recipe_list_screen.dart';
import 'recipes/starred_recipes_screen.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../auth/services/auth_service.dart';
import '../../main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _profilePhotoPath = '';
  String _displayName = 'User';

  // Global keys for highlighting tutorial elements
  final GlobalKey _waterTrackerKey = GlobalKey();
  final GlobalKey _scanKey = GlobalKey();
  final GlobalKey _profileKey = GlobalKey();
  final GlobalKey _chatKey = GlobalKey();

  int? _tutorialStep;
  OverlayEntry? _tutorialOverlayEntry;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkOnboarding();
  }

  @override
  void dispose() {
    _hideTutorialOverlay();
    super.dispose();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final bool showOnboarding = prefs.getBool('show_onboarding') ?? false;
    if (showOnboarding) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            setState(() {
              _tutorialStep = 0;
              _showTutorialOverlay();
            });
          }
        });
      });
    }
  }

  void _showTutorialOverlay() {
    _hideTutorialOverlay();
    _tutorialOverlayEntry = OverlayEntry(
      builder: (context) => _buildTutorialOverlayWidget(),
    );
    Overlay.of(context).insert(_tutorialOverlayEntry!);
  }

  void _hideTutorialOverlay() {
    _tutorialOverlayEntry?.remove();
    _tutorialOverlayEntry = null;
  }

  void _nextTutorialStep() {
    if (_tutorialStep == null) return;
    setState(() {
      if (_tutorialStep! < 4) {
        _tutorialStep = _tutorialStep! + 1;
        if (_currentIndex != 0) {
          _currentIndex = 0;
        }
        // Force immediate rebuild to recalculate locations
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _tutorialOverlayEntry?.markNeedsBuild();
        });
      } else {
        _tutorialStep = null;
        _hideTutorialOverlay();
        _saveOnboardingComplete();
      }
    });
  }

  Future<void> _saveOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_onboarding', false);
  }

  RRect? _getWidgetRRect(
    GlobalKey key, {
    double padding = 8,
    double radius = 16,
  }) {
    if (key.currentContext == null) return null;
    final renderBox = key.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);
    return RRect.fromRectAndRadius(
      Rect.fromLTWH(
        position.dx - padding,
        position.dy - padding,
        size.width + padding * 2,
        size.height + padding * 2,
      ),
      Radius.circular(radius),
    );
  }

  Widget _buildTutorialOverlayWidget() {
    RRect? targetRRect;
    String title = '';
    String description = '';
    String buttonText = 'Next';

    if (_tutorialStep == 0) {
      title = 'Welcome to NutriMind AI! 🌟';
      description =
          'Let\'s take a quick 1-minute tour to see how this app can help you manage your nutrition and health goals.';
    } else if (_tutorialStep == 1) {
      targetRRect = _getWidgetRRect(_waterTrackerKey, padding: 6, radius: 18);
      title = 'Hydration Tracker 💧';
      description =
          'Track your daily water intake. Log every cup you drink to reach your daily goal.';
    } else if (_tutorialStep == 2) {
      targetRRect = _getWidgetRRect(_chatKey, padding: 4, radius: 30);
      title = 'AI Nutritionist Support 💬';
      description =
          'Have questions about recipes or your diet? Chat with our AI nutritionist assistant anytime.';
    } else if (_tutorialStep == 3) {
      targetRRect = _getWidgetRRect(_scanKey, padding: 6, radius: 16);
      title = 'Food & Product Scanner 🔍';
      description =
          'Scan food labels or barcodes to analyze their nutritional value instantly.';
    } else if (_tutorialStep == 4) {
      targetRRect = _getWidgetRRect(_profileKey, padding: 6, radius: 16);
      title = 'Profile & Preferences 👤';
      description =
          'Customize your physical metrics, gender, and configure water reminders.';
      buttonText = 'Get Started';
    }

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Spotlight Painter
          Positioned.fill(
            child: CustomPaint(painter: SpotlightPainter(targetRRect)),
          ),

          // Intercept clicks to prevent tap-through on other UI elements
          Positioned.fill(
            child: GestureDetector(
              onTap: _nextTutorialStep,
              behavior: HitTestBehavior.translucent,
            ),
          ),

          // Description Card
          _buildTutorialCard(title, description, buttonText, targetRRect),
        ],
      ),
    );
  }

  Widget _buildTutorialCard(
    String title,
    String description,
    String buttonText,
    RRect? targetRRect,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Widget card = Container(
      width: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white12
              : AppColors.secondary.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleSecondary.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: AppTextStyles.bodyRegular.copyWith(
              fontSize: 13,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Progress indicator dots
              Row(
                children: List.generate(5, (index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 6),
                    width: _tutorialStep == index ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _tutorialStep == index
                          ? AppColors.secondary
                          : (isDark ? Colors.white24 : AppColors.border),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
              ElevatedButton(
                onPressed: _nextTutorialStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (_tutorialStep == 0) {
      return Center(child: card);
    }

    double? top;
    double? bottom;
    double left = 20;
    double right = 20;

    if (_tutorialStep == 1) {
      if (targetRRect != null) {
        top = targetRRect.bottom + 12;
      } else {
        top = 360;
      }
    } else if (_tutorialStep == 2) {
      if (targetRRect != null) {
        bottom = MediaQuery.of(context).size.height - targetRRect.top + 12;
      } else {
        bottom = 180;
      }
    } else {
      if (targetRRect != null) {
        bottom = MediaQuery.of(context).size.height - targetRRect.top + 12;
      } else {
        bottom = 110;
      }
    }

    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Center(child: card),
    );
  }

  void _loadUserData() {
    final user = AuthService.instance.currentUser;
    if (user != null) {
      setState(() {
        _displayName = user.displayName ?? 'User';
        _profilePhotoPath = user.photoURL ?? '';
      });
    }
  }

  ImageProvider _buildImageProvider(String path) {
    if (path.isEmpty) {
      return const AssetImage('assets/images/girl.png');
    }
    if (path.startsWith('assets/')) {
      return AssetImage(path);
    }
    if (path.startsWith('http') || path.startsWith('https')) {
      return NetworkImage(path);
    }
    if (kIsWeb) {
      return NetworkImage(path);
    }
    return FileImage(File(path));
  }

  String _getCurrentDateString() {
    final now = DateTime.now();
    final day = now.day;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final monthStr = months[now.month - 1];
    return 'Today, $day $monthStr';
  }

  List<Widget> get _pages => [
    HomeScreenContent(waterTrackerKey: _waterTrackerKey),
    const ScanScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: (_currentIndex == 1 || _currentIndex == 2)
          ? null
          : AppBar(
              toolbarHeight: 96,
              leadingWidth: 76,
              leading: Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 7.0),
                child: Center(
                  child: CircleAvatar(
                    radius: 28,
                    backgroundImage: _buildImageProvider(_profilePhotoPath),
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
              title: Padding(
                padding: const EdgeInsets.only(top: 7.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Hello, $_displayName',
                      style: AppTextStyles.titleSecondary.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getCurrentDateString(),
                      style: AppTextStyles.bodyRegular.copyWith(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              centerTitle: true,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(top: 7.0),
                  child: IconButton(
                    tooltip: 'Starred Recipes',
                    icon: const Icon(Icons.star_rounded, color: Colors.amber),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StarredRecipesScreen(),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 7.0),
                  child: ValueListenableBuilder<ThemeMode>(
                    valueListenable: MyApp.themeNotifier,
                    builder: (context, currentMode, _) {
                      return IconButton(
                        icon: Icon(
                          currentMode == ThemeMode.dark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          color: AppColors.secondary,
                        ),
                        onPressed: () {
                          MyApp.themeNotifier.value =
                              currentMode == ThemeMode.dark
                              ? ThemeMode.light
                              : ThemeMode.dark;
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
              ],
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              automaticallyImplyLeading: false,
            ),
      body: Stack(
        children: [
          // Current Page Content
          Positioned.fill(child: _pages[_currentIndex]),

          // Glassmorphic Bottom Navigation Bar
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  height: 68,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1E1E1E).withValues(alpha: 0.85)
                        : Colors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white12
                          : AppColors.secondary.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(0, Icons.home_rounded, 'Home'),
                      _buildNavItem(1, Icons.qr_code_scanner_rounded, 'Scan'),
                      _buildNavItem(2, Icons.person_rounded, 'Profile'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 104.0),
        child: FloatingActionButton(
          key: _chatKey,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SupportChatScreen(),
              ),
            );
          },
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          child: const Icon(Icons.chat_bubble_outline_rounded),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final navKey = index == 1 ? _scanKey : (index == 2 ? _profileKey : null);
    return Material(
      key: navKey,
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
            if (index == 0) {
              _loadUserData();
            }
          });
        },
        borderRadius: BorderRadius.circular(20),
        splashColor: AppColors.secondary.withValues(alpha: 0.2),
        highlightColor: AppColors.secondary.withValues(alpha: 0.1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.secondary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: isSelected
                        ? AppColors.secondary
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                    size: 24,
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 8),
                    Text(
                          label,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 150.ms)
                        .slideX(begin: -0.1, end: 0),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreenContent extends StatefulWidget {
  final GlobalKey waterTrackerKey;
  const HomeScreenContent({super.key, required this.waterTrackerKey});

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
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF121212), Color(0xFF1E1E1E)],
              )
            : AppColors.authBackgroundGradient,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Safe spacing for the tall AppBar
            const SizedBox(height: 88),

            // Daily Hydration Tracker Card
            Container(
                  key: widget.waterTrackerKey,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
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
                              const SizedBox(height: 2),
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
                      const SizedBox(height: 5),

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
                      const SizedBox(height: 10),

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
                          const SizedBox(width: 8),
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

            const SizedBox(height: 14),
            Text(
              "Recipes Ideas",
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            GridView.count(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.8,
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

class SpotlightPainter extends CustomPainter {
  final RRect? rrect;
  SpotlightPainter(this.rrect);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;

    if (rrect == null) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
      return;
    }

    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final holePath = Path()..addRRect(rrect!);

    final spotlightPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      holePath,
    );

    canvas.drawPath(spotlightPath, paint);

    final borderPaint = Paint()
      ..color = AppColors.secondary.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(rrect!, borderPaint);
  }

  @override
  bool shouldRepaint(covariant SpotlightPainter oldDelegate) {
    return rrect != oldDelegate.rrect;
  }
}
