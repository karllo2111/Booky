import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../models/borrowing_model.dart';

class BorrowingProvider extends ChangeNotifier {
  List<BorrowingModel> _borrowings = [];
  bool _isLoading = false;
  String? _error;
  String? _successMessage;

  List<BorrowingModel> get borrowings => _borrowings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get successMessage => _successMessage;

  Future<void> loadBorrowings({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final query = <String, String>{};
      if (status != null && status != 'all') query['status'] = status;
      final res = await ApiService.get('/borrowings', query: query);
      final pageData = res['data'];
      final list = pageData is Map ? pageData['data'] : pageData;
      _borrowings = (list as List).map((j) => BorrowingModel.fromJson(j)).toList();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> borrowBook(int bookId) async {
    _isLoading = true;
    _error = null;
    _successMessage = null;
    notifyListeners();
    try {
      final res = await ApiService.post('/borrowings', {'book_id': bookId});
      _successMessage = res['message'];
      await loadBorrowings();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelBorrowing(int id) async {
    try {
      await ApiService.post('/borrowings/$id/cancel', {});
      _borrowings.removeWhere((b) => b.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStatus(int id, String status, {String? adminNotes}) async {
    try {
      await ApiService.put('/borrowings/$id/status', {
        'status': status,
        if (adminNotes != null) 'admin_notes': adminNotes,
      });
      await loadBorrowings();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void clearMessages() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }
}
