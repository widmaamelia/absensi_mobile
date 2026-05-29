import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {

  bool isAbsenLoading = false;

  // ================= ABSEN API =================

  Future<void> absenMasuk() async {

    setState(() {
      isAbsenLoading = true;
    });

    try {

      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('auth_token');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Token tidak ditemukan"),
          ),
        );
        return;
      }

      http.Response response;
      try {
        response = await http
            .post(
          Uri.parse('http://192.168.100.158:8000/api/absensi/masuk'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: {
            'status': 'hadir',
          },
        )
            .timeout(const Duration(seconds: 10));
      } on TimeoutException catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Request timeout. Periksa koneksi Anda."),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      } on SocketException catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Tidak ada koneksi jaringan."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saat mengirim request: $e"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      Map<String, dynamic>? data;
      try {
        data = response.body.isNotEmpty ? jsonDecode(response.body) : null;
      } catch (_) {
        data = null;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data?['message'] ?? 'Absen berhasil'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data?['message'] ?? 'Gagal absen (kode ${response.statusCode})'),
            backgroundColor: Colors.orange,
          ),
        );
      }

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error : $e"),
          backgroundColor: Colors.red,
        ),
      );

    } finally {

      setState(() {
        isAbsenLoading = false;
      });

    }
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {

    String today =
        DateFormat('dd MMMM yyyy')
            .format(DateTime.now());

    return Scaffold(

      backgroundColor: const Color(0xffF8FAFC),

      body: SafeArea(

        child: SingleChildScrollView(

          padding: const EdgeInsets.all(20),

          child: Column(

            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              // ================= HEADER =================

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [

                  Row(
                    children: [

                      Container(
                        padding:
                            const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xff0F172A),
                          borderRadius:
                              BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.dashboard,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(width: 14),

                      const Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [

                          Text(
                            "InternTrack",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: 2),

                          Text(
                            "Monitoring Magang",
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),

                        ],
                      ),

                    ],
                  ),

                  const CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(
                      'https://i.pravatar.cc/150?img=11',
                    ),
                  ),

                ],
              ),

              const SizedBox(height: 30),

              // ================= GREETING =================

              const Text(
                "Halo Andi 👋",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Selamat datang kembali,\nsemoga harimu menyenangkan.",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 30),

              // ================= CARD ABSENSI =================

              Container(

                width: double.infinity,

                padding: const EdgeInsets.all(24),

                decoration: BoxDecoration(

                  borderRadius:
                      BorderRadius.circular(30),

                  gradient: const LinearGradient(
                    colors: [
                      Color(0xff1E293B),
                      Color(0xff0F172A),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),

                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],

                ),

                child: Column(

                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    Row(

                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,

                      children: [

                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [

                            Text(
                              today,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),

                            const SizedBox(height: 8),

                            const Text(
                              "Status Kehadiran",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                          ],
                        ),

                        Container(
                          padding:
                              const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                Colors.white.withOpacity(
                              0.1,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.fingerprint,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),

                      ],
                    ),

                    const SizedBox(height: 30),

                    Row(
                      children: [

                        Expanded(
                          child: infoCard(
                            title: "Masuk",
                            value: "08:00",
                            icon: Icons.login,
                            color: Colors.green,
                          ),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: infoCard(
                            title: "Pulang",
                            value: "--:--",
                            icon: Icons.logout,
                            color: Colors.red,
                          ),
                        ),

                      ],
                    ),

                    const SizedBox(height: 24),

                    SizedBox(

                      width: double.infinity,
                      height: 56,

                      child: ElevatedButton.icon(

                        onPressed:
                            isAbsenLoading
                                ? null
                                : absenMasuk,

                        style:
                            ElevatedButton.styleFrom(

                          backgroundColor:
                              Colors.white,

                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(18),
                          ),

                        ),

                        icon:
                            isAbsenLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.access_time,
                                    color:
                                        Color(0xff0F172A),
                                  ),

                        label: Text(
                          isAbsenLoading
                              ? "Memproses..."
                              : "ABSEN MASUK",
                          style: const TextStyle(
                            color: Color(0xff0F172A),
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                      ),

                    ),

                  ],
                ),
              ),

              const SizedBox(height: 30),

              // ================= SUMMARY =================

              const Text(
                "Ringkasan",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 18),

              Row(

                children: [

                  Expanded(
                    child: summaryCard(
                      title: "Hadir",
                      value: "22",
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: summaryCard(
                      title: "Izin",
                      value: "2",
                      icon: Icons.assignment,
                      color: Colors.orange,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: summaryCard(
                      title: "Telat",
                      value: "1",
                      icon: Icons.timer,
                      color: Colors.red,
                    ),
                  ),

                ],
              ),

              const SizedBox(height: 30),

              // ================= TUGAS =================

              const Text(
                "Tugas Hari Ini",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 18),

              taskCard(
                title:
                    "Membuat UI Dashboard Flutter",
                subtitle:
                    "Selesaikan tampilan dashboard modern untuk aplikasi monitoring magang.",
                deadline: "Deadline Besok",
              ),

              const SizedBox(height: 18),

              taskCard(
                title:
                    "Integrasi API Laravel",
                subtitle:
                    "Hubungkan fitur absensi ke backend menggunakan Sanctum.",
                deadline: "Deadline Jumat",
              ),

              const SizedBox(height: 100),

            ],
          ),
        ),
      ),

      // ================= BOTTOM NAV =================

      bottomNavigationBar: BottomNavigationBar(

        currentIndex: 0,

        selectedItemColor:
            const Color(0xff0F172A),

        unselectedItemColor: Colors.grey,

        type: BottomNavigationBarType.fixed,

        items: const [

          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: "Tugas",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: "Riwayat",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profil",
          ),

        ],
      ),
    );
  }

  // ================= INFO CARD =================

  Widget infoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),

      child: Column(

        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Icon(
            icon,
            color: color,
          ),

          const SizedBox(height: 12),

          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),

        ],
      ),
    );
  }

  // ================= SUMMARY CARD =================

  Widget summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius:
            BorderRadius.circular(22),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],

      ),

      child: Column(

        children: [

          Container(
            padding:
                const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
            ),
          ),

          const SizedBox(height: 14),

          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),

        ],
      ),
    );
  }

  // ================= TASK CARD =================

  Widget taskCard({
    required String title,
    required String subtitle,
    required String deadline,
  }) {
    return Container(

      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius:
            BorderRadius.circular(24),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.04),
            blurRadius: 12,
          ),
        ],

      ),

      child: Column(

        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Row(

            children: [

              Container(
                padding:
                    const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:
                      const Color(0xffDBEAFE),
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.design_services,
                  color: Color(0xff2563EB),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(

                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      deadline,
                      style: TextStyle(
                        color: Colors.red.shade400,
                        fontSize: 12,
                      ),
                    ),

                  ],
                ),
              ),

            ],
          ),

          const SizedBox(height: 18),

          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(

            width: double.infinity,
            height: 48,

            child: ElevatedButton(

              onPressed: () {},

              style:
                  ElevatedButton.styleFrom(

                backgroundColor:
                    const Color(0xff0F172A),

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(16),
                ),

              ),

              child: const Text(
                "Buka Tugas",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

            ),
          ),

        ],
      ),
    );
  }
}