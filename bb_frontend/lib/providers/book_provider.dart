import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../models/book_model.dart';
import '../models/category_model.dart';

class BookProvider extends ChangeNotifier {
  List<CategoryModel> _categories = [];
  bool _isLoadingCategories = false;

  // ── Home Screen State ──
  List<BookModel> _homeBooks = [];
  bool _isLoadingHome = false;
  bool _isLoadingMoreHome = false;
  int _homePage = 1;
  int _homeLastPage = 1;
  int? _homeCategoryId;
  String? _homeError;

  // ── Search Screen State ──
  List<BookModel> _searchBooks = [];
  bool _isLoadingSearch = false;
  bool _isLoadingMoreSearch = false;
  int _searchPage = 1;
  int _searchLastPage = 1;
  int? _searchCategoryId;
  String _searchQuery = '';
  String? _searchError;

  // ── Admin Screen State ──
  List<BookModel> _adminBooks = [];
  bool _isLoadingAdmin = false;
  bool _isLoadingMoreAdmin = false;
  int _adminPage = 1;
  int _adminLastPage = 1;
  String _adminQuery = '';
  String? _adminError;

  // ── Getters ──
  List<CategoryModel> get categories => _categories;
  bool get isLoadingCategories => _isLoadingCategories;

  // Home Getters
  List<BookModel> get homeBooks => _homeBooks;
  bool get isLoadingHome => _isLoadingHome;
  bool get isLoadingMoreHome => _isLoadingMoreHome;
  int? get homeCategoryId => _homeCategoryId;
  bool get hasMoreHome => _homePage < _homeLastPage;
  String? get homeError => _homeError;

  // Search Getters
  List<BookModel> get searchBooks => _searchBooks;
  bool get isLoadingSearch => _isLoadingSearch;
  bool get isLoadingMoreSearch => _isLoadingMoreSearch;
  int? get searchCategoryId => _searchCategoryId;
  String get searchQuery => _searchQuery;
  bool get hasMoreSearch => _searchPage < _searchLastPage;
  String? get searchError => _searchError;

  // Admin Getters
  List<BookModel> get adminBooks => _adminBooks;
  bool get isLoadingAdmin => _isLoadingAdmin;
  bool get isLoadingMoreAdmin => _isLoadingMoreAdmin;
  String get adminQuery => _adminQuery;
  bool get hasMoreAdmin => _adminPage < _adminLastPage;
  String? get adminError => _adminError;

  // ── Categories Loading ──
  Future<void> loadCategories() async {
    if (_categories.isNotEmpty) return; // Cache categories
    _isLoadingCategories = true;
    notifyListeners();
    try {
      final res = await ApiService.get('/categories', auth: false);
      _categories = (res['data'] as List)
          .map((j) => CategoryModel.fromJson(j))
          .toList();
    } catch (_) {
    } finally {
      _isLoadingCategories = false;
      notifyListeners();
    }
  }

  // ── Home Screen Methods ──
  Future<void> loadHomeBooks({bool refresh = false}) async {
    if (refresh) {
      _homePage = 1;
    }
    _isLoadingHome = refresh || _homeBooks.isEmpty;
    _homeError = null;
    notifyListeners();

    try {
      final query = <String, String>{
        'page': _homePage.toString(),
      };
      if (_homeCategoryId != null) {
        query['category_id'] = _homeCategoryId.toString();
      }

      final res = await ApiService.get('/books', auth: false, query: query);
      final pageData = res['data'];
      final newBooks = (pageData['data'] as List)
          .map((j) => BookModel.fromJson(j))
          .toList();

      if (refresh || _homePage == 1) {
        _homeBooks = newBooks;
      } else {
        _homeBooks.addAll(newBooks);
      }
      _homeLastPage = pageData['last_page'] ?? 1;
    } catch (e) {
      _homeError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoadingHome = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreHome() async {
    if (!hasMoreHome || _isLoadingMoreHome) return;
    _homePage++;
    _isLoadingMoreHome = true;
    notifyListeners();
    try {
      await loadHomeBooks();
    } finally {
      _isLoadingMoreHome = false;
      notifyListeners();
    }
  }

  void filterHomeByCategory(int? catId) {
    _homeCategoryId = catId;
    loadHomeBooks(refresh: true);
  }

  // ── Search Screen Methods ──
  Future<void> loadSearchBooks({bool refresh = false}) async {
    if (refresh) {
      _searchPage = 1;
    }
    _isLoadingSearch = refresh || _searchBooks.isEmpty;
    _searchError = null;
    notifyListeners();

    try {
      final query = <String, String>{
        'page': _searchPage.toString(),
      };
      if (_searchQuery.isNotEmpty) query['q'] = _searchQuery;
      if (_searchCategoryId != null) {
        query['category_id'] = _searchCategoryId.toString();
      }

      final res = await ApiService.get('/books', auth: false, query: query);
      final pageData = res['data'];
      final newBooks = (pageData['data'] as List)
          .map((j) => BookModel.fromJson(j))
          .toList();

      if (refresh || _searchPage == 1) {
        _searchBooks = newBooks;
      } else {
        _searchBooks.addAll(newBooks);
      }
      _searchLastPage = pageData['last_page'] ?? 1;
    } catch (e) {
      _searchError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoadingSearch = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreSearch() async {
    if (!hasMoreSearch || _isLoadingMoreSearch) return;
    _searchPage++;
    _isLoadingMoreSearch = true;
    notifyListeners();
    try {
      await loadSearchBooks();
    } finally {
      _isLoadingMoreSearch = false;
      notifyListeners();
    }
  }

  void searchBooksQuery(String q) {
    _searchQuery = q;
    loadSearchBooks(refresh: true);
  }

  void filterSearchByCategory(int? catId) {
    _searchCategoryId = catId;
    loadSearchBooks(refresh: true);
  }

  void clearSearchFilters() {
    _searchQuery = '';
    _searchCategoryId = null;
    loadSearchBooks(refresh: true);
  }

  // ── Admin Screen Methods ──
  Future<void> loadAdminBooks({bool refresh = false}) async {
    if (refresh) {
      _adminPage = 1;
    }
    _isLoadingAdmin = refresh || _adminBooks.isEmpty;
    _adminError = null;
    notifyListeners();

    try {
      final query = <String, String>{
        'page': _adminPage.toString(),
      };
      if (_adminQuery.isNotEmpty) query['q'] = _adminQuery;

      final res = await ApiService.get('/books', auth: false, query: query);
      final pageData = res['data'];
      final newBooks = (pageData['data'] as List)
          .map((j) => BookModel.fromJson(j))
          .toList();

      if (refresh || _adminPage == 1) {
        _adminBooks = newBooks;
      } else {
        _adminBooks.addAll(newBooks);
      }
      _adminLastPage = pageData['last_page'] ?? 1;
    } catch (e) {
      _adminError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoadingAdmin = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreAdmin() async {
    if (!hasMoreAdmin || _isLoadingMoreAdmin) return;
    _adminPage++;
    _isLoadingMoreAdmin = true;
    notifyListeners();
    try {
      await loadAdminBooks();
    } finally {
      _isLoadingMoreAdmin = false;
      notifyListeners();
    }
  }

  void searchAdminBooks(String q) {
    _adminQuery = q;
    loadAdminBooks(refresh: true);
  }

  void clearAdminFilters() {
    _adminQuery = '';
    loadAdminBooks(refresh: true);
  }

  // ── Book Detail Loading ──
  Future<BookModel?> getBookDetail(int id) async {
    try {
      final res = await ApiService.get('/books/$id', auth: false);
      return BookModel.fromJson(res['data']);
    } catch (_) {
      return null;
    }
  }

  // ── Admin Book CRUD ──
  Future<bool> createBook(Map<String, dynamic> data) async {
    try {
      await ApiService.post('/books', data);
      await loadAdminBooks(refresh: true);
      await loadHomeBooks(refresh: true);
      return true;
    } catch (e) {
      _adminError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateBook(int id, Map<String, dynamic> data) async {
    try {
      await ApiService.put('/books/$id', data);
      await loadAdminBooks(refresh: true);
      await loadHomeBooks(refresh: true);
      return true;
    } catch (e) {
      _adminError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteBook(int id) async {
    try {
      await ApiService.delete('/books/$id');
      _adminBooks.removeWhere((b) => b.id == id);
      _homeBooks.removeWhere((b) => b.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _adminError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAvailability(int id, String availability) async {
    try {
      await ApiService.patch('/books/$id/availability', {'availability': availability});
      await loadAdminBooks(refresh: true);
      await loadHomeBooks(refresh: true);
      return true;
    } catch (e) {
      _adminError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
