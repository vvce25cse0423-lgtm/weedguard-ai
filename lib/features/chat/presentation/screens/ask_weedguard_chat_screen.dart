import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../../core/l10n/app_localizations.dart';
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

  final FlutterTts _tts = FlutterTts();
  String? _currentlySpeakingId;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lang = ref.read(localeProvider).languageCode;

      String welcomeText = 'Hello farmer! 👋 I am your WeedGuard AI Agronomy Assistant. Ask me anything about weeds, crops, herbicide dosages, organic recipes, or spray windows.';
      if (lang == 'kn') {
        welcomeText = 'ನಮಸ್ಕಾರ ರೈತ ಬಾಂಧವರೇ! 👋 ನಾನು ನಿಮ್ಮ ವೀಡ್‌ಗಾರ್ಡ್ AI ಕೃಷಿ ಸಹಾಯಕ. ಕಳೆಗಳು, ಬೆಳೆಗಳು, ಸಸ್ಯನಾಶಕ ಪ್ರಮಾಣ, ಸಾವಯವ ನಿಯಂತ್ರಣ ಅಥವಾ ಸಿಂಪರಣಾ ಸಮಯದ ಬಗ್ಗೆ ಯಾವುದೇ ಪ್ರಶ್ನೆಗಳನ್ನು ಕೇಳಿ.';
      } else if (lang == 'hi') {
        welcomeText = 'नमस्ते किसान भाई! 👋 मैं आपका वीडगार्ड AI कृषि सहायक हूँ। खरपतवार, फसल, शाकनाशी की मात्रा, जैविक समाधान या स्प्रे के समय से संबंधित कोई भी प्रश्न पूछें।';
      }

      setState(() {
        _messages.add(
          ChatMessage(
            id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
            text: welcomeText,
            sender: MessageSender.ai,
          ),
        );
      });

      if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
        _handleSubmitted('Can you explain more about this farming tip: "${widget.initialQuery}"?');
      }
    });
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
    // Strip markdown formatting characters for clean speech
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
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              id: 'err_${DateTime.now().millisecondsSinceEpoch}',
              text: 'Unable to connect to AI assistant. Please check your internet connection or try again.',
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

  void _clearChat() {
    HapticFeedback.mediumImpact();
    _tts.stop();
    setState(() {
      _currentlySpeakingId = null;
      _messages.clear();
      _messages.add(
        ChatMessage(
          id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
          text: 'Conversation cleared. How can I help your farm today?',
          sender: MessageSender.ai,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            // Circular robot badge matching the dashboard image!
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2D6A4F),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Icon(Icons.auto_awesome, color: Colors.white, size: 9),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'WeedGuard AI',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF52B788),
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'Agronomy Assistant',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFD8F3DC),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Clear Chat',
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
            onPressed: _messages.length > 1 ? _clearChat : null,
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
                ? const Color(0xFF2D6A4F).withOpacity(0.25)
                : const Color(0xFFD8F3DC).withOpacity(0.55),
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
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1F000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  message.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // AI Assistant response bubble
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, right: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Small AI Avatar
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(top: 2, right: 8),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF2D6A4F),
            ),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 18),
          ),
          Flexible(
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
                  color: isDark ? Colors.white12 : const Color(0xFFE0E0E0),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
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
                      color: isDark ? Colors.white : const Color(0xFF212529),
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Voice readout TTS button
                      GestureDetector(
                        onTap: () => _speakText(message.id, message.text),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSpeaking
                                ? const Color(0xFF2D6A4F)
                                : (isDark ? Colors.white10 : const Color(0xFFF1F5F2)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSpeaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                                size: 14,
                                color: isSpeaking
                                    ? Colors.white
                                    : (isDark ? Colors.white70 : const Color(0xFF2D6A4F)),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isSpeaking ? 'Stop' : 'Listen',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSpeaking
                                      ? Colors.white
                                      : (isDark ? Colors.white70 : const Color(0xFF2D6A4F)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Copy text button
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: message.text));
                          HapticFeedback.lightImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Copied response to clipboard'),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : const Color(0xFFF1F5F2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.copy_rounded,
                                  size: 13,
                                  color: isDark ? Colors.white70 : Colors.black54),
                              const SizedBox(width: 4),
                              Text(
                                'Copy',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
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
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
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
                  hintText: 'Ask about weeds, crops, herbicides...',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.black45),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _handleSubmitted(_textController.text),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1B4332).withOpacity(0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
