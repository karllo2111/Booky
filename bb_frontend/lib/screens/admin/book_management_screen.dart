import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';
import '../../providers/book_provider.dart';
import '../../models/book_model.dart';

class BookManagementScreen extends StatefulWidget {
  const BookManagementScreen({super.key});

  @override
  State<BookManagementScreen> createState() => _BookManagementScreenState();
}

class _BookManagementScreenState extends State<BookManagementScreen> {
  final _searchCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bp = context.read<BookProvider>();
      bp.loadCategories();
      if (bp.adminBooks.isEmpty) {
        bp.loadAdminBooks(refresh: true);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final bp = context.read<BookProvider>();
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      bp.loadMoreAdmin();
    }
  }

  void _showBookForm([BookModel? book]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _BookFormModal(book: book),
    );
  }

  Future<void> _deleteBook(BookModel book) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Buku'),
        content: Text('Apakah Anda yakin ingin menghapus buku "${book.title}"?'),
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
      final success = await context.read<BookProvider>().deleteBook(book.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Buku berhasil dihapus' : 'Gagal menghapus buku'),
            backgroundColor: success ? AppTheme.success : AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Kelola Data Buku'),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Theme.of(context).primaryColor),
            onPressed: () => _showBookForm(),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) {
                if (v.isEmpty) {
                  context.read<BookProvider>().clearAdminFilters();
                }
              },
              onSubmitted: (v) => context.read<BookProvider>().searchAdminBooks(v),
              decoration: InputDecoration(
                hintText: 'Cari judul, penulis...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          context.read<BookProvider>().clearAdminFilters();
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: provider.isLoadingAdmin && provider.adminBooks.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : provider.adminBooks.isEmpty
                    ? const Center(child: Text('Tidak ada data buku'))
                    : RefreshIndicator(
                        onRefresh: () => provider.loadAdminBooks(refresh: true),
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: provider.adminBooks.length + (provider.isLoadingMoreAdmin ? 1 : 0),
                          itemBuilder: (context, i) {
                            if (i >= provider.adminBooks.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                              );
                            }
                            final book = provider.adminBooks[i];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 50,
                                    height: 70,
                                    child: book.coverUrl != null
                                        ? Image.network(
                                            book.coverUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              color: Theme.of(context).dividerColor,
                                              child: const Icon(Icons.book),
                                            ),
                                          )
                                        : Container(
                                            color: Theme.of(context).dividerColor,
                                            child: const Icon(Icons.book),
                                          ),
                                  ),
                                ),
                                title: Text(
                                  book.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(book.author),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.availabilityColor(book.availability).withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            AppTheme.availabilityLabel(book.availability),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: AppTheme.availabilityColor(book.availability),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text('Stok: ${book.stock}', style: const TextStyle(fontSize: 11)),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit_outlined, color: Theme.of(context).primaryColor),
                                      onPressed: () => _showBookForm(book),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                                      onPressed: () => _deleteBook(book),
                                    ),
                                  ],
                                ),
                              ),
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

class _BookFormModal extends StatefulWidget {
  final BookModel? book;
  const _BookFormModal({this.book});

  @override
  State<_BookFormModal> createState() => _BookFormModalState();
}

class _BookFormModalState extends State<_BookFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();
  final _publisherCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _isbnCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _coverCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();

  int? _selectedCatId;
  String _selectedAvailability = 'available';
  bool _isLoading = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    final cats = context.read<BookProvider>().categories;
    if (cats.isNotEmpty) {
      _selectedCatId = cats.first.id;
    }

    if (widget.book != null) {
      final b = widget.book!;
      _titleCtrl.text = b.title;
      _authorCtrl.text = b.author;
      _publisherCtrl.text = b.publisher ?? '';
      _yearCtrl.text = b.year?.toString() ?? '';
      _isbnCtrl.text = b.isbn ?? '';
      _descCtrl.text = b.description ?? '';
      _coverCtrl.text = b.coverUrl ?? '';
      _stockCtrl.text = b.stock.toString();
      _selectedCatId = b.categoryId;
      _selectedAvailability = b.availability;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    _publisherCtrl.dispose();
    _yearCtrl.dispose();
    _isbnCtrl.dispose();
    _descCtrl.dispose();
    _coverCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pilih Sumber Gambar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeri'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await picker.pickImage(source: source, maxWidth: 800, imageQuality: 85);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
        _coverCtrl.text = picked.name; // Show file name
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    bool success = false;

    try {
      if (_selectedImage != null) {
        // Use multipart upload when an image file is selected
        final fields = <String, String>{
          'category_id': _selectedCatId.toString(),
          'title': _titleCtrl.text.trim(),
          'author': _authorCtrl.text.trim(),
          'stock': (int.tryParse(_stockCtrl.text.trim()) ?? 1).toString(),
          'availability': _selectedAvailability,
        };
        if (_publisherCtrl.text.trim().isNotEmpty) fields['publisher'] = _publisherCtrl.text.trim();
        if (_yearCtrl.text.trim().isNotEmpty) fields['year'] = _yearCtrl.text.trim();
        if (_isbnCtrl.text.trim().isNotEmpty) fields['isbn'] = _isbnCtrl.text.trim();
        if (_descCtrl.text.trim().isNotEmpty) fields['description'] = _descCtrl.text.trim();

        final path = widget.book == null ? '/books' : '/books/${widget.book!.id}';
        await ApiService.multipartPost(path, fields: fields, file: _selectedImage);
        // Refresh admin & home lists
        if (mounted) {
          await context.read<BookProvider>().loadAdminBooks(refresh: true);
          await context.read<BookProvider>().loadHomeBooks(refresh: true);
        }
        success = true;
      } else {
        // Normal JSON POST/PUT
        final data = {
          'category_id': _selectedCatId,
          'title': _titleCtrl.text.trim(),
          'author': _authorCtrl.text.trim(),
          'publisher': _publisherCtrl.text.trim().isEmpty ? null : _publisherCtrl.text.trim(),
          'year': _yearCtrl.text.trim().isEmpty ? null : int.tryParse(_yearCtrl.text.trim()),
          'isbn': _isbnCtrl.text.trim().isEmpty ? null : _isbnCtrl.text.trim(),
          'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          'cover_url': _coverCtrl.text.trim().isEmpty ? null : _coverCtrl.text.trim(),
          'stock': int.tryParse(_stockCtrl.text.trim()) ?? 1,
          'availability': _selectedAvailability,
        };

        final bp = context.read<BookProvider>();
        if (widget.book == null) {
          success = await bp.createBook(data);
        } else {
          success = await bp.updateBook(widget.book!.id, data);
        }
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
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.book == null ? 'Buku berhasil ditambahkan' : 'Buku berhasil diperbarui'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cats = context.read<BookProvider>().categories;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.book == null ? 'Tambah Buku Baru' : 'Edit Buku',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Judul Buku'),
                validator: (v) => (v?.isEmpty ?? true) ? 'Judul wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _authorCtrl,
                decoration: const InputDecoration(labelText: 'Penulis'),
                validator: (v) => (v?.isEmpty ?? true) ? 'Penulis wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedCatId,
                      decoration: const InputDecoration(labelText: 'Kategori'),
                      items: cats
                          .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCatId = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedAvailability,
                      decoration: const InputDecoration(labelText: 'Ketersediaan'),
                      items: const [
                        DropdownMenuItem(value: 'available', child: Text('Tersedia')),
                        DropdownMenuItem(value: 'borrowed', child: Text('Dipinjam')),
                        DropdownMenuItem(value: 'late', child: Text('Terlambat')),
                      ],
                      onChanged: (v) => setState(() => _selectedAvailability = v ?? 'available'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stockCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Stok'),
                      validator: (v) => (v?.isEmpty ?? true) ? 'Stok wajib diisi' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _yearCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Tahun Terbit'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _publisherCtrl,
                decoration: const InputDecoration(labelText: 'Penerbit'),
              ),
              const SizedBox(height: 12),

              // Cover Image — URL or Gallery picker
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _coverCtrl,
                      decoration: const InputDecoration(labelText: 'URL Gambar Cover'),
                      readOnly: _selectedImage != null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image_outlined, size: 18),
                      label: const Text('Galeri', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                ],
              ),

              // Show image preview if selected
              if (_selectedImage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(_selectedImage!, height: 120, fit: BoxFit.cover),
                      ),
                      InkWell(
                        onTap: () => setState(() {
                          _selectedImage = null;
                          _coverCtrl.clear();
                        }),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.error,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Deskripsi Buku'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                    : const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
