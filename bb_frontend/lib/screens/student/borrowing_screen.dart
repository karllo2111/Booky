import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../providers/borrowing_provider.dart';
import '../../models/borrowing_model.dart';

class BorrowingScreen extends StatefulWidget {
  const BorrowingScreen({super.key});

  @override
  State<BorrowingScreen> createState() => _BorrowingScreenState();
}

class _BorrowingScreenState extends State<BorrowingScreen> {
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BorrowingProvider>().loadBorrowings(status: _selectedFilter);
    });
  }

  void _onFilterChanged(String? val) {
    if (val != null) {
      setState(() => _selectedFilter = val);
      context.read<BorrowingProvider>().loadBorrowings(status: val);
    }
  }

  Future<void> _cancelBorrowing(BorrowingModel borrowing) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Peminjaman'),
        content: Text('Apakah Anda yakin ingin membatalkan peminjaman buku "${borrowing.book?.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await context.read<BorrowingProvider>().cancelBorrowing(borrowing.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Peminjaman berhasil dibatalkan' : 'Gagal membatalkan peminjaman'),
            backgroundColor: success ? AppTheme.success : AppTheme.error,
          ),
        );
        if (success) {
          context.read<BorrowingProvider>().loadBorrowings(status: _selectedFilter);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BorrowingProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Peminjaman Saya'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DropdownButton<String>(
              value: _selectedFilter,
              onChanged: _onFilterChanged,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Semua')),
                DropdownMenuItem(value: 'pending', child: Text('Booking')),
                DropdownMenuItem(value: 'active', child: Text('Dipinjam')),
                DropdownMenuItem(value: 'returned', child: Text('Kembali')),
                DropdownMenuItem(value: 'overdue', child: Text('Terlambat')),
                DropdownMenuItem(value: 'cancelled', child: Text('Batal')),
              ],
            ),
          )
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : provider.borrowings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.library_books_outlined, size: 64, color: AppTheme.textHint),
                      const SizedBox(height: 16),
                      Text(
                        'Tidak ada data peminjaman',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppTheme.primary,
                  onRefresh: () => provider.loadBorrowings(status: _selectedFilter),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.borrowings.length,
                    itemBuilder: (context, i) {
                      final item = provider.borrowings[i];
                      return _BorrowingCard(
                        borrowing: item,
                        onCancel: item.isPending ? () => _cancelBorrowing(item) : null,
                      );
                    },
                  ),
                ),
    );
  }
}

class _BorrowingCard extends StatelessWidget {
  final BorrowingModel borrowing;
  final VoidCallback? onCancel;

  const _BorrowingCard({required this.borrowing, this.onCancel});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.statusColor(borrowing.status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    AppTheme.statusLabel(borrowing.status),
                    style: TextStyle(
                      color: AppTheme.statusColor(borrowing.status),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  dateFormat.format(borrowing.borrowedAt),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 60,
                    height: 80,
                    child: borrowing.book?.coverUrl != null
                        ? Image.network(
                            borrowing.book!.coverUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(color: AppTheme.divider, child: const Icon(Icons.book)),
                          )
                        : Container(color: AppTheme.divider, child: const Icon(Icons.book)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        borrowing.book?.title ?? 'Buku Tanpa Judul',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Penulis: ${borrowing.book?.author ?? '-'}',
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        borrowing.status == 'pending'
                            ? 'Batas Pengambilan: Hari Ini (Istirahat 2)'
                            : 'Batas Kembali: ${dateFormat.format(borrowing.dueDate)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: borrowing.isOverdue ? AppTheme.error : AppTheme.textSecondary,
                          fontWeight: borrowing.isOverdue ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (borrowing.adminNotes != null && borrowing.adminNotes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Catatan Admin: ${borrowing.adminNotes}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            ],
            if (onCancel != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error),
                      minimumSize: const Size(120, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Batalkan', style: TextStyle(fontSize: 13)),
                  ),
                ],
              )
            ],
          ],
        ),
      ),
    );
  }
}
