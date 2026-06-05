class ApiConfig {
  // =====================================================
  // ENVIRONMENT
  // =====================================================

  static const bool isProduction = false;

  // =====================================================
  // BASE URL
  // =====================================================

  static String get baseUrl {
    // SERVER HOSTING
    if (isProduction) {
      return 'https://your-production-domain.com';
    }

    // WIFI / LARAVEL LOCAL
    return 'http://172.28.52.111:8000';
  }

  static String get logbook => '$apiUrl/logbook';

  // =====================================================
  // API URL
  // =====================================================

  static String get apiUrl => '$baseUrl/api';

  // =====================================================
  // AUTH
  // =====================================================

  static String get login => '$apiUrl/login';

  static String get logout => '$apiUrl/logout';

  static String get register => '$apiUrl/register';

  static String get me => '$apiUrl/me';

  // =====================================================
  // ABSEN
  // =====================================================

  static String get absen => '$apiUrl/absen';

  static String get todayAbsen => '$apiUrl/absen/today';

  static String get absenMasuk => '$apiUrl/absen/masuk';

  static String get absenPulang => '$apiUrl/absen/pulang';

  static String get riwayatAbsen => '$apiUrl/absen/riwayat';

  static String get summaryAbsen => '$apiUrl/absen/summary';

  // =====================================================
  // PROFILE
  // =====================================================

  static String get profile => '$apiUrl/profile';

  // static String get updateProfile => '$apiUrl/profile/update';

  // Gunakan $baseUrl agar tidak ada tambahan /api
  static String get updateProfile => '$apiUrl/profile'; 
  static String get updatePassword => '$apiUrl/password';
  static String get detailProfil => '$apiUrl/profil/detail';

  //     // Gunakan PATCH untuk update profil sesuai standar Laravel Breeze
  // static String get updateProfile =>
  // '$baseUrl/profile';

  // Gunakan PUT untuk update password sesuai standar Laravel Breeze

  // =====================================================
  // HEADERS
  // =====================================================

  static Map<String, String> jsonHeaders({String? token}) {
    return {
      'Accept': 'application/json',

      'Content-Type': 'application/json',

      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Map<String, String> formHeaders({String? token}) {
    return {
      'Accept': 'application/json',

      'Content-Type': 'application/x-www-form-urlencoded',

      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // =====================================================
  // DEBUG
  // =====================================================

  static void debugConfig() {
    print('======================');
    print('API CONFIG');
    print('======================');
    print('Production : $isProduction');
    print('Base URL   : $baseUrl');
    print('API URL    : $apiUrl');
    print('======================');
  }
}
