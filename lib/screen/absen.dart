import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../Model/absen.dart';
import '../config/api_config.dart';
import '../screen/absen_map_widget.dart';

class AbsenPage extends StatefulWidget {
  const AbsenPage({super.key});

  @override
  State<AbsenPage> createState() => _AbsenPageState();
}

class _AbsenPageState extends State<AbsenPage>
    with SingleTickerProviderStateMixin {

  // ───────────────────────────────────────────────────────
  // KOORDINAT KANTOR
  // ───────────────────────────────────────────────────────

  static const double _officeLat  = -0.9274605313905109;
  static const double _officeLng  = 100.42972541512418;
  static const double _officeRadius = 1000;

  // ───────────────────────────────────────────────────────
  // DESIGN TOKENS  — "Slate + Indigo" refined-dark palette
  // ───────────────────────────────────────────────────────

  static const Color _bg          = Color(0xFF0F1117);
  static const Color _surface     = Color(0xFF1A1D27);
  static const Color _surfaceHigh = Color(0xFF22263A);
  static const Color _accent      = Color(0xFF6366F1); // indigo
  static const Color _accentSoft  = Color(0xFF818CF8);
  static const Color _accentGlow  = Color(0x336366F1);
  static const Color _textPri     = Color(0xFFEEF2FF);
  static const Color _textSec     = Color(0xFF94A3B8);
  static const Color _green       = Color(0xFF34D399);
  static const Color _amber       = Color(0xFFFBBF24);
  static const Color _red         = Color(0xFFF87171);
  static const Color _border      = Color(0xFF2D3148);

  // ───────────────────────────────────────────────────────
  // STATE
  // ───────────────────────────────────────────────────────

  bool      isLoading        = false;
  bool      isFetchingToday  = true;
  String    statusKehadiran  = 'Hadir';
  AbsensiModel? absensiHariIni;
  Position? currentPosition;
  LatLng?   _posisiMasuk;
  LatLng?   _posisiPulang;

  late AnimationController _animCtrl;
  late Animation<double>    _fadeAnim;
  late Animation<Offset>    _slideAnim;

  final List<Map<String, dynamic>> statusOptions = [
    {'label': 'Hadir',  'icon': Icons.check_circle_outline},
    {'label': 'Izin',   'icon': Icons.info_outline},
    {'label': 'Sakit',  'icon': Icons.medical_services_outlined},
  ];

  // ───────────────────────────────────────────────────────
  // LIFECYCLE
  // ───────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOut,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOut,
    ));

    _fetchAbsensiHariIni();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  // ───────────────────────────────────────────────────────
  // FETCH ABSEN HARI INI
  // ───────────────────────────────────────────────────────

  Future<void> _fetchAbsensiHariIni() async {
    setState(() => isFetchingToday = true);

    try {
      final prefs  = await SharedPreferences.getInstance();
      final token  = prefs.getString('auth_token') ?? '';

      final response = await http.get(
        Uri.parse(ApiConfig.todayAbsen),
        headers: ApiConfig.jsonHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['data'] != null) {
          var absensi = AbsensiModel.fromJson(data['data']);

          // Jika server tidak mengembalikan tanggal, gunakan tanggal perangkat
          if (absensi.tanggal == null || absensi.tanggal!.isEmpty) {
            final now = DateTime.now();
            final deviceDate = DateFormat('yyyy-MM-dd').format(now);
            absensi = absensi.copyWith(tanggal: deviceDate);
          }

          setState(() {
            absensiHariIni = absensi;

            if (absensi.latitudeMasuk != null && absensi.longitudeMasuk != null) {
              _posisiMasuk = LatLng(absensi.latitudeMasuk!, absensi.longitudeMasuk!);
            }
            if (absensi.latitudePulang != null && absensi.longitudePulang != null) {
              _posisiPulang = LatLng(absensi.latitudePulang!, absensi.longitudePulang!);
            }
          });
        }
      }
    } catch (_) {
    } finally {
      setState(() => isFetchingToday = false);
      _animCtrl.forward();
    }
  }

  // ───────────────────────────────────────────────────────
  // GET LOCATION
  // ───────────────────────────────────────────────────────

  Future<Position?> _getLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackbar('GPS Mati', 'Aktifkan layanan lokasi.', _red);
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackbar('Izin Ditolak', 'Izin lokasi diperlukan.', _red);
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnackbar('Izin Permanen', 'Aktifkan izin lokasi di setting.', _red);
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
    } catch (_) {
      _showSnackbar('Error', 'Gagal mendapatkan lokasi.', _red);
      return null;
    }
  }

  // ───────────────────────────────────────────────────────
  // SUBMIT ABSEN
  // ───────────────────────────────────────────────────────

  Future<void> _submitAbsen() async {
    HapticFeedback.mediumImpact();
    setState(() => isLoading = true);

    try {
      final position = await _getLocation();
      if (position == null) return;

      setState(() => currentPosition = position);

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final response = await http.post(
        Uri.parse(ApiConfig.absen),
        headers: ApiConfig.formHeaders(token: token),
        body: {
          'latitude':         position.latitude.toString(),
          'longitude':        position.longitude.toString(),
          'status_kehadiran': statusKehadiran,
        },
      );

      if (!mounted) return;

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        var absensi = AbsensiModel.fromJson(data['data']);

        // Pastikan kita menyimpan tanggal/jam berdasarkan waktu perangkat
        final now = DateTime.now();
        final deviceDate = DateFormat('yyyy-MM-dd').format(now);
        final deviceTime = DateFormat('HH:mm:ss').format(now);

        if (absensi.tanggal == null || absensi.tanggal!.isEmpty) {
          absensi = absensi.copyWith(tanggal: deviceDate);
        }
        if (absensi.jamMasuk == null || absensi.jamMasuk!.isEmpty) {
          absensi = absensi.copyWith(jamMasuk: deviceTime);
        }
        if (absensi.jamPulang == null || absensi.jamPulang!.isEmpty) {
          // Jangan overwrite jam pulang kecuali server mengembalikan kosong
          // (biasanya jam pulang dikirim setelah absen pulang)
          // absensi = absensi.copyWith(jamPulang: deviceTime);
        }

        setState(() {
          absensiHariIni = absensi;
          if (absensi.latitudeMasuk != null && absensi.longitudeMasuk != null) {
            _posisiMasuk = LatLng(absensi.latitudeMasuk!, absensi.longitudeMasuk!);
          }
          if (absensi.latitudePulang != null && absensi.longitudePulang != null) {
            _posisiPulang = LatLng(absensi.latitudePulang!, absensi.longitudePulang!);
          }
        });
        _showSnackbar('Berhasil', data['message'], _green);
      } else {
        _showSnackbar('Gagal', data['message'], _red);
      }
    } catch (e) {
      _showSnackbar('Error', e.toString(), _red);
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ───────────────────────────────────────────────────────
  // SNACKBAR
  // ───────────────────────────────────────────────────────

  void _showSnackbar(String title, String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _textPri,
                      fontSize: 13,
                    )),
                Text(message,
                    style: const TextStyle(
                      color: _textSec,
                      fontSize: 12,
                    )),
              ],
            ),
          ],
        ),
        backgroundColor: _surface,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withOpacity(0.4)),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────
  // HELPERS
  // ───────────────────────────────────────────────────────

  bool get _sudahMasuk  => absensiHariIni?.sudahMasuk  ?? false;
  bool get _sudahPulang => absensiHariIni?.sudahPulang ?? false;

  String get _buttonLabel {
    if (_sudahPulang) return 'Absensi Selesai';
    if (_sudahMasuk)  return 'Absen Pulang';
    return 'Absen Masuk';
  }

  bool get _buttonEnabled => !_sudahPulang && !isLoading;

  String _formattedToday() {
    // Prefer tanggal dari server/absensi yang bisa saja sudah berisi nilai.
    if (absensiHariIni?.tanggal != null && absensiHariIni!.tanggal!.isNotEmpty) {
      try {
        final dt = DateTime.parse(absensiHariIni!.tanggal!);
        const months = [
          'Januari','Februari','Maret','April','Mei','Juni',
          'Juli','Agustus','September','Oktober','November','Desember'
        ];
        const days = ['Senin','Selasa','Rabu','Kamis','Jumat','Sabtu','Minggu'];
        return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} ${dt.year}';
      } catch (_) {
        // fallback to device date below
      }
    }

    final now = DateTime.now();
    const months = [
      'Januari','Februari','Maret','April','Mei','Juni',
      'Juli','Agustus','September','Oktober','November','Desember'
    ];
    const days = ['Senin','Selasa','Rabu','Kamis','Jumat','Sabtu','Minggu'];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  Color get _statusBadgeColor {
    if (absensiHariIni?.isTerlambat == true) return _red;
    if (_sudahPulang) return _amber;
    if (_sudahMasuk)  return _green;
    return _textSec;
  }

  String get _statusBadgeText {
    if (absensiHariIni?.isTerlambat == true) return 'Terlambat';
    if (_sudahPulang) return 'Selesai';
    if (_sudahMasuk)  return 'Aktif';
    return 'Belum Absen';
  }

  // ───────────────────────────────────────────────────────
  // BUILD
  // ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(
          children: [
            // — ambient glow blobs —
            Positioned(
              top: -80, right: -60,
              child: _ambientBlob(280, _accent.withOpacity(0.18)),
            ),
            Positioned(
              bottom: 100, left: -80,
              child: _ambientBlob(240, _accentSoft.withOpacity(0.12)),
            ),
            Positioned(
              top: 320, left: -40,
              child: _ambientBlob(180, const Color(0xFF06B6D4).withOpacity(0.10)),
            ),

            SafeArea(
              child: isFetchingToday
                  ? const Center(
                      child: CircularProgressIndicator(color: _accent),
                    )
                  : FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: CustomScrollView(
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _buildTopBar(),
                                    const SizedBox(height: 28),
                                    _buildHeroCard(),
                                    const SizedBox(height: 16),
                                    _buildStatusKehadiranPicker(),
                                    const SizedBox(height: 16),
                                    _buildLocationCard(),
                                    const SizedBox(height: 24),
                                    _buildSubmitButton(),
                                    const SizedBox(height: 32),
                                  ],
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
      ),
    );
  }

  // ───────────────────────────────────────────────────────
  // TOP BAR  (back button + title)
  // ───────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Row(
      children: [
        // ── Back Button ──
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _surfaceHigh,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _textPri,
              size: 18,
            ),
          ),
        ),

        const SizedBox(width: 14),

        // ── Logo + Title ──
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: _accentGlow,
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Image.asset(
              'assets/Logo Mediatama.png',
              fit: BoxFit.contain,
            ),
          ),
        ),

        const SizedBox(width: 12),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'InternTrack',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _textPri,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              'Sistem Absensi',
              style: TextStyle(
                fontSize: 12,
                color: _textSec,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),

        const Spacer(),

        // ── Status badge ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _statusBadgeColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _statusBadgeColor.withOpacity(0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: _statusBadgeColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _statusBadgeText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _statusBadgeColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────
  // HERO CARD  (tanggal + jam masuk/pulang)
  // ───────────────────────────────────────────────────────

  Widget _buildHeroCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E2340), Color(0xFF161929)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(0.12),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // decorative circle top-right
          Positioned(
            top: -20, right: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _accent.withOpacity(0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 14, color: _textSec),
                    const SizedBox(width: 6),
                    Text(
                      _formattedToday(),
                      style: const TextStyle(
                        fontSize: 13,
                        color: _textSec,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(child: _buildTimeChip(
                      label: 'Jam Masuk',
                      value: absensiHariIni?.jamMasuk?.substring(0, 5) ?? '--:--',
                      icon:  Icons.login_rounded,
                      color: _green,
                      statusText: absensiHariIni?.isTerlambat == true ? _statusBadgeText : null,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTimeChip(
                      label: 'Jam Pulang',
                      value: absensiHariIni?.jamPulang?.substring(0, 5) ?? '--:--',
                      icon:  Icons.logout_rounded,
                      color: _amber,
                    )),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeChip({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    String? statusText,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 15),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -1,
            ),
          ),
          if (statusText != null && statusText.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────
  // STATUS KEHADIRAN PICKER
  // ───────────────────────────────────────────────────────

  Widget _buildStatusKehadiranPicker() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status Kehadiran',
            style: TextStyle(
              color: _textSec,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: statusOptions.map((opt) {
              final isSelected = statusKehadiran == opt['label'];
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => statusKehadiran = opt['label'] as String);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? _accent : _surfaceHigh,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? _accent : _border,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: _accent.withOpacity(0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          opt['icon'] as IconData,
                          size: 18,
                          color: isSelected ? Colors.white : _textSec,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          opt['label'] as String,
                          style: TextStyle(
                            color: isSelected ? Colors.white : _textSec,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────
  // LOCATION CARD
  // ───────────────────────────────────────────────────────

  Widget _buildLocationCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: _accent,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Lokasi Saat Ini',
                style: TextStyle(
                  color: _textSec,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),

          if (currentPosition != null) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AbsenMapWidget(
                userLat:      currentPosition!.latitude,
                userLng:      currentPosition!.longitude,
                officeLat:    _officeLat,
                officeLng:    _officeLng,
                radiusMeters: _officeRadius,
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: _surfaceHigh,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.location_searching_rounded,
                      color: _textSec, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Lokasi akan tampil setelah absen',
                    style: TextStyle(color: _textSec, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────
  // SUBMIT BUTTON
  // ───────────────────────────────────────────────────────

  Widget _buildSubmitButton() {
    final bool enabled = _buttonEnabled;

    return AnimatedOpacity(
      opacity: enabled ? 1.0 : 0.45,
      duration: const Duration(milliseconds: 250),
      child: GestureDetector(
        onTap: enabled ? _submitAbsen : null,
        child: Container(
          height: 62,
          decoration: BoxDecoration(
            gradient: enabled
                ? const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: enabled ? null : _surfaceHigh,
            borderRadius: BorderRadius.circular(20),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: _accent.withOpacity(0.45),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    )
                  ]
                : [],
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _sudahPulang
                            ? Icons.check_circle_rounded
                            : _sudahMasuk
                                ? Icons.logout_rounded
                                : Icons.login_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _buttonLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────
  // CARD WRAPPER
  // ───────────────────────────────────────────────────────

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  // ───────────────────────────────────────────────────────
  // AMBIENT BLOB
  // ───────────────────────────────────────────────────────

  Widget _ambientBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}