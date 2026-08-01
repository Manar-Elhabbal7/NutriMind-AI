import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  
  // State variables
  String _email = '';
  String _gender = 'Female'; // Default gender
  String _profilePhotoPath = '';
  String _bannerPhotoPath = '';
  bool _isLoading = false;
  bool _isSaving = false;

  // Defaults
  static const String _defaultProfilePhoto = 'assets/images/girl.png';
  static const String _defaultBannerPhoto = 'assets/images/profile_background.jpeg';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  /// Load profile data from SharedPreferences and Firebase Auth
  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final user = AuthService.instance.currentUser;
      if (user != null) {
        _nameController.text = user.displayName ?? '';
        _email = user.email ?? '';
        if (user.photoURL != null && _profilePhotoPath.isEmpty) {
          _profilePhotoPath = user.photoURL!;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      setState(() {
        // Load display name from local prefs if Firebase display name is empty
        if (_nameController.text.isEmpty) {
          _nameController.text = prefs.getString('profile_display_name') ?? '';
        }
        
        // Load other physical metrics
        _gender = prefs.getString('profile_gender') ?? 'Female';
        _heightController.text = prefs.getString('profile_height') ?? '';
        _weightController.text = prefs.getString('profile_weight') ?? '';
        
        // Load photo paths
        _profilePhotoPath = prefs.getString('profile_photo_path') ?? _profilePhotoPath;
        _bannerPhotoPath = prefs.getString('profile_banner_path') ?? '';
      });
    } catch (e) {
      debugPrint('Error loading profile data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Save profile data to SharedPreferences and Firebase Auth
  Future<void> _saveProfileData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save local metrics
      await prefs.setString('profile_display_name', _nameController.text.trim());
      await prefs.setString('profile_gender', _gender);
      await prefs.setString('profile_height', _heightController.text.trim());
      await prefs.setString('profile_weight', _weightController.text.trim());
      await prefs.setString('profile_photo_path', _profilePhotoPath);
      await prefs.setString('profile_banner_path', _bannerPhotoPath);

      // Save display name and photoURL in Firebase Auth
      final user = AuthService.instance.currentUser;
      if (user != null) {
        await user.updateDisplayName(_nameController.text.trim());
        if (_profilePhotoPath.isNotEmpty && !_profilePhotoPath.startsWith('assets/')) {
          await user.updatePhotoURL(_profilePhotoPath);
        }
        await user.reload();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Profile updated successfully!',
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// Select profile photo using ImagePicker
  Future<void> _pickProfilePhoto() async {
    final picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _profilePhotoPath = pickedFile.path;
        });
      }
    } catch (e) {
      debugPrint('Error picking profile image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not access image gallery.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Select banner photo using ImagePicker
  Future<void> _pickBannerPhoto() async {
    final picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _bannerPhotoPath = pickedFile.path;
        });
      }
    } catch (e) {
      debugPrint('Error picking banner image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not access image gallery.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Handles user sign out
  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign Out', style: AppTextStyles.titleSecondary.copyWith(fontSize: 20)),
        content: Text('Are you sure you want to sign out of NutriMind?', style: AppTextStyles.bodyRegular),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  /// Dynamically load and build profile or banner image based on platform and type
  ImageProvider _buildImageProvider(String path, bool isProfile) {
    if (path.isEmpty) {
      return AssetImage(isProfile ? _defaultProfilePhoto : _defaultBannerPhoto);
    }
    
    if (path.startsWith('assets/')) {
      return AssetImage(path);
    }

    if (path.startsWith('http') || path.startsWith('https')) {
      return NetworkImage(path);
    }

    if (kIsWeb) {
      // On web, XFile path is a Blob URL which can be retrieved with NetworkImage
      return NetworkImage(path);
    } else {
      return FileImage(File(path));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Header: Banner & Profile Image
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Banner Image
                GestureDetector(
                  onTap: _pickBannerPhoto,
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.primaryExtraLight,
                      image: DecorationImage(
                        image: _buildImageProvider(_bannerPhotoPath, false),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Overlay gradient for aesthetics
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.3),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.1),
                              ],
                            ),
                          ),
                        ),
                        // Edit banner button
                        Positioned(
                          top: 50,
                          right: 16,
                          child: InkWell(
                            onTap: _pickBannerPhoto,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white30),
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Profile image overlapping the banner
                Positioned(
                  bottom: -55,
                  child: GestureDetector(
                    onTap: _pickProfilePhoto,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer white circular border
                        Container(
                          width: 116,
                          height: 116,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: _buildImageProvider(_profilePhotoPath, true),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Camera Badge
                        Positioned(
                          bottom: 0,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.secondary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 65),

            // Form Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Display Name Input (with Pin / edit Icon)
                    TextFormField(
                      controller: _nameController,
                      style: AppTextStyles.titleSecondary.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: 'Enter your name',
                        hintStyle: AppTextStyles.hintStyle.copyWith(fontSize: 18),
                        suffixIcon: const Padding(
                          padding: EdgeInsets.only(right: 12.0),
                          child: Icon(
                            Icons.push_pin_rounded,
                            color: AppColors.secondary,
                            size: 20,
                          ),
                        ),
                        border: InputBorder.none,
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.secondary.withValues(alpha: 0.5), width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name cannot be empty';
                        }
                        return null;
                      },
                    ).animate().fade().slideY(begin: 0.1, end: 0, duration: 300.ms),
                    
                    const SizedBox(height: 4),

                    // Email (Read-only)
                    Text(
                      _email.isNotEmpty ? _email : 'no-email@nutrimind.com',
                      style: AppTextStyles.bodyRegular.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ).animate().fade().slideY(begin: 0.1, end: 0, delay: 50.ms, duration: 300.ms),

                    const SizedBox(height: 32),

                    // 2. Physical Metrics Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.textPrimary.withValues(alpha: 0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Physical Profile',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Divider(height: 24, color: AppColors.divider),

                          // Gender Selection Box
                          Text(
                            'Gender',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // Female Option
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _gender = 'Female'),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _gender == 'Female'
                                          ? AppColors.primaryExtraLight
                                          : AppColors.fill,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _gender == 'Female'
                                            ? AppColors.primary.withValues(alpha: 0.5)
                                            : Colors.transparent,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.female_rounded,
                                          color: _gender == 'Female'
                                              ? AppColors.primary
                                              : AppColors.textSecondary,
                                          size: 26,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Female',
                                          style: AppTextStyles.bodyMedium.copyWith(
                                            color: _gender == 'Female'
                                                ? AppColors.primary
                                                : AppColors.textSecondary,
                                            fontWeight: _gender == 'Female'
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Male Option
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _gender = 'Male'),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _gender == 'Male'
                                          ? AppColors.secondaryExtraLight
                                          : AppColors.fill,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _gender == 'Male'
                                            ? AppColors.secondary.withValues(alpha: 0.5)
                                            : Colors.transparent,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.male_rounded,
                                          color: _gender == 'Male'
                                              ? AppColors.secondary
                                              : AppColors.textSecondary,
                                          size: 26,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Male',
                                          style: AppTextStyles.bodyMedium.copyWith(
                                            color: _gender == 'Male'
                                                ? AppColors.secondary
                                                : AppColors.textSecondary,
                                            fontWeight: _gender == 'Male'
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 20),

                          // Height (Length) Field
                          Text(
                            'Height',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _heightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              hintText: '165',
                              hintStyle: AppTextStyles.hintStyle,
                              filled: true,
                              fillColor: AppColors.fill,
                              prefixIcon: const Icon(Icons.height_rounded, color: AppColors.textSecondary, size: 20),
                              suffixText: 'cm',
                              suffixStyle: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.border, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your height';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Enter a valid number';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Weight Field
                          Text(
                            'Weight',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _weightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              hintText: '60',
                              hintStyle: AppTextStyles.hintStyle,
                              filled: true,
                              fillColor: AppColors.fill,
                              prefixIcon: const Icon(Icons.scale_rounded, color: AppColors.textSecondary, size: 20),
                              suffixText: 'kg',
                              suffixStyle: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.border, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your weight';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Enter a valid number';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ).animate().fade(delay: 150.ms).slideY(begin: 0.08, end: 0, duration: 400.ms),

                    const SizedBox(height: 32),

                    // 3. Save Button
                    if (_isSaving)
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      )
                    else
                      AppButton(
                        text: 'Save Changes',
                        onPressed: _saveProfileData,
                        backgroundColor: AppColors.primary,
                        borderRadius: 14,
                        height: 52,
                      ).animate().fade(delay: 200.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), duration: 350.ms),

                    const SizedBox(height: 16),

                    // 4. Sign Out Button
                    TextButton.icon(
                      onPressed: _handleSignOut,
                      icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
                      label: Text(
                        'Sign Out',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ).animate().fade(delay: 250.ms),

                    // Padding for bottom nav bar overlay
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
