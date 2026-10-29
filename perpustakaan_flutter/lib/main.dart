import 'package:flutter/material.dart';
import 'viewmodels/library_view_model.dart';
import 'views/library_screen.dart';

void main() {
  runApp(const UniversityLibraryApp());
}

class UniversityLibraryApp extends StatefulWidget {
  const UniversityLibraryApp({super.key});

  @override
  State<UniversityLibraryApp> createState() => _UniversityLibraryAppState();
}

class _UniversityLibraryAppState extends State<UniversityLibraryApp> {
  final LibraryViewModel _viewModel = LibraryViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'University Library System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      home: LibraryScreen(viewModel: _viewModel),
    );
  }
}