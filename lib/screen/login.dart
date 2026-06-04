import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import 'dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // =========================================
  // CONTROLLER
  // =========================================
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // =========================================
  // STATE
  // =========================================
  bool obscurePassword = true;
  bool isLoading = false;

  // =========================================
  // COLORS (Modern Tailwind Light Theme + Navy)
  // =========================================
  final Color bgLight = const Color.fromARGB(255, 236, 244, 253);     // Slate 50 (Background Sangat Terang)
  final Color textDark = const Color(0xFF0F172A);    // Slate 900 (Navy Gelap untuk Teks)
  final Color textMuted = const Color(0xFF64748B);   // Slate 500 (Abu-abu kebiruan)
  
  final Color primaryBlue = const Color(0xFF2563EB); // Blue 600 (Biru Utama)
  final Color navyDark = const Color(0xFF1E293B);    // Slate 800 (Biru Dongker)
  final Color inputBg = const Color(0xFFF1F5F9);     // Slate 100 (Background Input)

  // =========================================
  // LOGIN FUNCTION (TIDAK DISENTUH SAMA SEKALI!)
  // =========================================
  Future<void> login() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: ApiConfig.formHeaders(),
        body: {
          'email': emailController.text.trim(),
          'password': passwordController.text,
          'device_name': 'android_mobile',
        },
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      // =========================================
      // LOGIN SUCCESS
      // =========================================
      if (response.statusCode == 200) {
        final token = data['token'] ?? '';
        final prefs = await SharedPreferences.getInstance();

        // SAVE TOKEN
        await prefs.setString(
          'auth_token',
          token,
        );

        // SAVE USER DATA (NAMA & EMAIL)
        if (data['user'] != null) {
          await prefs.setString(
            'user_name',
            data['user']['name'] ?? '',
          );
          
          // 🔥 TAMBAHKAN BARIS INI UNTUK MENYIMPAN EMAIL
          await prefs.setString(
            'user_email',
            data['user']['email'] ?? '',
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message'] ?? 'Login Berhasil',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // NAVIGATE TO DASHBOARD
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const DashboardPage(),
          ),
        );
      } else {
        // =========================================
        // LOGIN FAILED
        // =========================================
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message'] ?? 'Login gagal.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('LOGIN ERROR: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // =========================================
  // BUILD
  // =========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: Stack(
        children: [
          // =========================================
          // BACKGROUND BLOB EFFECTS (Sangat Halus)
          // =========================================
          Positioned(
            top: -100,
            right: -50,
            child: _buildBlob(350, const Color(0xFFDBEAFE).withValues(alpha: 0.6)), // Blue 100
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: _buildBlob(400, const Color(0xFFE0E7FF).withValues(alpha: 0.6)), // Indigo 100
          ),

          // =========================================
          // CONTENT
          // =========================================
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // =========================================
                    // LOGO (Animated)
                    // =========================================
                    _FadeInSlide(
                      delay: 0,
                      child: Hero(
                        tag: 'logo',
                        child: Container(
                          height: 110,
                          width: 110,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primaryBlue.withValues(alpha: 0.15),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Image.asset(
                              'assets/ogo.jpg', // Pastikan nama aset benar
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // =========================================
                    // TITLE (Animated)
                    // =========================================
                    _FadeInSlide(
                      delay: 100,
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
                    const SizedBox(height: 40),

                    // =========================================
                    // LOGIN CARD (Animated)
                    // =========================================
                    _FadeInSlide(
                      delay: 200,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: textDark.withValues(alpha: 0.06), // Soft modern shadow
                              blurRadius: 40,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // EMAIL
                            _buildInputLabel('Email Address'),
                            _buildCustomField(
                              controller: emailController,
                              hint: 'nama@email.com',
                              icon: Icons.alternate_email_rounded,
                            ),
                            const SizedBox(height: 24),

                            // PASSWORD
                            _buildInputLabel('Password'),
                            _buildCustomField(
                              controller: passwordController,
                              hint: '••••••••',
                              icon: Icons.lock_person_outlined,
                              isPassword: true,
                              obscure: obscurePassword,
                              onToggle: () {
                                setState(() {
                                  obscurePassword = !obscurePassword;
                                });
                              },
                            ),

                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {},
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: Text(
                                  'Lupa Sandi?',
                                  style: TextStyle(
                                    color: primaryBlue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // BUTTON LOGIN
                            _buildGradientButton(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // =========================================
                    // FOOTER (Animated)
                    // =========================================
                    _FadeInSlide(
                      delay: 300,
                      child: Text(
                        '© 2024 Mediatama System • v1.0',
                        style: TextStyle(
                          color: textMuted.withValues(alpha: 0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================
  // BACKGROUND BLOB
  // =========================================
  Widget _buildBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(
          color: Colors.transparent,
        ),
      ),
    );
  }

  // =========================================
  // INPUT LABEL
  // =========================================
  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          color: textDark,
          fontWeight: FontWeight.w700,
          fontSize: 13,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // =========================================
  // CUSTOM FIELD (Modern Clean UI)
  // =========================================
  Widget _buildCustomField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2), // Memberikan efek timbul sedikit
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: TextStyle(
          color: textDark,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 4.0),
            child: Icon(
              icon,
              color: textMuted,
              size: 22,
            ),
          ),
          suffixIcon: isPassword
              ? Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: textMuted.withValues(alpha: 0.8),
                      size: 22,
                    ),
                    onPressed: onToggle,
                  ),
                )
              : null,
          hintText: hint,
          hintStyle: TextStyle(
            color: textMuted.withValues(alpha: 0.5),
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
        ),
      ),
    );
  }

  // =========================================
  // BUTTON LOGIN (Gradient Primary to Navy)
  // =========================================
  Widget _buildGradientButton() {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [primaryBlue, navyDark], // Kombinasi Terang ke Biru Dongker Gelap
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
        onPressed: isLoading ? null : login,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.grey.withValues(alpha: 0.2),
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                'MASUK KE DASHBOARD',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
      ),
    );
  }
}

// =========================================
// ANIMATION HELPER WIDGET
// =========================================
class _FadeInSlide extends StatelessWidget {
  final Widget child;
  final int delay;

  const _FadeInSlide({required this.child, required this.delay});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.delayed(Duration(milliseconds: delay)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink(); // Menyembunyikan widget sebelum animasi mulai
        }
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 40 * (1 - value)), // Slide up 40 pixel
                child: child,
              ),
            );
          },
          child: child,
        );
      },
    );
  }
}