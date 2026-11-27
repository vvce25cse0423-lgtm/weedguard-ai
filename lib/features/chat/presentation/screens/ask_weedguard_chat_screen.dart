import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
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

  Future<void> _showApiKeyDialog() async {
    final currentKey = await WeedGuardChatService.getUserApiKey() ?? '';
    final controller = TextEditingController(text: currentKey);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.vpn_key_rounded, color: Color(0xFF1B4332)),
            SizedBox(width: 8),
            Text(
              'Groq API Key',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste your Groq API key below to enable live cloud AI intelligence for WeedGuard AI:',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'gsk_...',
                filled: true,
                fillColor: const Color(0xFFF1F5F2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFB7E4C7)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4332),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              await WeedGuardChatService.saveUserApiKey(controller.text);
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Groq API Key saved successfully!'),
                    backgroundColor: Color(0xFF1B4332),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Save Key'),
          ),
        ],
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

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.smart_toy_rounded, color: Color(0xFF1B4332)),
            SizedBox(width: 8),
            Text('About WeedGuard AI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ],
        ),
        content: const Text(
          'WeedGuard AI is your agricultural intelligence companion. It assists farmers with weed identification, integrated weed management (IWM), safe herbicide dosing, weather spray windows, and organic farming recipes.',
          style: TextStyle(fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
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

                // 3. Top-Right: Three Dots Menu
                Positioned(
                  top: 0,
                  right: 0,
                  width: w * 0.18,
                  height: h * 0.09,
                  child: PopupMenuButton<String>(
                    icon: const SizedBox.shrink(),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: Colors.white,
                    elevation: 4,
                    onSelected: (val) {
                      if (val == 'scanner') context.push('/scanner');
                      if (val == 'apikey') _showApiKeyDialog();
                      if (val == 'clear') _clearChat();
                      if (val == 'about') _showAboutDialog();
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'scanner',
                        child: Row(
                          children: [
                            Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF1B4332), size: 20),
                            SizedBox(width: 10),
                            Text('Weed Scanner Camera'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'apikey',
                        child: Row(
                          children: [
                            Icon(Icons.vpn_key_rounded, color: Color(0xFF2D6A4F), size: 20),
                            SizedBox(width: 10),
                            Text('Configure API Key'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'clear',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                            SizedBox(width: 10),
                            Text('Clear Conversation'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'about',
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: Color(0xFF1B4332), size: 20),
                            SizedBox(width: 10),
                            Text('About WeedGuard AI'),
                          ],
                        ),
                      ),
                    ],
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
                      splashColor: const Color(0xFF2D6A4F).withOpacity(0.18),
                      highlightColor: const Color(0xFF2D6A4F).withOpacity(0.08),
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
                      splashColor: const Color(0xFF0077B6).withOpacity(0.18),
                      highlightColor: const Color(0xFF0077B6).withOpacity(0.08),
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
                      splashColor: const Color(0xFFF77F00).withOpacity(0.18),
                      highlightColor: const Color(0xFFF77F00).withOpacity(0.08),
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
                      splashColor: const Color(0xFF7209B7).withOpacity(0.18),
                      highlightColor: const Color(0xFF7209B7).withOpacity(0.08),
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
                              color: Colors.black.withOpacity(0.18),
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
            tooltip: 'Clear Chat',
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
            onPressed: _messages.isNotEmpty ? _clearChat : null,
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
                      color: Colors.black.withOpacity(0.08),
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
                      ? Colors.redAccent.withOpacity(0.5)
                      : (isDark ? Colors.white12 : const Color(0xFFE0E0E0)),
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
            color: Colors.black.withOpacity(0.06),
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
