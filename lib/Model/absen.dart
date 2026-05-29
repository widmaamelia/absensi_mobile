class AbsenModel {
    bool success;
    String message;
    Data data;

    AbsenModel({
        required this.success,
        required this.message,
        required this.data,
    });

}

class Data {
    int userId;
    DateTime tanggal;
    String jamMasuk;
    dynamic jamPulang;
    double latitudeMasuk;
    double longitudeMasuk;
    String statusKehadiran;
    DateTime updatedAt;
    DateTime createdAt;
    int id;

    Data({
        required this.userId,
        required this.tanggal,
        required this.jamMasuk,
        required this.jamPulang,
        required this.latitudeMasuk,
        required this.longitudeMasuk,
        required this.statusKehadiran,
        required this.updatedAt,
        required this.createdAt,
        required this.id,
    });

}
