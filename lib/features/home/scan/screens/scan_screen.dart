import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../recipes/starred_recipes_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  CameraController? _controller;
  bool _isCameraReady = false;
  bool _hasError = false;
  String _errorMsg = '';
  final ImagePicker _picker = ImagePicker();
  final Dio _dio = Dio();
  XFile? _previewPhoto;

  // Focus properties
  Offset? _tapPosition;
  bool _showFocusSquare = false;
  Timer? _focusTimer;

  // Flash mode
  FlashMode _flashMode = FlashMode.off;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (kIsWeb) {
      setState(() {
        _hasError = true;
        _errorMsg =
            "Live camera view is not supported on web browsers. Use upload option instead.";
      });
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMsg = "No cameras found on this device.";
        });
        return;
      }

      // Allow only background camera
      CameraDescription? backCamera;
      for (var camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.back) {
          backCamera = camera;
          break;
        }
      }

      backCamera ??= cameras.first;

      _controller = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isCameraReady = true;
          _hasError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMsg =
              "Camera access denied. Please enable camera permissions in your settings.";
        });
      }
    }
  }

  @override
  void dispose() {
    _focusTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _handleFocus(TapUpDetails details) async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    // Calculate focal point
    final double x =
        details.localPosition.dx / MediaQuery.of(context).size.width;
    final double y =
        details.localPosition.dy / MediaQuery.of(context).size.height;
    final Offset focusPoint = Offset(x, y);

    try {
      await _controller!.setFocusPoint(focusPoint);
      await _controller!.setExposurePoint(focusPoint);

      setState(() {
        _tapPosition = details.localPosition;
        _showFocusSquare = true;
      });

      _focusTimer?.cancel();
      _focusTimer = Timer(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _showFocusSquare = false;
          });
        }
      });
    } catch (e) {
      // Focus settings might fail on emulator/hardware differences
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_isCameraReady) return;
    try {
      final nextMode = _flashMode == FlashMode.off
          ? FlashMode.torch
          : FlashMode.off;
      await _controller!.setFlashMode(nextMode);
      setState(() {
        _flashMode = nextMode;
      });
    } catch (e) {
      // Flash not supported
    }
  }

  Future<void> _captureAndAnalyze() async {
    if (_controller == null || !_isCameraReady) return;
    try {
      final XFile photo = await _controller!.takePicture();
      _showScanResultsBottomSheet(photo);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to take photo: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);
      if (photo != null) {
        _showScanResultsBottomSheet(photo);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to pick image: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        _showScanResultsBottomSheet(photo);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to capture image: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showScanResultsBottomSheet(XFile photoFile) {
    setState(() {
      _previewPhoto = photoFile;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.25),
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: _ScanResultDetailsSheet(photo: photoFile, dio: _dio),
          ),
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() {
          _previewPhoto = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_previewPhoto != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SizedBox.expand(
          child: kIsWeb
              ? Image.network(_previewPhoto!.path, fit: BoxFit.cover)
              : Image.file(File(_previewPhoto!.path), fit: BoxFit.cover),
        ),
      );
    }

    if (!_isCameraReady || _hasError) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.camera_alt_outlined,
                  size: 80,
                  color: Colors.white.withValues(alpha: 0.5),
                ).animate().scale(delay: 100.ms, duration: 400.ms),
                const SizedBox(height: 24),
                Text(
                  "Camera Setup",
                  style: AppTextStyles.titleSecondary.copyWith(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _errorMsg.isNotEmpty
                      ? _errorMsg
                      : "Setting up the scanner. If you are on an emulator, please upload a photo from gallery instead.",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyRegular.copyWith(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickFromCamera,
                      icon: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      label: const Text(
                        "Take Photo",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _pickFromGallery,
                      icon: const Icon(
                        Icons.photo_library_rounded,
                        color: AppColors.secondary,
                        size: 16,
                      ),
                      label: const Text(
                        "Upload",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppColors.secondary,
                          width: 1.5,
                        ),
                        foregroundColor: AppColors.secondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Live Camera Preview
          GestureDetector(
            onTapUp: _handleFocus,
            child: Center(
              child: Transform.scale(
                scale: 1.0,
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: CameraPreview(_controller!),
                ),
              ),
            ),
          ),

          // Scanner Target Frame Overlay
          Center(
            child: Container(
              width: size.width * 0.72,
              height: size.width * 0.72,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                children: [
                  // Corner brackets for professional feel
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: AppColors.secondary,
                            width: 4,
                          ),
                          top: BorderSide(color: AppColors.secondary, width: 4),
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: AppColors.secondary,
                            width: 4,
                          ),
                          top: BorderSide(color: AppColors.secondary, width: 4),
                        ),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    bottom: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: AppColors.secondary,
                            width: 4,
                          ),
                          bottom: BorderSide(
                            color: AppColors.secondary,
                            width: 4,
                          ),
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: AppColors.secondary,
                            width: 4,
                          ),
                          bottom: BorderSide(
                            color: AppColors.secondary,
                            width: 4,
                          ),
                        ),
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 400.ms),

          // Animated Scanning Line Overlay
          Center(
            child: Container(
              width: size.width * 0.72,
              height: size.width * 0.72,
              alignment: Alignment.topCenter,
              child:
                  Container(
                        width: size.width * 0.68,
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.secondary.withValues(alpha: 0.1),
                              AppColors.secondary,
                              AppColors.secondary.withValues(alpha: 0.1),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.secondary.withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      )
                      .animate(
                        onPlay: (controller) =>
                            controller.repeat(reverse: true),
                      )
                      .slideY(
                        begin: 0.05,
                        end: 12.0,
                        duration: 2500.ms,
                        curve: Curves.easeInOut,
                      ),
            ),
          ),

          // Top Header Controls
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _flashMode == FlashMode.torch
                          ? Icons.flash_on
                          : Icons.flash_off,
                      color: _flashMode == FlashMode.torch
                          ? Colors.yellow
                          : Colors.white,
                      size: 20,
                    ),
                    onPressed: _toggleFlash,
                  ),
                ),
              ],
            ),
          ),

          // Focus indicator visual square
          if (_showFocusSquare && _tapPosition != null)
            Positioned(
              left: _tapPosition!.dx - 28,
              top: _tapPosition!.dy - 28,
              child:
                  Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.secondary,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      )
                      .animate()
                      .scale(
                        begin: const Offset(1.4, 1.4),
                        end: const Offset(1.0, 1.0),
                        duration: 200.ms,
                      )
                      .fadeOut(delay: 800.ms, duration: 200.ms),
            ),

          // Bottom Controller Bar
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Place the food inside the box to scan",
                  style: AppTextStyles.bodyRegular.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Gallery selector button
                    GestureDetector(
                      onTap: _pickFromGallery,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.photo_library_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),

                    // Trigger/Capture Button
                    GestureDetector(
                      onTap: _captureAndAnalyze,
                      child: Container(
                        height: 76,
                        width: 76,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.secondary,
                            width: 4,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            height: 60,
                            width: 60,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Favorites button
                    Tooltip(
                      message: 'Starred Recipes',
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const StarredRecipesScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanResultDetailsSheet extends StatefulWidget {
  final XFile photo;
  final Dio dio;

  const _ScanResultDetailsSheet({required this.photo, required this.dio});

  @override
  State<_ScanResultDetailsSheet> createState() =>
      _ScanResultDetailsSheetState();
}

class _ScanResultDetailsSheetState extends State<_ScanResultDetailsSheet> {
  bool _isLoading = true;
  String? _errorMessage;
  String _analysisText = '';

  // Parsed nutrition values
  String _calories = 'N/A';
  String _carbs = 'N/A';
  String _protein = 'N/A';
  String _fats = 'N/A';
  String _foodName = 'Identified Food';

  @override
  void initState() {
    super.initState();
    _analyzeFoodImage();
  }

  Future<void> _analyzeFoodImage() async {
    try {
      final imageBytes = await widget.photo.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final String prompt =
          "Analyze this food image. Provide details in a structured way: "
          "1. Food Name / Identified Item "
          "2. Nutritional facts per 100g (Estimated Calories, Carbs, Protein, Fats) "
          "3. Health Score (1 to 10) and explanation "
          "4. Simple healthy tips or recommendation. "
          "Keep it highly readable, concise, and structured. "
          "Separate each of these 4 sections with a horizontal rule (---) so it renders beautiful dividers between them. "
          "At the very end of your response, add a single line in this exact format: "
          "METRICS: Name=FOOD_NAME, Calories=CALORIES_VAL, Carbs=CARBS_VAL, Protein=PROTEIN_VAL, Fats=FATS_VAL "
          "Where FOOD_NAME is the food item name, and CALORIES_VAL, CARBS_VAL, PROTEIN_VAL, FATS_VAL are numeric values like '150 kcal', '20g', '12g', '5g'.";

      final response = await widget.dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent?key=AQ.Ab8RN6LAcwx88KBQQADRB5SXHojNRdbGvYMWNZn7MCgIjtSYaQ',
        data: {
          'contents': [
            {
              'parts': [
                {'text': prompt},
                {
                  'inlineData': {'mimeType': 'image/jpeg', 'data': base64Image},
                },
              ],
            },
          ],
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
          receiveTimeout: const Duration(seconds: 25),
          connectTimeout: const Duration(seconds: 25),
        ),
      );

      String content = '';
      if (response.data != null && response.data['candidates'] != null) {
        final candidates = response.data['candidates'] as List;
        if (candidates.isNotEmpty) {
          final contentObj = candidates.first['content'];
          if (contentObj != null) {
            final parts = contentObj['parts'] as List;
            if (parts.isNotEmpty) {
              content = parts.first['text'] ?? '';
            }
          }
        }
      }

      if (content.isEmpty) {
        throw Exception("Failed to analyze image content from Gemini.");
      }

      // Parse Metrics Line
      final regex = RegExp(
        r'METRICS:\s*Name=(.*?),\s*Calories=(.*?),\s*Carbs=(.*?),\s*Protein=(.*?),\s*Fats=(.*)',
      );
      final match = regex.firstMatch(content);

      String mainAnalysis = content;
      if (match != null) {
        _foodName = match.group(1)?.trim() ?? 'Identified Food';
        _calories = match.group(2)?.trim() ?? 'N/A';
        _carbs = match.group(3)?.trim() ?? 'N/A';
        _protein = match.group(4)?.trim() ?? 'N/A';
        _fats = match.group(5)?.trim() ?? 'N/A';

        // Remove the METRICS line from display text
        mainAnalysis = content.split('METRICS:').first.trim();
      } else {
        // Fallback name guess
        final nameLines = content.split('\n');
        if (nameLines.isNotEmpty) {
          _foodName = nameLines.first.replaceAll(RegExp(r'[#*_\-]'), '').trim();
        }
      }

      if (mounted) {
        setState(() {
          _analysisText = mainAnalysis;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.80,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Drag indicator bar
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),

          // Loading and Analysis States
          Expanded(
            child: _isLoading
                ? _buildLoadingWidget()
                : _errorMessage != null
                ? _buildErrorWidget()
                : _buildResultsWidget(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.secondary),
          const SizedBox(height: 24),
          Text(
            "Analyzing Food Item...",
            style: AppTextStyles.titleSecondary.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            "NutriMind AI is scanning details and calculating nutrition values...",
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyRegular.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            "Analysis Failed",
            style: AppTextStyles.titleSecondary.copyWith(
              fontSize: 18,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? "An unexpected network error occurred.",
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyRegular.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
              _analyzeFoodImage();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsWidget() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        // Title and crop avatar row
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Circular Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: kIsWeb
                  ? Image.network(
                      widget.photo.path,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                    )
                  : Image.file(
                      File(widget.photo.path),
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "SCAN RESULT",
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.secondary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _foodName,
                    style: AppTextStyles.titleSecondary.copyWith(
                      fontSize: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ).animate().fadeIn(duration: 300.ms),

        const SizedBox(height: 20),
        Container(
          height: 1.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.secondary.withValues(alpha: 0.05),
                AppColors.secondary.withValues(alpha: 0.25),
                AppColors.secondary.withValues(alpha: 0.05),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // 4 Nutrition Metric Cards
        Row(
          children: [
            Expanded(
              child: _buildNutritionCard(
                title: "Calories",
                value: _calories,
                icon: Icons.local_fire_department_rounded,
                accentColor: const Color(0xFFFF8A65),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildNutritionCard(
                title: "Protein",
                value: _protein,
                icon: Icons.fitness_center_rounded,
                accentColor: const Color(0xFF64B5F6),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildNutritionCard(
                title: "Carbs",
                value: _carbs,
                icon: Icons.grass_rounded,
                accentColor: const Color(0xFFFFD54F),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildNutritionCard(
                title: "Fats",
                value: _fats,
                icon: Icons.opacity_rounded,
                accentColor: const Color(0xFFE57373),
              ),
            ),
          ],
        ).animate().slideY(begin: 0.1, end: 0, duration: 300.ms),

        const SizedBox(height: 24),
        Container(
          height: 1.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.secondary.withValues(alpha: 0.05),
                AppColors.secondary.withValues(alpha: 0.3),
                AppColors.secondary.withValues(alpha: 0.05),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        Text(
          "Detailed Analysis",
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 16,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // Full Markdown analysis details
        MarkdownBody(
          data: _analysisText,
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
            p: AppTextStyles.bodyRegular.copyWith(
              color: AppColors.textPrimary,
              fontSize: 14.5,
              height: 1.5,
            ),
            strong: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            listBullet: AppTextStyles.bodyRegular.copyWith(
              color: AppColors.textPrimary,
            ),
            h1: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            h2: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            h3: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            horizontalRuleDecoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

        const SizedBox(height: 32),

        // Dismiss action button
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text("Done"),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildNutritionCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 14,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: AppTextStyles.bodyRegular.copyWith(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
