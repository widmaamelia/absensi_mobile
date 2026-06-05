import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DetailTugasPage extends StatelessWidget {
  final dynamic tugas;

  const DetailTugasPage({super.key, required this.tugas});

  @override
  Widget build(BuildContext context) {
    // ================================
    // COLORS (Tailwind CSS Palette)
    // ================================
    final Color primaryDark = const Color.fromARGB(255, 17, 31, 64);       // Slate 900
    final Color cardDark = const Color.fromARGB(255, 46, 81, 138);      // Sesuai dengan card tugas.dart
    final Color bgColor = const Color.fromARGB(255, 233, 244, 255);
    final Color accentBlue = const Color.fromARGB(255, 106, 140, 195);        // Blue 500
    final Color accentCyan = const Color.fromARGB(255, 140, 182, 240);        // Cyan 500
    final Color textMuted = const Color(0xFF94A3B8);         // Slate 400

    // ================================
    // PARSING DATA
    // ================================
    bool isSelesai = tugas['is_submitted'] == true;
    var submission = tugas['submission'];
    bool isDinilai = submission != null && submission['nilai'] != null;

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

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detail Tugas', 
          style: TextStyle(color: primaryDark, fontWeight: FontWeight.w800, fontSize: 22),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER: STATUS & JUDUL (Animasi Delay 0) ---
            _FadeInSlide(
              delay: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelesai 
                          ? const Color(0xFF10B981).withValues(alpha: 0.15) 
                          : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelesai ? const Color(0xFF10B981).withValues(alpha: 0.3) : const Color(0xFFF59E0B).withValues(alpha: 0.3),
                      )
                    ),
                    child: Text(
                      isSelesai ? 'Status: Selesai' : 'Status: Belum Dikumpul',
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelesai ? const Color(0xFF059669) : const Color(0xFFD97706), 
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tugas['judul_tugas'] ?? 'Tanpa Judul', 
                    style: TextStyle(
                      fontSize: 32, 
                      fontWeight: FontWeight.w900, 
                      color: primaryDark, 
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 28),

            // --- INFO CARD (SEWARNA DENGAN LIST TUGAS) (Animasi Delay 150) ---
            _FadeInSlide(
              delay: 150,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cardDark, primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: primaryDark.withValues(alpha: 0.15), 
                      blurRadius: 24, 
                      offset: const Offset(0, 12)
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.description_outlined, color: textMuted, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Deskripsi Lengkap", 
                          style: TextStyle(fontWeight: FontWeight.w700, color: textMuted, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tugas['deskripsi_tugas'] ?? '-', 
                      style: const TextStyle(
                        fontSize: 15, 
                        height: 1.6, 
                        color: Colors.white, // Text putih agar terbaca di card gelap
                        fontWeight: FontWeight.w500
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20), 
                      child: Divider(color: Colors.white.withValues(alpha: 0.1), thickness: 1),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: accentCyan.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.timer_outlined, size: 18, color: accentCyan),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Batas Waktu (Deadline)", style: TextStyle(fontSize: 11, color: textMuted, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(
                              formattedDeadline, 
                              style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 14),
                            ),
                          ],
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),

            // --- WOW CARD (HASIL PENILAIAN BANNER) (Animasi Delay 300) ---
            if (isDinilai)
              _FadeInSlide(
                delay: 300,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accentBlue, accentCyan],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: accentBlue.withValues(alpha: 0.3), 
                        blurRadius: 20, 
                        offset: const Offset(0, 10)
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Evaluasi Mentor", 
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "\"${submission['catatan_nilai'] ?? 'Kerja bagus!'}\"", 
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, fontStyle: FontStyle.italic, height: 1.4),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Badge Nilai Sleek & Modern
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: primaryDark.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))
                          ]
                        ),
                        child: Column(
                          children: [
                            Text("NILAI", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: textMuted, letterSpacing: 1.0)),
                            const SizedBox(height: 4),
                            Text(
                              "${submission['nilai']}", 
                              style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: accentBlue, height: 1.0),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              )
            else if (isSelesai)
               _FadeInSlide(
                 delay: 300,
                 child: Center(
                   child: Padding(
                     padding: const EdgeInsets.all(20), 
                     child: Text(
                       "Tugas sedang diperiksa mentor...", 
                       style: TextStyle(color: textMuted, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500)
                     )
                   )
                 ),
               ),
               
            const SizedBox(height: 40), // Spasi bawah agar bisa di-scroll dengan nyaman
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