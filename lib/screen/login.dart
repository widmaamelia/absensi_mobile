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
  // COLORS
  // =========================================
  final Color primaryColor = const Color(0xFF007AFF);
  final Color secondaryColor = const Color(0xFF00D2FF);
  final Color textDark = const Color(0xFF1D1D1F);

  // =========================================
  // LOGIN FUNCTION
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

        final prefs =
            await SharedPreferences.getInstance();

        // SAVE TOKEN
        await prefs.setString(
          'auth_token',
          token,
        );

        // SAVE USER NAME
        if (data['user'] != null) {

          await prefs.setString(
            'user_name',
            data['user']['name'] ?? '',
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(
            content: Text(
              data['message'] ??
                  'Login Berhasil',
            ),

            backgroundColor: Colors.green,
          ),
        );

        // NAVIGATE TO DASHBOARD
        Navigator.pushReplacement(
          context,

          MaterialPageRoute(
            builder: (_) =>
                const DashboardPage(),
          ),
        );

      } else {

        // =========================================
        // LOGIN FAILED
        // =========================================
        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(
            content: Text(
              data['message'] ??
                  'Login gagal.',
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

      backgroundColor: Colors.white,

      body: Stack(
        children: [

          // =========================================
          // BACKGROUND
          // =========================================
          Positioned(
            top: -100,
            right: -50,

            child: _buildBlob(
              300,
              const Color(0xFFE0F2FE),
            ),
          ),

          Positioned(
            bottom: -50,
            left: -50,

            child: _buildBlob(
              250,
              const Color(0xFFF0F9FF),
            ),
          ),

          Positioned(
            top: 200,
            left: -80,

            child: _buildBlob(
              200,
              const Color(0xFFEEF2FF),
            ),
          ),

          // =========================================
          // CONTENT
          // =========================================
          SafeArea(

            child: Center(

              child: SingleChildScrollView(

                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 24,
                ),

                child: Column(

                  mainAxisAlignment:
                      MainAxisAlignment.center,

                  children: [

                    // =========================================
                    // LOGO
                    // =========================================
                    Hero(

                      tag: 'logo',

                      child: Container(

                        height: 110,
                        width: 110,

                        decoration: BoxDecoration(

                          color: Colors.white,

                          shape: BoxShape.circle,

                          boxShadow: [

                            BoxShadow(
                              color: primaryColor
                                  .withOpacity(0.15),

                              blurRadius: 30,

                              offset:
                                  const Offset(0, 10),
                            ),
                          ],
                        ),

                        child: Padding(

                          padding:
                              const EdgeInsets.all(20),

                          child: Image.asset(
                            'assets/Logo Mediatama.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // =========================================
                    // TITLE
                    // =========================================
                    Text(

                      'InternTrack',

                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: textDark,
                        letterSpacing: -1.5,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(

                      'Monitoring Magang Jadi Lebih Mudah',

                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 48),

                    // =========================================
                    // LOGIN CARD
                    // =========================================
                    ClipRRect(

                      borderRadius:
                          BorderRadius.circular(35),

                      child: BackdropFilter(

                        filter: ImageFilter.blur(
                          sigmaX: 10,
                          sigmaY: 10,
                        ),

                        child: Container(

                          width: double.infinity,

                          padding:
                              const EdgeInsets.all(32),

                          decoration: BoxDecoration(

                            color: Colors.white
                                .withOpacity(0.7),

                            borderRadius:
                                BorderRadius.circular(35),

                            border: Border.all(
                              color: Colors.white
                                  .withOpacity(0.5),

                              width: 1.5,
                            ),

                            boxShadow: [

                              BoxShadow(
                                color: Colors.black
                                    .withOpacity(0.03),

                                blurRadius: 40,

                                offset:
                                    const Offset(0, 20),
                              ),
                            ],
                          ),

                          child: Column(

                            crossAxisAlignment:
                                CrossAxisAlignment.start,

                            children: [

                              // EMAIL
                              _buildInputLabel(
                                'Email Address',
                              ),

                              _buildCustomField(
                                controller:
                                    emailController,

                                hint:
                                    'nama@email.com',

                                icon:
                                    Icons.alternate_email_rounded,
                              ),

                              const SizedBox(height: 24),

                              // PASSWORD
                              _buildInputLabel(
                                'Password',
                              ),

                              _buildCustomField(

                                controller:
                                    passwordController,

                                hint: '••••••••',

                                icon:
                                    Icons.lock_person_outlined,

                                isPassword: true,

                                obscure:
                                    obscurePassword,

                                onToggle: () {

                                  setState(() {

                                    obscurePassword =
                                        !obscurePassword;
                                  });
                                },
                              ),

                              Align(

                                alignment:
                                    Alignment.centerRight,

                                child: TextButton(

                                  onPressed: () {},

                                  child: Text(

                                    'Lupa Sandi?',

                                    style: TextStyle(
                                      color:
                                          primaryColor,

                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // BUTTON LOGIN
                              _buildGradientButton(),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    const Text(

                      '© 2024 Mediatama System • v1.0',

                      style: TextStyle(
                        color: Colors.black26,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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
  Widget _buildBlob(
    double size,
    Color color,
  ) {

    return Container(

      width: size,
      height: size,

      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),

      child: BackdropFilter(

        filter: ImageFilter.blur(
          sigmaX: 50,
          sigmaY: 50,
        ),

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

      padding: const EdgeInsets.only(
        left: 4,
        bottom: 10,
      ),

      child: Text(

        label,

        style: TextStyle(
          color: textDark,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }

  // =========================================
  // CUSTOM FIELD
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

        color: Colors.white,

        borderRadius:
            BorderRadius.circular(18),

        boxShadow: [

          BoxShadow(
            color:
                Colors.black.withOpacity(0.02),

            blurRadius: 15,

            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: TextField(

        controller: controller,

        obscureText: obscure,

        style: TextStyle(
          color: textDark,
          fontWeight: FontWeight.w600,
        ),

        decoration: InputDecoration(

          prefixIcon: Icon(
            icon,
            color: primaryColor,
            size: 22,
          ),

          suffixIcon: isPassword

              ? IconButton(

                  icon: Icon(

                    obscure
                        ? Icons.visibility_off
                        : Icons.visibility,

                    color: Colors.grey,
                  ),

                  onPressed: onToggle,
                )

              : null,

          hintText: hint,

          hintStyle: const TextStyle(
            color: Colors.black26,
            fontWeight: FontWeight.w400,
          ),

          border: OutlineInputBorder(

            borderRadius:
                BorderRadius.circular(18),

            borderSide: BorderSide.none,
          ),

          contentPadding:
              const EdgeInsets.symmetric(
            vertical: 20,
          ),
        ),
      ),
    );
  }

  // =========================================
  // BUTTON LOGIN
  // =========================================
  Widget _buildGradientButton() {

    return Container(

      width: double.infinity,
      height: 60,

      decoration: BoxDecoration(

        borderRadius:
            BorderRadius.circular(20),

        gradient: LinearGradient(

          colors: [
            secondaryColor,
            primaryColor,
          ],

          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        boxShadow: [

          BoxShadow(
            color:
                primaryColor.withOpacity(0.3),

            blurRadius: 20,

            offset: const Offset(0, 10),
          ),
        ],
      ),

      child: ElevatedButton(

        onPressed:
            isLoading ? null : login,

        style: ElevatedButton.styleFrom(

          backgroundColor: Colors.transparent,

          shadowColor: Colors.transparent,

          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
        ),

        child: isLoading

            ? const CircularProgressIndicator(
                color: Colors.white,
              )

            : const Text(

                'MASUK KE DASHBOARD',

                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
      ),
    );
  }
}