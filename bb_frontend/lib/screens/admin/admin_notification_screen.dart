import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';
import '../../models/user_model.dart';

class AdminNotificationScreen extends StatefulWidget {
  const AdminNotificationScreen({super.key});

  @override
  State<AdminNotificationScreen> createState() => _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends State<AdminNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();

  String _selectedType = 'info';
  int? _selectedUserId; // null means send to everyone
  List<UserModel> _students = [];
  bool _isLoading = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.get('/admin/users');
      if (res['success'] == true) {
        final list = res['data']['data'] as List;
        setState(() {
          _students = list.map((u) => UserModel.fromJson(u)).toList();
        });
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);

    final data = {
      'title': _titleCtrl.text.trim(),
      'message': _msgCtrl.text.trim(),
      'type': _selectedType,
      'user_id': _selectedUserId,
    };

    try {
      final res = await ApiService.post('/notifications/send', data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Notifikasi berhasil dikirim'),
            backgroundColor: AppTheme.success,
          ),
        );
        _titleCtrl.clear();
        _msgCtrl.clear();
        setState(() {
          _selectedUserId = null;
          _selectedType = 'info';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _showRecipientSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final filtered = _students.where((s) {
              final query = searchQuery.toLowerCase();
              return s.name.toLowerCase().contains(query) ||
                  (s.kelas != null && s.kelas!.toLowerCase().contains(query));
            }).toList();

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Pilih Penerima Notifikasi'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Cari nama atau kelas...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (v) {
                        setStateDialog(() {
                          searchQuery = v;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView(
                        children: [
                          ListTile(
                            title: const Text('Semua Siswa', style: TextStyle(fontWeight: FontWeight.bold)),
                            trailing: _selectedUserId == null ? Icon(Icons.check, color: Theme.of(context).primaryColor) : null,
                            onTap: () {
                              setState(() {
                                _selectedUserId = null;
                              });
                              Navigator.pop(context);
                            },
                          ),
                          const Divider(height: 1),
                          ...filtered.map((s) {
                            final isSelected = _selectedUserId == s.id;
                            return ListTile(
                              title: Text(s.name),
                              subtitle: Text(s.kelas ?? '-'),
                              trailing: isSelected ? Icon(Icons.check, color: Theme.of(context).primaryColor) : null,
                              onTap: () {
                                setState(() {
                                  _selectedUserId = s.id;
                                });
                                Navigator.pop(context);
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String selectedRecipientName = 'Semua Siswa';
    if (_selectedUserId != null) {
      final user = _students.firstWhere(
        (s) => s.id == _selectedUserId,
        orElse: () => UserModel(id: 0, name: 'Penerima Terpilih', email: '', role: 'student'),
      );
      selectedRecipientName = '${user.name} (${user.kelas ?? "-"})';
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Kirim Notifikasi'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kirim Pesan Notifikasi',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),

                        // Searchable Recipient Picker
                        InkWell(
                          onTap: _showRecipientSearchDialog,
                          borderRadius: BorderRadius.circular(14),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Penerima',
                              suffixIcon: Icon(Icons.arrow_drop_down),
                            ),
                            child: Text(
                              selectedRecipientName,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          value: _selectedType,
                          decoration: const InputDecoration(labelText: 'Tipe Notifikasi'),
                          items: const [
                            DropdownMenuItem(value: 'info', child: Text('Info (Biru)')),
                            DropdownMenuItem(value: 'success', child: Text('Sukses (Hijau)')),
                            DropdownMenuItem(value: 'reminder', child: Text('Pengingat (Kuning)')),
                            DropdownMenuItem(value: 'warning', child: Text('Peringatan (Merah)')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _selectedType = v);
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _titleCtrl,
                          decoration: const InputDecoration(labelText: 'Judul Notifikasi'),
                          validator: (v) => (v?.isEmpty ?? true) ? 'Judul wajib diisi' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _msgCtrl,
                          maxLines: 4,
                          decoration: const InputDecoration(labelText: 'Isi Pesan Notifikasi'),
                          validator: (v) => (v?.isEmpty ?? true) ? 'Pesan wajib diisi' : null,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isSending ? null : _send,
                          child: _isSending
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                              : const Text('Kirim Notifikasi'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
