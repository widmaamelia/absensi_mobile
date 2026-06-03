import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../config/api_config.dart';
import '../model/absen.dart';
import 'absen.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {

  // ================================
  // COLORS
  // ================================
  final Color primaryDark = const Color(0xFF0F172A);
  final Color primaryCard = const Color(0xFF1E293B);
  final Color bgColor = const Color(0xFFF8FAFC);

  // ================================
  // STATE
  // ================================
  bool isFetchingToday = true;

  AbsensiModel? absensiHariIni;

  String userName = '';

  int totalHadir = 0;
  int totalIzin = 0;
  int totalTerlambat = 0;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();

    _loadUserName();
    _fetchAbsensiHariIni();
    _fetchSummary();
  }

  // ================================
  // LOAD USER NAME
  // ================================
  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      userName = prefs.getString('user_name') ?? 'Magang';
    });
  }

  // ================================
  // FETCH ABSENSI TODAY
  // ================================
  Future<void> _fetchAbsensiHariIni() async {
    setState(() => isFetchingToday = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('auth_token') ?? '';

      final response = await http.get(
        Uri.parse(ApiConfig.todayAbsen),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['data'] != null) {
          setState(() {
            absensiHariIni = AbsensiModel.fromJson(data['data']);
          });
        }
      }
    } on TimeoutException {
      _showSnackbar(
        'Timeout',
        'Periksa koneksi internet Anda.',
        Colors.orange,
      );
    } on SocketException {
      _showSnackbar(
        'Offline',
        'Tidak ada koneksi jaringan.',
        Colors.red,
      );
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => isFetchingToday = false);
    }
  }

  // ================================
  // FETCH SUMMARY
  // ================================
  Future<void> _fetchSummary() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('auth_token') ?? '';

      final response = await http.get(
        Uri.parse(ApiConfig.summaryAbsen),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          totalHadir = data['hadir'] ?? 0;
          totalIzin = data['izin'] ?? 0;
          totalTerlambat = data['terlambat'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  // ================================
  // SNACKBAR
  // ================================
  void _showSnackbar(
    String title,
    String message,
    Color color,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================
  // NAVIGATE TO ABSEN PAGE
  // ================================
  void _goToAbsen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AbsenPage(),
      ),
    );

    _fetchAbsensiHariIni();
    _fetchSummary();
  }

  // ================================
  // HELPER
  // ================================
  bool get _sudahMasuk =>
      absensiHariIni?.sudahMasuk ?? false;

  bool get _sudahPulang =>
      absensiHariIni?.sudahPulang ?? false;

  String get _buttonLabel {
    if (_sudahPulang) {
      return 'ABSENSI SELESAI';
    }

    if (_sudahMasuk) {
      return 'ABSEN PULANG';
    }

    return 'ABSEN MASUK';
  }

  // ================================
  // BUILD
  // ================================
  @override
  Widget build(BuildContext context) {

    final today = DateFormat(
      'dd MMMM yyyy',
    ).format(DateTime.now());

    return Scaffold(
      backgroundColor: bgColor,

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _fetchAbsensiHariIni();
            await _fetchSummary();
          },

          child: SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(),

            padding: const EdgeInsets.all(20),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                // HEADER
                _buildHeader(),

                const SizedBox(height: 30),

                // GREETING
                _buildGreeting(),

                const SizedBox(height: 24),

                // ABSENSI CARD
                _buildAbsensiCard(today),

                const SizedBox(height: 30),

                // SUMMARY
                _buildSummarySection(),
              ],
            ),
          ),
        ),
      ),

      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ================================
  // HEADER
  // ================================
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,

      children: [

        Row(
          children: [

            Container(
              padding: const EdgeInsets.all(12),

              decoration: BoxDecoration(
                color: primaryDark,
                borderRadius:
                    BorderRadius.circular(16),
              ),

              child: const Icon(
                Icons.dashboard,
                color: Colors.white,
              ),
            ),

            const SizedBox(width: 14),

            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Text(
                  'InternTrack',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryDark,
                  ),
                ),

                Text(
                  'Monitoring Magang',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),

        const CircleAvatar(
          radius: 24,
          backgroundImage: NetworkImage(
            'https://i.pravatar.cc/150?img=11',
          ),
        ),
      ],
    );
  }

  // ================================
  // GREETING
  // ================================
  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [

        Text(
          'Halo $userName 👋',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: primaryDark,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Selamat datang kembali.',
          style: TextStyle(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // ================================
  // ABSENSI CARD
  // ================================
  Widget _buildAbsensiCard(String today) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(24),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),

        gradient: LinearGradient(
          colors: [
            primaryCard,
            primaryDark,
          ],
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Text(
            today,
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),

          const SizedBox(height: 20),

          isFetchingToday
              ? const Center(
                  child:
                      CircularProgressIndicator(
                    color: Colors.white,
                  ),
                )
              : Row(
                  children: [

                    Expanded(
                      child: _infoCard(
                        title: 'Masuk',
                        value: absensiHariIni
                                ?.jamMasuk
                                ?.substring(0, 5) ??
                            '--:--',
                        icon: Icons.login,
                        color: Colors.green,
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: _infoCard(
                        title: 'Pulang',
                        value: absensiHariIni
                                ?.jamPulang
                                ?.substring(0, 5) ??
                            '--:--',
                        icon: Icons.logout,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 56,

            child: ElevatedButton(
              onPressed:
                  _sudahPulang ? null : _goToAbsen,

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
              ),

              child: Text(
                _buttonLabel,
                style: TextStyle(
                  color: primaryDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================
  // SUMMARY
  // ================================
  Widget _buildSummarySection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [

        Text(
          'Ringkasan Bulan Ini',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryDark,
          ),
        ),

        const SizedBox(height: 18),

        Row(
          children: [

            Expanded(
              child: _summaryCard(
                title: 'Hadir',
                value: totalHadir.toString(),
                icon: Icons.check_circle,
                color: Colors.green,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: _summaryCard(
                title: 'Izin',
                value: totalIzin.toString(),
                icon: Icons.assignment,
                color: Colors.orange,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: _summaryCard(
                title: 'Telat',
                value: totalTerlambat.toString(),
                icon: Icons.timer,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ================================
  // BOTTOM NAV
  // ================================
  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,

      selectedItemColor: primaryDark,

      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });

        if (index == 2) {
          _goToAbsen();
        }
      },

      items: const [

        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.assignment),
          label: 'Tugas',
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'Riwayat',
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profil',
        ),
      ],
    );
  }

  // ================================
  // INFO CARD
  // ================================
  Widget _infoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {

    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Icon(icon, color: color),

          const SizedBox(height: 12),

          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  // ================================
  // SUMMARY CARD
  // ================================
  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {

    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
      ),

      child: Column(
        children: [

          Icon(icon, color: color),

          const SizedBox(height: 12),

          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primaryDark,
            ),
          ),

          Text(title),
        ],
      ),
    );
  }
}