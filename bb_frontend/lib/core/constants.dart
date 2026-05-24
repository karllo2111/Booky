class AppConstants {
  // For both physical devices (using adb reverse) and emulators
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  static const String tokenKey = 'booky_token';
  static const String userKey  = 'booky_user';

  // Borrowing messages
  static const String borrowingSuccessMessage =
      'Peminjaman berhasil! Silakan ambil buku Anda di Perpustakaan Lantai 1 '
      'pada jam istirahat pertama atau kedua.\n\n'
      'Mohon ambil buku di hari yang sama saat Anda melakukan pemesanan, '
      'batas waktu pinjam Anda adalah 2 minggu. Jika tidak diambil hingga '
      'batas akhir istirahat kedua hari ini, maka peminjaman Anda akan '
      'dibatalkan secara otomatis.';

  static const String homeNoticeText =
      'Layanan perpustakaan hanya beroperasi pada hari sekolah.';
}
