import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AbsenScreen extends StatelessWidget {
  final AbsenModel absen;

  const AbsenScreen({
    super.key,
    required this.absen,
  });

  @override
  Widget build(BuildContext context) {
    final data = absen.data;

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          "Detail Absensi",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            /// CARD HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xff4F46E5),
                    Color(0xff7C3AED),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [

                  /// ICON
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.fingerprint,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    data.statusKehadiran,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                        .format(data.tanggal),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            /// DETAIL CARD
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [

                  buildItem(
                    icon: Icons.login,
                    title: "Jam Masuk",
                    value: data.jamMasuk,
                    color: Colors.green,
                  ),

                  const Divider(height: 30),

                  buildItem(
                    icon: Icons.logout,
                    title: "Jam Pulang",
                    value: data.jamPulang ?? "-",
                    color: Colors.red,
                  ),

                  const Divider(height: 30),

                  buildItem(
                    icon: Icons.location_on,
                    title: "Latitude",
                    value: data.latitudeMasuk.toString(),
                    color: Colors.orange,
                  ),

                  const Divider(height: 30),

                  buildItem(
                    icon: Icons.map,
                    title: "Longitude",
                    value: data.longitudeMasuk.toString(),
                    color: Colors.blue,
                  ),

                  const Divider(height: 30),

                  buildItem(
                    icon: Icons.badge,
                    title: "User ID",
                    value: data.userId.toString(),
                    color: Colors.purple,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            /// BUTTON
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff4F46E5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                ),
                onPressed: () {},
                child: const Text(
                  "Lihat Lokasi",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            icon,
            color: color,
          ),
        ),

        const SizedBox(width: 15),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}