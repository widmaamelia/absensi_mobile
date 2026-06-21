import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart'; // Jangan lupa install url_launcher
import 'detail_logbook.dart';

import '../config/api_config.dart';

class LogbookPage extends StatefulWidget {
  const LogbookPage({super.key});

  @override
  State<LogbookPage> createState() => _LogbookPageState();
}

class _LogbookPageState extends State<LogbookPage> {
  final Color primaryDark = const Color(0xFF0F172A);
  final Color bgColor = const Color.fromARGB(255, 233, 244, 255);
  final Color accentBlue = const Color.fromARGB(255, 25, 75, 155);

  List<dynamic> logbooks = [];
  bool isLoading = true;

  // 🔥 State untuk Rentang Tanggal
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    _fetchLogbooks();
  }

  Future<void> _fetchLogbooks() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      // 🔥 Susun parameter URL berdasarkan tanggal yang dipilih
      String url = ApiConfig.logbook;
      if (startDate != null && endDate != null) {
        String startStr = DateFormat('yyyy-MM-dd').format(startDate!);
        String endStr = DateFormat('yyyy-MM-dd').format(endDate!);
        url = '$url?start_date=$startStr&end_date=$endStr';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          logbooks = data['data']['data'] ?? []; 
        });
      }
    } catch (e) {
      debugPrint("Error fetching logbooks: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // 🔥 Fungsi untuk memunculkan kalender ganda (Date Range Picker)
  Future<void> _selectDateRange() async {
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: startDate != null && endDate != null 
          ? DateTimeRange(start: startDate!, end: endDate!) 
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: accentBlue, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: primaryDark, // Body text color
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null) {
      setState(() {
        startDate = pickedRange.start;
        endDate = pickedRange.end;
      });
      _fetchLogbooks(); // Panggil ulang API setelah memilih tanggal
    }
  }

  // Fungsi Reset Filter
  void _resetFilter() {
    setState(() {
      startDate = null;
      endDate = null;
    });
    _fetchLogbooks();
  }

  void _showAddLogbookModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddLogbookModal(),
    ).then((value) {
      if (value == true) {
        _fetchLogbooks(); 
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Teks dinamis untuk filter
    String filterText = "6 Hari Terakhir (Default)";
    if (startDate != null && endDate != null) {
      filterText = "${DateFormat('dd MMM').format(startDate!)} - ${DateFormat('dd MMM yyyy').format(endDate!)}";
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
        title: Text('Logbook Harian', style: TextStyle(color: primaryDark, fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 🔥 FILTER RENTANG TANGGAL SECTION
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectDateRange,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 253, 254, 255),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: accentBlue.withOpacity(0.2), width: 1.5),
                        boxShadow: [
                          BoxShadow(color: accentBlue.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.date_range_rounded, color: accentBlue, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              filterText,
                              style: TextStyle(color: primaryDark, fontWeight: FontWeight.bold, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (startDate != null) ...[
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: _resetFilter,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.red, size: 20),
                    ),
                  ),
                ]
              ],
            ),
          ),

          // LIST DATA SECTION
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: accentBlue))
                : logbooks.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        color: accentBlue,
                        onRefresh: _fetchLogbooks,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          itemCount: logbooks.length,
                          itemBuilder: (context, index) {
                            final delay = 100 + (index * 100);
                            return _FadeInSlide(
                              delay: delay,
                              child: _buildLogbookCard(logbooks[index]),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddLogbookModal,
        backgroundColor: accentBlue,
        elevation: 6,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("Isi Logbook", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: accentBlue.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, 10))],
            ),
            child: Icon(Icons.menu_book_rounded, size: 60, color: accentBlue.withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          Text("Belum Ada Logbook", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryDark)),
          const SizedBox(height: 8),
          Text(
            "Kamu belum menulis catatan aktivitas hari ini.\nYuk, rajin isi logbook!",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CARD LOGBOOK ELEGAN (Tema Gelap / Dark Card)
  // ==========================================
  Widget _buildLogbookCard(dynamic logbook) {
    String status = logbook['status_approval'] ?? 'Pending';
    Color statusColor;
    IconData statusIcon;

    // 🔥 Warna status sedikit dicerahkan agar lebih menyala di background gelap
    if (status == 'Disetujui') {
      statusColor = const Color(0xFF34D399); // Emerald Light
      statusIcon = Icons.check_circle_rounded;
    } else if (status == 'Ditolak') {
      statusColor = const Color(0xFFF87171); // Red Light
      statusIcon = Icons.cancel_rounded;
    } else {
      statusColor = const Color(0xFFFBBF24); // Amber Light
      statusIcon = Icons.hourglass_top_rounded;
    }

    // String formattedDate = '-';
    // if (logbook['tanggal'] != null) {
    //   formattedDate = DateFormat('dd MMM yyyy').format(DateTime.parse(logbook['tanggal']).toLocal());
    // }

    String formattedDate = '-';
    if (logbook['tanggal'] != null) {
      try {
        String dbDate = logbook['tanggal'];
        if (!dbDate.endsWith('Z')) {
          dbDate = '${dbDate}Z'; 
        }
        DateTime parsedDate = DateTime.parse(dbDate).toLocal(); 
        
        // 🔥 HAPUS ", HH:mm" KARENA LOGBOOK MEMANG HANYA MENGGUNAKAN TANGGAL
        formattedDate = DateFormat('dd MMM yyyy').format(parsedDate);
      } catch (e) {
        formattedDate = logbook['tanggal'];
      }
    }

    
    // 🔥 1. Tambahkan return InkWell di sini
    return InkWell(
      onTap: () {
        // 🔥 2. Navigasi ke halaman detail saat kartu diklik
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailLogbookPage(logbook: logbook),
          ),
        );
      },
      borderRadius: BorderRadius.circular(24), // Agar efek kliknya melengkung rapi
      
      // 🔥 3. Ubah return Container yang lama menjadi child: Container
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 53, 85, 139), // Warna background pilihan Zukira
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: primaryDark.withOpacity(0.1),
              blurRadius: 24,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER CARD (Tanggal & Badge Status)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05), // Aksen transparan
                  border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 14, color: Colors.white70),
                        const SizedBox(width: 8),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            color: Colors.white70, // Teks putih tulang
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2), // Background badge menyala
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 12, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            status.toUpperCase(),
                            style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // BODY CARD
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    logbook['judul_aktivitas'] ?? 'Tanpa Judul',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5), // Teks putih terang
                  ),
                  const SizedBox(height: 8),
                  Text(
                    logbook['deskripsi'] ?? '-',
                    style: TextStyle(color: Colors.white.withOpacity(0.7), height: 1.5, fontSize: 13), // Teks deskripsi abu-abu muda
                  ),

                  // CATATAN MENTOR (Hanya muncul jika ada)
                  if (logbook['catatan_mentor'] != null && logbook['catatan_mentor'].toString().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B).withOpacity(0.4), // Warna biru pekat transparan
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.format_quote_rounded, color: Colors.white70, size: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Catatan Mentor:", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 0.5)),
                                const SizedBox(height: 4),
                                Text(
                                  logbook['catatan_mentor'],
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontStyle: FontStyle.italic), // Catatan putih terang
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // TOMBOL LIHAT FOTO BUKTI
                  if (logbook['foto_bukti'] != null) ...[
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final Uri url = Uri.parse('http://10.162.248.203:8000/storage/${logbook['foto_bukti']}');
                        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak bisa membuka foto')));
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1), // Tombol semi-transparan
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.image_outlined, size: 16, color: Colors.white),
                            SizedBox(width: 6),
                            Text("Lihat Foto Bukti", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    )
    );
  }
}

// ==========================================
// ANIMASI FADE IN & SLIDE (Agar Munculnya Mulus)
// ==========================================
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

// ==========================================
// BOTTOM SHEET FORM TAMBAH LOGBOOK (Biarkan Sama)
// ==========================================
class AddLogbookModal extends StatefulWidget {
  const AddLogbookModal({super.key});

  @override
  State<AddLogbookModal> createState() => _AddLogbookModalState();
}

class _AddLogbookModalState extends State<AddLogbookModal> {
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  File? _selectedFile;
  bool isSubmitting = false;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (_judulController.text.isEmpty || _deskripsiController.text.isEmpty || _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Isi semua data dan upload foto bukti!"), backgroundColor: Colors.red)
      );
      return;
    }

    setState(() => isSubmitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      
      var request = http.MultipartRequest('POST', Uri.parse(ApiConfig.logbook));
      
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json'; 
      
      request.fields['judul_aktivitas'] = _judulController.text;
      request.fields['deskripsi'] = _deskripsiController.text;
      request.fields['tanggal'] = DateFormat('yyyy-MM-dd').format(DateTime.now()); 
      
      request.files.add(await http.MultipartFile.fromPath('foto_bukti', _selectedFile!.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          Navigator.pop(context, true); 
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Logbook berhasil dikirim!"), backgroundColor: Colors.green)
          );
        }
      } else {
        String pesanError = "Gagal mengirim data";
        try {
          final errorData = jsonDecode(response.body);
          pesanError = errorData['message'] ?? response.body; 
        } catch (e) {
          pesanError = response.body;
        }
        throw Exception(pesanError);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString(), maxLines: 3, overflow: TextOverflow.ellipsis), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 24),
            const Text("Catatan Baru", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            
            TextField(
              controller: _judulController,
              decoration: InputDecoration(
                labelText: "Judul Aktivitas",
                filled: true,
                fillColor: const Color.fromARGB(255, 233, 244, 255),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _deskripsiController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Deskripsi",
                filled: true,
                fillColor: const Color.fromARGB(255, 233, 244, 255),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            
            InkWell(
              onTap: _pickFile,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: _selectedFile != null ? Colors.green.shade300 : Colors.grey.shade300, width: 1.5),
                  borderRadius: BorderRadius.circular(16),
                  color: _selectedFile != null ? Colors.green.shade50 : Colors.grey.shade50,
                ),
                child: Column(
                  children: [
                    Icon(Icons.cloud_upload_outlined, color: _selectedFile != null ? Colors.green : Colors.grey),
                    const SizedBox(height: 8),
                    Text(
                      _selectedFile != null ? "Foto Bukti Terpilih!" : "Upload Foto Bukti (Wajib)",
                      style: TextStyle(color: _selectedFile != null ? Colors.green : Colors.grey, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: isSubmitting 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("Kirim Logbook", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}