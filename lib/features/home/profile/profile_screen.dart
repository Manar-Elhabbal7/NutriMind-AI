import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/screens/login_screen.dart';
import '../services/notification_service.dart';
import 'widgets/profile_header.dart';
import 'widgets/physical_metrics_card.dart';
import 'widgets/preferences_card.dart';
import 'widgets/profile_actions.dart';

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
  final _scrollController = ScrollController();

  // State variables
  String _email = '';
  String _gender = 'Female'; // Default gender
  String _profilePhotoPath = '';
  String _bannerPhotoPath = '';
  bool _waterReminderEnabled = true;
  bool _isLoading = false;
  bool _isSaving = false;

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
    _scrollController.dispose();
    super.dispose();
  }

  /// Load profile data from Cloud Firestore, SharedPreferences and Firebase Auth
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
      bool loadedFromFirestore = false;

      if (user != null) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
            setState(() {
              if (data['displayName'] != null &&
                  data['displayName'].toString().trim().isNotEmpty) {
                _nameController.text = data['displayName'].toString();
              }
              if (data['gender'] != null &&
                  data['gender'].toString().trim().isNotEmpty) {
                _gender = data['gender'].toString();
              }
              if (data['height'] != null &&
                  data['height'].toString().trim().isNotEmpty) {
                _heightController.text = data['height'].toString();
              }
              if (data['weight'] != null &&
                  data['weight'].toString().trim().isNotEmpty) {
                _weightController.text = data['weight'].toString();
              }
              if (data['profilePhoto'] != null &&
                  data['profilePhoto'].toString().trim().isNotEmpty) {
                _profilePhotoPath = data['profilePhoto'].toString();
              }
              if (data['bannerPhoto'] != null &&
                  data['bannerPhoto'].toString().trim().isNotEmpty) {
                _bannerPhotoPath = data['bannerPhoto'].toString();
              }
              if (data['waterReminderEnabled'] != null) {
                _waterReminderEnabled = data['waterReminderEnabled'] as bool;
              }
            });
            loadedFromFirestore = true;

            // Cache to SharedPreferences
            await prefs.setString(
              'profile_display_name',
              _nameController.text.trim(),
            );
            await prefs.setString('profile_gender', _gender);
            await prefs.setString(
              'profile_height',
              _heightController.text.trim(),
            );
            await prefs.setString(
              'profile_weight',
              _weightController.text.trim(),
            );
            await prefs.setString('profile_photo_path', _profilePhotoPath);
            await prefs.setString('profile_banner_path', _bannerPhotoPath);
            await prefs.setBool(
              'water_reminder_enabled',
              _waterReminderEnabled,
            );
          }
        } catch (firestoreError) {
          debugPrint(
            'Error loading from Firestore, falling back to local storage: $firestoreError',
          );
        }
      }

      if (!loadedFromFirestore) {
        setState(() {
          // Load display name from local prefs if Firebase display name is empty
          if (_nameController.text.isEmpty) {
            _nameController.text =
                prefs.getString('profile_display_name') ?? '';
          }

          // Load other physical metrics
          _gender = prefs.getString('profile_gender') ?? 'Female';
          _heightController.text = prefs.getString('profile_height') ?? '';
          _weightController.text = prefs.getString('profile_weight') ?? '';

          // Load photo paths
          _profilePhotoPath =
              prefs.getString('profile_photo_path') ?? _profilePhotoPath;
          _bannerPhotoPath = prefs.getString('profile_banner_path') ?? '';
          _waterReminderEnabled =
              prefs.getBool('water_reminder_enabled') ?? true;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfileData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();

      // Handle water reminder scheduling & permissions
      bool granted = true;
      if (_waterReminderEnabled) {
        granted = await NotificationService.instance.requestPermissions();
        if (!granted && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Please enable notification permissions in system settings to receive reminders.',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
              ),
              backgroundColor: AppColors.secondary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }

      final List<Future<void>> saveTasks = [];

      // Concurrently save to SharedPreferences
      saveTasks.add(
        Future.wait([
          prefs.setString('profile_display_name', _nameController.text.trim()),
          prefs.setString('profile_gender', _gender),
          prefs.setString('profile_height', _heightController.text.trim()),
          prefs.setString('profile_weight', _weightController.text.trim()),
          prefs.setString('profile_photo_path', _profilePhotoPath),
          prefs.setString('profile_banner_path', _bannerPhotoPath),
          prefs.setBool('water_reminder_enabled', _waterReminderEnabled),
        ]),
      );

      // Concurrently handle water reminder scheduling
      if (_waterReminderEnabled) {
        saveTasks.add(NotificationService.instance.scheduleWaterReminders());
      } else {
        saveTasks.add(NotificationService.instance.cancelAllNotifications());
      }

      // Concurrently save to Firebase Firestore and Auth
      final user = AuthService.instance.currentUser;
      if (user != null) {
        final List<Future<void>> dbAndAuthTasks = [
          () async {
            try {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .set({
                    'displayName': _nameController.text.trim(),
                    'gender': _gender,
                    'height': _heightController.text.trim(),
                    'weight': _weightController.text.trim(),
                    'profilePhoto': _profilePhotoPath,
                    'bannerPhoto': _bannerPhotoPath,
                    'waterReminderEnabled': _waterReminderEnabled,
                    'updatedAt': FieldValue.serverTimestamp(),
                  }, SetOptions(merge: true));
            } catch (firestoreError) {
              debugPrint(
                'Firestore save failed (falling back to local-only cache): $firestoreError',
              );
            }
          }(),
          user.updateDisplayName(_nameController.text.trim()),
        ];

        if (_profilePhotoPath.isNotEmpty &&
            !_profilePhotoPath.startsWith('assets/') &&
            !_profilePhotoPath.startsWith('data:image/') &&
            _profilePhotoPath.length < 2048) {
          dbAndAuthTasks.add(
            user.updatePhotoURL(_profilePhotoPath).catchError((e) {
              debugPrint('Failed to update photo URL in Firebase Auth: $e');
            }),
          );
        }

        // Run db/auth updates concurrently and then reload user
        saveTasks.add(Future.wait(dbAndAuthTasks).then((_) => user.reload()));
      }

      // Await all parallel saving tasks
      await Future.wait(saveTasks);

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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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
    if (kIsWeb) {
      await _pickProfilePhotoFromSource(ImageSource.gallery);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_library_rounded,
                  color: AppColors.secondary,
                ),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickProfilePhotoFromSource(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_rounded,
                  color: AppColors.secondary,
                ),
                title: const Text('Take a Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickProfilePhotoFromSource(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickProfilePhotoFromSource(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 150,
        maxHeight: 150,
        imageQuality: 50,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        setState(() {
          _profilePhotoPath = base64String;
        });
      }
    } catch (e) {
      debugPrint('Error picking profile image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              source == ImageSource.camera
                  ? 'Could not access camera.'
                  : 'Could not access image gallery.',
            ),
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
        maxWidth: 500,
        maxHeight: 250,
        imageQuality: 50,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        setState(() {
          _bannerPhotoPath = base64String;
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
    await AuthService.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // 1. Header: Banner & Profile Image
            ProfileHeader(
              bannerPhotoPath: _bannerPhotoPath,
              profilePhotoPath: _profilePhotoPath,
              onPickProfilePhoto: _pickProfilePhoto,
              onPickBannerPhoto: _pickBannerPhoto,
            ),

            const SizedBox(height: 2),

            // Form Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Display Name Input
                    TextFormField(
                      controller: _nameController,
                      style: AppTextStyles.titleSecondary.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: 'Enter your name',
                        hintStyle: AppTextStyles.hintStyle.copyWith(
                          fontSize: 16,
                          color: isDark
                              ? Colors.white30
                              : AppColors.textSecondary.withValues(alpha: 0.5),
                        ),
                        border: InputBorder.none,
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.secondary.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 2,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name cannot be empty';
                        }
                        return null;
                      },
                    ).animate().fade().slideY(
                      begin: 0.1,
                      end: 0,
                      duration: 300.ms,
                    ),

                    const SizedBox(height: 0),

                    // Email (Read-only)
                    Text(
                      _email.isNotEmpty ? _email : 'no-email@nutrimind.com',
                      style: AppTextStyles.bodyRegular.copyWith(
                        color: isDark
                            ? Colors.white54
                            : AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ).animate().fade().slideY(
                      begin: 0.1,
                      end: 0,
                      delay: 50.ms,
                      duration: 300.ms,
                    ),

                    const SizedBox(height: 8),

                    // 2. Physical Metrics Card
                    PhysicalMetricsCard(
                      gender: _gender,
                      onGenderChanged: (value) {
                        setState(() {
                          _gender = value;
                        });
                      },
                      heightController: _heightController,
                      weightController: _weightController,
                    ),

                    const SizedBox(height: 8),

                    // 3. Notification Preferences Card
                    PreferencesCard(
                      waterReminderEnabled: _waterReminderEnabled,
                      onWaterReminderChanged: (value) {
                        setState(() {
                          _waterReminderEnabled = value;
                        });
                      },
                    ),

                    const SizedBox(height: 10),

                    // 4. Action Buttons Row
                    ProfileActions(
                      isSaving: _isSaving,
                      onSaveChanges: _saveProfileData,
                      onSignOut: _handleSignOut,
                    ),

                    // Padding for bottom nav bar overlay
                    const SizedBox(height: 110),
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
