import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Modern voice recognition modal with live black-and-white pitch variation waveform.
/// Dynamically recognizes speech in Kannada, Hindi, or English and feeds it to WeedGuard AI.
class VoicePitchWaveformSheet extends StatefulWidget {
  final String initialLanguageCode;
  final Function(String recognizedText, String languageCode) onSpeechResult;

  const VoicePitchWaveformSheet({
    super.key,
    required this.initialLanguageCode,
    required this.onSpeechResult,
  });

  @override
  State<VoicePitchWaveformSheet> createState() => _VoicePitchWaveformSheetState();
}

class _VoicePitchWaveformSheetState extends State<VoicePitchWaveformSheet>
    with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  late AnimationController _waveController;

  bool _isSpeechInitialized = false;
  bool _isListening = false;
  bool _permissionDenied = false;
  double _normalizedSoundLevel = 0.0;
  String _recognizedText = '';
  late String _activeLanguageCode;
  Timer? _silenceTimer;

  static const Map<String, Map<String, String>> _supportedLanguages = {
    'kn': {
      'name': 'ಕನ್ನಡ',
      'sub': 'Kannada',
      'locale': 'kn_IN',
      'prompt': 'ಕನ್ನಡದಲ್ಲಿ ಮಾತನಾಡಿ...',
    },
    'hi': {
      'name': 'हिंदी',
      'sub': 'Hindi',
      'locale': 'hi_IN',
      'prompt': 'हिंदी में बोलिए...',
    },
    'en': {
      'name': 'English',
      'sub': 'English',
      'locale': 'en_IN',
      'prompt': 'Speak in English...',
    },
  };

  @override
  void initState() {
    super.initState();
    _activeLanguageCode = widget.initialLanguageCode;
    if (!_supportedLanguages.containsKey(_activeLanguageCode)) {
      _activeLanguageCode = 'en';
    }

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _waveController.addListener(() {
      if (mounted) setState(() {});
    });

    _requestPermissionAndStartListening();
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _waveController.dispose();
    try {
      _speech.stop();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _requestPermissionAndStartListening() async {
    final status = await Permission.microphone.request();
    if (!mounted) return;

    if (status.isPermanentlyDenied || status.isDenied) {
      setState(() {
        _permissionDenied = true;
      });
      return;
    }

    await _initializeAndStartListening();
  }

  Future<void> _initializeAndStartListening() async {
    try {
      if (!_isSpeechInitialized) {
        _isSpeechInitialized = await _speech.initialize(
          onStatus: (status) {
            if (!mounted) return;
            if (status == 'listening') {
              setState(() => _isListening = true);
            } else if (status == 'notListening' || status == 'done') {
              setState(() {
                _isListening = false;
                _normalizedSoundLevel = 0.0;
              });
              // Auto-submit if speech finished and has content
              if (_recognizedText.trim().isNotEmpty) {
                _scheduleAutoSubmit();
              }
            }
          },
          onError: (errorNotification) {
            if (!mounted) return;
            setState(() {
              _isListening = false;
              _normalizedSoundLevel = 0.0;
            });
          },
        );
      }

      if (_isSpeechInitialized) {
        await _startListeningInCurrentLocale();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isListening = false);
      }
    }
  }

  Future<void> _startListeningInCurrentLocale() async {
    final langConfig = _supportedLanguages[_activeLanguageCode] ?? _supportedLanguages['en']!;
    final targetLocale = langConfig['locale'] ?? 'en_IN';

    try {
      setState(() {
        _isListening = true;
      });

      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;
          final words = result.recognizedWords;
          if (words.isNotEmpty) {
            setState(() {
              _recognizedText = words;
            });

            // Detect if speech contains Kannada or Devanagari characters
            _detectAndSyncLanguage(words);

            if (result.finalResult) {
              _scheduleAutoSubmit();
            }
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.confirmation,
          partialResults: true,
          cancelOnError: false,
          autoPunctuation: true,
          localeId: targetLocale,
          listenFor: const Duration(seconds: 35),
          pauseFor: const Duration(seconds: 4),
        ),
        onSoundLevelChange: (level) {
          if (!mounted) return;
          // Normalize typical STT sound level (-10 to 10 dB) to 0.0 .. 1.0
          final norm = ((level + 5) / 15).clamp(0.0, 1.0);
          setState(() {
            _normalizedSoundLevel = norm;
          });
        },
      );
    } catch (_) {}
  }

  void _detectAndSyncLanguage(String text) {
    if (RegExp(r'[\u0C80-\u0CFF]').hasMatch(text)) {
      if (_activeLanguageCode != 'kn') {
        setState(() => _activeLanguageCode = 'kn');
      }
    } else if (RegExp(r'[\u0900-\u097F]').hasMatch(text)) {
      if (_activeLanguageCode != 'hi') {
        setState(() => _activeLanguageCode = 'hi');
      }
    }
  }

  void _scheduleAutoSubmit() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted && _recognizedText.trim().isNotEmpty) {
        _submitRecognizedText();
      }
    });
  }

  void _submitRecognizedText() {
    final text = _recognizedText.trim();
    if (text.isEmpty) return;

    HapticFeedback.mediumImpact();
    widget.onSpeechResult(text, _activeLanguageCode);
    Navigator.of(context).pop();
  }

  Future<void> _switchLanguage(String newLangCode) async {
    if (_activeLanguageCode == newLangCode) return;
    HapticFeedback.selectionClick();

    _silenceTimer?.cancel();
    await _speech.stop();

    setState(() {
      _activeLanguageCode = newLangCode;
      _recognizedText = '';
    });

    await _startListeningInCurrentLocale();
  }

  @override
  Widget build(BuildContext context) {
    final currentLangConfig = _supportedLanguages[_activeLanguageCode] ?? _supportedLanguages['en']!;
    final promptText = currentLangConfig['prompt'] ?? 'Speak now...';

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 16,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF141915),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 42,
              height: 4.5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header: Title & Listening Status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isListening
                      ? const Color(0xFF2D6A4F).withValues(alpha: 0.3)
                      : Colors.white12,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isListening ? Icons.mic_rounded : Icons.mic_off_rounded,
                  color: _isListening ? const Color(0xFF52B788) : Colors.white60,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'WeedGuard Voice Recognition',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isListening
                          ? 'Listening • ಮಾತನಾಡಿ • बोलिए'
                          : (_permissionDenied
                              ? 'Microphone permission needed'
                              : 'Tap mic or language to speak'),
                      style: TextStyle(
                        color: _isListening ? const Color(0xFF74C69D) : Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Close button
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Language Selector Pills (Kannada, Hindi, English)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _supportedLanguages.entries.map((entry) {
                final isSelected = entry.key == _activeLanguageCode;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(
                      '${entry.value['name']} (${entry.value['sub']})',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.black : Colors.white70,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: Colors.white,
                    backgroundColor: const Color(0xFF222923),
                    side: BorderSide(
                      color: isSelected ? Colors.white : Colors.white12,
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    showCheckmark: false,
                    onSelected: (_) => _switchLanguage(entry.key),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // ── LIVE VOICE PITCH VARIATION WAVEFORM (Black & White Audio Spectrum) ──
          Container(
            height: 96,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CustomPaint(
                painter: VoicePitchWaveformPainter(
                  animationProgress: _waveController.value,
                  soundLevel: _isListening ? _normalizedSoundLevel : 0.0,
                  isListening: _isListening,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Recognized Text Preview Box
          Container(
            width: double.infinity,
            constraints: const Duration(milliseconds: 0) == Duration.zero
                ? const BoxConstraints(minHeight: 64, maxHeight: 110)
                : null,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1C221D),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _recognizedText.isNotEmpty ? const Color(0xFF40916C) : Colors.white10,
                width: 1,
              ),
            ),
            child: SingleChildScrollView(
              child: Text(
                _recognizedText.isNotEmpty
                    ? _recognizedText
                    : (_isListening ? promptText : 'Tap microphone to start speaking...'),
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: _recognizedText.isNotEmpty ? FontWeight.w600 : FontWeight.w400,
                  color: _recognizedText.isNotEmpty ? Colors.white : Colors.white38,
                  height: 1.35,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Bottom Action Controls
          Row(
            children: [
              // Cancel Button
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),

              // Mic Pause/Resume Button
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (_isListening) {
                    _speech.stop();
                    setState(() => _isListening = false);
                  } else {
                    _startListeningInCurrentLocale();
                  }
                },
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isListening ? const Color(0xFF2D6A4F) : Colors.white12,
                    border: Border.all(
                      color: _isListening ? const Color(0xFF74C69D) : Colors.white30,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _isListening ? Icons.pause_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Send / Submit Button
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: _recognizedText.trim().isNotEmpty ? _submitRecognizedText : null,
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Ask AI'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D6A4F),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.white12,
                    disabledForegroundColor: Colors.white30,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom painter rendering dynamic black-and-white audio pitch variation waveform
/// with frequency peaks, harmonic crests, and mirrored vertical oscillation.
class VoicePitchWaveformPainter extends CustomPainter {
  final double animationProgress;
  final double soundLevel;
  final bool isListening;

  VoicePitchWaveformPainter({
    required this.animationProgress,
    required this.soundLevel,
    required this.isListening,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    const barCount = 46;
    final totalSpacing = size.width / barCount;
    final barWidth = totalSpacing * 0.65;

    final whitePaint = Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth;

    final lightGreyPaint = Paint()
      ..color = const Color(0xFFB0B7B2)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth;

    final dimPaint = Paint()
      ..color = Colors.white24
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth;

    final phase = animationProgress * 2 * math.pi;

    for (int i = 0; i < barCount; i++) {
      final x = (i * totalSpacing) + (totalSpacing / 2);

      // Normalized distance from center (0.0 at edges to 1.0 at center)
      final centerFactor = 1.0 - math.pow(((i - barCount / 2) / (barCount / 2)).abs(), 1.6);

      // Pitch variation: multi-harmonic frequency calculation
      final wave1 = math.sin(phase * 2.2 + i * 0.32);
      final wave2 = math.cos(phase * 1.5 + i * 0.18);
      final wave3 = math.sin(phase * 4.0 + i * 0.55);
      final harmonic = ((wave1 * 0.55 + wave2 * 0.30 + wave3 * 0.15).abs());

      // Height calculation
      double barHeight;
      if (isListening) {
        final speechBoost = math.max(0.12, soundLevel);
        // Peak variation: when talking, amplitude scales up dramatically (up to ~76px)
        barHeight = 4.0 + (size.height * 0.78 * speechBoost * harmonic * centerFactor);
      } else {
        // Idle gentle undulation
        barHeight = 3.0 + (math.sin(phase + i * 0.25).abs() * 6.0 * centerFactor);
      }

      barHeight = barHeight.clamp(3.0, size.height * 0.88);

      final top = centerY - (barHeight / 2);
      final bottom = centerY + (barHeight / 2);

      // Alternating pitch tone: higher peaks use bright white, secondary use light grey
      Paint barPaint;
      if (barHeight > size.height * 0.42) {
        barPaint = whitePaint;
      } else if (barHeight > size.height * 0.18) {
        barPaint = lightGreyPaint;
      } else {
        barPaint = dimPaint;
      }

      canvas.drawLine(
        Offset(x, top),
        Offset(x, bottom),
        barPaint,
      );
    }

    // Horizontal baseline axis line through center for authentic audio analyzer look
    final axisPaint = Paint()
      ..color = Colors.white12
      ..strokeWidth = 0.8;

    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      axisPaint,
    );
  }

  @override
  bool shouldRepaint(covariant VoicePitchWaveformPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.soundLevel != soundLevel ||
        oldDelegate.isListening != isListening;
  }
}
