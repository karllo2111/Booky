import 'category_model.dart';

class BookModel {
  final int id;
  final int categoryId;
  final String title;
  final String author;
  final String? publisher;
  final int? year;
  final String? isbn;
  final String? description;
  final String? coverUrl;
  final int stock;
  final String availability;
  final CategoryModel? category;

  BookModel({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.author,
    this.publisher,
    this.year,
    this.isbn,
    this.description,
    this.coverUrl,
    required this.stock,
    required this.availability,
    this.category,
  });

  factory BookModel.fromJson(Map<String, dynamic> json) {
    return BookModel(
      id:           json['id'],
      categoryId:   json['category_id'],
      title:        json['title'] ?? '',
      author:       json['author'] ?? '',
      publisher:    json['publisher'],
      year:         json['year'],
      isbn:         json['isbn'],
      description:  json['description'],
      coverUrl:     json['cover_url'],
      stock:        json['stock'] ?? 0,
      availability: json['availability'] ?? 'available',
      category:     json['category'] != null ? CategoryModel.fromJson(json['category']) : null,
    );
  }

  bool get isAvailable => availability == 'available';
}
