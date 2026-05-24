import 'book_model.dart';

class WishlistModel {
  final int id;
  final int userId;
  final int bookId;
  final DateTime createdAt;
  final BookModel? book;

  WishlistModel({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.createdAt,
    this.book,
  });

  factory WishlistModel.fromJson(Map<String, dynamic> json) {
    return WishlistModel(
      id:        json['id'],
      userId:    json['user_id'],
      bookId:    json['book_id'],
      createdAt: DateTime.parse(json['created_at']),
      book:      json['book'] != null ? BookModel.fromJson(json['book']) : null,
    );
  }
}
