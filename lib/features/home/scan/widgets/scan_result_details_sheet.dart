import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:camera/camera.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class ScanResultDetailsSheet extends StatefulWidget {
  final XFile photo;
  final Dio dio;

  const ScanResultDetailsSheet({super.key, required this.photo, required this.dio});

  @override
  State<ScanResultDetailsSheet> createState() =>
      _ScanResultDetailsSheetState();
}

class _ScanResultDetailsSheetState extends State<ScanResultDetailsSheet> {
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

      const String apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: 'YOUR_API_KEY');
      final response = await widget.dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent?key=$apiKey',
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
