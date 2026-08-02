import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

enum MessageType { text, image, file, audio }

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final MessageType type;
  final String? mediaPath;
  final String? mediaName;
  final String? mediaDuration;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.type = MessageType.text,
    this.mediaPath,
    this.mediaName,
    this.mediaDuration,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'type': type.index,
      'mediaPath': mediaPath,
      'mediaName': mediaName,
      'mediaDuration': mediaDuration,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] ?? '',
      isUser: json['isUser'] ?? false,
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      type: MessageType.values[json['type'] ?? 0],
      mediaPath: json['mediaPath'],
      mediaName: json['mediaName'],
      mediaDuration: json['mediaDuration'],
    );
  }
}

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _QuickReplyItem {
  final String text;
  final IconData icon;
  const _QuickReplyItem(this.text, this.icon);
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Dio _dio = Dio();

  bool _isLoading = false;

  static const String _prefHistoryKey = 'n8n_chat_history';

  final List<_QuickReplyItem> _quickReplies = const [
    _QuickReplyItem("How to count calories", Icons.calculate_rounded),
    _QuickReplyItem(
      "How many liters of water I need to drink daily",
      Icons.local_drink_rounded,
    ),
    _QuickReplyItem(
      "Suggest sports or exercises to do at home",
      Icons.fitness_center_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSettingsAndHistory();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSettingsAndHistory() async {
    final prefs = await SharedPreferences.getInstance();

    // Load chat history
    final historyJson = prefs.getStringList(_prefHistoryKey);
    if (historyJson != null) {
      setState(() {
        _messages.clear();
        for (var item in historyJson) {
          try {
            _messages.add(ChatMessage.fromJson(jsonDecode(item)));
          } catch (e) {
            // Ignore malformed messages
          }
        }
      });
      _scrollToBottom();
    } else {
      // Add a welcoming message if the chat is completely fresh
      setState(() {
        _messages.add(
          ChatMessage(
            text:
                "Hello! I am your NutriMind AI Coach. 🍏\n\nI can help you build healthy nutrition habits, scan food items, plan recipes, and support your mental wellness. How can I help you today?",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> historyList = _messages
        .map((msg) => jsonEncode(msg.toJson()))
        .toList();
    await prefs.setStringList(_prefHistoryKey, historyList);
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefHistoryKey);

    setState(() {
      _messages.clear();
      _messages.add(
        ChatMessage(
          text:
              "Hello! I am your NutriMind AI Coach. 🍏\n\nI can help you build healthy nutrition habits, scan food items, plan recipes, and support your mental wellness. How can I help you today?",
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      type: MessageType.text,
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    _textController.clear();
    _scrollToBottom();
    await _saveHistory();

    // Convert messages to Gemini format
    final List<Map<String, dynamic>> contents = [];
    for (var msg in _messages) {
      contents.add({
        'role': msg.isUser ? 'user' : 'model',
        'parts': [
          {'text': msg.text},
        ],
      });
    }

    // Call Gemini API
    try {
      final response = await _dio.post(
        //note i have removed my api key for security reasons
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent?key=YOUR_API_KEY',
        data: {
          'contents': contents,
          'systemInstruction': {
            'parts': [
              {
                'text':
                    'You are NutriMind AI Coach.🍏 You help users build healthy nutrition habits, scan food items, plan recipes, and support mental wellness. Keep your responses extremely short, concise, highly useful, friendly, encouraging, and clear. Avoid long explanations; answer directly and briefly (usually in 2-3 sentences or short bullet points).',
              },
            ],
          },
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
          receiveTimeout: const Duration(seconds: 15),
          connectTimeout: const Duration(seconds: 15),
        ),
      );

      String botReply = '';
      if (response.data != null && response.data['candidates'] != null) {
        final candidates = response.data['candidates'] as List;
        if (candidates.isNotEmpty) {
          final firstCandidate = candidates.first;
          final content = firstCandidate['content'];
          if (content != null) {
            final parts = content['parts'] as List;
            if (parts.isNotEmpty) {
              botReply = parts.first['text'] ?? '';
            }
          }
        }
      }

      if (botReply.isEmpty) {
        botReply = "I received an empty response. Please try again.";
      }

      setState(() {
        _messages.add(
          ChatMessage(
            text: botReply,
            isUser: false,
            timestamp: DateTime.now(),
            type: MessageType.text,
          ),
        );
      });
    } on DioException catch (e) {
      String errorMessage =
          "Network error: Failed to connect to NutriMind AI Coach.";
      if (e.response != null) {
        errorMessage =
            "Server error (${e.response!.statusCode}): ${e.response!.statusMessage}";
      }

      setState(() {
        _messages.add(
          ChatMessage(
            text: errorMessage,
            isUser: false,
            timestamp: DateTime.now(),
            type: MessageType.text,
          ),
        );
      });
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: "An unexpected error occurred: $e",
            isUser: false,
            timestamp: DateTime.now(),
            type: MessageType.text,
          ),
        );
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
      await _saveHistory();
    }
  }

  // Settings dialog is no longer needed

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Theme.of(context).colorScheme.onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 22,
              backgroundImage: AssetImage('assets/images/chatbot.jpg'),
              backgroundColor: Colors.transparent,
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NutriMind AI Coach',
                  style: AppTextStyles.titleSecondary.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'AI Assistant • Online',
                      style: AppTextStyles.bodyRegular.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white12
                : AppColors.border.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Clear Chat History',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    'Clear Chat?',
                    style: AppTextStyles.titleSecondary.copyWith(fontSize: 18),
                  ),
                  content: Text(
                    'This will delete all message history and start a new session.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _clearHistory();
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Clear',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            icon: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          // Settings button removed
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF121212), Color(0xFF1E1E1E)],
                )
              : AppColors.backgroundGradient,
        ),
        child: Column(
          children: [
            // Chat message list
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _buildMessageBubble(message);
                },
              ),
            ),

            // Typing Indicator
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        border: Border.all(
                          color: isDark
                              ? Colors.white12
                              : AppColors.secondary.withValues(alpha: 0.08),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.01 : 0.02,
                            ),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'NutriMind AI is thinking',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const TypingIndicator(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Quick Replies horizontal scroll list
            if (!_isLoading) _buildQuickRepliesSection(),

            // Input field
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final bool isUser = message.isUser;
    final String timeStr = TimeOfDay.fromDateTime(
      message.timestamp,
    ).format(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isUser) {
      return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(50, 4, 16, 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(18),
                            topRight: Radius.circular(18),
                            bottomLeft: Radius.circular(18),
                            bottomRight: Radius.circular(4),
                          ),
                        ),
                        child: MarkdownBody(
                          data: message.text,
                          styleSheet:
                              MarkdownStyleSheet.fromTheme(
                                Theme.of(context),
                              ).copyWith(
                                p: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                strong: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                code: const TextStyle(
                                  backgroundColor: Colors.black26,
                                  color: Colors.white,
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                ),
                                h1: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                h2: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                h3: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                listBullet: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.white,
                                ),
                                blockquote: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.white70,
                                ),
                                codeblockDecoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 28, top: 2),
                  child: Text(
                    timeStr,
                    style: AppTextStyles.bodyRegular.copyWith(
                      color: AppColors.textSecondary.withValues(alpha: 0.6),
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          )
          .animate()
          .fadeIn(duration: 200.ms)
          .slideY(begin: 0.05, end: 0, curve: Curves.easeOutQuad);
    } else {
      return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundImage: AssetImage('assets/images/chatbot.jpg'),
                      backgroundColor: Colors.transparent,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(0, 4, 50, 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF252528)
                              : AppColors.secondaryExtraLight,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(18),
                            topRight: Radius.circular(18),
                            bottomLeft: Radius.circular(4),
                            bottomRight: Radius.circular(18),
                          ),
                        ),
                        child: MarkdownBody(
                          data: message.text,
                          styleSheet:
                              MarkdownStyleSheet.fromTheme(
                                Theme.of(context),
                              ).copyWith(
                                p: AppTextStyles.bodyMedium.copyWith(
                                  color: isDark
                                      ? Colors.white70
                                      : AppColors.textPrimary,
                                  fontSize: 14,
                                ),
                                strong: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                                code: TextStyle(
                                  backgroundColor: isDark
                                      ? Colors.white10
                                      : Colors.black12,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                ),
                                h1: AppTextStyles.bodyMedium.copyWith(
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                h2: AppTextStyles.bodyMedium.copyWith(
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                h3: AppTextStyles.bodyMedium.copyWith(
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                listBullet: AppTextStyles.bodyMedium.copyWith(
                                  color: isDark
                                      ? Colors.white70
                                      : AppColors.textPrimary,
                                ),
                                blockquote: AppTextStyles.bodyMedium.copyWith(
                                  color: isDark
                                      ? Colors.white54
                                      : AppColors.textSecondary,
                                ),
                                codeblockDecoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.black.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 38, top: 2),
                  child: Text(
                    timeStr,
                    style: AppTextStyles.bodyRegular.copyWith(
                      color: AppColors.textSecondary.withValues(alpha: 0.6),
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          )
          .animate()
          .fadeIn(duration: 200.ms)
          .slideY(begin: 0.05, end: 0, curve: Curves.easeOutQuad);
    }
  }

  Widget _buildQuickRepliesSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _quickReplies.length,
        itemBuilder: (context, index) {
          final reply = _quickReplies[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              elevation: 0,
              pressElevation: 2,
              shadowColor: Colors.black.withValues(alpha: isDark ? 0.01 : 0.04),
              side: BorderSide(
                color: isDark
                    ? Colors.white12
                    : AppColors.secondary.withValues(alpha: 0.15),
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              avatar: Icon(reply.icon, color: AppColors.secondary, size: 14),
              label: Text(
                reply.text,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () => _handleSendMessage(reply.text),
            ),
          );
        },
      ),
    ).animate().fadeIn(duration: 350.ms).slideX(begin: 0.05, end: 0);
  }

  Widget _buildInputBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isDark
                ? Colors.white12
                : AppColors.border.withValues(alpha: 0.8),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.01 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _textController,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                maxLines: 5,
                minLines: 1,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14.5,
                ),
                decoration: InputDecoration(
                  hintText: 'Ask about nutrition, meals, mind...',
                  hintStyle: AppTextStyles.hintStyle.copyWith(
                    color: isDark
                        ? Colors.white30
                        : AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (text) {
                  setState(() {});
                },
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () {
                final text = _textController.text.trim();
                if (text.isNotEmpty) {
                  _handleSendMessage(text);
                }
              },
              child: Container(
                margin: const EdgeInsets.all(5),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_upward_rounded,
                  color: AppColors.secondary,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 5),
          ],
        ),
      ),
    );
  }
}

// Typing Indicator Dot Animation
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final double offset = (index * 0.2);
            double value =
                (math.sin(
                      (_controller.value * 2 * math.pi) -
                          (offset * 2 * math.pi),
                    ) +
                    1) /
                2;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(
                  alpha: 0.3 + (0.7 * value),
                ),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}
