import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _loadingController;
  late final AnimationController _fadeController;
  late final Animation<double> _loadingAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();

    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 2800),
      vsync: this,
    );
    _loadingAnim = CurvedAnimation(
      parent: _loadingController,
      curve: Curves.easeInOut,
    );
    _loadingController.forward();

    _loadingController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigate();
      }
    });
  }

  void _navigate() {
    if (!mounted) return;
    final session = Supabase.instance.client.auth.currentSession;
    context.go(session != null ? '/' : '/login');
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/images/splash_bg.png', fit: BoxFit.cover),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.35, 0.65, 1.0],
                  colors: [
                    Color(0x22000000),
                    Color(0x00000000),
                    Color(0x55000000),
                    Color(0xCC000000),
                  ],
                ),
              ),
            ),
            // Logo + text
            Positioned(
              top: MediaQuery.of(context).size.height * 0.14,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(Icons.eco, color: Color(0xFF2E7D32), size: 56),
                        CustomPaint(size: const Size(100, 100), painter: _BracketPainter()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'WeedGuard ',
                          style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Color(0xFF1B5E20), letterSpacing: -0.5),
                        ),
                        TextSpan(
                          text: 'AI',
                          style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Color(0xFF2E7D32), letterSpacing: -0.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Healthier Crops. Smarter Decisions.',
                    style: TextStyle(fontSize: 15, color: Color(0xFF2E7D32), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            // Bottom loading
            Positioned(
              bottom: 60,
              left: 40,
              right: 40,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _loadingAnim,
                    builder: (_, __) => _GreenLoadingBar(progress: _loadingAnim.value),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Loading your farm...',
                    style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GreenLoadingBar extends StatelessWidget {
  final double progress;
  const _GreenLoadingBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(2),
      ),
      child: LayoutBuilder(
        builder: (_, constraints) {
          return Stack(
            children: [
              Container(
                width: constraints.maxWidth * progress,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF43A047).withOpacity(0.7),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              if (progress > 0.02 && progress < 1.0)
                Positioned(
                  left: (constraints.maxWidth * progress - 10).clamp(0, constraints.maxWidth),
                  top: -4,
                  child: Container(
                    width: 14,
                    height: 12,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF80E27E).withOpacity(0.9),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _BracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1B5E20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.square;

    const len = 18.0;

    // Top-left
    canvas.drawLine(Offset(0, len), const Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(len, 0), paint);
    // Top-right
    canvas.drawLine(Offset(size.width - len, 0), Offset(size.width, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, len), paint);
    // Bottom-left
    canvas.drawLine(Offset(0, size.height - len), Offset(0, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(len, size.height), paint);
    // Bottom-right
    canvas.drawLine(Offset(size.width - len, size.height), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height - len), Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
