enum BookStatus { available, borrowed, overdue, missing }

class Book {
  final String id;
  final String title;
  final String author;
  final int replacementPrice;
  bool isAvailable;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.replacementPrice,
    this.isAvailable = true,
  });
}