import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

// ═══════════════════════════════════════════════════════════
// MODEL
// ═══════════════════════════════════════════════════════════
class RiwayatPengajuan {
  final int id;
  final String statusKehadiran;
  final String keterangan;
  final String tanggal;
  final String statusApproval;
  final String? keteranganAdmin;

  const RiwayatPengajuan({
    required this.id,
    required this.statusKehadiran,
    required this.keterangan,
    required this.tanggal,
    required this.statusApproval,
    this.keteranganAdmin,
  });

  factory RiwayatPengajuan.fromJson(Map<String, dynamic> j) => RiwayatPengajuan(
        id:              j['id'],
        statusKehadiran: j['status_kehadiran']  ?? '',
        keterangan:      j['keterangan_pulang'] ?? '-',
        tanggal:         j['tanggal']           ?? '',
        statusApproval:  j['status_approval']   ?? 'pending',
        keteranganAdmin: j['keterangan_admin'],
      );
}

// ═══════════════════════════════════════════════════════════
// PAGE — Tampilan utama: Riwayat + FAB
// ═══════════════════════════════════════════════════════════
class PengajuanAbsenPage extends StatefulWidget {
  const PengajuanAbsenPage({super.key});

  @override
  State<PengajuanAbsenPage> createState() => _PengajuanAbsenPageState();
}

class _PengajuanAbsenPageState extends State<PengajuanAbsenPage> {
  // ── DESIGN TOKENS ──────────────────────────────────────
  static const Color _bg          = Color(0xFFF8FAFC);
  static const Color _surface     = Color(0xFFFFFFFF);
  static const Color _surfaceHigh = Color(0xFFF1F5F9);
  static const Color _accent      = Color.fromARGB(255, 19, 124, 205);
  static const Color _textPri     = Color(0xFF0F172A);
  static const Color _textSec     = Color(0xFF64748B);
  static const Color _green       = Color(0xFF10B981);
  static const Color _red         = Color(0xFFEF4444);
  static const Color _amber       = Color(0xFFF59E0B);
  static const Color _border      = Color(0xFFE2E8F0);

  // ── STATE RIWAYAT ──────────────────────────────────────
  List<RiwayatPengajuan> _riwayat        = [];
  bool                   _riwayatLoading = true;
  String?                _riwayatError;

  @override
  void initState() {
    super.initState();
    _fetchRiwayat();
  }

  // ═══════════════════════════════════════════════════════
  // FETCH — GET /api/absen/riwayat-pengajuan
  // ═══════════════════════════════════════════════════════
  Future<void> _fetchRiwayat() async {
    setState(() { _riwayatLoading = true; _riwayatError = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final res   = await http.get(
        Uri.parse(ApiConfig.riwayatPengajuanAbsen),
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      );
      if (!mounted) return;
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        final List list = data['data'] ?? [];
        setState(() {
          _riwayat        = list.map((e) => RiwayatPengajuan.fromJson(e)).toList();
          _riwayatLoading = false;
        });
      } else {
        setState(() {
          _riwayatError   = data['message'] ?? 'Gagal memuat riwayat.';
          _riwayatLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _riwayatError = 'Gagal menghubungi server.'; _riwayatLoading = false; });
    }
  }

  // ═══════════════════════════════════════════════════════
  // BUKA FORM — Bottom Sheet Pengajuan
  // ═══════════════════════════════════════════════════════
  void _bukaPengajuanSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context:        context,
      isScrollControlled: true,          // penting agar keyboard tidak nutup
      backgroundColor: Colors.transparent,
      builder: (_) => _PengajuanFormSheet(
        onSuccess: () {
          Navigator.pop(context);        // tutup sheet
          _fetchRiwayat();               // refresh list
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation:       0,
        foregroundColor: _textPri,
        title: const Text(
          'Pengajuan Izin / Sakit',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: _textPri),
        ),
        centerTitle: false,
        actions: [
          // Tombol refresh di AppBar
          IconButton(
            onPressed: _riwayatLoading ? null : _fetchRiwayat,
            icon: AnimatedOpacity(
              opacity:  _riwayatLoading ? 0.4 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.refresh_rounded, color: _accent),
            ),
          ),
        ],
      ),

      // ── FAB — Tombol Tambah Pengajuan ──────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed:       _bukaPengajuanSheet,
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        elevation:       3,
        icon:  const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'Buat Pengajuan',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),

      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    // Loading
    if (_riwayatLoading) {
      return const Center(child: CircularProgressIndicator(color: _accent, strokeWidth: 2.5));
    }

    // Error
    if (_riwayatError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:    const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color:        _surfaceHigh,
                  shape:        BoxShape.circle,
                  border:       Border.all(color: _border),
                ),
                child: const Icon(Icons.wifi_off_rounded, color: _textSec, size: 36),
              ),
              const SizedBox(height: 16),
              Text(_riwayatError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _textSec, fontSize: 14)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed:  _fetchRiwayat,
                icon:       const Icon(Icons.refresh_rounded, size: 18),
                label:      const Text('Coba Lagi'),
                style:      FilledButton.styleFrom(backgroundColor: _accent),
              ),
            ],
          ),
        ),
      );
    }

    // Empty
    if (_riwayat.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:    const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color:  _accent.withOpacity(0.08),
                  shape:  BoxShape.circle,
                ),
                child: const Icon(Icons.inbox_outlined, color: _accent, size: 40),
              ),
              const SizedBox(height: 16),
              const Text('Belum Ada Pengajuan',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: _textPri)),
              const SizedBox(height: 6),
              const Text(
                'Tap tombol "Buat Pengajuan" di bawah\nuntuk mengajukan izin atau sakit.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _textSec, fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    // List riwayat
    return RefreshIndicator(
      color:       _accent,
      onRefresh:   _fetchRiwayat,
      child: ListView.builder(
        padding:     const EdgeInsets.fromLTRB(16, 12, 16, 100), // 100 = ruang FAB
        itemCount:   _riwayat.length,
        itemBuilder: (_, i) => _RiwayatCard(item: _riwayat[i]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// RIWAYAT CARD — Widget terpisah agar lebih bersih
// ═══════════════════════════════════════════════════════════
class _RiwayatCard extends StatelessWidget {
  final RiwayatPengajuan item;
  const _RiwayatCard({required this.item});

  static const Color _surface     = Color(0xFFFFFFFF);
  static const Color _surfaceHigh = Color(0xFFF1F5F9);
  static const Color _accent      = Color.fromARGB(255, 19, 124, 205);
  static const Color _textPri     = Color(0xFF0F172A);
  static const Color _textSec     = Color(0xFF64748B);
  static const Color _green       = Color(0xFF10B981);
  static const Color _red         = Color(0xFFEF4444);
  static const Color _amber       = Color(0xFFF59E0B);
  static const Color _border      = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    // Status config
    late Color    sc;
    late IconData si;
    late String   sl;
    switch (item.statusApproval) {
      case 'approved': sc = _green; si = Icons.check_circle_outline_rounded; sl = 'Disetujui'; break;
      case 'rejected': sc = _red;   si = Icons.cancel_outlined;              sl = 'Ditolak';   break;
      default:         sc = _amber; si = Icons.access_time_rounded;          sl = 'Menunggu';
    }

    String fmt(String raw) {
      try { return DateFormat('dd MMM yyyy').format(DateTime.parse(raw)); }
      catch (_) { return raw; }
    }

    final jenisIcon = item.statusKehadiran == 'Sakit'
        ? Icons.medical_services_outlined
        : Icons.assignment_outlined;

    return Container(
      margin:     const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color:        _surface,
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Header ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding:    const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:        _accent.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(jenisIcon, color: _accent, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.statusKehadiran,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14, color: _textPri)),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 11, color: _textSec),
                          const SizedBox(width: 4),
                          Text(fmt(item.tanggal),
                              style: const TextStyle(fontSize: 12, color: _textSec)),
                        ],
                      ),
                    ],
                  ),
                ),

                // Chip status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color:        sc.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(si, size: 12, color: sc),
                      const SizedBox(width: 4),
                      Text(sl, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: sc)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Keterangan ───────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              width:   double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color:        _surfaceHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                item.keterangan.isEmpty ? '-' : item.keterangan,
                style:    const TextStyle(fontSize: 12, color: _textSec, height: 1.5),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // ── Catatan Admin ────────────────────────────
          if (item.keteranganAdmin != null && item.keteranganAdmin!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Container(
                width:   double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color:        sc.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border:       Border.all(color: sc.withOpacity(0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.admin_panel_settings_outlined, size: 13, color: sc),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(item.keteranganAdmin!,
                          style: TextStyle(fontSize: 12, color: sc, height: 1.5)),
                    ),
                  ],
                ),
              ),
            )
          else
            const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// FORM SHEET — Bottom sheet pengajuan izin/sakit
// ═══════════════════════════════════════════════════════════
class _PengajuanFormSheet extends StatefulWidget {
  final VoidCallback onSuccess;
  const _PengajuanFormSheet({required this.onSuccess});

  @override
  State<_PengajuanFormSheet> createState() => _PengajuanFormSheetState();
}

class _PengajuanFormSheetState extends State<_PengajuanFormSheet> {
  static const Color _surface     = Color(0xFFFFFFFF);
  static const Color _surfaceHigh = Color(0xFFF1F5F9);
  static const Color _accent      = Color.fromARGB(255, 19, 124, 205);
  static const Color _textPri     = Color(0xFF0F172A);
  static const Color _textSec     = Color(0xFF64748B);
  static const Color _green       = Color(0xFF10B981);
  static const Color _red         = Color(0xFFEF4444);
  static const Color _border      = Color(0xFFE2E8F0);

  String   statusKehadiran = 'Izin';
  final    TextEditingController _ketController = TextEditingController();
  XFile?   _lampiran;
  bool     isLoading = false;
  DateTime startDate = DateTime.now();
  DateTime endDate   = DateTime.now();

  final List<Map<String, dynamic>> statusOptions = [
    {'label': 'Izin',  'icon': Icons.assignment_outlined},
    {'label': 'Sakit', 'icon': Icons.medical_services_outlined},
  ];

  @override
  void dispose() {
    _ketController.dispose();
    super.dispose();
  }

  // ── SELECT DATE RANGE ───────────────────────────────────
  Future<void> _selectDateRange() async {
    HapticFeedback.lightImpact();
    final picked = await showDateRangePicker(
      context:          context,
      initialDateRange: DateTimeRange(start: startDate, end: endDate),
      firstDate:        DateTime.now(),
      lastDate:         DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _accent, onPrimary: Colors.white, onSurface: _textPri,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() { startDate = picked.start; endDate = picked.end; });
    }
  }

  // ── PICK IMAGE ──────────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
        source: source, imageQuality: 80, maxWidth: 1600);
    if (picked == null) return;
    if (await picked.length() > 2 * 1024 * 1024) {
      _snack('Ukuran Terlalu Besar', 'Lampiran maksimal 2MB.', _red);
      return;
    }
    final ext = picked.path.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png'].contains(ext)) {
      _snack('Format Tidak Didukung', 'Format harus JPG, JPEG, atau PNG.', _red);
      return;
    }
    setState(() => _lampiran = picked);
  }

  void _showImageSheet() {
    showModalBottomSheet(
      context:         context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color:        _surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top:   BorderSide(color: _border),
            left:  BorderSide(color: _border),
            right: BorderSide(color: _border),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(4)),
            )),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: _accent),
              title:   const Text('Ambil Foto'),
              onTap:   () { Navigator.pop(ctx); _pickImage(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: _accent),
              title:   const Text('Pilih dari Galeri'),
              onTap:   () { Navigator.pop(ctx); _pickImage(ImageSource.gallery); },
            ),
            if (_lampiran != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: _red),
                title:   const Text('Hapus Lampiran', style: TextStyle(color: _red)),
                onTap:   () { Navigator.pop(ctx); setState(() => _lampiran = null); },
              ),
          ],
        ),
      ),
    );
  }

  // ── SUBMIT ──────────────────────────────────────────────
  Future<void> _submit() async {
    final ket = _ketController.text.trim();
    if (ket.length < 10) {
      HapticFeedback.heavyImpact();
      _snack('Keterangan Tidak Valid', 'Keterangan minimal 10 karakter.', _red);
      return;
    }
    setState(() => isLoading = true);
    try {
      final prefs   = await SharedPreferences.getInstance();
      final token   = prefs.getString('auth_token') ?? '';
      final request = http.MultipartRequest('POST', Uri.parse(ApiConfig.pengajuanAbsen));
      request.headers.addAll({'Accept': 'application/json', 'Authorization': 'Bearer $token'});
      request.fields['status_kehadiran'] = statusKehadiran;
      request.fields['keterangan']       = ket;
      request.fields['tanggal_mulai']    = DateFormat('yyyy-MM-dd').format(startDate);
      request.fields['tanggal_selesai']  = DateFormat('yyyy-MM-dd').format(endDate);
      if (_lampiran != null) {
        request.files.add(await http.MultipartFile.fromPath('lampiran', _lampiran!.path));
      }
      final res  = await http.Response.fromStream(await request.send());
      if (!mounted) return;
      final data = jsonDecode(res.body);

      if (data['success'] == true) {
        _snack('Berhasil', data['message'], _green);
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) widget.onSuccess(); // tutup sheet + refresh
      } else {
        String msg = data['message'] ?? 'Terjadi kesalahan.';
        if (data['errors'] != null) {
          final e = data['errors'] as Map<String, dynamic>;
          final v = e[e.keys.first];
          if (v is List && v.isNotEmpty) msg = v.first.toString();
        }
        _snack('Gagal', msg, _red);
      }
    } catch (_) {
      _snack('Error', 'Gagal menghubungi server.', _red);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _snack(String title, String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Container(width: 4, height: 36,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 10),
          Expanded(child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: _textPri, fontSize: 13)),
              Text(msg,   style: const TextStyle(color: _textSec, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          )),
        ],
      ),
      backgroundColor: _surface,
      behavior:        SnackBarBehavior.floating,
      margin:          const EdgeInsets.all(16),
      padding:         const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side:         BorderSide(color: color.withOpacity(0.4)),
      ),
    ));
  }

  // ── BUILD SHEET ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom; // ikuti keyboard
    return Container(
      decoration: const BoxDecoration(
        color:        _surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top:   BorderSide(color: Color(0xFFE2E8F0)),
          left:  BorderSide(color: Color(0xFFE2E8F0)),
          right: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize:       MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(child: Container(
              width: 40, height: 4,
              margin:     const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(4)),
            )),

            // Judul sheet
            Row(
              children: [
                Container(
                  padding:    const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: _accent.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child:      const Icon(Icons.edit_note_rounded, color: _accent, size: 18),
                ),
                const SizedBox(width: 10),
                const Text('Buat Pengajuan',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _textPri)),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Hanya bisa diajukan jika belum ada data kehadiran pada tanggal tersebut.',
              style: TextStyle(fontSize: 11, color: _textSec, height: 1.4),
            ),
            const SizedBox(height: 20),

            // ── Jenis ─────────────────────────────────
            const Text('JENIS PENGAJUAN',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _textSec, letterSpacing: 0.8)),
            const SizedBox(height: 10),
            Row(
              children: statusOptions.map((opt) {
                final sel = statusKehadiran == opt['label'];
                return Expanded(
                  child: GestureDetector(
                    onTap: () { HapticFeedback.selectionClick(); setState(() => statusKehadiran = opt['label'] as String); },
                    child: AnimatedContainer(
                      duration:   const Duration(milliseconds: 180),
                      margin:     const EdgeInsets.only(right: 8),
                      padding:    const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color:        sel ? _accent : _surfaceHigh,
                        borderRadius: BorderRadius.circular(14),
                        border:       Border.all(color: sel ? _accent : _border),
                      ),
                      child: Column(
                        children: [
                          Icon(opt['icon'] as IconData, size: 18, color: sel ? Colors.white : _textSec),
                          const SizedBox(height: 4),
                          Text(opt['label'] as String,
                              style: TextStyle(color: sel ? Colors.white : _textSec,
                                  fontWeight: FontWeight.w700, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // ── Tanggal ───────────────────────────────
            const Text('DURASI TANGGAL',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _textSec, letterSpacing: 0.8)),
            const SizedBox(height: 10),
            InkWell(
              onTap:        _selectDateRange,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding:    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color:        _surfaceHigh,
                  borderRadius: BorderRadius.circular(14),
                  border:       Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_outlined, color: _accent, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        () {
                          final s = DateFormat('dd MMM yyyy').format(startDate);
                          final e = DateFormat('dd MMM yyyy').format(endDate);
                          return s == e ? s : '$s  s/d  $e';
                        }(),
                        style: const TextStyle(fontSize: 13, color: _textPri, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: _textSec, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Keterangan ────────────────────────────
            const Text('KETERANGAN ALASAN',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _textSec, letterSpacing: 0.8)),
            const SizedBox(height: 4),
            const Text('Minimal 10 karakter', style: TextStyle(fontSize: 11, color: _textSec)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color:        _surfaceHigh,
                borderRadius: BorderRadius.circular(14),
                border:       Border.all(color: _border),
              ),
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _ketController,
                maxLines:   4,
                style:      const TextStyle(fontSize: 13, color: _textPri, height: 1.6),
                decoration: const InputDecoration(
                  hintText:  'Contoh: Saya tidak dapat hadir karena demam tinggi...',
                  hintStyle: TextStyle(color: _textSec, fontSize: 13),
                  border:    InputBorder.none,
                  isDense:   true,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Lampiran ──────────────────────────────
            Row(
              children: [
                const Text('LAMPIRAN (OPSIONAL)',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _textSec, letterSpacing: 0.8)),
                const Spacer(),
                const Text('JPG/PNG, maks 2MB', style: TextStyle(fontSize: 10, color: _textSec)),
              ],
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showImageSheet,
              child: _lampiran == null
                  ? Container(
                      height:     72,
                      decoration: BoxDecoration(
                        color:        _surfaceHigh,
                        borderRadius: BorderRadius.circular(14),
                        border:       Border.all(color: _border),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, color: _textSec, size: 20),
                            SizedBox(width: 8),
                            Text('Tambah Lampiran', style: TextStyle(color: _textSec, fontSize: 12)),
                          ],
                        ),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        children: [
                          Image.file(File(_lampiran!.path),
                              width: double.infinity, height: 130, fit: BoxFit.cover),
                          Positioned(
                            top: 6, right: 6,
                            child: GestureDetector(
                              onTap: () => setState(() => _lampiran = null),
                              child: Container(
                                padding:    const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.55),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close_rounded, color: Colors.white, size: 15),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 24),

            // ── Tombol Kirim ──────────────────────────
            AnimatedOpacity(
              opacity:  isLoading ? 0.6 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: GestureDetector(
                onTap: isLoading ? null : _submit,
                child: Container(
                  height:     54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color.fromARGB(255, 22, 129, 206), Color(0xFF818CF8)],
                      begin:  Alignment.centerLeft,
                      end:    Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: isLoading
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.send_rounded, color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text('Kirim Pengajuan',
                                  style: TextStyle(color: Colors.white,
                                      fontWeight: FontWeight.w800, fontSize: 15)),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}