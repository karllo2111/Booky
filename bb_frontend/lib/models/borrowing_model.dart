import 'book_model.dart';
import 'user_model.dart';

class BorrowingModel {
  final int id;
  final int userId;
  final int bookId;
  final DateTime borrowedAt;
  final DateTime dueDate;
  final DateTime? returnedAt;
  final String status;
  final String? adminNotes;
  final BookModel? book;
  final UserModel? user;

  BorrowingModel({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.borrowedAt,
    required this.dueDate,
    this.returnedAt,
    required this.status,
    this.adminNotes,
    this.book,
    this.user,
  });

  factory BorrowingModel.fromJson(Map<String, dynamic> json) {
    return BorrowingModel(
      id:          json['id'],
      userId:      json['user_id'],
      bookId:      json['book_id'],
      borrowedAt:  DateTime.parse(json['borrowed_at']),
      dueDate:     DateTime.parse(json['due_date']),
      returnedAt:  json['returned_at'] != null ? DateTime.parse(json['returned_at']) : null,
      status:      json['status'] ?? 'pending',
      adminNotes:  json['admin_notes'],
      book:        json['book'] != null ? BookModel.fromJson(json['book']) : null,
      user:        json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }

  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';
  bool get isOverdue => status == 'overdue';
  bool get isReturned => status == 'returned';
  bool get isCancelled => status == 'cancelled';

  int get daysLeft {
    final now = DateTime.now();
    return dueDate.difference(now).inDays;
  }
}
