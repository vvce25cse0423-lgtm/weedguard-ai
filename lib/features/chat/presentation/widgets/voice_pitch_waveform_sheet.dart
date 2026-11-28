import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Modern voice recognition modal with crop field background image directly on the container,
/// #153F00 waveform container, dynamic #84E865 pitch variation waveform,
/// and real-time automatic language detection (Kannada, Hindi, English).
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

  @override
  void initState() {
    super.initState();
    _activeLanguageCode = widget.initialLanguageCode;
    if (_activeLanguageCode != 'kn' && _activeLanguageCode != 'hi' && _activeLanguageCode != 'en') {
      _activeLanguageCode = 'kn';
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
        await _startListeningWithAutoDetect();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isListening = false);
      }
    }
  }

  Future<void> _startListeningWithAutoDetect() async {
    // Choose appropriate initial locale based on app context
    String targetLocale = 'en_IN';
    if (_activeLanguageCode == 'kn') {
      targetLocale = 'kn_IN';
    } else if (_activeLanguageCode == 'hi') {
      targetLocale = 'hi_IN';
    }

    try {
      setState(() {
        _isListening = true;
      });

      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;
          final words = result.recognizedWords;
          if (words.isNotEmpty) {
            // Intelligent real-time language detection from spoken words
            final detectedLang = _detectLanguage(words);

            setState(() {
              _recognizedText = words;
              _activeLanguageCode = detectedLang;
            });

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
          listenFor: const Duration(seconds: 40),
          pauseFor: const Duration(seconds: 4),
        ),
        onSoundLevelChange: (level) {
          if (!mounted) return;
          // When sound level is <= -1.0 dB (ambient silence/no speech), clamp to 0.0 (rest)
          final norm = level > -1.0 ? ((level + 1.0) / 11.0).clamp(0.0, 1.0) : 0.0;
          setState(() {
            _normalizedSoundLevel = norm;
          });
        },
      );
    } catch (_) {}
  }

  /// Automatically detects whether the user is speaking Kannada, Hindi, or English.
  String _detectLanguage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return _activeLanguageCode;

    // 1. Kannada Unicode script range (\u0C80 - \u0CFF)
    if (RegExp(r'[\u0C80-\u0CFF]').hasMatch(trimmed)) {
      return 'kn';
    }

    // 2. Devanagari / Hindi Unicode script range (\u0900 - \u097F)
    if (RegExp(r'[\u0900-\u097F]').hasMatch(trimmed)) {
      return 'hi';
    }

    // 3. Phonetic & vocabulary analysis for transliterated Kannada / Hindi
    final lower = trimmed.toLowerCase();
    final words = lower.split(RegExp(r'\s+'));

    final kannadaKeywords = {
      'kale', 'kalegalu', 'hullu', 'hege', 'yava', 'yavudu', 'beku', 'agide',
      'bithane', 'thota', 'neeru', 'gobbara', 'gida', 'gidagalu', 'namaskara',
      'madodu', 'madbeku', 'tholisodu', 'haku', 'raitha', 'raitharu', 'kabbina',
      'bhatta', 'jola', 'tomatada', 'bella', 'kallu', 'kelsa', 'oota'
    };

    final hindiKeywords = {
      'ghaas', 'khet', 'kheti', 'fasal', 'dawa', 'dawai', 'kaise', 'kya', 'kare',
      'rokne', 'upay', 'namaste', 'namashkar', 'podha', 'patti', 'keede',
      'paani', 'mitti', 'gehun', 'chawal', 'dhaan', 'ganna', 'tamatar', 'khad',
      'kharpatwar', 'safai', 'bataye', 'batao', 'chahiye', 'hoga', 'hai', 'hain'
    };

    int knScore = 0;
    int hiScore = 0;
    for (final w in words) {
      if (kannadaKeywords.contains(w)) knScore += 2;
      if (hindiKeywords.contains(w)) hiScore += 2;
    }

    if (knScore > hiScore && knScore > 0) return 'kn';
    if (hiScore > knScore && hiScore > 0) return 'hi';

    // 4. Default to English for Latin queries
    return 'en';
  }

  String _getLanguageDisplayName(String code) {
    switch (code) {
      case 'kn':
        return 'ಕನ್ನಡ (Kannada)';
      case 'hi':
        return 'हिंदी (Hindi)';
      case 'en':
      default:
        return 'English';
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

  @override
  Widget build(BuildContext context) {
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
        image: DecorationImage(
          image: AssetImage('assets/images/voice_recognition_sheet_bg.png'),
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
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
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 4),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header: Title & Listening Status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isListening
                      ? const Color(0xFF153F00)
                      : Colors.black54,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF84E865),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  _isListening ? Icons.mic_rounded : Icons.mic_off_rounded,
                  color: const Color(0xFF84E865),
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
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                        shadows: [
                          Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 1)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isListening
                          ? 'Listening • ಮಾತನಾಡಿ • बोलिए • Speak'
                          : (_permissionDenied
                              ? 'Microphone permission needed'
                              : 'Tap microphone to speak'),
                      style: TextStyle(
                        color: _isListening ? const Color(0xFF84E865) : Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        shadows: const [
                          Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Close button
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Real-Time Language Auto-Detection Pill (Aligned left to display complete text without clipping) ──
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
              decoration: BoxDecoration(
                color: const Color(0xFF153F00),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF84E865).withValues(alpha: 0.6),
                  width: 1.2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFF84E865),
                    size: 14,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    _recognizedText.isEmpty
                        ? 'Auto-detect: Kannada • Hindi • English'
                        : 'Language: ${_getLanguageDisplayName(_activeLanguageCode)}',
                    style: const TextStyle(
                      color: Color(0xFF84E865),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── LIVE VOICE PITCH VARIATION WAVEFORM ──
          // Container background: #153F00, Waveform active color: #84E865
          Container(
            height: 96,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF153F00),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF84E865).withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
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
            constraints: const BoxConstraints(minHeight: 64, maxHeight: 110),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF153F00).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _recognizedText.isNotEmpty
                    ? const Color(0xFF84E865)
                    : Colors.white24,
                width: 1.2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Text(
                _recognizedText.isNotEmpty
                    ? _recognizedText
                    : (_isListening
                        ? 'Speak in your language (ಕನ್ನಡ, हिंदी, English)...'
                        : 'Tap microphone to start speaking...'),
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: _recognizedText.isNotEmpty ? FontWeight.w600 : FontWeight.w400,
                  color: _recognizedText.isNotEmpty ? Colors.white : Colors.white70,
                  height: 1.35,
                  shadows: const [
                    Shadow(color: Colors.black54, blurRadius: 4),
                  ],
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
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black45,
                    side: const BorderSide(color: Colors.white38),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
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
                    _startListeningWithAutoDetect();
                  }
                },
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF153F00),
                    border: Border.all(
                      color: const Color(0xFF84E865),
                      width: 2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isListening ? Icons.pause_rounded : Icons.mic_rounded,
                    color: const Color(0xFF84E865),
                    size: 26,
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
                  label: const Text('Ask AI', style: TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF153F00),
                    foregroundColor: const Color(0xFF84E865),
                    side: BorderSide(
                      color: _recognizedText.trim().isNotEmpty
                          ? const Color(0xFF84E865)
                          : Colors.white24,
                      width: 1.5,
                    ),
                    disabledBackgroundColor: Colors.black45,
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

/// Custom painter rendering dynamic audio pitch variation waveform
/// with frequency peaks, harmonic crests, and mirrored vertical oscillation
/// using color #84E865 over #153F00 container.
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

    // #84E865 Color variants for dynamic pitch variation
    const waveColor = Color(0xFF84E865);

    final vibrantPaint = Paint()
      ..color = waveColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth;

    final midPaint = Paint()
      ..color = waveColor.withValues(alpha: 0.80)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth;

    final dimPaint = Paint()
      ..color = waveColor.withValues(alpha: 0.30)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth;

    // Waveform is only active when recording voice (isListening AND active voice soundLevel > 0.05)
    // When no recording of voice, the waveform MUST BE COMPLETELY AT REST!
    final bool isRecordingVoice = isListening && soundLevel > 0.05;

    final phase = animationProgress * 2 * math.pi;

    for (int i = 0; i < barCount; i++) {
      final x = (i * totalSpacing) + (totalSpacing / 2);

      double barHeight;
      if (isRecordingVoice) {
        // Normalized distance from center (0.0 at edges to 1.0 at center)
        final centerFactor = 1.0 - math.pow(((i - barCount / 2) / (barCount / 2)).abs(), 1.6);

        // Multi-harmonic pitch variation formula
        final wave1 = math.sin(phase * 2.2 + i * 0.32);
        final wave2 = math.cos(phase * 1.5 + i * 0.18);
        final wave3 = math.sin(phase * 4.0 + i * 0.55);
        final harmonic = ((wave1 * 0.55 + wave2 * 0.30 + wave3 * 0.15).abs());

        // Dynamic pitch variation: scales up with voice intensity up to ~76px
        final speechIntensity = ((soundLevel - 0.05) / 0.95).clamp(0.0, 1.0);
        barHeight = 3.0 + (size.height * 0.82 * speechIntensity * harmonic * centerFactor);
      } else {
        // AT REST: Completely flat, calm resting line (constant 3.0px)
        barHeight = 3.0;
      }

      barHeight = barHeight.clamp(3.0, size.height * 0.88);

      final top = centerY - (barHeight / 2);
      final bottom = centerY + (barHeight / 2);

      // Pitch-based intensity: active voice peaks use full #84E865, resting bars use dimPaint
      Paint barPaint;
      if (isRecordingVoice && barHeight > size.height * 0.38) {
        barPaint = vibrantPaint;
      } else if (isRecordingVoice && barHeight > size.height * 0.16) {
        barPaint = midPaint;
      } else {
        barPaint = dimPaint;
      }

      canvas.drawLine(
        Offset(x, top),
        Offset(x, bottom),
        barPaint,
      );
    }

    // Horizontal baseline axis line through center with #84E865 accent
    final axisPaint = Paint()
      ..color = waveColor.withValues(alpha: 0.20)
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
