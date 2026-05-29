import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Model/absen.dart';
import '../screen/absen_map_widget.dart';

class AbsenPage extends StatefulWidget {
  const AbsenPage({super.key});

  @override
  State<AbsenPage> createState() => _AbsenPageState();
}

class _AbsenPageState extends State<AbsenPage> {
  // ── Base URL ───────────────────────────────────────────
  static const String _baseUrl = 'http://172.31.179.234:8000/api';

  // ── Koordinat kantor ───────────────────────────────────
  static const double _officeLat    = -0.9526046972684186;
  static const double _officeLng    = 100.38929852527497;
  static const double _officeRadius = 50;

  // ── Warna ──────────────────────────────────────────────
  final Color primaryColor   = const Color(0xFF007AFF);
  final Color secondaryColor = const Color(0xFF00D2FF);
  final Color textDark       = const Color(0xFF1D1D1F);

  // ── State ──────────────────────────────────────────────
  bool isLoading       = false;
  bool isFetchingToday = true;
  String statusKehadiran = 'Hadir';
  AbsensiModel? absensiHariIni;
  Position? currentPosition;

  LatLng? _posisiMasuk;
  LatLng? _posisiPulang;

  final List<String> statusOptions = ['Hadir', 'Izin', 'Sakit'];

  @override
  void initState() {
    super.initState();
    _fetchAbsensiHariIni();
  }

  // ── Fetch absensi hari ini ─────────────────────────────
  Future<void> _fetchAbsensiHariIni() async {
    setState(() => isFetchingToday = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final response = await http.get(
        Uri.parse('$_baseUrl/absen/today'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          final absensi = AbsensiModel.fromJson(data['data']);
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
      // Belum ada absen hari ini
    } finally {
      setState(() => isFetchingToday = false);
    }
  }

  // ── Ambil lokasi dengan akurasi terbaik + timeout ──────
  Future<Position?> _getLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackbar('GPS Mati', 'Aktifkan layanan lokasi untuk absensi.', Colors.red);
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackbar('Izin Ditolak', 'Izin lokasi diperlukan untuk absensi.', Colors.red);
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnackbar(
        'Izin Ditolak Permanen',
        'Aktifkan izin lokasi di pengaturan aplikasi.',
        Colors.red,
      );
      return null;
    }

    try {
      _showSnackbar('Info', 'Mendapatkan lokasi GPS...', Colors.blue);

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () async {
          // Fallback ke last known position atau medium accuracy
          final last = await Geolocator.getLastKnownPosition();
          if (last != null) return last;
          return await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
          );
        },
      );

      if (position.accuracy > 30) {
        _showSnackbar(
          'Peringatan',
          'Akurasi GPS rendah (${position.accuracy.toStringAsFixed(0)} m). '
          'Coba di tempat terbuka.',
          Colors.orange,
        );
      }

      return position;
    } catch (e) {
      _showSnackbar('Error', 'Gagal mendapatkan lokasi.', Colors.red);
      return null;
    }
  }

  // ── Submit absen ───────────────────────────────────────
  Future<void> _submitAbsen() async {
    setState(() => isLoading = true);

    try {
      final position = await _getLocation();
      if (position == null) return;

      setState(() => currentPosition = position);

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final response = await http.post(
        Uri.parse('$_baseUrl/absen'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Bearer $token',
        },
        body: {
          'latitude': position.latitude.toString(),
          'longitude': position.longitude.toString(),
          'status_kehadiran': statusKehadiran,
        },
      );

      if (!mounted) return;

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        final absensi = AbsensiModel.fromJson(data['data']);
        setState(() {
          absensiHariIni = absensi;

          if (absensi.latitudeMasuk != null && absensi.longitudeMasuk != null) {
            _posisiMasuk = LatLng(absensi.latitudeMasuk!, absensi.longitudeMasuk!);
          }
          if (absensi.latitudePulang != null && absensi.longitudePulang != null) {
            _posisiPulang = LatLng(absensi.latitudePulang!, absensi.longitudePulang!);
          }
        });

        final String msg = data['keterlambatan'] != null
            ? '${data['message']}\n⚠️ ${data['keterlambatan']}'
            : data['message'];

        _showSnackbar('Berhasil', msg, Colors.green);
      } else {
        _showSnackbar('Gagal', data['message'] ?? 'Terjadi kesalahan.', Colors.red);
      }
    } catch (e) {
      _showSnackbar('Error', e.toString(), Colors.red);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSnackbar(String title, String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            Text(message, style: const TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────
  bool get _sudahMasuk  => absensiHariIni?.sudahMasuk  ?? false;
  bool get _sudahPulang => absensiHariIni?.sudahPulang ?? false;

  String get _buttonLabel {
    if (_sudahPulang) return 'Absensi Selesai';
    if (_sudahMasuk)  return 'Absen Pulang';
    return 'Absen Masuk';
  }

  bool get _buttonEnabled => !_sudahPulang && !isLoading;

  String _formattedToday() {
    final now = DateTime.now();
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  // ── BUILD ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(top: -100, right: -50,  child: _buildBlob(300, const Color(0xFFE0F2FE))),
          Positioned(bottom: -50, left: -50, child: _buildBlob(250, const Color(0xFFF0F9FF))),
          Positioned(top: 200,   left: -80,  child: _buildBlob(200, const Color(0xFFEEF2FF))),

          SafeArea(
            child: isFetchingToday
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 24),
                        _buildStatusCard(),
                        const SizedBox(height: 16),
                        _buildStatusKehadiranPicker(),
                        const SizedBox(height: 16),
                        _buildLocationCard(),
                        const SizedBox(height: 16),

                        if (_posisiMasuk != null) ...[
                          _buildHistoryMapCard(
                            label: 'Lokasi Absen Masuk',
                            time: absensiHariIni?.jamMasuk?.substring(0, 5),
                            userLatLng: _posisiMasuk!,
                            color: Colors.green,
                            icon: Icons.login_rounded,
                          ),
                          const SizedBox(height: 16),
                        ],

                        if (_posisiPulang != null) ...[
                          _buildHistoryMapCard(
                            label: 'Lokasi Absen Pulang',
                            time: absensiHariIni?.jamPulang?.substring(0, 5),
                            userLatLng: _posisiPulang!,
                            color: Colors.orange,
                            icon: Icons.logout_rounded,
                          ),
                          const SizedBox(height: 16),
                        ],

                        _buildSubmitButton(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Image.asset('assets/Logo Mediatama.png', fit: BoxFit.contain),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'InternTrack',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: textDark,
                letterSpacing: -0.5,
              ),
            ),
            const Text(
              'Sistem Absensi',
              style: TextStyle(fontSize: 12, color: Colors.black45),
            ),
          ],
        ),
      ],
    );
  }

  // ── Status Card ────────────────────────────────────────
  Widget _buildStatusCard() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, color: primaryColor, size: 18),
              const SizedBox(width: 8),
              Text(
                _formattedToday(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildTimeChip(
                  label: 'Jam Masuk',
                  value: absensiHariIni?.jamMasuk?.substring(0, 5) ?? '--:--',
                  icon: Icons.login_rounded,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeChip(
                  label: 'Jam Pulang',
                  value: absensiHariIni?.jamPulang?.substring(0, 5) ?? '--:--',
                  icon: Icons.logout_rounded,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          if (absensiHariIni?.statusKedatangan != null) ...[
            const SizedBox(height: 16),
            _buildStatusKedatanganBadge(absensiHariIni!.statusKedatangan!),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeChip({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 11, color: color.withOpacity(0.8))),
              Text(value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusKedatanganBadge(String status) {
    final map = {
      'Tepat Waktu': (Colors.green,  Icons.check_circle_rounded),
      'Terlambat':   (Colors.red,    Icons.warning_rounded),
      'Izin':        (Colors.blue,   Icons.info_rounded),
      'Sakit':       (Colors.orange, Icons.local_hospital_rounded),
    };
    final color = map[status]?.$1 ?? Colors.grey;
    final icon  = map[status]?.$2 ?? Icons.help_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            'Status: $status',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ── Picker Status Kehadiran ────────────────────────────
  Widget _buildStatusKehadiranPicker() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status Kehadiran',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textDark,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: statusOptions.map((status) {
              final isSelected = statusKehadiran == status;
              return Expanded(
                child: GestureDetector(
                  onTap: _buttonEnabled
                      ? () => setState(() => statusKehadiran = status)
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [secondaryColor, primaryColor],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected ? null : const Color(0xFFF1F1F1),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        status,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black54,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
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

  // ── Kartu Lokasi Live ──────────────────────────────────
  Widget _buildLocationCard() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.location_on_rounded, color: primaryColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lokasi Saat Ini',
                      style: TextStyle(
                        fontSize: 13,
                        color: textDark.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentPosition != null
                          ? '${currentPosition!.latitude.toStringAsFixed(6)}, '
                            '${currentPosition!.longitude.toStringAsFixed(6)}'
                          : 'Akan dideteksi saat absen',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textDark,
                      ),
                    ),
                    if (currentPosition != null)
                      Text(
                        'Akurasi: ${currentPosition!.accuracy.toStringAsFixed(1)} m',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ],
          ),

          if (currentPosition != null) ...[
            const SizedBox(height: 16),
            AbsenMapWidget(
              userLat: currentPosition!.latitude,
              userLng: currentPosition!.longitude,
              officeLat: _officeLat,
              officeLng: _officeLng,
              radiusMeters: _officeRadius,
            ),
            const SizedBox(height: 10),
            _buildDistanceBadge(
              LatLng(currentPosition!.latitude, currentPosition!.longitude),
            ),
          ],
        ],
      ),
    );
  }

  // ── Kartu Peta Riwayat ─────────────────────────────────
  Widget _buildHistoryMapCard({
    required String label,
    required String? time,
    required LatLng userLatLng,
    required Color color,
    required IconData icon,
  }) {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                    ),
                  ),
                  if (time != null)
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          AbsenMapWidget(
            userLat: userLatLng.latitude,
            userLng: userLatLng.longitude,
            officeLat: _officeLat,
            officeLng: _officeLng,
            radiusMeters: _officeRadius,
            userAccuracy: currentPosition!.accuracy,
          ),
          const SizedBox(height: 10),
          _buildDistanceBadge(userLatLng),
        ],
      ),
    );
  }

  // ── Badge Jarak ────────────────────────────────────────
  Widget _buildDistanceBadge(LatLng userLatLng) {
    final distance = const Distance().as(
      LengthUnit.Meter,
      userLatLng,
      LatLng(_officeLat, _officeLng),
    );
    final isInside = distance <= _officeRadius;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isInside ? Icons.check_circle_rounded : Icons.warning_rounded,
          color: isInside ? Colors.green : Colors.orange,
          size: 15,
        ),
        const SizedBox(width: 5),
        Text(
          isInside
              ? 'Dalam radius kantor (${distance.toStringAsFixed(0)} m)'
              : 'Di luar radius: ${distance.toStringAsFixed(0)} m dari kantor',
          style: TextStyle(
            fontSize: 12,
            color: isInside ? Colors.green : Colors.orange,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── Submit Button ──────────────────────────────────────
  Widget _buildSubmitButton() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: _buttonEnabled
            ? LinearGradient(
                colors: [secondaryColor, primaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: _buttonEnabled ? null : Colors.grey.shade300,
        boxShadow: _buttonEnabled
            ? [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ]
            : [],
      ),
      child: ElevatedButton(
        onPressed: _buttonEnabled ? _submitAbsen : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
            : Text(
                _buttonLabel.toUpperCase(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
      ),
    );
  }

  // ── Glass Card Helper ──────────────────────────────────
  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  // ── Background Blob ────────────────────────────────────
  Widget _buildBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}