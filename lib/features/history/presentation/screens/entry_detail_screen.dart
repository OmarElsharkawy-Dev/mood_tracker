import 'package:flutter/material.dart';

class EntryDetailScreen extends StatelessWidget {
  const EntryDetailScreen({super.key, required this.entryId});
  final String entryId;
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('Entry $entryId (placeholder)')));
}
