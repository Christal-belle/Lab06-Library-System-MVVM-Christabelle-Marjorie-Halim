import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../models/loan.dart';

class LibraryViewModel extends ChangeNotifier {
  static const int weeklyFineRate = 5000;
  static const int defaultLoanDays = 7;

  final List<Book> _books = [];
  final List<Loan> _loans = [];

  String _searchQuery = '';
  BookStatus? _selectedFilter;

  LibraryViewModel() {
    _initDummyData();
  }

  void _initDummyData() {
    final today = _dateOnly(DateTime.now());

    _books.addAll([
      Book(
        id: 'B001',
        title: 'The Golden Fairy',
        author: 'TinkerBella',
        replacementPrice: 250000,
        isAvailable: true,
      ),
      Book(
        id: 'B002',
        title: 'How to Survive in The Human Kitchen',
        author: 'Remy the Mice',
        replacementPrice: 180000,
        isAvailable: true,
      ),
      Book(
        id: 'B003',
        title: 'Unnoticed',
        author: 'Woody',
        replacementPrice: 320000,
        isAvailable: false,
      ),
      Book(
        id: 'B004',
        title: 'I Forgot Every Second',
        author: 'Nemo',
        replacementPrice: 275000,
        isAvailable: false,
      ),
      Book(
        id: 'B005',
        title: 'Mission on Saving Earth',
        author: 'Wall-e',
        replacementPrice: 350000,
        isAvailable: false,
      ),
      Book(
        id: 'B006',
        title: 'How to Get Your Own Prince Charming',
        author: 'Cinderella',
        replacementPrice: 550000,
        isAvailable: false,
      ),
    ]);

    _loans.addAll([
      Loan(
        id: 'L001',
        bookId: 'B003',
        studentId: 'NIM-001',
        borrowDate: today.subtract(const Duration(days: 4)),
        dueDate: today.add(const Duration(days: 3)),
      ),
      Loan(
        id: 'L002',
        bookId: 'B004',
        studentId: 'NIM-002',
        borrowDate: today.subtract(const Duration(days: 14)),
        dueDate: today.subtract(const Duration(days: 7)),
      ),
      Loan(
        id: 'L003',
        bookId: 'B005',
        studentId: 'NIM-003',
        borrowDate: today.subtract(const Duration(days: 21)),
        dueDate: today.subtract(const Duration(days: 14)),
      ),
      Loan(
        id: 'L004',
        bookId: 'B006',
        studentId: 'NIM-004',
        borrowDate: DateTime(today.year, today.month - 7, today.day - 7),
        dueDate: DateTime(today.year, today.month - 7, today.day),
        wasDeclaredMissing: true,
      ),
    ]);
  }

  List<Book> get allBooks => List.unmodifiable(_books);
  List<Loan> get allLoans => List.unmodifiable(_loans);

  List<Loan> get activeLoans => _loans.where((loan) => !loan.isReturned).toList();

  List<Loan> get returnedLoans => _loans.where((loan) => loan.isReturned).toList();

  String get searchQuery => _searchQuery;
  BookStatus? get selectedFilter => _selectedFilter;

  List<Book> get filteredBooks {
    return _books.where((book) {
      final matchesSearch = _searchQuery.isEmpty ||
          book.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          book.author.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          book.id.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesFilter =
          _selectedFilter == null || getBookStatus(book) == _selectedFilter;

      return matchesSearch && matchesFilter;
    }).toList();
  }

  int get totalOutstandingFines {
    int total = 0;
    for (final loan in _loans) {
      total += calculateFine(loan);
    }
    return total;
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Book? getBookById(String bookId) {
    try {
      return _books.firstWhere((b) => b.id == bookId);
    } catch (_) {
      return null;
    }
  }

  Loan? getActiveLoanForBook(String bookId) {
    try {
      return _loans.firstWhere((l) => l.bookId == bookId && !l.isReturned);
    } catch (_) {
      return null;
    }
  }

  bool isLoanMissing(Loan loan) {
    if (loan.wasDeclaredMissing) return true;

    final due = _dateOnly(loan.dueDate);
    final refDate = _dateOnly(loan.returnDate ?? DateTime.now());

    final sixMonthsThreshold = DateTime(due.year, due.month + 6, due.day);

    return !refDate.isBefore(sixMonthsThreshold);
  }

  bool isLoanOverdue(Loan loan) {
    final due = _dateOnly(loan.dueDate);
    final refDate = _dateOnly(loan.returnDate ?? DateTime.now());
    return refDate.isAfter(due) && !isLoanMissing(loan);
  }

  BookStatus getOverdueStatus(Loan loan) {
    if (isLoanMissing(loan)) {
      return BookStatus.missing;
    }
    if (isLoanOverdue(loan)) {
      return BookStatus.overdue;
    }
    return loan.isReturned ? BookStatus.available : BookStatus.borrowed;
  }

  BookStatus getBookStatus(Book book) {
    if (book.isAvailable) {
      return BookStatus.available;
    }
    final activeLoan = getActiveLoanForBook(book.id);
    if (activeLoan == null) {
      return BookStatus.available;
    }
    return getOverdueStatus(activeLoan);
  }

  int calculateFine(Loan loan) {
    final book = getBookById(loan.bookId);
    if (book == null) return 0;

    final due = _dateOnly(loan.dueDate);
    final refDate = _dateOnly(loan.returnDate ?? DateTime.now());

    if (!refDate.isAfter(due) && !isLoanMissing(loan)) {
      return 0;
    }

    int runningFine = 0;
    final daysOverdue = refDate.difference(due).inDays;

    for (int day = 1; day <= daysOverdue; day++) {
      int weekNumber = ((day - 1) ~/ 7) + 1;
      runningFine += weekNumber * weeklyFineRate;
    }

    if (isLoanMissing(loan)) {
      return book.replacementPrice + runningFine;
    }

    return runningFine;
  }

  bool borrowBook(String bookId, String studentId) {
    final book = getBookById(bookId);
    if (book == null || !book.isAvailable) {
      return false;
    }

    if (getActiveLoanForBook(bookId) != null) {
      return false;
    }

    final today = _dateOnly(DateTime.now());
    final newLoan = Loan(
      id: 'L${(_loans.length + 1).toString().padLeft(3, '0')}',
      bookId: book.id,
      studentId: studentId.trim().isEmpty ? 'STD-001' : studentId.trim(),
      borrowDate: today,
      dueDate: today.add(const Duration(days: defaultLoanDays)),
    );

    book.isAvailable = false;
    _loans.insert(0, newLoan);

    notifyListeners();
    return true;
  }

  bool returnBook(String loanId) {
    Loan? loan;
    try {
      loan = _loans.firstWhere((l) => l.id == loanId);
    } catch (_) {
      return false;
    }

    if (loan.isReturned) {
      return false;
    }

    if (isLoanMissing(loan)) {
      loan.wasDeclaredMissing = true;
    }

    loan.returnDate = _dateOnly(DateTime.now());

    final book = getBookById(loan.bookId);
    if (book != null) {
      book.isAvailable = true;
    }

    notifyListeners();
    return true;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(BookStatus? status) {
    _selectedFilter = status;
    notifyListeners();
  }
}