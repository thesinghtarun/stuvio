import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:studyvault/core/const/constant.dart';
import 'package:studyvault/core/utils/app_logger.dart';
import 'package:studyvault/provider/home_provider.dart';
import 'package:studyvault/provider/workspace_counter_provider.dart';
import 'package:studyvault/screens/home_screen.dart';
import 'package:studyvault/screens/onboarding/onboarding_screen.dart';
import 'package:studyvault/services/share_handler_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _progressController;

  late final Animation<double> _logoScale;
  late final Animation<Offset> _nameOffset;
  late final Animation<double> _nameOpacity;
  late final Animation<Offset> _taglineOffset;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    context.read<HomeProvider>().resetInboxPopup();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _logoScale = Tween<double>(begin: 0.6, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOutBack),
      ),
    );

    _nameOffset = Tween<Offset>(begin: const Offset(-0.8, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.35, 0.65, curve: Curves.easeOutCubic),
          ),
        );

    _nameOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.35, 0.65)),
    );

    _taglineOffset =
        Tween<Offset>(begin: const Offset(-0.8, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.6, 1, curve: Curves.easeOutCubic),
          ),
        );

    _taglineOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.6, 1)),
    );

    _progressAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_progressController);

    _initialize();
  }

  Future<void> _initialize() async {
    // Start splash animation
    final splashAnimation = _controller.forward();

    // Load preferences while animation is running
    await context.read<WorkspaceCounterProvider>().load();

    // Wait for splash animation to complete
    await splashAnimation;

    // Start progress bar
    await _progressController.forward();

    if (!mounted) return;

    final hasWorkspace = context.read<WorkspaceCounterProvider>().hasWorkspace;
    final targetScreen = hasWorkspace ? 'HomeScreen' : 'OnboardingScreen';
    AppLogger.nav('SplashScreen', targetScreen);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => hasWorkspace ? HomeScreen() : const OnboardingScreen(),
      ),
    );

    // Wait for the new screen to mount, then release any queued shared files
    Future.delayed(const Duration(milliseconds: 600), () {
      AppLogger.action(
        'SplashScreen',
        'Notifying ShareHandlerService splash is done',
      );
      ShareHandlerService.instance.setSplashActive(false);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Widget buildAnimatedText({
    required Animation<Offset> offset,
    required Animation<double> opacity,
    required Widget child,
  }) {
    return FadeTransition(
      opacity: opacity,
      child: SlideTransition(position: offset, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            ScaleTransition(
              scale: _logoScale,
              child: Image.asset(splashLogo, width: 220),
            ),

            const SizedBox(height: 20),

            buildAnimatedText(
              offset: _nameOffset,
              opacity: _nameOpacity,
              child: Text(
                appName,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 8),

            buildAnimatedText(
              offset: _taglineOffset,
              opacity: _taglineOpacity,
              child: Text(
                appTagLine,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  letterSpacing: 1,
                ),
              ),
            ),

            const Spacer(),

            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                final progress = _progressAnimation.value;

                return Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "${(progress * 100).toInt()}%",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
