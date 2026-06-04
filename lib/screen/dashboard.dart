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
import 'tugas.dart';
import 'logbook.dart';
import 'profil.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // ================================
  // COLORS (Modern Tailwind Palette)
  // ================================
  final Color primaryDark = const Color.fromARGB(255, 0, 16, 52); // Slate 900
  final Color primaryCard = const Color.fromARGB(255, 25, 42, 68); // Slate 800
  final Color bgColor = const Color.fromARGB(255, 233, 244, 255); // Slate 50
  final Color accentBlue = const Color(0xFF3B82F6); // Blue 500

  // ================================
  // STATE (Logic tidak disentuh!)
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
      final response = await http
          .get(
            Uri.parse(ApiConfig.todayAbsen),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          setState(() {
            absensiHariIni = AbsensiModel.fromJson(data['data']);
          });
        }
      }
    } on TimeoutException {
      _showSnackbar('Timeout', 'Periksa koneksi internet Anda.', Colors.orange);
    } on SocketException {
      _showSnackbar('Offline', 'Tidak ada koneksi jaringan.', Colors.red);
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
      final response = await http
          .get(
            Uri.parse(ApiConfig.summaryAbsen),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

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
  void _showSnackbar(String title, String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
            Text(message, style: const TextStyle(color: Colors.white)),
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
      MaterialPageRoute(builder: (_) => const AbsenPage()),
    );
    _fetchAbsensiHariIni();
    _fetchSummary();
  }

  // ================================
  // HELPER
  // ================================
  bool get _sudahMasuk => absensiHariIni?.sudahMasuk ?? false;
  bool get _sudahPulang => absensiHariIni?.sudahPulang ?? false;
  String get _buttonLabel {
    if (_sudahPulang) return 'ABSENSI SELESAI';
    if (_sudahMasuk) return 'ABSEN PULANG';
    return 'ABSEN MASUK';
  }

  // ================================
  // BUILD
  // ================================
  @override
  Widget build(BuildContext context) {
    final today = (absensiHariIni?.tanggal != null && absensiHariIni!.tanggal!.isNotEmpty)
      ? DateFormat('dd MMMM yyyy').format(DateTime.parse(absensiHariIni!.tanggal!))
      : DateFormat('dd MMMM yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: accentBlue,
          onRefresh: () async {
            await _fetchAbsensiHariIni();
            await _fetchSummary();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FadeInSlide(delay: 0, child: _buildHeader()),
                const SizedBox(height: 10),
                _FadeInSlide(delay: 100, child: _buildGreeting()),
                const SizedBox(height: 28),
                _FadeInSlide(delay: 200, child: _buildAbsensiCard(today)),
                const SizedBox(height: 36),
                _FadeInSlide(delay: 300, child: _buildSummarySection()),
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start, // 🔥 Tambahkan ini agar ditarik sejajar ke atas
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            // 🔥 SizedBox yang ada di atas teks 'Halo' dihapus agar tidak mendorong teks ke bawah
            Text(
              'Halo $userName',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: primaryDark,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Siap Produktif hari ini?',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              'Jangan lupa absen hari ini ya. 😊',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
        
            
  //           Container(
  // // padding: const EdgeInsets.all(12),
  // // decoration: BoxDecoration(
  // //   color: Colors.blue, // 🔥 Gradien dihapus, diganti jadi warna putih solid
  // //   borderRadius: BorderRadius.circular(16),
  // //   boxShadow: [
  // //     BoxShadow(
  // //       color: bgColor.withOpacity(0.2), 
  // //       blurRadius: 8,
  // //       offset: const Offset(0, 4),
  // //     ),
  // //   ],
  // // ),
  // // child: 
  // // Image.asset( 
  // //   'assets/ogo.jpg',
  // //   width: 25,
  // //   height: 25,
  // //             ),
  //           ),
            // const SizedBox(width: 16),
            // Column(
            //   crossAxisAlignment: CrossAxisAlignment.start,
            //   children: [
            //     Text(
            //       'SIMAGANG',
            //       style: TextStyle(
            //         fontSize: 20,
            //         fontWeight: FontWeight.w800,
            //         color: primaryDark,
            //         letterSpacing: -0.5,
            //       ),
            //     ),
            //     Text(
            //       'Monitoring Magang',
            //       style: TextStyle(
            //         color: Colors.grey.shade500,
            //         fontSize: 13,
            //         fontWeight: FontWeight.w500,
            //       ),
            //     ),
            //   ],
            // ),
          ],
        ),
        // Container(
        //   decoration: BoxDecoration(
        //     shape: BoxShape.circle,
        //     border: Border.all(color: Colors.white, width: 3),
        //     boxShadow: [
        //       BoxShadow(
        //         color: Colors.black.withOpacity(0.1),
        //         blurRadius: 10,
        //         offset: const Offset(0, 4),
        //       ),
        //     ],
        //   ),
        //   child: const CircleAvatar(
        //     radius: 24,
        //     backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
        //   ),
        // ),
        GestureDetector(
          onTap: () {
            // Animasi meluncur ke halaman Profil
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(builder: (context) => const ProfilPage()),
            // );

            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilPage()),
            ).then((_) {
              // 🔥 JURUS RAHASIA: Fungsi ini akan otomatis berjalan SETELAH
              // halaman profil ditutup dan kembali ke Dashboard.

              _loadUserName();
              // (Catatan: Ganti "_loadUserData()" dengan nama fungsi yang biasa
              // kamu pakai di dashboard.dart untuk mengambil nama dari SharedPreferences.
              // Kalau namanya getUserData(), ya tulis getUserData() ).
            });
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color.fromARGB(255, 48, 126, 199),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            // child: const CircleAvatar(
            //   radius: 24,
            //   backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
            // ),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white,
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'Z',
                style: const TextStyle(
                  color: Color.fromARGB(255, 53, 146, 228),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      // children: [
      //   Text(
      //     'Halo $userName',
      //     style: TextStyle(
      //       fontSize: 28,
      //       fontWeight: FontWeight.w800,
      //       color: primaryDark,
      //       letterSpacing: -0.5,
      //     ),
      //   ),
      //   const SizedBox(height: 6),
      //   Text(
      //     'Siap produktif hari ini? Jangan lupa absen ya.',
      //     style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
      //   ),
      // ],
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
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryCard, primaryDark],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text(
      'Status Kehadiran',
      style: TextStyle(
        color: Colors.white.withOpacity(0.9),
        fontSize: 14, // 🔥 Font diperkecil dari 16 menjadi 14
        fontWeight: FontWeight.w600,
      ),
    ),
    Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8, // 🔥 Padding kiri-kanan diperkecil dari 12 menjadi 8
        vertical: 4,   // 🔥 Padding atas-bawah diperkecil dari 6 menjadi 4
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        today,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 10, // 🔥 Font tanggal diperkecil dari 12 menjadi 10
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  ],
),
          const SizedBox(height: 16), // 🔥 Jarak di atas kotak diperkecil dari 24 ke 16
          isFetchingToday
              ? const SizedBox(
                  height: 70, // 🔥 Tinggi loading indicator diperkecil dari 90 ke 70
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                )
              : Row(
                  children: [
                    Expanded(
                      child: _infoCard(
                        title: 'Masuk',
                        value:
                            absensiHariIni?.jamMasuk?.substring(0, 5) ??
                            '--:--',
                        icon: Icons.login_rounded,
                        color: const Color(0xFF10B981), // Tailwind Emerald 500
                      ),
                    ),
                    const SizedBox(width: 20), // 🔥 Jarak antar kotak diperkecil dari 16 ke 12
                    Expanded(
                      child: _infoCard(
                        title: 'Pulang',
                        value:
                            absensiHariIni?.jamPulang?.substring(0, 5) ??
                            '--:--',
                        icon: Icons.logout_rounded,
                        color: const Color(0xFFEF4444), // Tailwind Red 500
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 20), // 🔥 Jarak sebelum tombol absen diperkecil dari 28 ke 20
          SizedBox(
            width: double.infinity,
            height: 48, // 🔥 Tinggi tombol diperkecil dari 56 ke 48
            child: ElevatedButton(
              onPressed: _sudahPulang ? null : _goToAbsen,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentBlue,
                disabledBackgroundColor: Colors.white.withOpacity(0.1),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // 🔥 Sudut tombol sedikit dipertajam dari 16 ke 12
                ),
              ),
              child: Text(
                _buttonLabel,
                style: TextStyle(
                  color: _sudahPulang
                      ? const Color.fromARGB(162, 150, 252, 194)
                      : const Color.fromARGB(255, 255, 255, 255), // 🔥 Warna diubah jadi putih terang agar lebih kontras
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  fontSize: 13, // 🔥 Font tombol diperkecil dari 15 ke 13
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ringkasan Bulan Ini',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryDark,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                title: 'Hadir',
                value: totalHadir.toString(),
                icon: Icons.check_circle_rounded,
                color: const Color.fromARGB(255, 34, 110, 192),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _summaryCard(
                title: 'Izin',
                value: totalIzin.toString(),
                icon: Icons.assignment_rounded,
                color: const Color.fromARGB(255, 34, 110, 192),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _summaryCard(
                title: 'Telat',
                value: totalTerlambat.toString(),
                icon: Icons.timer_rounded,
                color: const Color.fromARGB(255, 34, 110, 192),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ================================
  // BOTTOM NAV (FIXED BUG TEKS HILANG)
  // ================================
  // ================================
  // BOTTOM NAV (UPDATED: LOGBOOK)
  // ================================
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: Colors.white,
        selectedItemColor: primaryDark,
        unselectedItemColor: Colors.grey.shade400,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });

          // Index 1: Tugas
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TugasPage()),
            );
          }
          // Index 2: Logbook
          else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LogbookPage()),
            ); // Kita buat filenya di bawah
          }
          // Index 3: Riwayat
          // else if (index == 3) {
          //   _goToAbsen();
          // }
        },
        items: const [
  BottomNavigationBarItem(
    icon: Icon(
      Icons.home_rounded,
      color: Color.fromARGB(255, 4, 54, 108),
    ),
    label: 'Home',
  ),
  BottomNavigationBarItem(
    icon: Icon(
      Icons.assignment_outlined,
      color: Color.fromARGB(255, 4, 54, 108),
    ),
    label: 'Tugas',
  ),
  BottomNavigationBarItem(
    icon: Icon(
      Icons.menu_book_rounded,
      color: Color.fromARGB(255, 4, 54, 108),
    ),
    label: 'Logbook',
  ),
  // BottomNavigationBarItem(
  //   icon: Icon(
  //     Icons.history_rounded,
  //     color: Color.fromARGB(255, 4, 54, 108),
  //   ),
  //   label: 'Riwayat',
  // ),
],
      ),
    );
  }

  // ================================
  // INFO CARD (Glassmorphism Effect)
  // ================================
  Widget _infoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? badge,
    Color? badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
              letterSpacing: 0.5,
            ),
          ),
          if (badge != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (badgeColor ?? Colors.white).withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  color: badgeColor ?? Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ================================
  // SUMMARY CARD (Tailwind Shadow Card)
  // ================================
  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      // 🔥 1. Padding atas-bawah dikurangi dari 20 menjadi 12
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // Sedikit disesuaikan agar tidak terlalu membulat
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // 🔥 2. WAJIB DITAMBAHKAN agar tinggi Column mengikuti isinya saja
        children: [
          Container(
            padding: const EdgeInsets.all(8), // 🔥 3. Padding ikon dikurangi dari 10 ke 8
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20), // 🔥 4. Ukuran ikon diperkecil dari 24 ke 20
          ),
          const SizedBox(height: 8), // 🔥 5. Jarak ke angka diperkecil dari 14 ke 8
          Text(
            value,
            style: TextStyle(
              fontSize: 20, // 🔥 6. Ukuran angka diperkecil dari 26 ke 20
              fontWeight: FontWeight.w800,
              color: primaryDark,
            ),
          ),
          const SizedBox(height: 2), // 🔥 7. Jarak ke tulisan diperkecil dari 4 ke 2
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
              fontSize: 12, // 🔥 8. Ukuran teks diperkecil dari 13 ke 11
            ),
          ),
        ],
      ),
    );
  }
}

// ================================
// ANIMATION HELPER WIDGET
// ================================
class _FadeInSlide extends StatefulWidget {
  final Widget child;
  final int delay;

  const _FadeInSlide({required this.child, required this.delay});

  @override
  State<_FadeInSlide> createState() => _FadeInSlideState();
}

class _FadeInSlideState extends State<_FadeInSlide> {
  bool _show = false;

  @override
  void initState() {
    super.initState();
    // Memastikan animasi hanya dipanggil 1x saat widget pertama kali dimuat
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        setState(() {
          _show = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: _show ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: widget.child,
          ),
        );
      },
    );
  }
}
