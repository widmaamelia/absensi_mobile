import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AbsenMapWidget extends StatelessWidget {
  final double userLat;
  final double userLng;
  final double officeLat;
  final double officeLng;
  final double radiusMeters;
  final double? userAccuracy; // akurasi GPS dalam meter

  const AbsenMapWidget({
    super.key,
    required this.userLat,
    required this.userLng,
    required this.officeLat,
    required this.officeLng,
    this.radiusMeters = 50,
    this.userAccuracy, // opsional
  });

  @override
  Widget build(BuildContext context) {
    final userPoint   = LatLng(userLat, userLng);
    final officePoint = LatLng(officeLat, officeLng);

    final distance = const Distance().as(
      LengthUnit.Meter,
      userPoint,
      officePoint,
    );
    final isInRadius = distance <= radiusMeters;

    final centerLat = (userLat + officeLat) / 2;
    final centerLng = (userLng + officeLng) / 2;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 220,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(centerLat, centerLng),
            initialZoom: 17.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.interntrack',
            ),

            CircleLayer(
              circles: [
                // Lingkaran radius kantor
                CircleMarker(
                  point: officePoint,
                  radius: radiusMeters,
                  useRadiusInMeter: true,
                  color: Colors.blue.withOpacity(0.12),
                  borderColor: Colors.blue.withOpacity(0.5),
                  borderStrokeWidth: 1.5,
                ),

                // Lingkaran akurasi GPS user (kalau tersedia)
                if (userAccuracy != null && userAccuracy! > 0)
                  CircleMarker(
                    point: userPoint,
                    radius: userAccuracy!,
                    useRadiusInMeter: true,
                    color: (isInRadius ? Colors.green : Colors.orange)
                        .withOpacity(0.12),
                    borderColor: (isInRadius ? Colors.green : Colors.orange)
                        .withOpacity(0.4),
                    borderStrokeWidth: 1,
                  ),
              ],
            ),

            MarkerLayer(
              markers: [
                // Pin kantor
                Marker(
                  point: officePoint,
                  width: 36,
                  height: 36,
                  child: const Icon(
                    Icons.business_rounded,
                    color: Colors.red,
                    size: 32,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black26)],
                  ),
                ),
                // Pin user
                Marker(
                  point: userPoint,
                  width: 36,
                  height: 36,
                  child: Icon(
                    Icons.person_pin_circle_rounded,
                    color: isInRadius ? Colors.green : Colors.orange,
                    size: 36,
                    shadows: const [
                      Shadow(blurRadius: 4, color: Colors.black26),
                    ],
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