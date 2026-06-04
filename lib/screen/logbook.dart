import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

import '../config/api_config.dart';

class LogbookPage extends StatefulWidget {
  const LogbookPage({super.key});

  @override
  State<LogbookPage> createState() => _LogbookPageState();
}

class _LogbookPageState extends State<LogbookPage> {
  final Color primaryDark = const Color(0xFF0F172A);
  final Color bgColor = const Color.fromARGB(255, 233, 244, 255);
  final Color accentBlue = const Color(0xFF3B82F6);

  List<dynamic> logbooks = [];
  bool isLoading = true;

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
      
      final response = await http.get(
        Uri.parse(ApiConfig.logbook),
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          logbooks = data['data'] ?? []; // Sesuaikan dengan response Laravel
        });
      }
    } catch (e) {
      debugPrint("Error fetching logbooks: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Menampilkan form tambah logbook dari bawah (Sangat Modern)
  void _showAddLogbookModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddLogbookModal(),
    ).then((value) {
      if (value == true) {
        _fetchLogbooks(); // Refresh data jika berhasil tambah
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Logbook Harian', style: TextStyle(color: primaryDark, fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: accentBlue))
          : logbooks.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: accentBlue,
                  onRefresh: _fetchLogbooks,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(24),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: logbooks.length,
                    itemBuilder: (context, index) {
                      return _buildLogbookCard(logbooks[index]);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddLogbookModal,
        backgroundColor: accentBlue,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("Isi Logbook", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("Belum ada catatan logbook", style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildLogbookCard(dynamic logbook) {
    String status = logbook['status_approval'] ?? 'pending';
    Color statusColor = status == 'approved' ? const Color(0xFF10B981) : (status == 'rejected' ? const Color(0xFFEF4444) : const Color(0xFFF59E0B));
    
    String formattedDate = '-';
    if (logbook['tanggal'] != null) {
      formattedDate = DateFormat('dd MMM yyyy').format(DateTime.parse(logbook['tanggal']));
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(formattedDate, style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            logbook['judul_aktivitas'] ?? 'Tanpa Judul',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryDark),
          ),
          const SizedBox(height: 8),
          Text(
            logbook['deskripsi'] ?? '-',
            style: TextStyle(color: Colors.grey.shade700, height: 1.5, fontSize: 14),
          ),
          if (logbook['catatan_mentor'] != null) ...[
            const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentBlue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accentBlue.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Icon(Icons.comment_rounded, color: accentBlue, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Mentor: ${logbook['catatan_mentor']}",
                      style: TextStyle(color: primaryDark, fontSize: 13, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }
}

// ==========================================
// BOTTOM SHEET FORM TAMBAH LOGBOOK
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
    // 1. Sembunyikan keyboard saat tombol ditekan
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
      
      // 🔥 PENTING 1: Beritahu Laravel agar membalas dengan format JSON
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json'; 
      
      request.fields['judul_aktivitas'] = _judulController.text;
      request.fields['deskripsi'] = _deskripsiController.text;
      request.fields['tanggal'] = DateFormat('yyyy-MM-dd').format(DateTime.now()); 
      
      request.files.add(await http.MultipartFile.fromPath('foto_bukti', _selectedFile!.path));

      // 🔥 PENTING 2: Baca balasan dari Laravel secara utuh
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
        // 🔥 DETEKTIF: Kalau ditolak, kita tangkap pesan aslinya!
        debugPrint("ERROR LARAVEL: ${response.statusCode} - ${response.body}");
        
        String pesanError = "Gagal mengirim data";
        try {
          final errorData = jsonDecode(response.body);
          pesanError = errorData['message'] ?? response.body; // Ambil pesan dari Laravel
        } catch (e) {
          pesanError = response.body;
        }
        
        throw Exception(pesanError);
      }
    } catch (e) {
      // Tampilkan errornya di layar HP!
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString(), maxLines: 3, overflow: TextOverflow.ellipsis), 
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          )
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
                fillColor: Colors.grey.shade50,
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
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            
            // Tombol Upload Foto
            InkWell(
              onTap: _pickFile,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey.shade50,
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