import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/book_provider.dart';
import '../../models/book_model.dart';
import 'book_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bp = context.read<BookProvider>();
      bp.loadCategories();
      // Cache logic: only load if empty to prevent transition lag
      if (bp.searchBooks.isEmpty) {
        bp.loadSearchBooks(refresh: true);
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final bp = context.read<BookProvider>();
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      bp.loadMoreSearch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bp = context.watch<BookProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Cari Buku'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _ctrl,
              onSubmitted: (v) => bp.searchBooksQuery(v),
              onChanged: (v) {
                if (v.isEmpty) bp.clearSearchFilters();
              },
              decoration: InputDecoration(
                hintText: 'Cari judul atau penulis...',
                prefixIcon: Icon(Icons.search, color: Theme.of(context).primaryColor),
                suffixIcon: _ctrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _ctrl.clear();
                          bp.clearSearchFilters();
                        },
                      )
                    : null,
              ),
            ),
          ),
          if (bp.categories.isNotEmpty)
            SizedBox(
              height: 52,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: bp.categories.length + 1,
                itemBuilder: (context, i) {
                  if (i == 0) {
                    final sel = bp.searchCategoryId == null;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('Semua'),
                        selected: sel,
                        selectedColor: Theme.of(context).primaryColor,
                        labelStyle: TextStyle(
                          color: sel ? Colors.white : Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) => bp.filterSearchByCategory(null),
                      ),
                    );
                  }
                  final cat = bp.categories[i - 1];
                  final sel = bp.searchCategoryId == cat.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat.name),
                      selected: sel,
                      selectedColor: Theme.of(context).primaryColor,
                      labelStyle: TextStyle(
                        color: sel ? Colors.white : Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) => bp.filterSearchByCategory(cat.id),
                    ),
                  );
                },
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: bp.isLoadingSearch && bp.searchBooks.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : bp.searchBooks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off, size: 64, color: AppTheme.textHint),
                            const SizedBox(height: 12),
                            Text(
                              'Buku tidak ditemukan',
                              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: GridView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.50,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: bp.searchBooks.length,
                              itemBuilder: (context, i) {
                                final book = bp.searchBooks[i];
                                return GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: book.id)),
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardTheme.color ?? AppTheme.surface,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Theme.of(context).dividerColor),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        )
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                          child: AspectRatio(
                                            aspectRatio: 2 / 3, // Tall vertical aspect ratio
                                            child: book.coverUrl != null
                                                ? Image.network(
                                                    book.coverUrl!,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) => _placeholder(book),
                                                  )
                                                : _placeholder(book),
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  book.title,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12.5,
                                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  book.author,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontSize: 10.5, color: AppTheme.textSecondary),
                                                ),
                                                const Spacer(),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.availabilityColor(book.availability).withOpacity(0.12),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    AppTheme.availabilityLabel(book.availability),
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      color: AppTheme.availabilityColor(book.availability),
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          if (bp.isLoadingMoreSearch)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                            ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(BookModel b) => Container(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        child: Center(
          child: Text(
            b.title.isNotEmpty ? b.title[0] : '?',
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
          ),
        ),
      );
}
