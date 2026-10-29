class Loan {
  final String id;
  final String bookId;
  final String studentId;
  final DateTime borrowDate;
  final DateTime dueDate;
  DateTime? returnDate;
  bool wasDeclaredMissing;

  Loan({
    required this.id,
    required this.bookId,
    required this.studentId,
    required this.borrowDate,
    required this.dueDate,
    this.returnDate,
    this.wasDeclaredMissing = false,
  });

  bool get isReturned => returnDate != null;
}