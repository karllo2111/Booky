class NotificationModel {
  final int id;
  final int userId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final int? borrowingId;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.borrowingId,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id:          json['id'],
      userId:      json['user_id'],
      title:       json['title'] ?? '',
      message:     json['message'] ?? '',
      type:        json['type'] ?? 'info',
      isRead:      json['is_read'] == true || json['is_read'] == 1,
      borrowingId: json['borrowing_id'],
      createdAt:   DateTime.parse(json['created_at']),
    );
  }
}
