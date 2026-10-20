import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'login_page.dart';

class SplashScreen extends StatefulWidget {
  final Widget nextPage;

  const SplashScreen({
    super.key,
    required this.nextPage,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController leafController;
  late AnimationController introController;

  late Animation<double> logoScale;
  late Animation<double> logoOpacity;
  late Animation<double> titleOpacity;
  late Animation<Offset> subtitleSlide;
  late Animation<double> loadingOpacity;

  Timer? navigationTimer;

  @override
  void initState() {
    super.initState();

    // ==========================================================
    // LEAF ANIMATION
    // ==========================================================

    leafController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();

    // ==========================================================
    // INTRO ANIMATION
    // ==========================================================

    introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    logoScale = Tween<double>(
      begin: 0.65,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: introController,
        curve: const Interval(
          0.0,
          0.45,
          curve: Curves.easeOutBack,
        ),
      ),
    );

    logoOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: introController,
        curve: const Interval(
          0.0,
          0.35,
          curve: Curves.easeIn,
        ),
      ),
    );

    titleOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: introController,
        curve: const Interval(
          0.30,
          0.65,
          curve: Curves.easeIn,
        ),
      ),
    );

    subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: introController,
        curve: const Interval(
          0.45,
          0.80,
          curve: Curves.easeOut,
        ),
      ),
    );

    loadingOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: introController,
        curve: const Interval(
          0.70,
          1.0,
          curve: Curves.easeIn,
        ),
      ),
    );

    introController.forward();

    // ==========================================================
    // GO TO LOGIN
    // ==========================================================

    navigationTimer = Timer(
      const Duration(milliseconds: 5000),
      () {
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginPage(
              nextPage: widget.nextPage,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    leafController.dispose();
    introController.dispose();
    navigationTimer?.cancel();
    super.dispose();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF9),

      body: Stack(
        children: [
          // ====================================================
          // SOFT BACKGROUND CIRCLES
          // ====================================================

          Positioned(
            top: -120,
            right: -100,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF16875B)
                    .withOpacity(0.05),
              ),
            ),
          ),

          Positioned(
            bottom: -130,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF16875B)
                    .withOpacity(0.05),
              ),
            ),
          ),

          // ====================================================
          // FLOATING LEAVES
          // ====================================================

          AnimatedBuilder(
            animation: leafController,
            builder: (context, child) {
              return Stack(
                children: [
                  buildLeaf(
                    screenSize: screenSize,
                    startX: 0.08,
                    startY: -0.15,
                    fallDistance: 1.25,
                    swayAmount: 0.05,
                    size: 28,
                    color: const Color(0xFF7BCB8E),
                    delay: 0.00,
                    rotationSpeed: 2.0,
                  ),

                  buildLeaf(
                    screenSize: screenSize,
                    startX: 0.75,
                    startY: -0.20,
                    fallDistance: 1.30,
                    swayAmount: -0.05,
                    size: 24,
                    color: const Color(0xFF55B96E),
                    delay: 0.15,
                    rotationSpeed: 1.5,
                  ),

                  buildLeaf(
                    screenSize: screenSize,
                    startX: 0.22,
                    startY: -0.25,
                    fallDistance: 1.25,
                    swayAmount: 0.08,
                    size: 20,
                    color: const Color(0xFFA5D6A7),
                    delay: 0.28,
                    rotationSpeed: 2.5,
                  ),

                  buildLeaf(
                    screenSize: screenSize,
                    startX: 0.58,
                    startY: -0.18,
                    fallDistance: 1.20,
                    swayAmount: -0.07,
                    size: 30,
                    color: const Color(0xFF6FCF97),
                    delay: 0.42,
                    rotationSpeed: 1.8,
                  ),

                  buildLeaf(
                    screenSize: screenSize,
                    startX: 0.90,
                    startY: -0.14,
                    fallDistance: 1.22,
                    swayAmount: -0.06,
                    size: 22,
                    color: const Color(0xFF8BC34A),
                    delay: 0.56,
                    rotationSpeed: 2.2,
                  ),

                  buildLeaf(
                    screenSize: screenSize,
                    startX: 0.03,
                    startY: -0.20,
                    fallDistance: 1.30,
                    swayAmount: 0.07,
                    size: 26,
                    color: const Color(0xFF81C784),
                    delay: 0.70,
                    rotationSpeed: 1.6,
                  ),

                  buildLeaf(
                    screenSize: screenSize,
                    startX: 0.42,
                    startY: -0.30,
                    fallDistance: 1.35,
                    swayAmount: 0.04,
                    size: 18,
                    color: const Color(0xFF9CCC65),
                    delay: 0.82,
                    rotationSpeed: 2.4,
                  ),
                ],
              );
            },
          ),

          // ====================================================
          // MAIN CONTENT
          // ====================================================

          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 30,
              ),

              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  // ============================================
                  // LOGO
                  // ============================================

                  FadeTransition(
                    opacity: logoOpacity,
                    child: ScaleTransition(
                      scale: logoScale,

                      child: Container(
                        width: 165,
                        height: 165,
                        padding: const EdgeInsets.all(7),

                        decoration: BoxDecoration(
                          shape: BoxShape.circle,

                          color: Colors.white,

                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF16875B,
                              ).withOpacity(0.12),

                              blurRadius: 35,

                              spreadRadius: 5,
                            ),
                          ],
                        ),

                        child: ClipOval(
                          child: Image.asset(
                            'assests/images/app_logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ============================================
                  // APP NAME
                  // ============================================

                  FadeTransition(
                    opacity: titleOpacity,

                    child: const Text(
                      'WasteHotspot AI',
                      textAlign: TextAlign.center,

                      style: TextStyle(
                        fontSize: 30,

                        fontWeight:
                            FontWeight.bold,

                        color:
                            Color(0xFF16875B),

                        letterSpacing: -0.4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ============================================
                  // SUBTITLE
                  // ============================================

                  SlideTransition(
                    position: subtitleSlide,

                    child: FadeTransition(
                      opacity: titleOpacity,

                      child: const Text(
                        'Township Waste Intelligence',
                        textAlign:
                            TextAlign.center,

                        style: TextStyle(
                          fontSize: 14,

                          color:
                              Colors.black45,

                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 38),

                  // ============================================
                  // LOADING SECTION
                  // ============================================

                  FadeTransition(
                    opacity: loadingOpacity,

                    child: Column(
                      children: [
                        const SizedBox(
                          width: 28,
                          height: 28,

                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2.8,

                            color:
                                Color(0xFF16875B),
                          ),
                        ),

                        const SizedBox(height: 13),

                        Text(
                          'Preparing a cleaner township...',
                          style: TextStyle(
                            fontSize: 11,

                            color:
                                Colors.grey.shade500,

                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ====================================================
          // BOTTOM TEXT
          // ====================================================

          Positioned(
            left: 0,
            right: 0,
            bottom: 35,

            child: FadeTransition(
              opacity: loadingOpacity,

              child: const Text(
                'REPORT • VERIFY • ANALYSE • IMPROVE',
                textAlign: TextAlign.center,

                style: TextStyle(
                  fontSize: 9,

                  fontWeight: FontWeight.w600,

                  letterSpacing: 1.4,

                  color: Color(0xFF89A498),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // LEAF
  // ==========================================================

  Widget buildLeaf({
    required Size screenSize,
    required double startX,
    required double startY,
    required double fallDistance,
    required double swayAmount,
    required double size,
    required Color color,
    required double delay,
    required double rotationSpeed,
  }) {
    final progress =
        (leafController.value + delay) % 1.0;

    final top =
        (startY + fallDistance * progress) *
        screenSize.height;

    final left =
        (startX +
                swayAmount *
                    sin(progress * 2 * pi)) *
            screenSize.width;

    final rotation =
        progress * 2 * pi * rotationSpeed;

    // Fade leaf slightly at beginning/end
    double opacity = 0.65;

    if (progress < 0.10) {
      opacity = progress / 0.10 * 0.65;
    }

    if (progress > 0.88) {
      opacity =
          (1 - progress) / 0.12 * 0.65;
    }

    opacity = opacity.clamp(0.0, 0.65);

    return Positioned(
      top: top,
      left: left,

      child: Transform.rotate(
        angle: rotation,

        child: Opacity(
          opacity: opacity,

          child: Icon(
            Icons.eco,
            size: size,
            color: color,
          ),
        ),
      ),
    );
  }
}