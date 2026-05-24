import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';
import '../../providers/book_provider.dart';
import '../../models/category_model.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    context.read<BookProvider>().loadCategories();
  }

  void _showForm([CategoryModel? category]) {
    showDialog(
      context: context,
      builder: (context) => _CategoryFormDialog(
        category: category,
        onSaved: () {
          _load();
        },
      ),
    );
  }

  Future<void> _deleteCategory(CategoryModel category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: Text('Apakah Anda yakin ingin menghapus kategori "${category.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isLoading = true);
      try {
        final res = await ApiService.delete('/categories/${category.id}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'Kategori berhasil dihapus'),
              backgroundColor: res['success'] == true ? AppTheme.success : AppTheme.error,
            ),
          );
          _load();
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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Kelola Kategori Buku'),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Theme.of(context).primaryColor),
            onPressed: () => _showForm(),
          )
        ],
      ),
      body: _isLoading || provider.isLoadingCategories
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
          : provider.categories.isEmpty
              ? const Center(child: Text('Tidak ada data kategori'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.categories.length,
                  itemBuilder: (context, i) {
                    final cat = provider.categories[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          child: Icon(_getIcon(cat.icon), color: Theme.of(context).primaryColor),
                        ),
                        title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          cat.description ?? 'Tanpa deskripsi',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit_outlined, color: Theme.of(context).primaryColor),
                              onPressed: () => _showForm(cat),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                              onPressed: () => _deleteCategory(cat),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  IconData _getIcon(String? iconName) {
    switch (iconName) {
      case 'science':
        return Icons.science;
      case 'history_edu':
        return Icons.history_edu;
      case 'computer':
        return Icons.computer;
      case 'edit_note':
        return Icons.edit_note;
      case 'person':
        return Icons.person;
      case 'mosque':
        return Icons.mosque;
      case 'school':
        return Icons.school;
      case 'favorite':
        return Icons.favorite;
      case 'menu_book':
        return Icons.menu_book;
      default:
        return Icons.auto_stories;
    }
  }
}

class _CategoryFormDialog extends StatefulWidget {
  final CategoryModel? category;
  final VoidCallback onSaved;

  const _CategoryFormDialog({this.category, required this.onSaved});

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _selectedIcon = 'auto_stories';
  bool _isLoading = false;

  final List<String> _icons = const [
    'auto_stories',
    'menu_book',
    'science',
    'history_edu',
    'computer',
    'edit_note',
    'person',
    'mosque',
    'school',
    'favorite',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameCtrl.text = widget.category!.name;
      _descCtrl.text = widget.category!.description ?? '';
      _selectedIcon = widget.category!.icon ?? 'auto_stories';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final data = {
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      'icon': _selectedIcon,
    };

    try {
      if (widget.category == null) {
        await ApiService.post('/categories', data);
      } else {
        await ApiService.put('/categories/${widget.category!.id}', data);
      }

      if (mounted) {
        widget.onSaved();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.category == null ? 'Kategori berhasil ditambahkan' : 'Kategori berhasil diperbarui'),
            backgroundColor: AppTheme.success,
          ),
        );
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
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(widget.category == null ? 'Tambah Kategori' : 'Edit Kategori'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama Kategori'),
                validator: (v) => (v?.isEmpty ?? true) ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedIcon,
                decoration: const InputDecoration(labelText: 'Icon Kategori'),
                items: _icons
                    .map((ico) => DropdownMenuItem(value: ico, child: Text(ico)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedIcon = v);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          style: ElevatedButton.styleFrom(minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
          child: _isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
              : const Text('Simpan'),
        ),
      ],
    );
  }
}
