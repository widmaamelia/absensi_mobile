import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard.dart';
import 'login.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _buttonFadeAnimation;

  bool _showLoginButton = false;

  // ==========================================
  // PALETTE WARNA SENADA DENGAN LOGIN PAGE
  // ==========================================
  final Color bgLight = const Color.fromARGB(255, 236, 244, 253);     // Slate 50 (Sama persis)
  final Color textDark = const Color(0xFF0F172A);    // Slate 900 (Navy Gelap)
  final Color textMuted = const Color(0xFF64748B);   // Slate 500 (Abu-abu kebiruan)
  final Color primaryBlue = const Color(0xFF2563EB); // Blue 600 (Biru Utama)
  final Color navyDark = const Color(0xFF1E293B);    // Slate 800 (Biru Dongker)

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
  vsync: this, // Cukup vsync saja yang dipasang
  duration: const Duration(milliseconds: 1800),
);

    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.65, curve: Curves.elasticOut),
      ),
    );

    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.55, 1.0, curve: Curves.easeInOutCubic),
      ),
    );

    _buttonFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.75, 1.0, curve: Curves.easeInOut),
      ),
    );

    _animationController.forward();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token');

    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      _navigateToPage(const DashboardPage());
    } else {
      setState(() {
        _showLoginButton = true;
      });
    }
  }

  void _navigateToPage(Widget targetPage) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => targetPage,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var fadeTween = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          );
          var scaleTween = Tween<double>(begin: 0.96, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          );
          return FadeTransition(
            opacity: fadeTween,
            child: ScaleTransition(scale: scaleTween, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight, // Warna background disamakan solid dengan login page
      body: Stack(
        children: [
          // ==========================================
          // BACKGROUND BLOB EFFECTS (Diambil dari Login Page)
          // ==========================================
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE).withValues(alpha: 0.6), // Blue 100
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E7FF).withValues(alpha: 0.6), // Indigo 100
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          // KONTEN UTAMA
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo Mediatama Bulat (Sama Persis dengan Hero di Login Page)
                ScaleTransition(
                  scale: _logoScaleAnimation,
                  child: Hero(
                    tag: 'logo',
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withValues(alpha: 0.15),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(18),
                      child: Image.asset(
                        'assets/Logo Mediatama.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Judul Aplikasi (Gaya Font Disamakan dengan Login Page)
                AnimatedBuilder(
                  animation: _textFadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _textFadeAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, 15 * (1 - _textFadeAnimation.value)),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Text(
                        'SIMAGANG',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: textDark,
                          letterSpacing: -1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sistem Manajemen Magang Mediatama',
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // BUTTON MENU BAWAH
          Positioned(
            bottom: 60,
            left: 32,
            right: 32,
            child: AnimatedBuilder(
              animation: _buttonFadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _buttonFadeAnimation.value,
                  child: child,
                );
              },
              child: _showLoginButton
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Tombol Ceria Gradasi (Sama persis dengan login page)
                        Container(
                          width: double.infinity,
                          height: 58,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: LinearGradient(
                              colors: [primaryBlue, navyDark],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: navyDark.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () => _navigateToPage(const LoginPage()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'MASUK KE APLIKASI',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 35),
                        Text(
                          '© 2026 Mediatama System • v1.0',
                          style: TextStyle(
                            color: textMuted.withValues(alpha: 0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Loading bulat disamakan dengan login page
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: primaryBlue,
                            strokeWidth: 2.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'MEMUAT DATA...',
                          style: TextStyle(
                            color: textMuted.withValues(alpha: 0.6),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}