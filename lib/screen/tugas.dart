import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; 
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'detail_tugas.dart';

class TugasPage extends StatefulWidget {
  const TugasPage({super.key});

  @override
  State<TugasPage> createState() => _TugasPageState();
}

class _TugasPageState extends State<TugasPage> {
  // ================================
  // COLORS (Modern Tailwind Light + Dark Card)
  // ================================
  final Color primaryDark = const Color.fromARGB(255, 17, 32, 68);       
  final Color cardDark = const Color.fromARGB(255, 46, 81, 138);          
  final Color bgColor = const Color.fromARGB(255, 233, 244, 255);
  final Color accentBlue = const Color(0xFF3B82F6);        
  final Color accentCyan = const Color(0xFF06B6D4);      
  final Color textMuted = const Color(0xFF94A3B8);         

  // ================================
  // STATE (Data Asli dari API nanti masuk ke sini)
  // ================================
  List<dynamic> daftarTugas = [];
  bool isLoading = false; 

  @override
  void initState() {
    super.initState();
    _fetchTugasAPI();
  }

  // ================================
  // FUNGSI KUMPUL TUGAS (Upload API)
  // ================================
  Future<void> _kumpulTugas(int taskId) async {
    try {
      
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any, 
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token') ?? '';

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sedang mengunggah tugas...')),
        );

        var request = http.MultipartRequest(
          'POST',
          Uri.parse('http://10.152.19.111:8000/api/tasks/$taskId/submit'),
        );
        
        // Masukkan Token
        request.headers.addAll({
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        });

        request.files.add(
          await http.MultipartFile.fromPath('file_jawaban', file.path),
        );

        // 4. Kirim ke Server!
        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        if (!mounted) return;

        // 5. Cek Hasilnya
        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tugas berhasil dikumpulkan!'), backgroundColor: Colors.green),
          );
          // Refresh tampilan layar setelah berhasil kumpul
          _fetchTugasAPI();
        } else {
          final errorData = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorData['message'] ?? 'Gagal mengumpulkan tugas'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      debugPrint('Error upload: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan sistem.'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _fetchTugasAPI() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      
      // PERBAIKAN 1: URL menggunakan /api/tasks sesuai route Laravel
      final response = await http.get(
        Uri.parse('http://10.152.19.111:8000/api/tasks'), 
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        }
      );

      debugPrint("STATUS CODE: ${response.statusCode}");
      debugPrint("BALASAN SERVER: ${response.body}");

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        // Pastikan API membalas dengan 'success' == true
        if (jsonData['success'] == true) {
          setState(() {
            daftarTugas = jsonData['data']; 
          });
        }
      }
    } catch (e) {
      debugPrint("Error Fetch: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Daftar Tugas',
          style: TextStyle(
            color: primaryDark,
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER SECTION
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: _FadeInSlide(
                delay: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tugas Terkirim',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: primaryDark,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Kerjakan dan kumpulkan tugas dari mentor tepat waktu ya.',
                      style: TextStyle(
                        color: const Color(0xFF64748B),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // LIST TUGAS SECTION
            Expanded(
              child: isLoading 
                ? Center(child: CircularProgressIndicator(color: accentBlue))
                : daftarTugas.isEmpty 
                    ? _buildEmptyState() // Tampil jika belum ada data dari API
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        physics: const BouncingScrollPhysics(),
                        itemCount: daftarTugas.length,
                        itemBuilder: (context, index) {
                          final tugas = daftarTugas[index];
                          final delay = 100 + (index * 100); 

                          return _FadeInSlide(
                            delay: delay,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: _buildTaskCard(tugas),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================
  // EMPTY STATE (Tampilan jika data kosong)
  // ================================
  Widget _buildEmptyState() {
    return _FadeInSlide(
      delay: 150,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: accentBlue.withValues(alpha: 0.1), blurRadius: 30, offset: const Offset(0, 10)),
                ],
              ),
              child: Icon(Icons.assignment_turned_in_rounded, size: 60, color: accentBlue.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 24),
            Text(
              'Belum Ada Tugas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryDark),
            ),
            const SizedBox(height: 8),
            Text(
              'Santai dulu, mentor belum mengirimkan\ntugas baru untukmu.',
              textAlign: TextAlign.center,
              style: TextStyle(color: const Color(0xFF64748B), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // ================================
  // TASK CARD WIDGET (Versi Compact + Format Waktu Rapi)
  // ================================
  // ================================
  // TASK CARD WIDGET (Logika Status Diperbaiki)
  // ================================
  Widget _buildTaskCard(dynamic tugas) {
    // 1. Cek apakah anak magang sudah mengumpulkan
    // bool isSubmitted = tugas['is_submitted'] == true;
    
    // // 2. Cek apakah mentor sudah menilai
    // // 🔥 PERHATIAN: Saya menggunakan asumsi bahwa Laravel mengirimkan data 'nilai'.
    // bool isDinilai = tugas['nilai'] != null && tugas['nilai'].toString().isNotEmpty; 

    // bool adaMateri = tugas['file_materi'] != null;



    bool isSubmitted = tugas['is_submitted'] == true;
    
    // 2. 🔥 PERBAIKAN: Masuk ke dalam 'submission' dulu untuk mencari nilai!
    bool isDinilai = false;
    if (tugas['submission'] != null) {
      isDinilai = tugas['submission']['nilai'] != null && tugas['submission']['nilai'].toString().isNotEmpty; 
    }

    bool adaMateri = tugas['file_materi'] != null;

    // --- LOGIC FORMAT WAKTU ---
    String formattedDeadline = '-';
    if (tugas['deadline'] != null) {
      try {
        // 🔥 Tambahkan .toLocal() agar jamnya kembali ke waktu WIB
        DateTime parsedDate = DateTime.parse(tugas['deadline']).toLocal(); 
        formattedDeadline = DateFormat('dd MMM yyyy, HH:mm').format(parsedDate);
      } catch (e) {
        formattedDeadline = tugas['deadline'];
      }
    }

    // --- LOGIC WARNA & TEKS BERDASARKAN 3 STATUS ---
    String badgeText = isDinilai ? 'Selesai' : (isSubmitted ? 'Menunggu' : 'Belum');
    Color badgeColor = isDinilai 
        ? const Color(0xFF10B981) // Hijau jika dinilai
        : (isSubmitted ? accentBlue : const Color(0xFFF59E0B)); // Biru jika nunggu, Kuning jika belum
        
    String btnText = isDinilai ? 'Dinilai' : (isSubmitted ? 'Terkumpul' : 'Kumpul');
    bool isButtonDisabled = isSubmitted || isDinilai; // Tombol mati kalau sudah dikumpul atau dinilai

    return InkWell( 
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DetailTugasPage(tugas: tugas)),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cardDark, primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryDark.withValues(alpha: 0.15), 
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BARIS 1: Icon, Judul/Deskripsi, & Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // GLOWING ICON
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: badgeColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    isDinilai ? Icons.task_alt_rounded : (isSubmitted ? Icons.hourglass_top_rounded : Icons.code_rounded),
                    color: badgeColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                
                // TITLE & DESC
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tugas['judul_tugas'] ?? 'Tanpa Judul',
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tugas['deskripsi_tugas'] ?? 'Tidak ada deskripsi',
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                
                // STATUS BADGE
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: badgeColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // BARIS 2: Deadline, Materi & Tombol Kumpul
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      // DEADLINE
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer_outlined, size: 14, color: textMuted),
                          const SizedBox(width: 4),
                          Text(
                            formattedDeadline, 
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                      
                      // TOMBOL MATERI
                      if (adaMateri)
                        InkWell(
                          onTap: () async {
                            final String namaFile = tugas['file_materi'];
                            final Uri url = Uri.parse('http://10.152.19.111:8000/storage/$namaFile');
                            
                            if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Tidak bisa membuka file materi')),
                              );
                            }
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.download_rounded, size: 14, color: accentCyan),
                              const SizedBox(width: 4),
                              Text(
                                'Materi',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: accentCyan,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 8),

                // TOMBOL KUMPUL
                Container(
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isButtonDisabled 
                          ? [Colors.white.withValues(alpha: 0.1), Colors.white.withValues(alpha: 0.05)]
                          : [accentBlue, accentCyan],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: isButtonDisabled ? [] : [
                      BoxShadow(
                        color: accentBlue.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: isButtonDisabled ? null : () => _kumpulTugas(tugas['id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      disabledBackgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      btnText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: isButtonDisabled ? textMuted : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ================================
// ANIMATION HELPER WIDGET
// ================================
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
          return const SizedBox.shrink(); 
        }
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
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