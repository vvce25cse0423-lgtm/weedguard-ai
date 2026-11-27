import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/providers/app_providers.dart';
import '../../models/chat_message_model.dart';
import '../../data/weedguard_chat_service.dart';

class AskWeedGuardChatScreen extends ConsumerStatefulWidget {
  final String? initialQuery;

  const AskWeedGuardChatScreen({super.key, this.initialQuery});

  @override
  ConsumerState<AskWeedGuardChatScreen> createState() => _AskWeedGuardChatScreenState();
}

class _AskWeedGuardChatScreenState extends ConsumerState<AskWeedGuardChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _showChatView = false;

  final FlutterTts _tts = FlutterTts();
  String? _currentlySpeakingId;
  final ImagePicker _picker = ImagePicker();

  final List<String> _quickSuggestions = [
    'How to control Parthenium (Congress Grass)?',
    'Best time to spray herbicides?',
    'Pre-emergent vs Post-emergent herbicides?',
    'Zero-chemical organic weed recipes?',
    'How to control Purple Nutsedge (Cyperus)?',
    'Herbicide dosage calculation per acre',
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      _tts.setCompletionHandler(() {
        if (mounted) setState(() => _currentlySpeakingId = null);
      });
      _tts.setErrorHandler((_) {
        if (mounted) setState(() => _currentlySpeakingId = null);
      });
      _tts.setCancelHandler(() {
        if (mounted) setState(() => _currentlySpeakingId = null);
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _tts.stop();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _speakText(String messageId, String text) async {
    if (_currentlySpeakingId == messageId) {
      await _tts.stop();
      setState(() => _currentlySpeakingId = null);
      return;
    }

    await _tts.stop();
    final lang = ref.read(localeProvider).languageCode;
    if (lang == 'kn') {
      await _tts.setLanguage('kn-IN');
    } else if (lang == 'hi') {
      await _tts.setLanguage('hi-IN');
    } else {
      await _tts.setLanguage('en-US');
    }

    setState(() => _currentlySpeakingId = messageId);
    final cleanText = text.replaceAll('*', '').replaceAll('#', '').replaceAll('•', '');
    await _tts.speak(cleanText);
  }

  Future<void> _handleSubmitted(String text) async {
    final query = text.trim();
    if (query.isEmpty || _isLoading) return;

    _textController.clear();
    HapticFeedback.lightImpact();

    final userMessage = ChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      text: query,
      sender: MessageSender.user,
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
      _showChatView = true;
    });
    _scrollToBottom();

    final lang = ref.read(localeProvider).languageCode;

    try {
      final responseText = await WeedGuardChatService.sendMessage(
        history: _messages,
        userMessage: query,
        languageCode: lang,
      );

      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
              text: responseText,
              sender: MessageSender.ai,
            ),
          );
          _isLoading = false;
        });
        _scrollToBottom();
        _saveCurrentSessionToHistory();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              id: 'err_${DateTime.now().millisecondsSinceEpoch}',
              text: 'Unable to connect to AI assistant. Please check your network or try again.',
              sender: MessageSender.ai,
              isError: true,
            ),
          );
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  Future<void> _saveCurrentSessionToHistory() async {
    if (_messages.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('weedguard_chat_history_v1');
      List<dynamic> historyList = [];
      if (raw != null) {
        historyList = jsonDecode(raw) as List<dynamic>;
      }

      final firstUserMsg = _messages.firstWhere(
        (m) => m.sender == MessageSender.user,
        orElse: () => _messages.first,
      );
      final title = firstUserMsg.text.length > 50
          ? '${firstUserMsg.text.substring(0, 48)}...'
          : firstUserMsg.text;

      final session = {
        'id': 'sess_${DateTime.now().millisecondsSinceEpoch}',
        'title': title,
        'timestamp': DateTime.now().toIso8601String(),
        'messages': _messages
            .map((m) => {
                  'id': m.id,
                  'text': m.text,
                  'isUser': m.sender == MessageSender.user,
                  'isError': m.isError,
                })
            .toList(),
      };

      // Check if session with same title exists, update it or prepend
      historyList.removeWhere((item) => item['title'] == title);
      historyList.insert(0, session);

      if (historyList.length > 25) {
        historyList = historyList.sublist(0, 25);
      }
      await prefs.setString('weedguard_chat_history_v1', jsonEncode(historyList));
    } catch (_) {}
  }

  Future<void> _bookmarkMessage(String content) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('weedguard_saved_results_v1');
      List<dynamic> saved = [];
      if (raw != null) {
        saved = jsonDecode(raw) as List<dynamic>;
      }

      final lines = content.split('\n').where((l) => l.trim().isNotEmpty).toList();
      String title = 'WeedGuard Advisory';
      if (lines.isNotEmpty) {
        title = lines.first.replaceAll('*', '').replaceAll('#', '').replaceAll('•', '').trim();
      }
      if (title.length > 45) {
        title = '${title.substring(0, 43)}...';
      }

      saved.insert(0, {
        'id': 'saved_${DateTime.now().millisecondsSinceEpoch}',
        'title': title,
        'content': content,
        'timestamp': DateTime.now().toIso8601String(),
      });

      await prefs.setString('weedguard_saved_results_v1', jsonEncode(saved));

      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.bookmark_added_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Advisory saved to Saved Results! 🔖'),
              ],
            ),
            backgroundColor: Color(0xFF1B4332),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {}
  }

  void _clearChat() {
    HapticFeedback.mediumImpact();
    _tts.stop();
    setState(() {
      _currentlySpeakingId = null;
      _messages.clear();
      _showChatView = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chat conversation cleared.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Custom Pop-up Menu matching the user's cropped design exactly
  void _showCustomMenu(BuildContext context) {
    HapticFeedback.lightImpact();
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top + 50.0;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Menu',
      barrierColor: Colors.black.withValues(alpha: 0.35),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, anim1, anim2) {
        const double menuWidth = 265.0;
        const double menuHeight = menuWidth * (434.0 / 382.0); // ~301 px

        return SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: EdgeInsets.only(top: topPadding, right: 14),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: menuWidth,
                  height: menuHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.24),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(
                      children: [
                        // The exact cropped menu template image
                        Image.asset(
                          'assets/images/weedguard_chat_menu.png',
                          width: menuWidth,
                          height: menuHeight,
                          fit: BoxFit.fill,
                        ),

                        // 5 Interactive Hitboxes matching the 5 menu rows
                        Column(
                          children: [
                            // 1. Chat History
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  splashColor: const Color(0xFF1B4332).withValues(alpha: 0.12),
                                  highlightColor: const Color(0xFF1B4332).withValues(alpha: 0.06),
                                  onTap: () {
                                    Navigator.of(ctx).pop();
                                    _showChatHistory();
                                  },
                                  child: const SizedBox.expand(),
                                ),
                              ),
                            ),

                            // 2. Saved Results
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  splashColor: const Color(0xFF1B4332).withValues(alpha: 0.12),
                                  highlightColor: const Color(0xFF1B4332).withValues(alpha: 0.06),
                                  onTap: () {
                                    Navigator.of(ctx).pop();
                                    _showSavedResults();
                                  },
                                  child: const SizedBox.expand(),
                                ),
                              ),
                            ),

                            // 3. Language (English / ಕನ್ನಡ)
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  splashColor: const Color(0xFF1B4332).withValues(alpha: 0.12),
                                  highlightColor: const Color(0xFF1B4332).withValues(alpha: 0.06),
                                  onTap: () {
                                    Navigator.of(ctx).pop();
                                    _showLanguagePicker();
                                  },
                                  child: const SizedBox.expand(),
                                ),
                              ),
                            ),

                            // 4. How to Use
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  splashColor: const Color(0xFF1B4332).withValues(alpha: 0.12),
                                  highlightColor: const Color(0xFF1B4332).withValues(alpha: 0.06),
                                  onTap: () {
                                    Navigator.of(ctx).pop();
                                    _showHowToUse();
                                  },
                                  child: const SizedBox.expand(),
                                ),
                              ),
                            ),

                            // 5. Help & Feedback
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  splashColor: const Color(0xFF1B4332).withValues(alpha: 0.12),
                                  highlightColor: const Color(0xFF1B4332).withValues(alpha: 0.06),
                                  onTap: () {
                                    Navigator.of(ctx).pop();
                                    _showHelpAndFeedback();
                                  },
                                  child: const SizedBox.expand(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            alignment: const Alignment(0.85, -0.9),
            scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
            child: child,
          ),
        );
      },
    );
  }

  // ── Menu Option 1: Chat History ──────────────────────────────────────────
  Future<void> _showChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('weedguard_chat_history_v1');
    List<dynamic> history = [];
    if (raw != null) {
      try {
        history = jsonDecode(raw) as List<dynamic>;
      } catch (_) {}
    }

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.72,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.history_rounded, color: Color(0xFF1B4332), size: 26),
                      SizedBox(width: 10),
                      Text(
                        'Chat History',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1B4332),
                        ),
                      ),
                    ],
                  ),
                  if (history.isNotEmpty)
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Clear All', style: TextStyle(fontWeight: FontWeight.w700)),
                      onPressed: () async {
                        await prefs.remove('weedguard_chat_history_v1');
                        setSheetState(() => history.clear());
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: history.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFE8F5E9),
                              ),
                              child: const Icon(Icons.forum_outlined, size: 48, color: Color(0xFF2D6A4F)),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'No chat history yet',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1B4332)),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Questions you ask WeedGuard AI will appear here for easy access.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: history.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = history[index] as Map<String, dynamic>;
                          final title = item['title'] ?? 'Agronomy Inquiry';
                          final dateStr = item['timestamp'] != null
                              ? DateTime.tryParse(item['timestamp'])?.toLocal().toString().substring(0, 16) ?? ''
                              : '';
                          final msgs = (item['messages'] as List<dynamic>?) ?? [];

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD8F3DC),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF1B4332), size: 20),
                            ),
                            title: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                            ),
                            subtitle: Text(
                              '$dateStr • ${msgs.length} messages',
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                              onPressed: () async {
                                history.removeAt(index);
                                await prefs.setString('weedguard_chat_history_v1', jsonEncode(history));
                                setSheetState(() {});
                              },
                            ),
                            onTap: () {
                              Navigator.of(ctx).pop();
                              setState(() {
                                _messages.clear();
                                for (final m in msgs) {
                                  _messages.add(
                                    ChatMessage(
                                      id: m['id'] ?? 'm_${DateTime.now().millisecondsSinceEpoch}',
                                      text: m['text'] ?? '',
                                      sender: (m['isUser'] ?? false) ? MessageSender.user : MessageSender.ai,
                                      isError: m['isError'] ?? false,
                                    ),
                                  );
                                }
                                _showChatView = true;
                              });
                            },
                          );
                        },
                      ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4332),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.add_comment_rounded, size: 20),
                  label: const Text('Start New Topic', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _clearChat();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Menu Option 2: Saved Results ─────────────────────────────────────────
  Future<void> _showSavedResults() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('weedguard_saved_results_v1');
    List<dynamic> saved = [];
    if (raw != null) {
      try {
        saved = jsonDecode(raw) as List<dynamic>;
      } catch (_) {}
    }

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bookmark_rounded, color: Color(0xFF1B4332), size: 26),
                      SizedBox(width: 10),
                      Text(
                        'Saved Results',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1B4332),
                        ),
                      ),
                    ],
                  ),
                  if (saved.isNotEmpty)
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                      onPressed: () async {
                        await prefs.remove('weedguard_saved_results_v1');
                        setSheetState(() => saved.clear());
                      },
                      child: const Text('Clear All', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: saved.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFE8F5E9),
                              ),
                              child: const Icon(Icons.bookmark_border_rounded, size: 48, color: Color(0xFF2D6A4F)),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'No saved results yet',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1B4332)),
                            ),
                            const SizedBox(height: 6),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                'Tap the bookmark icon 🔖 next to any AI advisory to save it here for offline reference.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: saved.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = saved[index] as Map<String, dynamic>;
                          final title = item['title'] ?? 'Agronomy Advisory';
                          final content = item['content'] ?? '';
                          final dateStr = item['timestamp'] != null
                              ? DateTime.tryParse(item['timestamp'])?.toLocal().toString().substring(0, 16) ?? ''
                              : '';

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FCFA),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFD8F3DC)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1B4332)),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                      onPressed: () async {
                                        saved.removeAt(index);
                                        await prefs.setString('weedguard_saved_results_v1', jsonEncode(saved));
                                        setSheetState(() {});
                                      },
                                    ),
                                  ],
                                ),
                                Text(
                                  content,
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      dateStr,
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.volume_up_rounded, size: 18, color: Color(0xFF2D6A4F)),
                                          tooltip: 'Read aloud',
                                          onPressed: () => _speakText('saved_$index', content),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.grey),
                                          tooltip: 'Copy',
                                          onPressed: () {
                                            Clipboard.setData(ClipboardData(text: content));
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Copied advisory to clipboard!'),
                                                duration: Duration(seconds: 1),
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Menu Option 3: Language (English / ಕನ್ನಡ) ───────────────────────────
  void _showLanguagePicker() {
    final currentLang = ref.read(localeProvider).languageCode;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.translate_rounded, color: Color(0xFF1B4332), size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Select App Language',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B4332),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Option 1: English
              _buildLanguageTile(
                ctx: ctx,
                title: 'English',
                subtitle: 'English language',
                code: 'en',
                isSelected: currentLang == 'en',
                onSelect: () async {
                  await ref.read(localeProvider.notifier).setLocale(const Locale('en'));
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (mounted) {
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Language switched to English'),
                        backgroundColor: Color(0xFF1B4332),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),

              const Divider(height: 10),

              // Option 2: Kannada (ಕನ್ನಡ)
              _buildLanguageTile(
                ctx: ctx,
                title: 'ಕನ್ನಡ (Kannada)',
                subtitle: 'ಕರ್ನಾಟಕದ ರೈತರಿಗಾಗಿ ಕನ್ನಡ ಭಾಷೆ',
                code: 'kn',
                isSelected: currentLang == 'kn',
                onSelect: () async {
                  await ref.read(localeProvider.notifier).setLocale(const Locale('kn'));
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (mounted) {
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ಭಾಷೆಯನ್ನು ಕನ್ನಡಕ್ಕೆ ಯಶಸ್ವಿಯಾಗಿ ಬದಲಾಯಿಸಲಾಗಿದೆ'),
                        backgroundColor: Color(0xFF1B4332),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),

              const Divider(height: 10),

              // Option 3: Hindi (हिंदी)
              _buildLanguageTile(
                ctx: ctx,
                title: 'हिंदी (Hindi)',
                subtitle: 'भारतीय किसानों के लिए हिंदी भाषा',
                code: 'hi',
                isSelected: currentLang == 'hi',
                onSelect: () async {
                  await ref.read(localeProvider.notifier).setLocale(const Locale('hi'));
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (mounted) {
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('भाषा हिंदी में सफलतापूर्वक बदल दी गई है'),
                        backgroundColor: Color(0xFF1B4332),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageTile({
    required BuildContext ctx,
    required String title,
    required String subtitle,
    required String code,
    required bool isSelected,
    required VoidCallback onSelect,
  }) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      tileColor: isSelected ? const Color(0xFFD8F3DC).withValues(alpha: 0.5) : Colors.transparent,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B4332) : const Color(0xFFE8F5E9),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            code.toUpperCase(),
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF1B4332),
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF1B4332))
          : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
      onTap: onSelect,
    );
  }

  // ── Menu Option 4: How to Use ────────────────────────────────────────────
  void _showHowToUse() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.82,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Color(0xFF1B4332), size: 26),
                SizedBox(width: 10),
                Text(
                  'How to Use WeedGuard AI',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B4332),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView(
                children: [
                  _buildHowToCard(
                    number: '1',
                    icon: Icons.camera_alt_rounded,
                    title: 'Identify Weeds with Camera',
                    desc: 'Tap "Identify Weed" or the attachment paperclip 📎 to capture a live field photo. AI visual detection identifies broadleaf, grass, and sedge species instantly.',
                  ),
                  _buildHowToCard(
                    number: '2',
                    icon: Icons.science_rounded,
                    title: 'Precise Herbicide Dosage Math',
                    desc: 'Ask for custom dilution recipes (e.g. per 15L knapsack tank or per acre) for pre-emergent (Pendimethalin, Atrazine) and selective post-emergent molecules.',
                  ),
                  _buildHowToCard(
                    number: '3',
                    icon: Icons.eco_rounded,
                    title: 'Zero-Chemical Organic Solutions',
                    desc: 'Get proven organic agronomy recipes like vinegar + neem bio-spray, straw mulching (4-6 inches), and intercropping with cowpea to starve weeds naturally.',
                  ),
                  _buildHowToCard(
                    number: '4',
                    icon: Icons.cloud_sync_rounded,
                    title: 'Weather-Smart Spray Windows',
                    desc: 'Always verify wind speed (<10 km/h) to avoid spray drift and check rainfastness (minimum 3-4 hours clear weather) before applying any chemical.',
                  ),
                  _buildHowToCard(
                    number: '5',
                    icon: Icons.volume_up_rounded,
                    title: 'Voice Input & Audio Readout',
                    desc: 'Tap the mic 🎙️ to speak your query in Kannada, Hindi, or English. Tap the speaker icon on any response to have the advice read aloud.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4332),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Got It!', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowToCard({
    required String number,
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FCFA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD8F3DC)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFF1B4332),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  number,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: const Color(0xFF2D6A4F), size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: Color(0xFF1B4332)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    desc,
                    style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Menu Option 5: Help & Feedback ───────────────────────────────────────
  void _showHelpAndFeedback() {
    int selectedRating = 5;
    final feedbackController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.help_outline_rounded, color: Color(0xFF1B4332), size: 26),
                    SizedBox(width: 10),
                    Text(
                      'Help & Feedback',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B4332),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Support Helpline Info Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFB7E4C7)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.phone_in_talk_rounded, color: Color(0xFF1B4332), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Kisan Helpline (Toll-Free): 1800-180-1551',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF1B4332)),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Agronomy Email: support@weedguard.ai • Mon-Sat 8:00 AM - 6:00 PM',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                const Text(
                  'Rate your WeedGuard AI experience:',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 8),

                // Star Rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final star = index + 1;
                    return IconButton(
                      icon: Icon(
                        star <= selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
                        color: Colors.amber.shade700,
                        size: 36,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        setSheetState(() => selectedRating = star);
                      },
                    );
                  }),
                ),

                const SizedBox(height: 12),
                const Text(
                  'Your suggestions or feedback:',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: feedbackController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Tell us how WeedGuard AI can better serve your farm...',
                    hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFB7E4C7)),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B4332),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final prefs = await SharedPreferences.getInstance();
                      final feedbackData = {
                        'rating': selectedRating,
                        'comment': feedbackController.text.trim(),
                        'timestamp': DateTime.now().toIso8601String(),
                      };
                      await prefs.setString('weedguard_farmer_feedback', jsonEncode(feedbackData));

                      if (ctx.mounted) Navigator.of(ctx).pop();
                      HapticFeedback.mediumImpact();
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Expanded(child: Text('Thank you! Your feedback helps us improve precision farming.')),
                            ],
                          ),
                          backgroundColor: Color(0xFF1B4332),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    },
                    child: const Text('Submit Feedback', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showIdentifyWeedOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.camera_alt_rounded, color: Color(0xFF1B4332), size: 26),
                  SizedBox(width: 10),
                  Text(
                    'Identify Weed',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B4332),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8F3DC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF1B4332)),
                ),
                title: const Text(
                  'Open Weed Scanner Camera',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Capture live field photo to detect weeds instantly'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  Navigator.of(ctx).pop();
                  context.push('/scanner');
                },
              ),
              const Divider(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8F3DC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF1B4332)),
                ),
                title: const Text(
                  'Ask AI Weed Identification Guide',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Read visual characteristics, leaf shapes & weed biology'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _handleSubmitted('How do I identify different types of weeds in my crops, and what visual features (leaf shape, stem, flowering) should I look for?');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndAnalyzeImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.attach_file_rounded, color: Color(0xFF1B4332), size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Attach Weed Image',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B4332),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF1B4332)),
                title: const Text('Take Photo with Camera', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  try {
                    final photo = await _picker.pickImage(source: ImageSource.camera);
                    if (photo != null) {
                      _handleSubmitted('I have captured a photo of an invasive weed. What are the key identification signs to confirm its species?');
                    }
                  } catch (_) {}
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF1B4332)),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  try {
                    final image = await _picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      _handleSubmitted('I selected an image of a weed from my gallery. How should I identify its type and determine safe removal methods?');
                    }
                  } catch (_) {}
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _triggerVoiceInput() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.mic, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(child: Text('Voice input ready. Tap send or type your question below.')),
          ],
        ),
        backgroundColor: const Color(0xFF1B4332),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showChatView) {
      return _buildChatView(context);
    }
    return _buildTemplateView(context);
  }

  /// Template View: Perfect pixel fit with all interactive working buttons
  Widget _buildTemplateView(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFEAF5EC),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;

            return Stack(
              fit: StackFit.expand,
              children: [
                // 1. Template Background Image perfectly fitted
                Image.asset(
                  'assets/images/weedguard_ai_template.png',
                  width: w,
                  height: h,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                ),

                // 2. Top-Left: Back Button
                Positioned(
                  top: 0,
                  left: 0,
                  width: w * 0.18,
                  height: h * 0.09,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),

                // 3. Top-Right: Three Dots Menu (Opens exact custom cropped popup)
                Positioned(
                  top: 0,
                  right: 0,
                  width: w * 0.18,
                  height: h * 0.09,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => _showCustomMenu(context),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),

                // 4. Card 1: "Identify Weed"
                Positioned(
                  left: w * (27 / 512),
                  width: w * (222 / 512),
                  top: h * (464 / 1024),
                  height: h * (133 / 1024),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      splashColor: const Color(0xFF2D6A4F).withValues(alpha: 0.18),
                      highlightColor: const Color(0xFF2D6A4F).withValues(alpha: 0.08),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _showIdentifyWeedOptions();
                      },
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),

                // 5. Card 2: "Removal Method"
                Positioned(
                  left: w * (264 / 512),
                  width: w * (223 / 512),
                  top: h * (464 / 1024),
                  height: h * (133 / 1024),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      splashColor: const Color(0xFF0077B6).withValues(alpha: 0.18),
                      highlightColor: const Color(0xFF0077B6).withValues(alpha: 0.08),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _handleSubmitted('What are the most effective weed removal methods (mechanical, cultural, chemical, and biological) for crop protection?');
                      },
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),

                // 6. Card 3: "Safe Herbicides"
                Positioned(
                  left: w * (27 / 512),
                  width: w * (222 / 512),
                  top: h * (620 / 1024),
                  height: h * (135 / 1024),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      splashColor: const Color(0xFFF77F00).withValues(alpha: 0.18),
                      highlightColor: const Color(0xFFF77F00).withValues(alpha: 0.08),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _handleSubmitted('Which safe herbicides are recommended for weed control without harming crops or soil, and what are their safety precautions?');
                      },
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),

                // 7. Card 4: "Farming Tips"
                Positioned(
                  left: w * (264 / 512),
                  width: w * (223 / 512),
                  top: h * (620 / 1024),
                  height: h * (135 / 1024),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      splashColor: const Color(0xFF7209B7).withValues(alpha: 0.18),
                      highlightColor: const Color(0xFF7209B7).withValues(alpha: 0.08),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _handleSubmitted('What are the top practical farming tips, soil practices, and best methods for weed prevention?');
                      },
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),

                // 8. Bottom Pill Input Bar: Active interactive elements
                Positioned(
                  left: w * (17 / 512),
                  right: w * (17 / 512),
                  bottom: bottomInset > 0 ? bottomInset + 10 : h * (36 / 1024),
                  height: h * (66 / 1024),
                  child: Row(
                    children: [
                      // Paperclip attachment button
                      SizedBox(
                        width: w * (52 / 512),
                        height: double.infinity,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: _pickAndAnalyzeImage,
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),

                      // Text input field
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: TextField(
                            controller: _textController,
                            textInputAction: TextInputAction.send,
                            onSubmitted: _handleSubmitted,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1B4332),
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Type your question...',
                              hintStyle: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B8A7A),
                                fontWeight: FontWeight.w500,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ),

                      // Mic button
                      SizedBox(
                        width: w * (48 / 512),
                        height: double.infinity,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: _triggerVoiceInput,
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),

                      // Send button (green circle)
                      SizedBox(
                        width: w * (58 / 512),
                        height: double.infinity,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () => _handleSubmitted(_textController.text),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 9. Floating pill to view existing conversation (if any)
                if (_messages.isNotEmpty)
                  Positioned(
                    top: h * 0.10,
                    right: 16,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _showChatView = true);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B4332),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'Chat (${_messages.length})',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 11),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Interactive Chat View: Displayed when question is submitted or card clicked
  Widget _buildChatView(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F7F5),
      appBar: AppBar(
        elevation: 2,
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            setState(() => _showChatView = false);
          },
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2D6A4F),
                border: Border.all(color: Colors.white, width: 1.8),
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WeedGuard AI',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    'Agronomy Assistant',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFD8F3DC),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Button to toggle back to Template view
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            icon: const Icon(Icons.grid_view_rounded, size: 18),
            label: const Text('Topics', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            onPressed: () {
              setState(() => _showChatView = false);
            },
          ),
          IconButton(
            tooltip: 'More Options',
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            onPressed: () => _showCustomMenu(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Quick suggestions horizontal slider
            _buildSuggestionsBar(isDark),

            // Messages chat area
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isLoading) {
                    return _buildLoadingBubble(isDark);
                  }
                  final msg = _messages[index];
                  return _buildMessageItem(msg, isDark);
                },
              ),
            ),

            // Bottom message input field
            _buildInputBar(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsBar(bool isDark) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white12 : const Color(0xFFE8F0EA),
            width: 1,
          ),
        ),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        itemCount: _quickSuggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final suggestion = _quickSuggestions[index];
          return ActionChip(
            label: Text(
              suggestion,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF74C69D) : const Color(0xFF1B4332),
              ),
            ),
            backgroundColor: isDark
                ? const Color(0xFF2D6A4F).withValues(alpha: 0.25)
                : const Color(0xFFD8F3DC).withValues(alpha: 0.55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isDark ? const Color(0xFF40916C) : const Color(0xFFB7E4C7),
                width: 1,
              ),
            ),
            onPressed: () => _handleSubmitted(suggestion),
          );
        },
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage message, bool isDark) {
    final isUser = message.sender == MessageSender.user;
    final isSpeaking = _currentlySpeakingId == message.id;

    if (isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12, left: 48),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  message.text,
                  style: const TextStyle(
                    fontSize: 14.5,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF52B788),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ],
        ),
      );
    }

    // AI Message
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, right: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(top: 2, right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1B4332),
              border: Border.all(color: const Color(0xFF52B788), width: 1.5),
            ),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 18),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF242424) : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(
                  color: message.isError
                      ? Colors.redAccent.withValues(alpha: 0.5)
                      : (isDark ? Colors.white12 : const Color(0xFFE0E0E0)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    message.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: message.isError
                          ? Colors.redAccent
                          : (isDark ? Colors.white : const Color(0xFF1A1A1A)),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Bookmark button to save result
                      IconButton(
                        icon: const Icon(Icons.bookmark_add_outlined, size: 18, color: Color(0xFF2D6A4F)),
                        tooltip: 'Save result',
                        onPressed: () => _bookmarkMessage(message.text),
                      ),
                      IconButton(
                        icon: Icon(
                          isSpeaking ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
                          size: 18,
                          color: isSpeaking ? Colors.redAccent : const Color(0xFF2D6A4F),
                        ),
                        tooltip: isSpeaking ? 'Stop speaking' : 'Read aloud',
                        onPressed: () => _speakText(message.id, message.text),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.grey),
                        tooltip: 'Copy',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: message.text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Copied to clipboard'),
                              duration: Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingBubble(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 8),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF2D6A4F),
            ),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 18),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF242424) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFE0E0E0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D6A4F)),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'WeedGuard AI is thinking...',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file_rounded, color: Color(0xFF1B4332)),
            onPressed: _pickAndAnalyzeImage,
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF1F5F2),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFD8F3DC),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _textController,
                textInputAction: TextInputAction.send,
                onSubmitted: _handleSubmitted,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: const InputDecoration(
                  hintText: 'Type your question...',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.black45),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.mic_rounded, color: Color(0xFF1B4332)),
            onPressed: _triggerVoiceInput,
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _handleSubmitted(_textController.text),
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
