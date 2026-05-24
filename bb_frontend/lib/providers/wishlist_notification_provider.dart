import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../models/wishlist_model.dart';
import '../models/notification_model.dart';

class WishlistProvider extends ChangeNotifier {
  List<WishlistModel> _wishlists = [];
  bool _isLoading = false;
  Set<int> _wishlistBookIds = {};

  List<WishlistModel> get wishlists => _wishlists;
  bool get isLoading => _isLoading;
  Set<int> get wishlistBookIds => _wishlistBookIds;

  bool isInWishlist(int bookId) => _wishlistBookIds.contains(bookId);

  Future<void> loadWishlists() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await ApiService.get('/wishlist');
      _wishlists = (res['data'] as List).map((j) => WishlistModel.fromJson(j)).toList();
      _wishlistBookIds = _wishlists.map((w) => w.bookId).toSet();
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addToWishlist(int bookId) async {
    try {
      await ApiService.post('/wishlist', {'book_id': bookId});
      _wishlistBookIds.add(bookId);
      await loadWishlists();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeFromWishlist(int bookId) async {
    try {
      await ApiService.delete('/wishlist/$bookId');
      _wishlistBookIds.remove(bookId);
      _wishlists.removeWhere((w) => w.bookId == bookId);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await ApiService.get('/notifications');
      final pageData = res['data'];
      final list = pageData is Map ? pageData['data'] : pageData;
      _notifications = (list as List).map((j) => NotificationModel.fromJson(j)).toList();
      _unreadCount = res['unread_count'] ?? 0;
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<void> markRead(int id) async {
    try {
      await ApiService.post('/notifications/$id/read', {});
      final idx = _notifications.indexWhere((n) => n.id == id);
      if (idx != -1 && !_notifications[idx].isRead) {
        _unreadCount = (_unreadCount - 1).clamp(0, 9999);
        notifyListeners();
      }
      await loadNotifications();
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await ApiService.post('/notifications/read-all', {});
      _unreadCount = 0;
      notifyListeners();
      await loadNotifications();
    } catch (_) {}
  }

  Future<bool> sendNotification({
    required String title,
    required String message,
    required String type,
    int? userId,
  }) async {
    try {
      await ApiService.post('/notifications/send', {
        'title': title,
        'message': message,
        'type': type,
        if (userId != null) 'user_id': userId,
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
