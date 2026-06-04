import 'package:intl/intl.dart';

class AbsensiModel {
  final int? id;
  final int? userId;
  final String? tanggal;
  final String? jamMasuk;
  final String? jamPulang;
  final double? latitudeMasuk;
  final double? longitudeMasuk;
  final double? latitudePulang;
  final double? longitudePulang;
  final String? statusKehadiran;
  final String? statusKedatangan;

  AbsensiModel({
    this.id,
    this.userId,
    this.tanggal,
    this.jamMasuk,
    this.jamPulang,
    this.latitudeMasuk,
    this.longitudeMasuk,
    this.latitudePulang,
    this.longitudePulang,
    this.statusKehadiran,
    this.statusKedatangan,
  });

  factory AbsensiModel.fromJson(Map<String, dynamic> json) {
    return AbsensiModel(
      id: json['id'],
      userId: json['user_id'],
      tanggal: json['tanggal'],
      jamMasuk: json['jam_masuk'],
      jamPulang: json['jam_pulang'],
      latitudeMasuk: json['latitude_masuk'] != null
          ? double.tryParse(json['latitude_masuk'].toString())
          : null,
      longitudeMasuk: json['longitude_masuk'] != null
          ? double.tryParse(json['longitude_masuk'].toString())
          : null,
      latitudePulang: json['latitude_pulang'] != null
          ? double.tryParse(json['latitude_pulang'].toString())
          : null,
      longitudePulang: json['longitude_pulang'] != null
          ? double.tryParse(json['longitude_pulang'].toString())
          : null,
      statusKehadiran: json['status_kehadiran'],
      statusKedatangan: json['status_kedatangan'],
    );
  }

  AbsensiModel copyWith({
    int? id,
    int? userId,
    String? tanggal,
    String? jamMasuk,
    String? jamPulang,
    double? latitudeMasuk,
    double? longitudeMasuk,
    double? latitudePulang,
    double? longitudePulang,
    String? statusKehadiran,
    String? statusKedatangan,
  }) {
    return AbsensiModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tanggal: tanggal ?? this.tanggal,
      jamMasuk: jamMasuk ?? this.jamMasuk,
      jamPulang: jamPulang ?? this.jamPulang,
      latitudeMasuk: latitudeMasuk ?? this.latitudeMasuk,
      longitudeMasuk: longitudeMasuk ?? this.longitudeMasuk,
      latitudePulang: latitudePulang ?? this.latitudePulang,
      longitudePulang: longitudePulang ?? this.longitudePulang,
      statusKehadiran: statusKehadiran ?? this.statusKehadiran,
      statusKedatangan: statusKedatangan ?? this.statusKedatangan,
    );
  }

  /// Formatted tanggal (Indonesian) e.g. "Rabu, 3 Juni 2026"
  String get formattedTanggal {
    try {
      if (tanggal == null || tanggal!.isEmpty) return '';
      final dt = DateTime.parse(tanggal!);
      final days = ['Senin','Selasa','Rabu','Kamis','Jumat','Sabtu','Minggu'];
      final months = [
        'Januari','Februari','Maret','April','Mei','Juni',
        'Juli','Agustus','September','Oktober','November','Desember'
      ];
      final dayName = days[dt.weekday - 1];
      final monthName = months[dt.month - 1];
      return '$dayName, ${dt.day} $monthName ${dt.year}';
    } catch (_) {
      return tanggal ?? '';
    }
  }

  /// Formatted jam (HH:mm) from jamMasuk / jamPulang if present
  String formattedJamMasuk() {
    try {
      if (jamMasuk == null || jamMasuk!.isEmpty) return '';
      if (jamMasuk!.length >= 5) return jamMasuk!.substring(0, 5);
      return jamMasuk!;
    } catch (_) {
      return jamMasuk ?? '';
    }
  }

  String formattedJamPulang() {
    try {
      if (jamPulang == null || jamPulang!.isEmpty) return '';
      if (jamPulang!.length >= 5) return jamPulang!.substring(0, 5);
      return jamPulang!;
    } catch (_) {
      return jamPulang ?? '';
    }
  }

  bool get sudahMasuk => jamMasuk != null;
  bool get sudahPulang => jamPulang != null;

  /// Returns true when the attendance arrival status indicates late.
  /// Handles common server values like 'terlambat' or 'late' (case-insensitive).
  bool get isTerlambat {
    final s = statusKedatangan;
    if (s == null) return false;
    final lower = s.toLowerCase();
    return lower.contains('terlambat') || lower.contains('late');
  }
}