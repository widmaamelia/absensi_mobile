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

  bool get sudahMasuk => jamMasuk != null;
  bool get sudahPulang => jamPulang != null;
}