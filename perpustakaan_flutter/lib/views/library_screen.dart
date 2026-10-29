import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/loan.dart';
import '../viewmodels/library_view_model.dart';

class LibraryScreen extends StatefulWidget {
  final LibraryViewModel viewModel;

  const LibraryScreen({super.key, required this.viewModel});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _studentIdController = TextEditingController(
    text: 'NIM-',
  );

  @override
  void dispose() {
    _studentIdController.dispose();
    super.dispose();
  }

  String _formatCurrency(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer('Rp');
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('University Library System'),
              centerTitle: false,
              bottom: TabBar(
                tabs: [
                  Tab(
                    icon: const Icon(Icons.menu_book_outlined),
                    text: 'Catalogue (${vm.filteredBooks.length})',
                  ),
                  Tab(
                    icon: const Icon(Icons.assignment_ind_outlined),
                    text: 'Loans (${vm.activeLoans.length} Active)',
                  ),
                ],
              ),
            ),
            body: Column(
              children: [
                _FineSummaryBanner(
                  totalFineFormatted: _formatCurrency(vm.totalOutstandingFines),
                  activeLoanCount: vm.activeLoans.length,
                ),

                Expanded(
                  child: TabBarView(
                    children: [
                      _buildCatalogueTab(context, vm),
                      _buildLoansTab(context, vm),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCatalogueTab(BuildContext context, LibraryViewModel vm) {
    final books = vm.filteredBooks;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search by title, author, or book ID...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: vm.setSearchQuery,
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              FilterChip(
                label: const Text('All'),
                selected: vm.selectedFilter == null,
                onSelected: (_) => vm.setStatusFilter(null),
              ),
              const SizedBox(width: 8),
              ...BookStatus.values.map((status) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(status.name.toUpperCase()),
                    selected: vm.selectedFilter == status,
                    onSelected: (_) => vm.setStatusFilter(status),
                  ),
                );
              }),
            ],
          ),
        ),

        if (books.isEmpty)
          const Expanded(
            child: Center(
              child: Text('No books match the current search or filter.'),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                final status = vm.getBookStatus(book);

                return BookCard(
                  book: book,
                  status: status,
                  formattedReplacementPrice:
                      _formatCurrency(book.replacementPrice),
                  onBorrow: () => _showBorrowDialog(context, vm, book),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildLoansTab(BuildContext context, LibraryViewModel vm) {
    final loans = vm.allLoans;

    if (loans.isEmpty) {
      return const Center(
        child: Text('No borrowing records found.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: loans.length,
      itemBuilder: (context, index) {
        final loan = loans[index];
        final book = vm.getBookById(loan.bookId);
        final fine = vm.calculateFine(loan);
        final status = vm.getOverdueStatus(loan);

        return LoanCard(
          loan: loan,
          bookTitle: book?.title ?? 'Unknown Book',
          status: status,
          formattedBorrowDate: _formatDate(loan.borrowDate),
          formattedDueDate: _formatDate(loan.dueDate),
          formattedReturnDate:
              loan.returnDate != null ? _formatDate(loan.returnDate!) : null,
          formattedFine: _formatCurrency(fine),
          hasFine: fine > 0,
          onReturn: () => vm.returnBook(loan.id),
        );
      },
    );
  }

  void _showBorrowDialog(
    BuildContext context,
    LibraryViewModel vm,
    Book book,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Borrow "${book.title}"'),
        content: TextField(
          controller: _studentIdController,
          decoration: const InputDecoration(
            labelText: 'Student ID (NIM)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final success = vm.borrowBook(
                book.id,
                _studentIdController.text,
              );
              Navigator.pop(ctx);
              if (!success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Book is not eligible for borrowing.'),
                  ),
                );
              }
            },
            child: const Text('Confirm Borrow'),
          ),
        ],
      ),
    );
  }
}

class _FineSummaryBanner extends StatelessWidget {
  final String totalFineFormatted;
  final int activeLoanCount;

  const _FineSummaryBanner({
    required this.totalFineFormatted,
    required this.activeLoanCount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Outstanding Fines',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                totalFineFormatted,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
              ),
            ],
          ),
          Chip(
            label: Text('$activeLoanCount Active Loans'),
          ),
        ],
      ),
    );
  }
}

class BookCard extends StatelessWidget {
  final Book book;
  final BookStatus status;
  final String formattedReplacementPrice;
  final VoidCallback onBorrow;

  const BookCard({
    super.key,
    required this.book,
    required this.status,
    required this.formattedReplacementPrice,
    required this.onBorrow,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        book.id,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(width: 8),
                      _StatusBadge(status: status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    book.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text('Author: ${book.author}'),
                  const SizedBox(height: 4),
                  Text(
                    'Replacement Price: $formattedReplacementPrice',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: book.isAvailable ? onBorrow : null,
              child: const Text('Borrow'),
            ),
          ],
        ),
      ),
    );
  }
}

class LoanCard extends StatelessWidget {
  final Loan loan;
  final String bookTitle;
  final BookStatus status;
  final String formattedBorrowDate;
  final String formattedDueDate;
  final String? formattedReturnDate;
  final String formattedFine;
  final bool hasFine;
  final VoidCallback onReturn;

  const LoanCard({
    super.key,
    required this.loan,
    required this.bookTitle,
    required this.status,
    required this.formattedBorrowDate,
    required this.formattedDueDate,
    required this.formattedReturnDate,
    required this.formattedFine,
    required this.hasFine,
    required this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${loan.id} • Student: ${loan.studentId}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                _StatusBadge(
                  status: status,
                  isReturned: loan.isReturned,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              bookTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text('Borrowed: $formattedBorrowDate  |  Due: $formattedDueDate'),
            if (formattedReturnDate != null)
              Text('Returned on: $formattedReturnDate'),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status == BookStatus.missing
                          ? 'Replacement Charge (Missing):'
                          : 'Overdue Fine:',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      formattedFine,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: hasFine
                                ? colorScheme.error
                                : colorScheme.primary,
                          ),
                    ),
                  ],
                ),
                if (!loan.isReturned)
                  OutlinedButton.icon(
                    onPressed: onReturn,
                    icon: const Icon(Icons.assignment_turned_in_outlined),
                    label: const Text('Return Book'),
                  )
                else
                  const Chip(
                    avatar: Icon(Icons.check, size: 16),
                    label: Text('Returned'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final BookStatus status;
  final bool isReturned;

  const _StatusBadge({
    required this.status,
    this.isReturned = false,
  });

  @override
  Widget build(BuildContext context) {
    final (String label, Color bgColor, Color textColor) = switch (status) {
      BookStatus.available => (
          isReturned ? 'RETURNED' : 'AVAILABLE',
          Colors.green.shade100,
          Colors.green.shade900
        ),
      BookStatus.borrowed => (
          'BORROWED',
          Colors.blue.shade100,
          Colors.blue.shade900
        ),
      BookStatus.overdue => (
          'OVERDUE',
          Colors.orange.shade100,
          Colors.orange.shade900
        ),
      BookStatus.missing => (
          'MISSING (6+ MO)',
          Colors.red.shade100,
          Colors.red.shade900
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}