import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../config/api_config.dart';
import 'login.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  // ================================
  // COLORS (Tailwind Palette)
  // ================================
  final Color primaryDark = const Color(0xFF0F172A); 
  final Color bgColor = const Color.fromARGB(255, 233, 244, 255);
  final Color accentBlue = const Color(0xFF3B82F6);  
  final Color textMuted = const Color(0xFF64748B);   

  String userName = 'Memuat...';
  String userEmail = 'Memuat...';
  
  // Variabel untuk data dari tabel data_anak_magang
  String instansi = '-';
  String tglMulai = '-';
  String tglSelesai = '-';
  String namaMentor = '-';
  
  // Status loading khusus untuk kartu detail magang
  bool isLoadingDetail = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchDetailMagang(); // Panggil API saat halaman dibuka
  }

  // Cukup ambil Nama dan Email dari memori (karena sudah disave saat login)
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('user_name') ?? 'Anak Magang';
      // userEmail = prefs.getString('user_email') ?? 'magang@mediatama.co.id';
      userEmail = prefs.getString('email') ?? 'Email tidak ditemukan';
    });
  }

  // =====================================
  // FETCH DATA LANGSUNG DARI DATABASE
  // =====================================
  Future<void> _fetchDetailMagang() async {
    setState(() => isLoadingDetail = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final response = await http.get(
        Uri.parse(ApiConfig.detailProfil), // Memanggil API khusus detail magang
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // if (response.statusCode == 200) {
      //   final data = jsonDecode(response.body);
      //   if (data['data'] != null && mounted) {
      //     setState(() {
      //       userEmail = data['data']['email'] ?? userEmail;
      //       instansi = data['data']['instansi'] ?? '-';
      //       tglMulai = data['data']['tanggal_mulai_magang'] ?? '-';
      //       tglSelesai = data['data']['tanggal_selesai_magang'] ?? '-';
      //       // Tergantung backend, ini bisa ID mentor atau nama mentornya langsung
      //       namaMentor = data['data']['nama_mentor']?.toString() ?? '-'; 
      //     });
      //   }
      // }


      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null && mounted) {
          
          // 🔥 1. Update juga memori HP agar tidak perlu login ulang!
          await prefs.setString('user_name', data['data']['name'] ?? userName);
          await prefs.setString('email', data['data']['email'] ?? userEmail);

          // 🔥 2. Paksa layar untuk refresh saat itu juga
          setState(() {
            userName = data['data']['name'] ?? userName; 
            userEmail = data['data']['email'] ?? userEmail;
            
            instansi = data['data']['instansi'] ?? '-';
            tglMulai = data['data']['tanggal_mulai_magang'] ?? '-';
            tglSelesai = data['data']['tanggal_selesai_magang'] ?? '-';
            namaMentor = data['data']['nama_mentor']?.toString() ?? '-'; 
          });
        }
      }


    } catch (e) {
      debugPrint("Gagal mengambil detail profil: $e");
    } finally {
      if (mounted) setState(() => isLoadingDetail = false);
    }
  }
  
  // Helper untuk format tanggal dari YYYY-MM-DD ke DD MMM YYYY
  String _formatTanggal(String tanggal) {
    if (tanggal == '-') return tanggal;
    try {
      final date = DateTime.parse(tanggal);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return tanggal;
    }
  }

  // =====================================
  // MODAL EDIT PROFIL (NAMA & EMAIL)
  // =====================================
  void _showEditProfileModal() {
    final nameController = TextEditingController(text: userName);
    final emailController = TextEditingController(text: userEmail);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24, 
              left: 24, right: 24, top: 24
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 24),
                Text("Edit Profil", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: primaryDark)),
                const SizedBox(height: 20),
                
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: "Nama Lengkap", filled: true, fillColor: const Color.fromARGB(255, 233, 244, 255), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: "Email", filled: true, fillColor: const Color.fromARGB(255, 233, 244, 255), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : () async {
                      setModalState(() => isSaving = true);
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        final token = prefs.getString('auth_token') ?? '';
                        
                        var request = http.Request('PATCH', Uri.parse(ApiConfig.updateProfile));
                        request.headers.addAll({
                          'Accept': 'application/json',
                          'Authorization': 'Bearer $token',
                          'Content-Type': 'application/x-www-form-urlencoded',
                        });
                        request.bodyFields = {
                          'name': nameController.text,
                          'email': emailController.text,
                        };
                        request.followRedirects = false; 

                        var streamedResponse = await request.send();
                        var response = await http.Response.fromStream(streamedResponse);

                        if (response.statusCode == 200 || response.statusCode == 302 || response.statusCode == 303) {
                          await prefs.setString('user_name', nameController.text);
                          await prefs.setString('email', emailController.text);
                          _loadUserData(); 
                          
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profil berhasil diupdate!"), backgroundColor: Colors.green));
                          }
                        } else {
                          String errorMsg = "Gagal: Status ${response.statusCode}";
                          try {
                            errorMsg = jsonDecode(response.body)['message'] ?? errorMsg;
                          } catch (_) {}
                          throw Exception(errorMsg);
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                      } finally {
                        setModalState(() => isSaving = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Color.fromARGB(255, 39, 103, 206), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("Simpan Perubahan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                )
              ],
            ),
          );
        }
      ),
    );
  }

  // =====================================
  // MODAL UBAH PASSWORD
  // =====================================
  void _showEditPasswordModal() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24, 
              left: 24, right: 24, top: 24
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 24),
                Text("Ubah Password", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: primaryDark)),
                const SizedBox(height: 20),
                
                TextField(
                  controller: oldPasswordController, obscureText: true,
                  decoration: InputDecoration(labelText: "Password Lama", filled: true, fillColor: const Color.fromARGB(255, 233, 244, 255), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController, obscureText: true,
                  decoration: InputDecoration(labelText: "Password Baru", filled: true, fillColor: const Color.fromARGB(255, 233, 244, 255), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController, obscureText: true,
                  decoration: InputDecoration(labelText: "Konfirmasi Password Baru", filled: true, fillColor: const Color.fromARGB(255, 233, 244, 255), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : () async {
                      if (newPasswordController.text != confirmPasswordController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Konfirmasi password tidak cocok!"), backgroundColor: Colors.red));
                        return;
                      }

                      setModalState(() => isSaving = true);
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        final token = prefs.getString('auth_token') ?? '';
                        
                        var request = http.Request('PUT', Uri.parse(ApiConfig.updatePassword));
                        request.headers.addAll({
                          'Accept': 'application/json',
                          'Authorization': 'Bearer $token',
                          'Content-Type': 'application/x-www-form-urlencoded',
                        });
                        request.bodyFields = {
                          'current_password': oldPasswordController.text,
                          'password': newPasswordController.text, 
                          'password_confirmation': confirmPasswordController.text,
                        };
                        request.followRedirects = false;

                        var streamedResponse = await request.send();
                        var response = await http.Response.fromStream(streamedResponse);

                        if (response.statusCode == 200 || response.statusCode == 302 || response.statusCode == 303) {
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password berhasil diubah!"), backgroundColor: Colors.green));
                          }
                        } else {
                          String errorMsg = "Gagal ubah password: ${response.statusCode}";
                          try {
                            errorMsg = jsonDecode(response.body)['message'] ?? errorMsg;
                          } catch (_) {}
                          throw Exception(errorMsg);
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                      } finally {
                        setModalState(() => isSaving = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Color.fromARGB(255, 39, 103, 206), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("Simpan Password", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                )
              ],
            ),
          );
        }
      ),
    );
  }

  // =====================================
  // FUNGSI LOGOUT
  // =====================================
  void _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Konfirmasi Keluar", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Apakah kamu yakin ingin keluar dari aplikasi?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear(); 
              
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false, 
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444), 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Ya, Keluar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Logika Inisial Nama
    String inisial = userName.isNotEmpty && userName != 'Memuat...' 
        ? userName[0].toUpperCase() 
        : '?';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Profil Saya', style: TextStyle(color: primaryDark, fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            // --- FOTO PROFIL (INISIAL) & NAMA ---
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [accentBlue, Color.fromARGB(255, 4, 54, 108)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(color: accentBlue.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 10))
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: Text(
                        inisial,
                        style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: accentBlue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userName,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: primaryDark),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userEmail,
                    style: TextStyle(fontSize: 14, color: textMuted, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: accentBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Mahasiswa Magang",
                      style: TextStyle(color: accentBlue, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // --- KARTU INFORMASI MAGANG ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color.fromARGB(221, 28, 48, 93),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: isLoadingDetail 
                ? const Center(child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ))
                : Column(
                    children: [
                      _buildInfoRow(Icons.business_rounded, "Instansi / Tempat Magang", instansi),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                      _buildInfoRow(Icons.calendar_today_rounded, "Tanggal Mulai", _formatTanggal(tglMulai)),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                      _buildInfoRow(Icons.event_available_rounded, "Tanggal Selesai", _formatTanggal(tglSelesai)),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                      _buildInfoRow(Icons.supervisor_account_rounded, "Mentor", namaMentor),
                    ],
                  ),
            ),

            const SizedBox(height: 24),

            // --- MENU PENGATURAN ---
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color.fromARGB(221, 28, 48, 93),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                children: [
                  _buildMenuTile(Icons.edit_rounded, "Edit Profil", _showEditProfileModal),
                  _buildMenuTile(Icons.lock_outline_rounded, "Ubah Password", _showEditPasswordModal),
                  _buildMenuTile(Icons.logout_rounded, "Keluar", _logout, isDanger: true),
                ],
              ),
            ),
            
            // const SizedBox(height: 40),
            // Text(
            //   "InternTrack v1.0.0\nMade with ❤️ by Zukira",
            //   textAlign: TextAlign.center,
            //   style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            // )
          ],
        ),
      ),
    );
  }

  // --- WIDGET BANTUAN ---
  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: textMuted, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: const Color.fromARGB(255, 234, 234, 234), fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuTile(IconData icon, String title, VoidCallback onTap, {bool isDanger = false}) {
    // 1. Warna untuk Ikon: Merah jika isDanger (Keluar), Gelap (primaryDark) jika menu biasa
    final Color iconColor = isDanger ? const Color(0xFFEF4444) : const Color.fromARGB(255, 70, 95, 155);
    
    // 2. Warna untuk Teks: Merah jika isDanger (Keluar), Putih jika menu biasa
    final Color textColor = isDanger ? const Color(0xFFEF4444) : Colors.white;
    
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDanger ? const Color(0xFFEF4444).withValues(alpha: 0.1) : bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        // Ikon menggunakan iconColor (gelap)
        child: Icon(icon, color: iconColor, size: 20),
      ),
      // Teks menggunakan textColor (putih)
      title: Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
      
      // Opsional: Panah ke kanan juga diubah jadi Colors.white70 biar kelihatan jelas di background gelap
      trailing: isDanger ? null : const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white70),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}