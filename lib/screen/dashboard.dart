import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../Model/absen.dart';
import 'absen.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // ── Warna ──────────────────────────────────────────────
  final Color primaryDark  = const Color(0xFF0F172A);
  final Color primaryCard  = const Color(0xFF1E293B);
  final Color bgColor      = const Color(0xFFF8FAFC);

  // ── State ──────────────────────────────────────────────
  bool isFetchingToday = true;
  AbsensiModel? absensiHariIni;
  String userName = '';
  int totalHadir     = 0;
  int totalIzin      = 0;
  int totalTerlambat = 0;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _fetchAbsensiHariIni();
    _fetchSummary();
  }

  // ── Load nama user dari SharedPreferences ──────────────
  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('user_name') ?? 'Magang';
    });
  }

  // ── Fetch absensi hari ini ─────────────────────────────
  Future<void> _fetchAbsensiHariIni() async {
    setState(() => isFetchingToday = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/absen/today'),
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
      _showSnackbar('Timeout', 'Periksa koneksi Anda.', Colors.orange);
    } on SocketException {
      _showSnackbar('Offline', 'Tidak ada koneksi jaringan.', Colors.red);
    } catch (_) {
      // Belum ada absen hari ini
    } finally {
      setState(() => isFetchingToday = false);
    }
  }

  // ── Fetch ringkasan bulan ini ──────────────────────────
  Future<void> _fetchSummary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/absen/summary'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          totalHadir     = data['hadir']     ?? 0;
          totalIzin      = data['izin']      ?? 0;
          totalTerlambat = data['terlambat'] ?? 0;
        });
      }
    } catch (_) {}
  }

  // ── Snackbar helper ────────────────────────────────────
  void _showSnackbar(String title, String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white)),
            Text(message, style: const TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Navigasi ke AbsenPage ──────────────────────────────
  void _goToAbsen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AbsenPage()),
    );
    // Refresh data setelah kembali dari AbsenPage
    _fetchAbsensiHariIni();
    _fetchSummary();
  }

  // ── Helpers ────────────────────────────────────────────
  bool get _sudahMasuk  => absensiHariIni?.sudahMasuk  ?? false;
  bool get _sudahPulang => absensiHariIni?.sudahPulang ?? false;

  String get _buttonLabel {
    if (_sudahPulang) return 'ABSENSI SELESAI';
    if (_sudahMasuk)  return 'ABSEN PULANG';
    return 'ABSEN MASUK';
  }

  IconData get _buttonIcon {
    if (_sudahPulang) return Icons.check_circle;
    if (_sudahMasuk)  return Icons.logout;
    return Icons.access_time;
  }

  Color get _statusColor {
    switch (absensiHariIni?.statusKedatangan) {
      case 'Tepat Waktu': return Colors.green;
      case 'Terlambat':   return Colors.red;
      case 'Izin':        return Colors.blue;
      case 'Sakit':       return Colors.orange;
      default:            return Colors.grey;
    }
  }

  // ── BUILD ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final today = DateFormat('dd MMMM yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _fetchAbsensiHariIni();
            await _fetchSummary();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 30),
                _buildGreeting(),
                const SizedBox(height: 24),
                _buildAbsensiCard(today),
                const SizedBox(height: 30),
                _buildSummarySection(),
                const SizedBox(height: 30),
                _buildTaskSection(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Header ─────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryDark,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.dashboard, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('InternTrack',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryDark,
                    )),
                Text('Monitoring Magang',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              ],
            ),
          ],
        ),
        const CircleAvatar(
          radius: 24,
          backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
        ),
      ],
    );
  }

  // ── Greeting ───────────────────────────────────────────
  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
          'Selamat datang kembali,\nsemoga harimu menyenangkan.',
          style: TextStyle(color: Colors.grey.shade600, height: 1.5),
        ),
      ],
    );
  }

  // ── Card Absensi ───────────────────────────────────────
  Widget _buildAbsensiCard(String today) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [primaryCard, primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tanggal + ikon fingerprint
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(today,
                      style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  const Text('Status Kehadiran',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      )),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.fingerprint, color: Colors.white, size: 34),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Badge status kedatangan
          if (absensiHariIni?.statusKedatangan != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _statusColor.withOpacity(0.4)),
              ),
              child: Text(
                absensiHariIni!.statusKedatangan!,
                style: TextStyle(
                  color: _statusColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),

          // Jam masuk & pulang
          isFetchingToday
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: CircularProgressIndicator(color: Colors.white54),
                  ),
                )
              : Row(
                  children: [
                    Expanded(
                      child: _infoCard(
                        title: 'Masuk',
                        value: absensiHariIni?.jamMasuk?.substring(0, 5) ?? '--:--',
                        icon: Icons.login,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _infoCard(
                        title: 'Pulang',
                        value: absensiHariIni?.jamPulang?.substring(0, 5) ?? '--:--',
                        icon: Icons.logout,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),

          const SizedBox(height: 24),

          // Tombol absen
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _sudahPulang ? null : _goToAbsen,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                disabledBackgroundColor: Colors.white24,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: Icon(_buttonIcon, color: _sudahPulang ? Colors.white54 : primaryDark),
              label: Text(
                _buttonLabel,
                style: TextStyle(
                  color: _sudahPulang ? Colors.white54 : primaryDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Ringkasan ──────────────────────────────────────────
  Widget _buildSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ringkasan Bulan Ini',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryDark,
            )),
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

  // ── Tugas ──────────────────────────────────────────────
  Widget _buildTaskSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tugas Hari Ini',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryDark,
            )),
        const SizedBox(height: 18),
        _taskCard(
          title: 'Membuat UI Dashboard Flutter',
          subtitle:
              'Selesaikan tampilan dashboard modern untuk aplikasi monitoring magang.',
          deadline: 'Deadline Besok',
        ),
        const SizedBox(height: 18),
        _taskCard(
          title: 'Integrasi API Laravel',
          subtitle:
              'Hubungkan fitur absensi ke backend menggunakan Sanctum.',
          deadline: 'Deadline Jumat',
        ),
      ],
    );
  }

  // ── Bottom Nav ─────────────────────────────────────────
  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      selectedItemColor: primaryDark,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        setState(() => _currentIndex = index);
        if (index == 2) _goToAbsen(); // Tab Riwayat → AbsenPage
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Tugas'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      ],
    );
  }

  // ── Info Card (dalam card absensi) ─────────────────────
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
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              )),
        ],
      ),
    );
  }

  // ── Summary Card ───────────────────────────────────────
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
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 14),
          Text(value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryDark,
              )),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  // ── Task Card ──────────────────────────────────────────
  Widget _taskCard({
    required String title,
    required String subtitle,
    required String deadline,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.design_services, color: Color(0xFF2563EB)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: primaryDark,
                        )),
                    const SizedBox(height: 4),
                    Text(deadline,
                        style: TextStyle(
                          color: Colors.red.shade400,
                          fontSize: 12,
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(subtitle,
              style: TextStyle(color: Colors.grey.shade600, height: 1.5)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Buka Tugas',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  )),
            ),
          ),
        ],
      ),
    );
  }
}