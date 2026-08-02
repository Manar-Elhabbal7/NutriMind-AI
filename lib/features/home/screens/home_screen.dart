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
    const _BlankPage(title: 'Home Screen'),
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

class _BlankPage extends StatelessWidget {
  const _BlankPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1E1E1E), Color(0xFF121212)],
              )
            : AppColors.authBackgroundGradient,
      ),
      child: SafeArea(
        child: Center(
          child: Text(
            title,
            style: AppTextStyles.titleSecondary.copyWith(
              color: isDark ? Colors.white70 : AppColors.textPrimary.withValues(alpha: 0.4),
              fontSize: 20,
            ),
          ),
        ),
      ),
    );
  }
}
