import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';
import '../../providers/book_provider.dart';
import '../../providers/borrowing_provider.dart';
import '../../providers/wishlist_notification_provider.dart';
import '../../models/book_model.dart';

class BookDetailScreen extends StatefulWidget {
  final int bookId;
  const BookDetailScreen({super.key, required this.bookId});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  Map<String, dynamic>? _bookData;
  BookModel? _book;
  List<dynamic> _activeBorrowings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiService.get('/books/${widget.bookId}', auth: false);
      if (res['success'] == true && mounted) {
        final data = res['data'];
        setState(() {
          _bookData = data;
          _book = BookModel.fromJson(data);
          _activeBorrowings = data['borrowings'] ?? [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _availableStock {
    if (_book == null) return 0;
    return _book!.stock - _activeBorrowings.length;
  }

  bool get _canBorrow => _availableStock > 0;

  Future<void> _borrow() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Konfirmasi Peminjaman'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Anda akan meminjam:\n\n"${_book!.title}"', textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Batas waktu pinjam adalah 2 minggu. Ambil buku di Perpustakaan Lantai 1 saat jam istirahat.',
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
            child: const Text('Pinjam'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    try {
      final success = await context.read<BorrowingProvider>().borrowBook(_book!.id);
      if (mounted) {
        if (success) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(children: [
                Icon(Icons.check_circle_outline, color: AppTheme.success, size: 28),
                SizedBox(width: 8),
                Text('Booking Berhasil!'),
              ]),
              content: Text('Anda berhasil memesan "${_book!.title}". Silakan ambil buku di perpustakaan.'),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mengajukan peminjaman')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    }
  }

  Widget _coverFallback() {
    return Container(
      color: AppTheme.primary,
      child: Center(
        child: Text(
          _book != null && _book!.title.isNotEmpty ? _book!.title[0].toUpperCase() : '?',
          style: const TextStyle(fontSize: 80, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppTheme.primary)));
    if (_book == null) return const Scaffold(body: Center(child: Text('Buku tidak ditemukan')));

    final wishlist = context.watch<WishlistProvider>();
    final inWishlist = wishlist.isInWishlist(_book!.id);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: AppTheme.primary,
            actions: [
              IconButton(
                icon: Icon(inWishlist ? Icons.bookmark : Icons.bookmark_outline, color: Colors.white),
                onPressed: () async {
                  if (inWishlist) {
                    await wishlist.removeFromWishlist(_book!.id);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dihapus dari wishlist')));
                  } else {
                    await wishlist.addToWishlist(_book!.id);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ditambahkan ke wishlist ✓'), backgroundColor: AppTheme.success));
                  }
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // ── Blurred background image ──
                  if (_book!.coverUrl != null)
                    Image.network(
                      _book!.coverUrl!,
                      fit: BoxFit.cover,
                      color: Colors.black.withOpacity(0.55),
                      colorBlendMode: BlendMode.darken,
                    )
                  else
                    Container(color: AppTheme.primaryDark),

                  // Blur effect overlay
                  ClipRect(
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(color: Colors.transparent),
                    ),
                  ),

                  // Subtle gradient overlay for better contrast
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.black.withOpacity(0.1),
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),

                  // ── Uncropped centered tall cover ──
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 40, bottom: 20),
                      height: 220,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: AspectRatio(
                        aspectRatio: 2 / 3,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: _book!.coverUrl != null
                              ? Image.network(
                                  _book!.coverUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _coverFallback(),
                                )
                              : _coverFallback(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.availabilityColor(_book!.availability).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      AppTheme.availabilityLabel(_book!.availability),
                      style: TextStyle(
                        color: AppTheme.availabilityColor(_book!.availability),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_book!.category != null)
                    Chip(label: Text(_book!.category!.name, style: const TextStyle(fontSize: 11))),
                ]),
                const SizedBox(height: 12),
                Text(_book!.title, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 6),
                Text('oleh ${_book!.author}', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 16),
                _infoRow('Penerbit', _book!.publisher ?? '-'),
                _infoRow('Tahun', _book!.year?.toString() ?? '-'),
                if (_book!.isbn != null) _infoRow('ISBN', _book!.isbn!),

                const SizedBox(height: 20),

                // ── Stock Breakdown Table ──
                _buildStockTable(),

                if (_book!.description != null) ...[
                  const SizedBox(height: 20),
                  Text('Deskripsi', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    _book!.description!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
                    maxLines: 10,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _canBorrow
              ? ElevatedButton.icon(
                  onPressed: _borrow,
                  icon: const Icon(Icons.library_add_outlined),
                  label: Text('Pinjam Sekarang (${_availableStock} tersedia)'),
                )
              : ElevatedButton(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.textHint),
                  child: const Text('Semua Stok Sedang Dipinjam'),
                ),
        ),
      ),
    );
  }

  Widget _buildStockTable() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Icon(Icons.inventory_2_outlined, size: 18, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text('Informasi Stok', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const Divider(height: 1),

          // Stock summary rows
          _stockRow('Total Stok', '${_book!.stock} buku', Icons.library_books_outlined, Theme.of(context).primaryColor),
          _stockRow('Sedang Dipinjam', '${_activeBorrowings.length} buku', Icons.person_outline, AppTheme.warning),
          _stockRow(
            'Tersedia',
            '$_availableStock buku',
            Icons.check_circle_outline,
            _availableStock > 0 ? AppTheme.success : AppTheme.error,
          ),

          // Active borrowings detail (if any)
          if (_activeBorrowings.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Text('Detail Peminjaman Aktif', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color)),
            ),
            ..._activeBorrowings.map((b) {
              final status = b['status'] ?? 'active';
              final user = b['user'];
              final userName = user != null ? (user['name'] ?? 'Siswa') : 'Siswa';
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppTheme.statusColor(status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(userName, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.statusColor(status).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        AppTheme.statusLabel(status),
                        style: TextStyle(fontSize: 9, color: AppTheme.statusColor(status), fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _stockRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      SizedBox(width: 80, child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
      const Text(': ', style: TextStyle(color: AppTheme.textSecondary)),
      Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
    ]),
  );
}
