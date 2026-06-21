import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailLogbookPage extends StatelessWidget {
  final dynamic logbook;

  const DetailLogbookPage({super.key, required this.logbook});

  @override
  Widget build(BuildContext context) {
    // ================================
    // COLOR PALETTE
    // ================================
    final Color primaryDark = const Color(0xFF0F172A);
    final Color bgColor = const Color.fromARGB(255, 233, 244, 255);
    final Color accentBlue = const Color.fromARGB(255, 25, 75, 155);

    // ================================
    // LOGIC STATUS & TANGGAL
    // ================================
    String status = logbook['status_approval'] ?? 'Pending';
    Color statusColor;
    IconData statusIcon;

    if (status == 'Disetujui') {
      statusColor = const Color(0xFF10B981);
      statusIcon = Icons.check_circle_rounded;
    } else if (status == 'Ditolak') {
      statusColor = const Color(0xFFEF4444);
      statusIcon = Icons.cancel_rounded;
    } else {
      statusColor = const Color(0xFFF59E0B);
      statusIcon = Icons.hourglass_top_rounded;
    }

    String formattedDate = '-';
    if (logbook['tanggal'] != null) {
      try {
        String dbDate = logbook['tanggal'];
        if (!dbDate.endsWith('Z')) {
          dbDate = '${dbDate}Z';
        }
        DateTime parsedDate = DateTime.parse(dbDate).toLocal();
        formattedDate = DateFormat('dd MMMM yyyy').format(parsedDate);
      } catch (e) {
        formattedDate = logbook['tanggal'];
      }
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detail Laporan',
          style: TextStyle(color: primaryDark, fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER: STATUS & TANGGAL ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    Text(
                      formattedDate,
                      style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- JUDUL AKTIVITAS ---
            Text(
              logbook['judul_aktivitas'] ?? 'Tanpa Judul',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: primaryDark, height: 1.2, letterSpacing: -0.5),
            ),
            const SizedBox(height: 24),

            // --- DESKRIPSI ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 251, 252, 254),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: accentBlue.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.subject_rounded, size: 18, color: accentBlue),
                      const SizedBox(width: 8),
                      Text("Deskripsi Aktivitas", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: accentBlue)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    logbook['deskripsi'] ?? '-',
                    style: TextStyle(color: Colors.grey.shade700, height: 1.6, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- FOTO BUKTI ---
            if (logbook['foto_bukti'] != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: accentBlue.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.image_rounded, size: 18, color: accentBlue),
                        const SizedBox(width: 8),
                        Text("Foto Bukti", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: accentBlue)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        'http://10.162.248.203:8000/storage/${logbook['foto_bukti']}',
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 150,
                            color: Colors.grey.shade100,
                            child: const Center(child: Text("Gagal memuat gambar", style: TextStyle(color: Colors.grey))),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 150,
                            color: Colors.grey.shade50,
                            child: const Center(child: CircularProgressIndicator()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final Uri url = Uri.parse('http://10.162.248.203:8000/storage/${logbook['foto_bukti']}');
                          if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak bisa membuka tautan foto')));
                            }
                          }
                        },
                        icon: const Icon(Icons.open_in_new_rounded, size: 16),
                        label: const Text("Buka di Browser"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: accentBlue,
                          side: BorderSide(color: accentBlue.withOpacity(0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    )
                  ],
                ),
              ),

            // --- CATATAN MENTOR ---
            if (logbook['catatan_mentor'] != null && logbook['catatan_mentor'].toString().isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentBlue, const Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: accentBlue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                          child: const Icon(Icons.format_quote_rounded, color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 10),
                        const Text("Catatan & Evaluasi Mentor", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      logbook['catatan_mentor'],
                      style: const TextStyle(color: Colors.white, height: 1.6, fontSize: 14, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 40), // Spasi bawah
          ],
        ),
      ),
    );
  }
}