import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ProfileHeader extends StatelessWidget {
  final String bannerPhotoPath;
  final String profilePhotoPath;
  final VoidCallback onPickProfilePhoto;
  final VoidCallback onPickBannerPhoto;

  const ProfileHeader({
    super.key,
    required this.bannerPhotoPath,
    required this.profilePhotoPath,
    required this.onPickProfilePhoto,
    required this.onPickBannerPhoto,
  });

  static const String _defaultProfilePhoto = 'assets/images/girl.png';
  static const String _defaultBannerPhoto = 'assets/images/profile_background1.jpeg';

  ImageProvider _buildImageProvider(String path, bool isProfile) {
    if (path.isEmpty) {
      return AssetImage(isProfile ? _defaultProfilePhoto : _defaultBannerPhoto);
    }

    if (path.startsWith('data:image/') || path.contains(';base64,')) {
      final base64String = path.contains(',') ? path.split(',').last : path;
      try {
        return MemoryImage(base64Decode(base64String));
      } catch (e) {
        debugPrint('Error decoding base64 image: $e');
        return AssetImage(isProfile ? _defaultProfilePhoto : _defaultBannerPhoto);
      }
    }

    if (path.startsWith('assets/')) {
      return AssetImage(path);
    }

    if (path.startsWith('http') || path.startsWith('https')) {
      return NetworkImage(path);
    }

    if (kIsWeb) {
      return NetworkImage(path);
    } else {
      return FileImage(File(path));
    }
  }

  @override
  Widget build(BuildContext context) {

    return SizedBox(
      height: 185,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Banner Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 120,
            child: GestureDetector(
              onTap: onPickBannerPhoto,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryExtraLight,
                  image: DecorationImage(
                    image: _buildImageProvider(bannerPhotoPath, false),
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
                      top: 30,
                      right: 16,
                      child: InkWell(
                        onTap: onPickBannerPhoto,
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
          ),

          // Profile image overlapping the banner
          Positioned(
            top: 75,
            child: GestureDetector(
              onTap: onPickProfilePhoto,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer white circular border containing full profile photo
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                      image: DecorationImage(
                        image: _buildImageProvider(
                          profilePhotoPath,
                          true,
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Camera Badge
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.all(5),
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
                        size: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
