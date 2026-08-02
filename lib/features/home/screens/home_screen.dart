import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../chat/chat_screen.dart';

import 'profile_screen.dart';
import '../../scan/screens/scan_screen.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../../auth/services/auth_service.dart';
import '../../../main.dart';
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

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final monthStr = months[now.month - 1];
    return 'Today, $day $monthStr';
  }

  List<Widget> get _pages => [
    const HomeScreenContent(),
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
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              centerTitle: true,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(top: 7.0),
                  child: ValueListenableBuilder<ThemeMode>(
                    valueListenable: MyApp.themeNotifier,
                    builder: (context, currentMode, _) {
                      return IconButton(
                        icon: Icon(
                          currentMode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                          color: AppColors.secondary,
                        ),
                        onPressed: () {
                          MyApp.themeNotifier.value = currentMode == ThemeMode.dark
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
          Positioned.fill(
            child: _pages[_currentIndex],
          ),
          
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
    return Material(
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
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
                    ).animate().fadeIn(duration: 150.ms).slideX(begin: -0.1, end: 0),
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
  const HomeScreenContent({super.key});

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
            const SizedBox(height: 105),

            // Daily Hydration Tracker Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark ? Colors.white12 : AppColors.border,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withValues(alpha: isDark ? 0.01 : 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
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
                            "Daily Tracker",
                            style: GoogleFonts.poppins(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Track your hydration intake",
                            style: GoogleFonts.poppins(
                              color: isDark ? Colors.white54 : AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.water_drop_rounded,
                          color: AppColors.secondary,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  // Progress display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${currentIntakeLiters}L / ${targetIntakeLiters}L",
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${(progress * 100).toInt()}%",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: isDark ? Colors.white12 : AppColors.secondary.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  // Buttons Row
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _addWater,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text("Add 250 ml"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: _resetWater,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? Colors.white70 : AppColors.textSecondary,
                          side: BorderSide(color: isDark ? Colors.white24 : AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        child: const Text("Reset"),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fade(delay: 150.ms).slideY(begin: 0.1, end: 0, duration: 400.ms),

            const SizedBox(height: 120), // clearance for bottom navigation bar
          ],
        ),
      ),
    );
  }
}
