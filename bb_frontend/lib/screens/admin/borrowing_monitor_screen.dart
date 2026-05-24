import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';
import '../../providers/borrowing_provider.dart';
import '../../models/borrowing_model.dart';

class BorrowingMonitorScreen extends StatefulWidget {
  const BorrowingMonitorScreen({super.key});

  @override
  State<BorrowingMonitorScreen> createState() => _BorrowingMonitorScreenState();
}

class _BorrowingMonitorScreenState extends State<BorrowingMonitorScreen> {
  String _selectedFilter = 'all';

  static const _filterItems = [
    DropdownMenuItem(value: 'all',       child: Text('Semua')),
    DropdownMenuItem(value: 'pending',   child: Text('Booking')),
    DropdownMenuItem(value: 'active',    child: Text('Dipinjam')),
    DropdownMenuItem(value: 'returned',  child: Text('Kembali')),
    DropdownMenuItem(value: 'overdue',   child: Text('Terlambat')),
    DropdownMenuItem(value: 'cancelled', child: Text('Batal')),
  ];

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

  Future<void> _updateStatus(BorrowingModel borrowing) async {
    String currentStatus = borrowing.status;
    String nextStatus    = currentStatus;
    final noteCtrl       = TextEditingController();

    final result = await showDialog<Map<String, String>?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Ubah Status Peminjaman'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${borrowing.book?.title ?? "Buku"}',
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Peminjam: ${borrowing.user?.name ?? "Siswa"}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: nextStatus,
                decoration: const InputDecoration(labelText: 'Status Baru'),
                items: const [
                  DropdownMenuItem(value: 'pending',   child: Text('Pending (Booking)')),
                  DropdownMenuItem(value: 'active',    child: Text('Active (Dipinjam)')),
                  DropdownMenuItem(value: 'returned',  child: Text('Returned (Dikembalikan)')),
                  DropdownMenuItem(value: 'overdue',   child: Text('Overdue (Terlambat)')),
                  DropdownMenuItem(value: 'cancelled', child: Text('Cancelled (Dibatalkan)')),
                ],
                onChanged: (v) { if (v != null) setDialogState(() => nextStatus = v); },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: 'Catatan Admin (Opsional)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, {
                'status': nextStatus,
                'notes': noteCtrl.text.trim(),
              }),
              style: ElevatedButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      final success = await context.read<BorrowingProvider>().updateStatus(
            borrowing.id,
            result['status']!,
            adminNotes: result['notes']!.isEmpty ? null : result['notes'],
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success ? 'Status berhasil diperbarui' : 'Gagal memperbarui status'),
          backgroundColor: success ? AppTheme.success : AppTheme.error,
        ));
        if (success) {
          context.read<BorrowingProvider>().loadBorrowings(status: _selectedFilter);
        }
      }
    }
  }

  Future<void> _sendReminder(BorrowingModel borrowing) async {
    try {
      final res = await ApiService.post('/admin/remind/${borrowing.id}', {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['message'] ?? 'Pengingat berhasil dikirim'),
          backgroundColor: AppTheme.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppTheme.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BorrowingProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Monitor Peminjaman'),
      ),
      // Filter bar moved to body to avoid AppBar overflow
      body: Column(
        children: [
          // ── Filter pill row ─────────────────────────────────────────────
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.filter_list, size: 18, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedFilter,
                      isExpanded: true,
                      onChanged: _onFilterChanged,
                      items: _filterItems,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Content ─────────────────────────────────────────────────────
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : provider.borrowings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.swap_horiz, size: 64, color: AppTheme.textHint),
                            const SizedBox(height: 16),
                            Text(
                              'Tidak ada data peminjaman',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(color: AppTheme.textSecondary),
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
                            return _BorrowingMonitorCard(
                              borrowing: item,
                              onUpdateStatus: () => _updateStatus(item),
                              onSendReminder: (item.status == 'active' || item.status == 'overdue')
                                  ? () => _sendReminder(item)
                                  : null,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Borrowing Monitor Card — overflow-safe
// ─────────────────────────────────────────────────────────────────────────────
class _BorrowingMonitorCard extends StatelessWidget {
  final BorrowingModel borrowing;
  final VoidCallback onUpdateStatus;
  final VoidCallback? onSendReminder;

  const _BorrowingMonitorCard({
    required this.borrowing,
    required this.onUpdateStatus,
    this.onSendReminder,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row: status badge + date ─────────────────────────────
            Row(
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
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  fmt.format(borrowing.borrowedAt),
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Book cover + info row ─────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 52,
                    height: 70,
                    child: borrowing.book?.coverUrl != null
                        ? Image.network(
                            borrowing.book!.coverUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppTheme.divider,
                              child: const Icon(Icons.book, size: 24, color: AppTheme.textHint),
                            ),
                          )
                        : Container(
                            color: AppTheme.divider,
                            child: const Icon(Icons.book, size: 24, color: AppTheme.textHint),
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // Title / student / due date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        borrowing.book?.title ?? 'Buku Tanpa Judul',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${borrowing.user?.name ?? "Siswa"} · ${borrowing.user?.kelas ?? "-"}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Batas: ${fmt.format(borrowing.dueDate)}',
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

            // ── Admin notes ──────────────────────────────────────────────────
            if (borrowing.adminNotes != null && borrowing.adminNotes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Catatan: ${borrowing.adminNotes}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            const SizedBox(height: 12),

            // ── Action buttons ───────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onSendReminder != null) ...[
                  Flexible(
                    child: OutlinedButton.icon(
                      onPressed: onSendReminder,
                      icon: const Icon(Icons.alarm, size: 14),
                      label: const Text('Pengingat', style: TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.warning,
                        side: const BorderSide(color: AppTheme.warning),
                        minimumSize: const Size(0, 34),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: ElevatedButton.icon(
                    onPressed: onUpdateStatus,
                    icon: const Icon(Icons.edit, size: 14, color: Colors.white),
                    label: const Text('Ubah Status', style: TextStyle(fontSize: 11, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      minimumSize: const Size(0, 34),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
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
